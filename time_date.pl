#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : time_date.pl
#
# Author    : Barry Kimelman
#
# Created   : April 18, 2011
#
# Purpose   : Functions to manipulate time date values.
#
######################################################################

use strict;
use warnings;
use months_days;

######################################################################
#
# Function  : format_time_date
#
# Purpose   : Format a binary time value into a printable ASCII string.
#
# Inputs    : $_[0] - the binary time value
#             $_[1] - flag controlling the formatting of the date value
#
# Output    : (none)
#
# Returns   : formatted ASCII time/date value
#
# Example   : $today = format_time_date(time,"yyyy");
#
# Notes     : (none)
#
######################################################################

sub format_time_date
{
	my ( $clock , $date_flag ) = @_;
	my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst );
	my ( @full_months , @months , $buffer , $am_pm , $time_date , @weekdays );

	( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst ) =
				localtime($clock);
	if ( $hour < 12 ) {
		$am_pm = "AM";
		if ( $hour == 0 ) {
			$hour = 12;
		} # IF
	} # IF
	else {
		$am_pm = "PM";
		if ( $hour > 12 ) {
			$hour -= 12;
		} # IF
	} # ELSE
	$time_date = sprintf "%02d:%02d:%02d %s ",$hour,$min,$sec,$am_pm;
	unless ( defined $date_flag ) {
		$date_flag = "m";
	} # UNLESS
	if ( $date_flag eq "yyyy" ) {
		$buffer = sprintf "%02d/%02d/%04d",1+$mon,$mday,1900+$year;
	} elsif ( $date_flag eq "yy" ) {
		$buffer = sprintf "%02d/%02d/%02d",1+$mon,$mday,$year%100;
	} elsif ( $date_flag eq "w" ) {
		$buffer = sprintf "%s %s %d, %d",$months::full_weekdays[$wday],$months_days::full_months[$mon],$mday,
							1900+$year;
	} else {
		$buffer = sprintf "%s %02d, %d",$months_days::months[$mon],$mday,1900+$year;
	} # ELSE
	$time_date .= $buffer;
	return $time_date;
} # end of format_time_date

1;
