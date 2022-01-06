#!/usr/bin/perl -w

######################################################################
#
# File      : hexdump.pl
#
# Author    : Barry Kimelman
#
# Created   : May 18, 2016
#
# Purpose   : Generate a hex/char dump of a buffer
#
######################################################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;

######################################################################
#
# Function  : hexdump
#
# Purpose   : Generate a hex/char dump of a block of data
#
# Inputs    : $_[0] - buffer to be dumped
#             $_[1] - starting offset
#             $_[2] - optional flag , if specified and ne 0 then add decimal offset to the dumped lines
#
# Output    : (none)
#
# Returns   : requested dump
#
# Example   : $hex = hexdump($buffer,0);
#
# Notes     : (none)
#
######################################################################

sub hexdump
{
	my ( $hexdata , $offset , $decimal_flag ) = @_;
	my ( $hex , $hexbuffer );

	$hexbuffer = "";
	foreach my $chunk ( unpack "(a16)*", $hexdata ) {
		$hex = unpack "H*", $chunk; # hexadecimal magic
		$chunk =~ tr/ -~/./c;          # replace unprintables
		$hex   =~ s/(.{1,8})/$1 /gs;   # insert spaces
		# $hexbuffer .= sprintf "0x%08x   %-*s %s\n",
		$hexbuffer .= sprintf "0x%08x", $offset;
		if ( defined $decimal_flag && $decimal_flag ) {
			$hexbuffer .= sprintf " (%010d)",$offset;
		} # IF
		$hexbuffer .= sprintf "   %-*s %s\n",36, $hex, $chunk;
		$offset += 16;
	}

	return $hexbuffer;
} # end of hexdump

1;
