#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : factorial.pl
#
# Author    : Barry Kimelman
#
# Created   : March 7, 2020
#
# Purpose   : Calculate the value of factorial
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

my ( $factorial );

unless ( 0 < scalar @ARGV ) {
	die("Usage : $0 [-dh] number [... number]\n");
} # UNLESS

foreach my $number ( @ARGV ) {
	$factorial = 1;
	map { $factorial *= $_ } (1 .. $number);
	print "factorial($number) = $factorial\n";
}

exit 0;