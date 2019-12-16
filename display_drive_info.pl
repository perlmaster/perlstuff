#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : freespace.pl
#
# Author    : Barry Kimelman
#
# Created   : March 31, 2019
#
# Purpose   : Display drive information using Perl
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Win32::DriveInfo;
use FindBin;
use lib $FindBin::Bin;

require "comma_format.pl";
require "format_megabytes.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : display_drive_info
#
# Purpose   : Display space info for the specified drive
#
# Inputs    : $_[0] - drive
#
# Output    : space info for specified drive
#
# Returns   : nothing
#
# Example   : display_drive_info("c");
#
# Notes     : (none)
#
######################################################################

sub display_drive_info
{
	my ( $drive ) = @_;
	my ( $SectorsPerCluster, $BytesPerSector, $NumberOfFreeClusters );
	my ( $TotalNumberOfClusters, $FreeBytesAvailableToCaller, $TotalNumberOfBytes);
	my ( $TotalNumberOfFreeBytes , $pct_free , $free_megs , $bytes_megs );

	print "\nSpace Info for drive ${drive}\n";
	($SectorsPerCluster,
	$BytesPerSector,
	$NumberOfFreeClusters,
	$TotalNumberOfClusters,
	$FreeBytesAvailableToCaller,
	$TotalNumberOfBytes,
	$TotalNumberOfFreeBytes) = Win32::DriveInfo::DriveSpace($drive);
	$free_megs = format_megabytes($FreeBytesAvailableToCaller);
	$bytes_megs = format_megabytes($TotalNumberOfBytes);

	$pct_free = sprintf "%.4f",100.0 * ($TotalNumberOfFreeBytes / $TotalNumberOfBytes);
	$NumberOfFreeClusters = comma_format($NumberOfFreeClusters);
	$TotalNumberOfClusters = comma_format($TotalNumberOfClusters);
	$FreeBytesAvailableToCaller = comma_format($FreeBytesAvailableToCaller);
	$TotalNumberOfBytes = comma_format($TotalNumberOfBytes);
	$TotalNumberOfFreeBytes = comma_format($TotalNumberOfFreeBytes);

	print qq~
SectorsPerCluster          = $SectorsPerCluster
BytesPerSector             = $BytesPerSector
NumberOfFreeClusters       = $NumberOfFreeClusters
TotalNumberOfClusters      = $TotalNumberOfClusters
FreeBytesAvailableToCaller = $FreeBytesAvailableToCaller $free_megs
TotalNumberOfBytes         = $TotalNumberOfBytes $bytes_megs
TotalNumberOfFreeBytes     = $TotalNumberOfFreeBytes
% Free                     = $pct_free %
~;

	return;
} # end of display_drive_info

1;
