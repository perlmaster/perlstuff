#!/usr/bin/perl -w

######################################################################
#
# File      : run-query.pl
#
# Author    : Barry Kimelman
#
# Created   : November 30, 2017
#
# Purpose   : Run the specified query
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
require "display_pod_help.pl";
require "hexdump.pl";

my %options = (
	"d" => 0 , "h" => 0 , "c" => 0 , "f" => 0 , "H" => 0 , "v" => 0 , "e" => 0
);
my $dbh;

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

	unless ( $options{'e'} ) {
		print "\n$sql\n";
	} # UNLESS
	else {
		print "\n";
	} # ELSE

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
# Purpose   : Run the specified query
#
# Inputs    : @ARGV - optional arguments
#
# Output    : File contents
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : run-query.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , $sql , @sql , $errmsg );

	$status = getopts("dhcfHve",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dhcfHve] query\n");
	} # IF
	$status = localtime;
	print "\n$status\n\n";

	if ( $options{'f'} ) {
		$filename = $ARGV[0];
		unless ( open(QUERY,"<$filename") ) {
			die("open failed for '$filename' : $!\n");
		} # UNLESS
		@sql = <QUERY>;
		close QUERY;
		@sql = grep ! /^\s*#/,@sql;  # delete comment lines
		@sql = grep /\S/,@sql;  # delete blank lines
		$sql = join("",@sql);
		$sql =~ s/^\s+//g;
	} # IF
	else {
		$sql = join(" ",@ARGV);
	} # ELSE

	unless ( $sql =~ m/SELECT/is ) {
		die("SQL does not begin with 'SELECT'\n$sql\n");
	} # UNLESS

	# connect to the database.
	$dbh = database::connect_to_mysql_database($database::db_name,"127.0.0.1",$database::db_user,$database::db_pass, \$errmsg);
	unless ( defined $dbh ) {
		die("Can't connect to '$database::db_name' as '$database::db_user'\n$errmsg\n");
	} # UNLESS

	run_query($sql);

	# disconnect from databse
	$dbh->disconnect;

	exit 0;
} # end of MAIN
__END__
=head1 NAME

run-query.pl - Run the specified query

=head1 SYNOPSIS

run-query.pl [-hdcfHe] query

=head1 DESCRIPTION

Run the specified query

=head1 PARAMETERS

  query_file - name of SQL file containing query

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -v - activate verbose mode
  -c - display records in column format
  -f - query parameter is the name of a file containing the query
  -H - display column values in hex/char format
  -e - do not echo the specified query

=head1 EXAMPLES

run-query.pl query1.sql

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
