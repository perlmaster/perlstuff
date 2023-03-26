#!/usr/bin/perl -w

######################################################################
#
# File      : file_age.pl
#
# Author    : Barry Kimelman
#
# Created   : March 26, 2023
#
# Purpose   : Determine the age of files
#
######################################################################

use strict;
use warnings;
use Data::Dumper;
use File::stat;
use filetest 'access';
use FindBin;
use lib $FindBin::Bin;

require "get_file_age.pl";

########
# MAIN #
########

my ( $filename , $age , %age , $buffer );

if ( 1 > @ARGV ) {
	die("Usage : $0 filename [... filename]\n");
} # IF

foreach $filename ( @ARGV ) {
	$age = get_file_age($filename,\%age);
	print "age of $filename is $age\n";
	$buffer = Dumper(\%age);
	$buffer =~ s/\$VAR1/$filename/g;
	$buffer =~ s/\n/ /g;
	$buffer =~ s/\s+/ /g;
	print "age of $buffer\n";
} # FOREACH

exit 0;
