#!/usr/bin/perl -w

######################################################################
#
# File      : extract-ip.pl
#
# Author    : Barry Kimelman
#
# Created   : January 6, 2022
#
# Purpose   : Find ip addresses in the specified files
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : search_file
#
# Purpose   : Search the named file for the specified ip address
#
# Inputs    : $_[0] - filename
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : search_file($filename);
#
# Notes     : (none)
#
######################################################################

sub search_file
{
	my ( $filename ) = @_;
	my ( $handle , $buffer , $ip , $count );

	unless ( open($handle,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return;
	} # UNLESS

	while ( $buffer = <$handle> ) {
		$count = 0;
		while ( $buffer =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/gms ) {
			$ip = $1;
			if ( ++$count == 1 ) {
				print "\nip addresses found on line $. : $buffer";
			} # IF
			print "Found $ip\n";
		} # WHILE
	} # WHILE
	close $handle;

	return;
} # end of search_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Find ip addresses in the specified files
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : extract-ip.pl -d arg1 arg2
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
		die("Usage : $0 [-dh] filename  [... filename]\n");
	} # UNLESS

	foreach my $filename ( @ARGV ) {
		search_file($filename);
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

extract-ip.pl - Find ip addresses in the specified files

=head1 SYNOPSIS

extract-ip.pl [-hd] filename [... filename]

=head1 DESCRIPTION

Find ip addresses in the specified files

=head1 PARAMETERS

  filename - name of file to be searched

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

extract-ip.pl *.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
