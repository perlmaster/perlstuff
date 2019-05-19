#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : drive-info.pl
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
# Function  : MAIN
#
# Purpose   : Display drive information using Perl
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : drive-info.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status );
	my ($SectorsPerCluster, $BytesPerSector, $NumberOfFreeClusters );
	my ( $TotalNumberOfClusters, $FreeBytesAvailableToCaller, $TotalNumberOfBytes);
	my ( $TotalNumberOfFreeBytes , $pct_free , $free_megs , $bytes_megs );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		if ( $^O =~ m/MSWin/ ) {
# Windows stuff goes here
			system("pod2text $0 | more");
		} # IF
		else {
# Non-Windows stuff (i.e. UNIX) goes here
			system("pod2man $0 | nroff -man | less -M");
		} # ELSE
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] drive [... drive]\n");
	} # UNLESS

	foreach my $drive ( @ARGV ) {
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
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

drive-info.pl - Display drive information using Perl

=head1 SYNOPSIS

drive-info.pl [-hd] drive

=head1 DESCRIPTION

Display drive information using Perl

=head1 PARAMETERS

  drive - drive specifier

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

drive-info.pl c:

drive-info.pl e

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
