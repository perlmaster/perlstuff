#!/usr/bin/perl -w

######################################################################
#
# File      : get_file_age.pl
#
# Author    : Barry Kimelman
#
# Created   : March 26, 2023
#
# Purpose   : Determine the age of a file
#
######################################################################

use strict;
use warnings;
use File::stat;
use filetest 'access';

use constant MIN_SECS => 60;
use constant HOUR_SECS => 60 * 60;
use constant DAY_SECS => 60 * 60 * 24;

######################################################################
#
# Function  : get_file_age
#
# Purpose   : Compute the age of a file in days from the current date.
#
# Inputs    : $_[0] - filename
#             $_[1] - ref to hash to receive age info
#                     hash keys are : days , hours , minutes , seconds
#
# Output    : (none)
#
# Returns   : formatted string containing age
#
# Example   : $age = get_file_age($filename,\%age);
#
# Notes     : (none)
#
######################################################################

sub get_file_age
{
	my ( $filename , $ref_age ) = @_;
	my ( $age , $filestat , $mtime , $time_diff , $save , $count );
	my ( $Dd , $Dh , $Dm , $Ds );
	my ( $start_time );

	$start_time = time;

	%$ref_age = ();
	unless ( $filestat = lstat $filename ) {
		die("lstat failed for '$filename' : $!\n");
	} # UNLESS
	$mtime = $filestat->mtime;
	$time_diff = $start_time - $mtime;
	$save = $time_diff;
	$Dd = 0;
	$Dh = 0;
	$Dm = 0;
	$Ds = 0;

	$count = int ($time_diff / DAY_SECS);
	if ( $count > 0 ) {
		$Dd = $count;
		$time_diff -= $count * DAY_SECS;
	} # IF

	$count = int ($time_diff / HOUR_SECS);
	if ( $count > 0 ) {
		$Dh = $count;
		$time_diff -= $count * HOUR_SECS;
	} # IF

	$count = int ($time_diff / MIN_SECS);
	if ( $count > 0 ) {
		$Dm = $count;
		$time_diff -= $count * MIN_SECS;
	} # IF

	$Ds = $time_diff;

	$age = "$Dd days , $Dh hours , $Dm minutes , $Ds seconds";
	$ref_age->{'days'} = $Dd;
	$ref_age->{'hours'} = $Dh;
	$ref_age->{'minutes'} = $Dm;
	$ref_age->{'seconds'} = $Ds;

	return $age;
} # end of get_file_age

1;
