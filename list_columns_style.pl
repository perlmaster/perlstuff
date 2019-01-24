#!/usr/bin/perl -w

######################################################################
#
# File      : list_columns_style.pl
#
# Author    : Barry Kimelman
#
# Created   : August 16, 2017
#
# Purpose   : List an array of strings in columns style
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

######################################################################
#
# Function  : list_columns_style
#
# Purpose   : List an array of strings in columns style
#
# Inputs    : $_[0] - reference to array of strings
#             $_[1] - maximum output line width
#             $_[2] - optional title
#             $_[3] - file handle
#
# Output    : Listing of strings
#
# Returns   : nothing
#
# Example   : list_columns_style(\@list,80,$title,\*STDOUT);
#
# Notes     : (none)
#
######################################################################

sub list_columns_style
{
	my ( $ref_strings , $max_width , $title , $handle ) = @_;
	my ( $entry , $count , $maxlen , $line_size );

	$count = scalar @$ref_strings;
	if ( $count > 0 ) {
		$maxlen = (sort { $b <=> $a } map { length $_ } @$ref_strings)[0];
		if ( defined $title ) {
			print $handle "\n$title\n";
		} # IF
		$line_size = 0;
		$maxlen += 1;
		foreach $entry ( sort { lc $a cmp lc $b } @$ref_strings ) {
			$line_size += $maxlen;
			if ( $line_size >= $max_width ) {
				print $handle "\n";
				$line_size = $maxlen;
			} # IF
			printf $handle "%-${maxlen}.${maxlen}s",$entry;
		} # FOREACH
		print $handle "\n";
	} # IF
	return;
} # end of list_columns_style

1;
