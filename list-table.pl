#!/usr/bin/perl -w

######################################################################
#
# File      : list-table.pl
#
# Author    : Barry Kimelman
#
# Created   : June 26, 2005
#
# Purpose   : Display the records in a table.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;
use DBI;
use database;

require "print_lists.pl";
require "mysql_utils.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "t" => 0 , "r" => -1 , "D" => $database::db_name , "x" => 0 );
my $dbh;
my @column_headers = ();

######################################################################
#
# Function  : dump_table
#
# Purpose   : Dump the contents of the named table
#
# Inputs    : $_[0] - database table name
#
# Output    : formatted table dump
#
# Returns   : IF problem THEN negative ELSE zero
#
# Example   : $status = dump_table($table);
#
# Notes     : (none)
#
######################################################################

sub dump_table
{
	my ( $table ) = @_;
	my ( $sql , $sth , @colnames , $colname , $status , $num_cols , $i );
	my ( $length , $column , $row , @headers , $maxlen , $errmsg , $comment );
	my ( $ref_names , @rows , @row , $row_num , $num_rows );

	$comment = get_table_comment($table,$options{"D"},\$errmsg,$dbh);
	if ( defined $comment ) {
		if ( $comment =~ m/\S/ ) {
			$comment = " : $comment";
		} # IF
		else {
			$comment = "";
		} # ELSE
	} # IF
	else {
		print "\n$errmsg\n";
	} # ELSE

	print "\n==  $table${comment}  ==\n\n";

	$sql = "SELECT * FROM $table";

	# executing the SQL statement.

	$sth = $dbh->prepare($sql);
	unless ( defined $sth ) {
		warn("can't prepare sql : $sql\n$DBI::errstr\n");
		return -1;
	} # UNLESS
	unless ( $sth->execute ) {
		warn("can't execute sql : $sql\n$DBI::errstr\n");
		return -1;
	} # UNLESS

	$num_cols = $sth->{NUM_OF_FIELDS};
	$ref_names = $sth->{'NAME'};
	@colnames = @$ref_names;

	@rows = ();
	$row_num = 0;
	$num_rows = 0;
	while ( $row = $sth->fetchrow_hashref ) {
		$row_num += 1;
		if ( $options{'r'} > 0 && $row_num > $options{'r'} ) {
			last;
		} # IF
		$num_rows += 1;
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

	if ( exists $options{'c'} || exists $options{"C"} ) {
		@headers = @column_headers;
	} # IF
	else {
		@headers = @colnames;
	} # ELSE
	$maxlen = (sort { $b <=> $a} map { length $_ } @headers)[0];

	if ( $options{'x'} ) {
		$row_num = 0;
		foreach my $row ( @rows ) {
			$row_num += 1;
			@row = @$row;
			print "\nRecord ${row_num}\n";
			if ( $options{'n'} ) {
				printf "Record %d\n",$row_num;
			} # IF
			for ( $i = 0 ; $i < $num_cols ; ++$i ) {
				printf "%-${maxlen}.${maxlen}s %s\n",$headers[$i],$row[$i];
			} # FOR
		} # FOREACH
	} # IF
	else {
		print "\n";
		print_list_of_rows(\@rows,\@headers,"=",0,\*STDOUT);
	} # ELSE
	print "\n${num_rows} rows retrieved from table ${table}\n";

	return 0;
} # end of dump_table

######################################################################
#
# Function  : MAIN
#
# Purpose   : Display the records in a table.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : File contents
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : list-table.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $errmsg );

	$status = getopts("dhc:C:tr:D:x",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < @ARGV ) {
		die("Usage : $0 [-dhtx] [-D database] [-r rows_limit] [-C column_header_strings] [-c column_headers_file] table [... table]\n");
	} # IF
	print "\n";

	unless ( $options{"t"} ) {
		$status = localtime;
		print "$status\n\n";
	} # UNLESS

	if ( exists $options{'c'} && exists $options{"C"} ) {
		die("options 'c' and 'C' are mutually exclusive\n");
	} # IF
	if ( exists $options{'c'} ) {
		unless ( open(INPUT,"<$options{'c'}") ) {
			die("open failed for '$options{'c'}' : $!\n");
		} # UNLESS
		@column_headers = <INPUT>;
		close INPUT;
		chomp @column_headers;
	} # IF
	if ( exists $options{'C'} ) {
		@column_headers = split(/,/,$options{"C"});
	} # IF

	# connect to the database.
	$dbh = database::connect_to_mysql_database($options{"D"},"127.0.0.1",$database::db_user,$database::db_pass, \$errmsg);
	unless ( defined $dbh ) {
		die("Can't connect to database '$options{'D'}' as $database::db_user\n$errmsg\n");
	} # UNLESS

	foreach my $table ( @ARGV ) {
		dump_table($table);
	} # FOREACH

	# disconnect from databse
	$dbh->disconnect;

	exit 0;
} # end of MAIN
__END__
=head1 NAME

list-table.pl - Display the records in a table.

=head1 SYNOPSIS

list-table.pl [-hdtx] [-D database] [-r rows_limit] [-C column_header_strings] [-c column_headers_file] table [... table]

=head1 DESCRIPTION

Display the records in a table.

=head1 PARAMETERS

  table - name of database table

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -c filename - name of file containing list of column headers
  -C csv_list - comma separated list of column headers
  -t - do not display a time/date message
  -r rows_limit - only display this many rows
  -D database - override default database
  -x - list records in column format

=head1 EXAMPLES

list-table.pl customers

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
