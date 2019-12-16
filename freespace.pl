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
require "display_drive_info.pl";
require "display_pod_help.pl";

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
# Example   : freespace.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] drive [... drive]\n");
	} # UNLESS

	foreach my $drive ( @ARGV ) {
		display_drive_info($drive);
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

freespace.pl - Display drive information using Perl

=head1 SYNOPSIS

freespace.pl [-hd] drive

=head1 DESCRIPTION

Display drive information using Perl

=head1 PARAMETERS

  drive - drive specifier

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

freespace.pl c:

freespace.pl e

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
