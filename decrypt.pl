#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : decrypt.pl
#
# Author    : Barry Kimelman
#
# Created   : May 28, 2020
#
# Purpose   : Query an encrypted database table
#
######################################################################

use strict;
use warnings;
use DBI;
use Time::Local;
use File::Spec;
use File::Basename;
use Data::Dumper;
use Term::ReadKey;
use FindBin;
use lib $FindBin::Bin;
use months_days;

require "mysql_utils.pl";
require "display_pod_help.pl";
require "print_lists.pl";

my $table_name;
my $encrypted_field;
my $secret_key;
my %options = ( "d" => 0 , "h" => 0 , "D" => "mydatabase" );
my $dbh;

######################################################################
#
# Function  : run_query
#
# Purpose   : Run the specified query
#
# Inputs    : $_[0] - buffer containing a query
#
# Output    : formatted query output
#
# Returns   : IF problem THEN negative ELSE zero
#
# Example   : $status = run_query($sql);
#
# Notes     : (none)
#
######################################################################

sub run_query
{
	my ( $sql ) = @_;
	my ( $sth , @colnames , $colname , $status , $num_cols , $i );
	my ( $length , $column , $row , $maxlen , $hex );
	my ( $ref_names , @rows , @row , $row_num );

	# executing the SQL statement.

	$sth = $dbh->prepare($sql);
	unless ( defined $sth ) {
		warn("can't prepare sql : $sql\n$DBI::errstr\n");
		$dbh->disconnect();
		die("Goodbye ...\n");
	} # UNLESS
	unless ( $sth->execute ) {
		warn("can't execute sql : $sql\n$DBI::errstr\n");
		$dbh->disconnect();
		die("Goodbye ...\n");
	} # UNLESS

	$num_cols = $sth->{NUM_OF_FIELDS};
	$ref_names = $sth->{'NAME'};
	@colnames = @$ref_names;
	$maxlen = (sort { $b <=> $a} map { length $_ } @colnames)[0];

	@rows = ();
	$row_num = 0;
	while ( $row = $sth->fetchrow_hashref ) {
		$row_num += 1;
		if ( $options{'v'} ) {
			print "\nRow ${row_num}\n",Dumper($row);
		} # IF
		@row = ();
		for ( $i = 0 ; $i <= $#colnames ; ++$i ) {
			$colname = $colnames[$i];
			$column = $row->{$colname};
			unless ( defined $column ) {
				$column = " ";
			} # UNLESS
			push @row,$column;
		} # FOR over columns in row
		push @rows,[ @row ];
	} # WHILE over all rows in table
	$sth->finish();

	if ( $options{'c'} || $options{"H"} ) {
		foreach my $row ( @rows ) {
			@row = @$row;
			print "\n";
			if ( $options{"H"} ) {
				for ( $i = 0 ; $i < $num_cols ; ++$i ) {
					print "$colnames[$i]\n";
					$hex = hexdump($row[$i],0);
					print "$hex\n";
				} # FOR
			} # IF
			else {
				for ( $i = 0 ; $i < $num_cols ; ++$i ) {
					printf "%-${maxlen}.${maxlen}s %s\n",$colnames[$i],$row[$i];
				} # FOR
			} # ELSE
		} # FOREACH
	} # IF
	else {
		print "\n";
		print_list_of_rows(\@rows,\@colnames,"=",0,\*STDOUT);
	} # ELSE
	print "\n${row_num} rows returned from the query\n";

	return 0;
} # end of run_query

######################################################################
#
# Function  : MAIN
#
# Purpose   : Query an encrypted database table
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : decrypt.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $sql , $sth , $ref_all , $count , %attr , $errmsg );
	my ( $ref , $pattern , $numcols , %columns , @colnames );
	my ( $ref_enc , @names , @ids , @indices );

	$status = getopts("hdD:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 2 == scalar @ARGV ) {
		die("Usage : $0 [-hd] [-D database_name] table_name field_name\n");
	} # UNLESS
	$table_name = $ARGV[0];
	$encrypted_field = $ARGV[1];

	%attr = ( "PrintError" => 0 , "RaiseError" => 0 );
	$dbh = mysql_connect_to_db($options{'D'}, "127.0.0.1", "root", "mypassword", \$errmsg, \%attr);
	unless ( defined $dbh ) {
		die("Can't connect to database\n${errmsg}\n\n");
	} # UNLESS

	$numcols = get_table_columns_info($table_name,$options{"D"},\%columns,\@colnames,\$errmsg);
	if ( $numcols < 0 ) {
		die("\n$errmsg\n");
	} # IF

	$ref_enc = $columns{$encrypted_field};
	unless ( defined $ref_enc ) {
		die("'$encrypted_field' is not a column in '$table_name'\n");
	} # UNLESS
	delete $columns{$encrypted_field};
	@names = keys %columns;
	@ids = ();
	foreach my $name ( @names ) {
		push @ids,$columns{$name}{"ordinal"};
	} # FOREACH
	@indices = sort { $ids[$a] <=> $ids[$b] } (0 .. $#ids);
	@names = @names[@indices];

	ReadMode( "noecho");
	print "Please enter decryption key : ";
	$secret_key = <STDIN>;
	chomp $secret_key;
	ReadMode ("original") ;
	print "\n";

	$sql = "SELECT " . join(" , ",@names) . " , ";
	$sql .= "aes_decrypt($encrypted_field,'$secret_key') $encrypted_field ";
	$sql .= "FROM $table_name";

	run_query($sql);

	$dbh->disconnect();

	exit(0);
} # end of MAIN
__END__
=head1 NAME

decrypt.pl - Query an encrypted database table

=head1 SYNOPSIS

decrypt.pl [-dh] [-D database_name] table_name encrypted_field_name

=head1 DESCRIPTION

Query an encrypted database table

=head1 PARAMETERS

  table_name - name of database table
  encrypted_field_name - name of field containing encrypted data

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -D database_name - override default database name

=head1 EXAMPLES

decrypt.pl my_table encrypted_data

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
