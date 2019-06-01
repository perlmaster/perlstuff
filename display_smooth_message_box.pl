#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : smooth-message-box.pl
#
# Author    : Barry Kimelman
#
# Created   : May 25, 2019
#
# Purpose   : Display a message inside a smooth lined box
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

my %options = ( "d" => 0 , "h" => 0 , "D" => 0 );

my $ulc = 0xda;
my $urc = 0xbf;
my $horiz = 0xc4;
my $vert = 0xb3;
my $llc = 0xc0;
my $lrc = 0xd9;
my $ulc_double = 0xc9;
my $urc_double = 0xbb;
my $horiz_double = 0xcd;
my $vert_double = 0xba;
my $llc_double = 0xc8;
my $lrc_double = 0xbc;

######################################################################
#
# Function  : display_smooth_message_box
#
# Purpose   : Display a message inside a smooth lined message box
#
# Inputs    : $_[0] - single (0) or double (1) lines indicator
#             $_[1 .. $#_] - strings comprising message
#
# Output    : smooth message box
#
# Returns   : nothing
#
# Example   : display_smooth_message_box(0,"Process the files : ",join(" ",@xx));
#
# Notes     : (none)
#
######################################################################

sub display_smooth_message_box
{
	my ( $flag , $count , $width , $message , $msglen );

	$flag = shift @_;
	$message = join("",@_);
	$msglen = length $message;
	$width = $msglen + 2;  #  account for padding

	if ( $flag ) {
		printf "%c",$ulc_double;
	} # IF
	else {
		printf "%c",$ulc;
	} # ELSE
	for ( $count = 1 ; $count <= $width ; ++$count ) {
		if ( $flag ) {
			printf "%c",$horiz_double;
		} # IF
		else {
			printf "%c",$horiz;
		} # ELSE
	} # FOR
	if ( $flag ) {
		printf "%c",$urc_double;
	} # IF
	else {
		printf "%c",$urc;
	} # ELSE
	print "\n";

	if ( $flag ) {
		printf "%c %s %c\n",$vert_double,$message,$vert_double;
	} # IF
	else {
		printf "%c %s %c\n",$vert,$message,$vert;
	} # ELSE

	if ( $flag ) {
		printf "%c",$llc_double;
	} # IF
	else {
		printf "%c",$llc;
	} # ELSE
	for ( $count = 1 ; $count <= $width ; ++$count ) {
		if ( $flag ) {
			printf "%c",$horiz_double;
		} # IF
		else {
			printf "%c",$horiz;
		} # ELSE
	} # FOR
	if ( $flag ) {
		printf "%c\n",$lrc_double;
	} # IF
	else {
		printf "%c\n",$lrc;
	} # ELSE

	return;
} # end of display_smooth_message_box

######################################################################
#
# Function  : display_smooth_multi_line_message_box
#
# Purpose   : Display a message inside a smooth lined message box
#
# Inputs    : $_[0] - single (0) or double (1) lines indicator
#             $_[1 .. $#_] - strings comprising message
#
# Output    : smooth message box
#
# Returns   : nothing
#
# Example   : display_smooth_multi_line_message_box(0,"Process the files : ",join(" ",@xx));
#
# Notes     : (none)
#
######################################################################

sub display_smooth_multi_line_message_box
{
	my ( $flag , $count , $width , $maxlen , $index );

	$flag = shift @_;
	$maxlen = (sort { $b <=> $a } map { length $_ } @_)[0];
	$width = $maxlen + 2;  #  account for padding

# Print top of box
	if ( $flag ) {
		printf "%c",$ulc_double;
	} # IF
	else {
		printf "%c",$ulc;
	} # ELSE
	for ( $count = 1 ; $count <= $width ; ++$count ) {
		if ( $flag ) {
			printf "%c",$horiz_double;
		} # IF
		else {
			printf "%c",$horiz;
		} # ELSE
	} # FOR
	if ( $flag ) {
		printf "%c",$urc_double;
	} # IF
	else {
		printf "%c",$urc;
	} # ELSE
	print "\n";

# Print messages inside the box
	for ( $index = 0 ; $index <= $#_ ; ++$index ) {
		if ( $flag ) {
			printf "%c %-${maxlen}.${maxlen}s %c\n",$vert_double,$_[$index],$vert_double;
		} # IF
		else {
			printf "%c %-${maxlen}.${maxlen}s %c\n",$vert,$_[$index],$vert;
		} # ELSE
	} # FOR

# Print bottom of box
	if ( $flag ) {
		printf "%c",$llc_double;
	} # IF
	else {
		printf "%c",$llc;
	} # ELSE
	for ( $count = 1 ; $count <= $width ; ++$count ) {
		if ( $flag ) {
			printf "%c",$horiz_double;
		} # IF
		else {
			printf "%c",$horiz;
		} # ELSE
	} # FOR
	if ( $flag ) {
		printf "%c\n",$lrc_double;
	} # IF
	else {
		printf "%c\n",$lrc;
	} # ELSE

	return;
} # end of display_smooth_multi_line_message_box

1;
