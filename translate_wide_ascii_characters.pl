#!/usr/bin/perl -w

use strict;
use warnings;

######################################################################
#
# Function  : translate_wide_ascii_characters
#
# Purpose   : Translate wide ascii characters (e.g. value > 0x7f) into a printable format
#
# Inputs    : $_[0] - string to be translated
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : $result = translate_wide_ascii_characters($wide_data);
#
# Notes     : (none)
#
######################################################################

sub translate_wide_ascii_characters
{
	my ( $wide_data ) = @_;

	$wide_data =~ s/([^[:ascii:]])/sprintf("\\x{%.4x}",ord $1)/eg;

	return $wide_data;
} # end of translate_wide_ascii_characters

1;
