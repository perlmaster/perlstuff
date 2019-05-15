#!/usr/bin/perl -w

######################################################################
#
# File      : mydesc.pl
#
# Author    : Barry Kimelman
#
# Created   : October 30, 2005
#
# Purpose   : Describe the structure of mysql database tables
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

require "time_date.pl";
require "mysql_utils.pl";
require "print_lists.pl";
require "display_pod_help.pl";

my ( $owner , $dbh );

my %options = ( "d" => 0 , "h" => 0 , "D" => "qwlc" );

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
	my ( %columns , @colnames , $numcols , $ref , @arrays , @headers , $errmsg );
	my ( @data_types , @nulls , @comments , @col_key , @extra , @maxlen , $enum );

	print "\n==  $table [ $dbname ]  ==\n\n";

	$numcols = get_table_columns_info($table,$dbname,\%columns,\@colnames,\$errmsg);
	if ( $numcols < 0 ) {
		warn("\n$errmsg\n");
		return;
	} # IF

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
# Purpose   : Describe the structure of mysql database tables
#
# Inputs    : @ARGV - optional arguments
#
# Output    : File contents
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : describe.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( @tables , $table , %tables , %attr , $errmsg );
	my ( @colnames , $statement , $table_sth , $qual , $name , $remarks );
	my ( $type , @matched , $match , $status , $pattern , $clock );

	$status = getopts("hdD:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-hd] [-D database] table [... table]\n");
	} # UNLESS

	%attr = ( "PrintError" => 0 , "RaiseError" => 0 );
	$dbh = mysql_connect_to_db($options{'D'}, "127.0.0.1", "root", "archer-nx01", \$errmsg, \%attr);
	unless ( defined $dbh ) {
		die("Can't connect to database\n${errmsg}\n\n");
	} # UNLESS

	$clock = time;
	print "\n",format_time_date($clock),"\n\n";

	if ( 1 > @ARGV ) {
		die("No table name was specified.\n");
	} # IF
	else {
		foreach $table ( @ARGV ) {
			describe_table($table,$options{"D"});
		} # FOREACH
	} # ELSE

	# disconnect from databse
	$dbh->disconnect;

	exit 0;
} # end of MAIN
__END__
=head1 NAME

mydesc2.pl - Describe the structure of mysql database tables

=head1 SYNOPSIS

mydesc2.pl [-hd] [-D database] table [... table]

=head1 DESCRIPTION

Describe the structure of mysql database tables

=head1 PARAMETERS

  dirname - name of directory to be processed

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

mydesc2.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
