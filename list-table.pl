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

require "mysql_utils.pl";
require "print_lists.pl";

my %options = ( "d" => 0 , "h" => 0 , "t" => 0 , "r" => -1 , "D" => "qwlc" );
my $dbh;
my @column_headers = ();

######################################################################
#
# Function  : debug_print
#
# Purpose   : Optionally print a debugging message.
#
# Inputs    : @_ - array of strings comprising message
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : debug_print("Process the files : ",join(" ",@xx),"\n");
#
# Notes     : (none)
#
######################################################################

sub debug_print
{
	if ( $options{"d"} ) {
		print join("",@_);
	} # IF

	return;
} # end of debug_print

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
	my ( $length , $column , $row , @headers );
	my ( $ref_names , @rows , @row , $row_num );

	print "\n==  $table  ==\n\n";

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
	while ( $row = $sth->fetchrow_hashref ) {
		$row_num += 1;
		if ( $options{'r'} > 0 && $row_num > $options{'r'} ) {
			last;
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

	if ( exists $options{'c'} || exists $options{"C"} ) {
		@headers = @column_headers;
	} # IF
	else {
		@headers = @colnames;
	} # ELSE
	print_list_of_rows(\@rows,\@headers,"=",0,\*STDOUT);

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
	my ( $status );

	$status = getopts("dhc:C:tr:D:",\%options);
	if ( $options{"h"} ) {
		if ( $^O =~ m/MSWin/ ) {
# Windows stuff goes here
			system("pod2text $0 | more");
		} # IF
		else {
# Non-Windows stuff (i.e. UNIX) goes here
			system("pod2man $0 | nroff -man | less -M");
		} # ELSE
		exit 0;
	} # IF
	unless ( $status && 0 < @ARGV ) {
		die("Usage : $0 [-dht] [-D database] [-r rows_limit] [-C column_header_strings] [-c column_headers_file] table [... table]\n");
	} # IF
	print "\n";
	if ( $options{"t"} ) {
		$status = localtime;
		print "$status\n\n";
	} # IF
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
	$dbh = mysql_connect_to_db($options{"D"},"127.0.0.1","root","archer-nx01");

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

list-table.pl [-hdt] [-D database] [-r rows_limit] [-C column_header_strings] [-c column_headers_file] table [... table]

=head1 DESCRIPTION

Display the records in a table.

=head1 PARAMETERS

  table - name of database table

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -c filename - name of file containing list of column headers
  -C csv_list - comma separated list of column headers
  -t - display a time/date message
  -r rows_limit - only display this many rows
  -D database - override default database

=head1 EXAMPLES

list-table.pl customers

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
