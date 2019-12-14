#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : show-tables.pl
#
# Author    : Barry Kimelman
#
# Created   : April 13, 2017
#
# Purpose   : List all the tables in a schema
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Sys::Hostname;
use DBI;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;

require "mysql_utils.pl";
require "print_lists.pl";
require "display_pod_help.pl";
require "list_columns_style.pl";

my %options = ( "d" => 0 , "h" => 0 , "t" => 0 , "D" => 0 , "p" => "." , "c" => 0 );

######################################################################
#
# Function  : describe_table
#
# Purpose   : Print table descriptive information.
#
# Inputs    : $_[0] - tablename
#             $_[1] - database name
#
# Output    : table description
#
# Returns   : nothing
#
# Example   : describe_table($tablename,$dbname);
#
# Notes     : (none)
#
######################################################################

sub describe_table
{
	my ( $table , $dbname ) = @_;
	my ( %columns , @colnames , $numcols , $ref , @arrays , @headers );
	my ( @data_types , @nulls , @comments , @col_key , @extra , @maxlen , $enum );

	print "\n==  $table [ $dbname ]  ==\n\n";

	$numcols = get_table_columns_info($table,$dbname,\%columns,\@colnames);

	@data_types = ();
	@nulls = ();
	@comments = ();
	@col_key = ();
	@extra = ();
	@maxlen = ();
	foreach my $column ( @colnames ) {
		$ref = $columns{$column};
		push @data_types,$ref->{'column_type'};
		push @col_key,$ref->{'column_key'};
		push @nulls,$ref->{'is_null'};
		push @comments,$ref->{'comment'};
		push @extra,$ref->{'extra'};
		if ( defined $ref->{'char_maxlen'} ) {
			push @maxlen,$ref->{'char_maxlen'};
		} # IF
		else {
			push @maxlen,"--";
		} # ELSE
	} # FOREACH
	@arrays = ( \@colnames , \@data_types , \@maxlen , \@nulls , \@col_key , \@extra , \@comments );
	@headers = ( "Column name" , "Data Type" , "Maxlen" , "Nullable ?" , "Key" , "Extra" , "Comment" );
	print_lists_with_trim(\@arrays,\@headers,"=");

	return;
} # end of describe_table

######################################################################
#
# Function  : MAIN
#
# Purpose   : List all the tables in a schema
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : show-tables.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $buffer , $ref , $dbh , $query , $sth , $count );
	my ( $ref_names , @colnames , $ref_all , @row , $errmsg , %attr );
	my ( $index , @index , @table , @type );

	$status = getopts("dhtDp:c",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF

	unless ( $status && 0 < @ARGV ) {
		die("Usage : $0 [-dhtDc] [-p pattern] schema\n");
	} # UNLESS
	$status = localtime;
	print "$status\n\n";

	%attr = ( "PrintError" => 0 , "RaiseError" => 0 );
	$dbh = mysql_connect_to_db($ARGV[0], "127.0.0.1", "root", "archer-nx01", \$errmsg, \%attr);
	unless ( defined $dbh ) {
		die("$\n$errmsg\n");
	} # UNLESS

	$query =<<QUERY;
SELECT TABLE_NAME,TABLE_TYPE FROM `information_schema`.`tables` where table_schema = '$ARGV[0]';
QUERY

	$sth = $dbh->prepare($query);
	unless ( defined $sth ) {
		warn("prepare failed for [$query] : $DBI::errstr\n");
		$dbh->disconnect();
		exit 1;
	} # UNLESS
	unless ( $sth->execute() ) {
		$sth->finish();
		$dbh->disconnect();
	} # UNLESS
	$ref_names = $sth->{'NAME'};
	@colnames = @$ref_names;

	$ref_all = $sth->fetchall_arrayref();
	$count = scalar @$ref_all;

	$sth->finish();
	$dbh->disconnect();

	$index = 0;
	@index = ();
	@table = ();
	@type = ();
	foreach my $row ( @$ref_all ) {
		@row = @$row;
		if ( $row[0] =~ m/${options{'p'}}/i ) {
			$index += 1;
			push @index,$index;
			push @table,$row[0];
			push @type,$row[1];
		} # IF
	} # FOREACH
	if ( $options{'c'} ) {
		list_columns_style(\@table,100,"${index} tables under $ARGV[0]\n",\*STDOUT);
	} # IF
	else {
		if ( $options{'t'} ) {
			print join("\n",@table),"\n";
		} # IF
		else {
			print_lists( [ \@index , \@table , \@type ] , [ "#" , "Table" , "Type" ] , "=" );
		} # ELSE
	} # ELSE

	if ( $options{"D"} ) {
		foreach my $row ( @$ref_all ) {
			@row = @$row;
			if ( $row[0] =~ m/${options{'p'}}/i ) {
				describe_table($row[0],$ARGV[0]);
			} # IF
		} # FOREACH
	} # IF

	print "\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

show-tables.pl - List all the tables in a schema

=head1 SYNOPSIS

show-tables.pl [-dhtDc] [-p pattern] schema

=head1 DESCRIPTION

List all the tables in a schema

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -t - only list table names
  -c - list table names in a comnpact columns style
  -D - describe the listed tables
  -p pattern - only show tables whose name matches this pattern

=head1 PARAMETERS

  schema - schema name

=head1 EXAMPLES

show-tables.pl 'schema1'

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
