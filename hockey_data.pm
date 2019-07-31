package hockey_data;

######################################################################
#
# File      : hockey_data.pm
#
# Author    : Barry Kimelman
#
# Created   : February 14, 2019
#
# Purpose   : Perl module defining global data items for Tomcat
#             hockey league utilities.
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

	@EXPORT_OK   = qw( $db $host $user $pwd );
}
use vars      @EXPORT_OK;

# initialize package globals, first exported ones

$user = 'root';
$pwd = 'archer-nx01';
$db = 'qwlc';
$host = '127.0.0.1';

1;

END # module clean-up code here (global destructor)
{
}
