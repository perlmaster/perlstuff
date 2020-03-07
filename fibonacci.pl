#!/usr/local/bin/perl -w

######################################################################
#
# File      : fibonacci.pl
#
# Author    : Barry Kimelman
#
# Created   : May 8, 2007
#
# Purpose   : Calculate Fibonacci numbers
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : fibonacci
#
# Purpose   : Display the requested number of fibonacci numbers
#
# Inputs    : $_[0] - 1-origin number of fibonacci numbers to be displayed
#
# Output    : the requested number of fibonacci numbers
#
# Returns   : The last number in the sequence
#
# Example   : $fib_num = fibonacci(4);
#
# Notes     : (none)
#
######################################################################

sub fibonacci
{
	my ( $fib ) = @_;
	my ( @fibs , $number , $result );

	@fibs = map { 1 } (1 .. $fib);
	if ( $fib > 2 ) {
		map { $fibs[$_] = $fibs[$_-2] + $fibs[$_-1] } (2 .. $fib-1);
	}
	print join(" , ",@fibs),"\n\n";

	return $fibs[$fib-1];
} # end of fibonacci

######################################################################
#
# Function  : MAIN
#
# Purpose   : Calculate Fibonacci numbers
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : fibonacci.pl 1 2 4 3
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $result );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-hd] count [... count]\n");
	} # UNLESS

	foreach my $number ( @ARGV ) {
		$result = fibonacci($number);
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

fibonacci.pl - Calculate Fibonacci numbers

=head1 SYNOPSIS

fibonacci.pl [-hd] count [... count]

=head1 DESCRIPTION

Calculate Fibonacci numbers

=head1 PARAMETERS

  count - number of fibnoacci numbers to display

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

fibonacci.pl 5

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
