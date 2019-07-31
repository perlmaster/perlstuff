package months_days;

######################################################################
#
# File      : months_days.pm
#
# Author    : Barry Kimelman
#
# Created   : January 14, 2015
#
# Purpose   : Perl module defining weekdays and months arrays.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;

BEGIN
{
    use Exporter   ();
    use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 1.00;

    @ISA         = qw(Exporter);
    @EXPORT      = qw( );

    # your exported package globals go here,
    # as well as any optionally exported functions

    @EXPORT_OK   = qw( @months @full_months @weekdays @full_weekdays );
}
use vars      @EXPORT_OK;

# initialize package globals, first exported ones

@months = ( "Jan" , "Feb" , "Mar" , "Apr" , "May" , "Jun" , "Jul" , "Aug" ,
				"Sep" , "Oct" , "Nov" , "Dec" );
@full_months = ( "January" , "February" , "March" , "April" , "May" , "June" ,
						"July" , "August" , "September" , "October" , "November" ,
						"December" );

@weekdays = ( "Sun" , "Mon" , "Tue" , "Wed" , "Thu" , "Fri" , "Sat" );
@full_weekdays = ( "Sunday" , "Monday" , "Tuesday" , "Wednesday" , "Thursday" ,
					"Friday" , "Saturday" );

END # module clean-up code here (global destructor)
{
}
