#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : shuffle.pl
#
# Author    : Barry Kimelman
#
# Created   : June 6, 2019
#
# Purpose   : Random;ly shuffle the lines of text in a file
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Entry point for this program.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : shuffle.pl.pl filename
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $number , $filename , @records );
	my ( $index , $num_lines );

	$status = getopts("dh",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [filename]\n");
	} # UNLESS
	if ( 0 < @ARGV ) {
		$filename = $ARGV[0];
		unless ( open(INPUT,"<$filename") ) {
			die("open failed for file '$filename' : $!\n");
		} # UNLESS
		@records = <INPUT>;
		close INPUT;
	} # IF
	else {
		$filename = "-- STDIN --";
		@records = <STDIN>;
	} # ELSE
	$num_lines = scalar @records;

	srand( time() - ($$ + ($$ << 15)) );
	for ( $index = 0 ; $index <= $#records ; ++$index ) {
		$number = int(rand $num_lines) + 1;
		@records[$number , $index] = @records[$index , $number];
	} # FOR
	print join("",@records);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

shuffle.pl - Random;ly shuffle the lines of text in a file

=head1 SYNOPSIS

shuffle.pl [-dh] filename

=head1 DESCRIPTION

Random;ly shuffle the lines of text in a file

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary

=head1 EXAMPLES

shuffle.pl junk.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
