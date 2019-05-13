#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : box_message.pl
#
# Author    : Barry Kimelman
#
# Created   : October 26, 2010
#
# Purpose   : Print messages inside boxes.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

######################################################################
#
# Function  : print_box_message
#
# Purpose   : Print a single line message inside a box.
#
# Inputs    : $_[0] - prefix string
#             $_[1 .. n-1] - strings comprising the message
#             $_[n] - postfix string
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : print_box_message("\n","hello","out","there","\n");
#
# Notes     : (none)
#
######################################################################

sub print_box_message
{
	my ( $prefix , $postfix , $stars , $buffer , $length , $length2 );

	$prefix = shift @_;
	$postfix = pop @_;

	$buffer = join("",@_);
	$length = length $buffer;
	$length2 = 2 + $length;
	$stars = "*" . "-" x $length2 . "*";
	print "${prefix}$stars\n| $buffer |\n$stars\n${postfix}";

	return;
} # end of print_box_message

######################################################################
#
# Function  : print_multi_line_box_message
#
# Purpose   : Print a multi line message inside a box.
#
# Inputs    : $_[0] - prefix string
#             $_[1] - reference to array of strings
#             $_[2] - postfix string
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : print_multi_line_box_message("\n",\@data,"\n");
#
# Notes     : (none)
#
######################################################################

sub print_multi_line_box_message
{
	my ( $prefix , $ref_list , $postfix ) = @_;
	my ( @messages , $stars , $maxlen , $maxlen4 );

	@messages = @$ref_list;
	$maxlen = (sort { $b <=> $a} map { length $_ } @messages)[0];
	$maxlen4 = 4 + $maxlen;
	$stars = "*" x $maxlen4;
	print "${prefix}$stars\n";

	foreach my $message ( @messages ) {
		printf "| %-${maxlen}.${maxlen}s |\n",$message;
	} # FOREACH
	print "$stars\n${postfix}";

	return;
} # end of print_multi_line_box_message

1;
