package global_data;

######################################################################
#
# File      : database.pm
#
# Author    : Barry Kimelman
#
# Created   : April 25, 2015
#
# Purpose   : Perl module defining global data items for database work.
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

	@EXPORT_OK   = qw( $dbh %tables %tables_lower %table_columns
						$db_user $db_pass $db_name $db_server
						);
}
use vars      @EXPORT_OK;

# initialize package globals, first exported ones

$db_user = 'root';
$db_pass = 'archer-nx01';
$db_name = 'qwlc';
$db_server = '127.0.0.1';

1;

END # module clean-up code here (global destructor)
{
}
