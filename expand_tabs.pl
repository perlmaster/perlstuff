#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : expand_tabs.pl
#
# Author    : Barry Kimelman
#
# Created   : June 17, 2013
#
# Purpose   : Expand tabs to spaces.
#
######################################################################

use strict;
use warnings;

######################################################################
#
# Function  : expand_tabs
#
# Purpose   : Expand tabs to spaces.
#
# Inputs    : $_[0] - record to be expanded
#             $_[1] - tabwidth
#
# Output    : (none)
#
# Returns   : expanded record
#
# Example   : $expanded = expand_tabs($buffer,$tabwidth);
#
# Notes     : (none)
#
######################################################################

sub expand_tabs
{
	my ( $oldbuffer , $tabwidth ) = @_;
	my ( $expanded , $loc );

	$expanded = $oldbuffer;
	while ($expanded =~ m/\t/g) {
		$loc = pos($expanded) - 1;
		substr ($expanded,$loc,1) = ' ' x ($tabwidth - ($loc % $tabwidth));
	} # WHILE

	return $expanded;
} # end of expand_tabs

1;
