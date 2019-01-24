#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : comma_format.pl
#
# Author    : Barry Kimelman
#
# Created   : May 7, 2002
#
# Purpose   : Function to format numeric value with commas.
#
######################################################################

use strict;

######################################################################
#
# Function  : comma_format
#
# Purpose   : Format a binary value into a string with commas.
#
# Inputs    : $_[0] - numeric value to be formatted
#
# Output    : (none)
#
# Returns   : formatted value
#
# Example   : $string = comma_format(123);
#
# Notes     : (none)
#
######################################################################

sub comma_format
{
	my $text = reverse $_[0];

	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
} # end of comma_format

1;
