#!/usr/bin/perl -w

######################################################################
#
# File      : hex-dump-file.pl
#
# Author    : Barry Kimelman
#
# Created   : February 23, 2017
#
# Purpose   : Generate a hex / char dump of a file
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use File::stat;
use Fcntl;
use FindBin;
use lib $FindBin::Bin;

require "hexdump.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "D" => 0);

######################################################################
#
# Function  : MAIN
#
# Purpose   : Generate a hex / char dump of a file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : hex-dump-file.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , $count , $buffer , $hex , $offset , $handle );

	$status = getopts("hdD",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dhD] [filename]\n");
	} # UNLESS

	if ( 0 == scalar @ARGV ) {
		$handle = \*STDIN;
	} # IF
	else {
		$filename = $ARGV[0];
		unless ( sysopen(DATA,"$filename",O_RDONLY) ) {
			die("open failed for '$filename' : $!\n");
		} # UNLESS
		$handle = \*DATA;
	} # ELSE

	$count = sysread($handle,$buffer,16);
	$offset = 0;
	while ( $count > 0 ) {
		$hex = hexdump($buffer,$offset,$options{"D"});
		print "$hex";
		$offset += $count;
		$count = sysread($handle,$buffer,16);
	} # WHILE
	if ( 0 < scalar @ARGV ) {
		close DATA;
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

hex-dump-file.pl - Generate a hex / char dump of a file

=head1 SYNOPSIS

hex-dump-file.pl [-dhD] filename

=head1 DESCRIPTION

Generate a hex / char dump of a file

=head1 PARAMETERS

  filename - name of fiel to be dumped

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -D - include decimal offset in dump

=head1 EXAMPLES

hex-dump-file.pl stuff.dat

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
