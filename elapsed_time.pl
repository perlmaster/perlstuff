#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : elapsed_time.pl
#
# Author    : Barry Kimelman
#
# Created   : January 4, 2019
#
# Purpose   : Module to display a formatted elapsed time message
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

######################################################################
#
# Function  : elapsed_time
#
# Purpose   : Display a formatted elapsed time message
#
# Inputs    : $_[0] - binary start time
#             $_[1] - binary end time
#             $_[2] - formatting string
#
# Output    : requested elapsed time message
#
# Returns   : nothing
#
# Example   : elapsed_time($start_time,$end_time,"\nElapsed Time : %d minutes %d seconds\n\n");
#
# Notes     : (none)
#
######################################################################

sub elapsed_time
{
	my ( $start_time , $end_time , $format ) = @_;
	my ( $elapsed , $minutes , $seconds );

	$elapsed = $end_time - $start_time;
	$minutes = int( $elapsed / 60);
	$seconds = $elapsed - ($minutes * 60);
	##  print "\nElapsed Time : ${minutes} minutes ${seconds} seconds\n\n";
	printf $format,$minutes,$seconds;

	return;
} # end of elapsed_time

1;
