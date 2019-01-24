#!/usr/bin/perl
 
######################################################################
#
# File      : size_to_gb.pl
#
# Author    : Barry Kimelman
#
# Created   : September 5, 2017
#
# Purpose   : Convert a filesize to a GB / MB / KB value
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
# Function  : size_to_gb
#
# Purpose   : Convert a filesize to a GB / MB / KB value
#
# Inputs    : $_[0] - numeric value to be converted
#
# Output    : (none)
#
# Returns   : character string of mode/permission bits as produced by ls command
#
# Example   : $size = size_to_gb($status->size);
#
# Notes     : (none)
#
######################################################################

sub size_to_gb
{
	my ( $size ) = @_;
	my ( $formatted , $gb , $kb , $mb );

	$kb = 1 << 10;
	$mb = 1 << 20;
	$gb = 1 << 30;
	if ( $size >= $gb ) {
		$formatted = sprintf "%.2f GB",$size / $gb;
	} elsif ( $size >= $mb ) {
		$formatted = sprintf "%.2f MB",$size / $mb;
	} # IF
	else {
		$formatted = sprintf "%.2f KB",$size / $kb;
	} # ELSE

	return $formatted;
} # end of size_to_gb

1;
