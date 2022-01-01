package tcpdata;

######################################################################
#
# File      : tcpdata.pm
#
# Author    : Barry Kimelman
#
# Created   : April 3, 2020
#
# Purpose   : Define items used by server and client TCP programs
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

    @EXPORT_OK   = qw( $peerport $buffer_size $peerhost );
}
use vars      @EXPORT_OK;

# initialize package globals, first exported ones

$peerport = '7777';
$buffer_size = 262144;  # max buffer size is (64K 65536) 256K
$peerhost = '127.0.0.1';

END # module clean-up code here (global destructor)
{
}
