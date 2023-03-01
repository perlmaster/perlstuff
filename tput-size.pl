#!/usr/bin/perl -w

######################################################################
#
# File      : tput-size.pl
#
# Author    : Barry Kimelman
#
# Created   : March 1, 2023
#
# Purpose   : Use "tput" to determine the number of ros and columns for the terminal
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;

my ( $num_lines , $num_cols );

$num_lines = `tput lines`;
chomp $num_lines;
$num_cols = `tput cols`;
chomp $num_cols;

print "num_lines = $num_lines , num_cols = $num_cols\n";

exit 0;
