#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : col-summary.pl
#
# Author    : Barry Kimelman
#
# Created   : November 18, 2019
#
# Purpose   : Generate a column summary count for a specific column in a CSV file
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "s" => "," );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Generate a column summary count for a specific column in a CSV file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : col-summary.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , @records , $num_records , $count , $index );
	my ( $col_num , @fields , %summary , @values , @counts , @indices );
	my ( $maxlen );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] [-s separator] column_number [filename]\n");
	} # UNLESS
	$col_num = shift @ARGV;
	if ( 0 == scalar @ARGV ) {
		$filename = "-- stdin --";
		@records = <STDIN>;
	} # IF
	else {
		$filename = $ARGV[0];
		unless ( open(INPUT,"<$filename") ) {
			die("open failed for '$filename' : $!\n");
		} # UNLESS
		@records = <INPUT>;
		close INPUT;
	} # ELSE
	chomp @records;
	$num_records = scalar @records;
	@fields = split(/${options{'s'}}/,$records[0]);
	$count = scalar @fields;
	if ( $col_num > $count ) {
		die("Only found $count columns in 1st record , $col_num is not a valid column number\n");
	} # IF
	%summary = ();
	@values = ();
	@counts = ();
	for ( $index = 0 ; $index < $num_records ; ++$index ) {
		@fields = split(/${options{'s'}}/,$records[$index]);
		$count = scalar @fields;
		$summary{$fields[$col_num-1]} += 1;
	} # FOR
	$count = scalar keys %summary;
	##  print Dumper(\%summary);
	@values = keys %summary;
	@counts = map { $summary{$_} } @values;
	@indices = sort { $counts[$a] <=> $counts[$b] } (0 .. $#counts);
	@values = @values[@indices];
	@counts = @counts[@indices];
	$maxlen = (reverse sort { $a <=> $b} map { length $_ } @values)[0];
	for ( $index = 0 ; $index < $count ; ++$index ) {
		printf "%-${maxlen}.${maxlen}s %d\n",$values[$index],$counts[$index];
	} # FOR
	print "\n$count different values for column $col_num in $num_records records from $filename\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

col-summary.pl - Generate a column summary count for a specific column in a CSV file

=head1 SYNOPSIS

col-summary.pl [-hd] [-s separator] column_number [filename]

=head1 DESCRIPTION

Generate a column summary count for a specific column in a CSV file

=head1 PARAMETERS

  filename - name of optional filename
  column_number - column number for summary

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -s separator - override default column separator of ','

=head1 EXAMPLES

col-summary.pl 2 foo.csv

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
