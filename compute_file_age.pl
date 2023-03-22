#!/usr/bin/perl -w

######################################################################
#
# File      : compute_file_age.pl
#
# Author    : Barry Kimelman
#
# Created   : March 22, 2023
#
# Purpose   : Determine the age of files
#
######################################################################

use strict;
use warnings;
use Data::Dumper;
use File::stat;
use filetest 'access';
use Date::Calc;

my ( $start_time );
my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst );

######################################################################
#
# Function  : compute_file_age
#
# Purpose   : Compute the age of a file in days/hours/minutes/seconds from the current date.
#
# Inputs    : $_[0] - filename
#             $_[1] - ref to hash to receive age info
#                     hash keys are : days , hours , minutes , seconds
#
# Output    : (none)
#
# Returns   : formatted string containing age
#
# Example   : $age = compute_file_age($filename,\%age);
#
# Notes     : (none)
#
######################################################################

sub compute_file_age
{
	my ( $filename , $ref_age ) = @_;
	my ( $age , $filestat , $mtime );
	my ($Dd,$Dh,$Dm,$Ds);
	my ( $file_sec , $file_min , $file_hour , $file_mday , $file_mon , $file_year , $file_wday , $file_yday , $file_isdst );
	my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst , $start_time );

	$start_time = time;
	( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst ) = localtime($start_time);
	
	%$ref_age = ();
	unless ( $filestat = lstat $filename ) {
		warn("lstat failed for '$filename' : $!\n");
		return undef;
	} # UNLESS

	$mtime = $filestat->mtime;
	( $file_sec , $file_min , $file_hour , $file_mday , $file_mon , $file_year , $file_wday , $file_yday , $file_isdst ) =
		localtime($mtime);

	($Dd,$Dh,$Dm,$Ds) = Date::Calc::Delta_DHMS($file_year,$file_mon,$file_mday,$file_hour,$file_min,$file_sec,
						$year,$mon,$mday,$hour,$min,$sec);

	$age = "$Dd days , $Dh hours , $Dm minutes , $Ds seconds";
	$ref_age->{'days'} = $Dd;
	$ref_age->{'hours'} = $Dh;
	$ref_age->{'minutes'} = $Dm;
	$ref_age->{'seconds'} = $Ds;

	return $age;
} # end of compute_file_age

1;
