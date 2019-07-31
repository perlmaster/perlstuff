package telnet;

use Net::Telnet;

######################################################################
#
# File      : telnet.pm
#
# Author    : Barry Kimelman
#
# Created   : December 19, 2011
#
# Purpose   : Perl module defining "telnet" data.
#
# Notes     : (none)
#
######################################################################

use strict;

BEGIN
{
   use Exporter   ();
   use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
   # set the version for version checking
   $VERSION     = 1.00;
   @ISA         = qw(Exporter);
   @EXPORT      = qw(&telnet_error_handler &telnet_login);
   # your exported package globals go here,
   # as well as any optionally exported functions
   @EXPORT_OK   = qw($telnet_error_flag);
}
use vars      @EXPORT_OK;

# initialize package globals, first exported ones
	$telnet_error_flag = 0;

######################################################################
#
# Function  : telnet_error_handler
#
# Purpose   : Handle errors from Net::Telnet::Cisco.
#
# Inputs    : $_[0] - error message from Net::Telnet::Cisco
#
# Output    : (none)
#
# Returns   : zero
#
# Example   : telnet_error_handler("........");
#
# Notes     : (none)
#
######################################################################

sub telnet_error_handler
{

	$telnet_error_flag = 1;
	warn("$_[0]\n");

	return 0;
} # end of telnet_error_handler

######################################################################
#
# Function  : telnet_login
#
# Purpose   : Create a connection to the specified system and perform a login.
#
# Inputs    : $_[0] - reference to hash of values for telnet object
#             $_[1] - username for login
#             $_[2] - password for login
#             $_[3] - optional parameter naming a logfile
#
# Output    : (none)
#
# Returns   : IF ok THEN telnet object ELSE undefined
#
# Example   : $telnet = telnet_login(\%telnet,$username,$password);
#
# Notes     : (none)
#
######################################################################

sub telnet_login
{
	my ( $ref_telnet_info , $username , $password , $logfile ) = @_;
	my ( $telnet );

	$telnet_error_flag = 0;
	if ( defined $logfile ) {
		$telnet = Net::Telnet->new(Host => $ref_telnet_info->{Host},
						Timeout => $ref_telnet_info->{Timeout},
						Prompt => $ref_telnet_info->{Prompt},
						Input_log => "$logfile",
						Errmode => $ref_telnet_info->{Errmode});
	} # IF
	else {
		$telnet = Net::Telnet->new(Host => $ref_telnet_info->{Host},
						Timeout => $ref_telnet_info->{Timeout},
						Prompt => $ref_telnet_info->{Prompt},
						Errmode => $ref_telnet_info->{Errmode});
	} # ELSE
	unless ( defined $telnet ) {
		warn("Can't connect to $ref_telnet_info->{Host}\n");
		return undef;
	} # UNLESS
	$telnet->errmode(\&telnet_error_handler);

#----------------------#
# Login to the router. #
#----------------------#
	$telnet->login(Name => $username, Password => $password, Timeout => 20);
	if ( $telnet_error_flag != 0 ) {
		warn("Can't login to $ref_telnet_info->{Host}\n");
		$telnet->close();
		return undef;
	} # IF

	return $telnet;
} # end of telnet_login

######################################################################
#
# Function  : telnet_send_commands
#
# Purpose   : Send multiple telnet comands.
#
# Inputs    : $_[0] - telnet session object
#             $_[1] - reference to list of commands
#             $_[2] - site name (used for messaging)
#             $_[3] - command timeout (in seconds)
#             $_[4] - boolean flag : if true echo commands before sending
#
# Output    : (none)
#
# Returns   : IF ok THEN zero ELSE non-zero
#
# Example   : $status = telnet_send_commands($telnet,\@commands,$site,10,1);
#
# Notes     : No telnet command output is saved.
#
######################################################################

sub telnet_send_commands
{
	my ( $telnet , $ref_commands , $site , $timeout_seconds , $flag ) = @_;

	foreach my $command ( @$ref_commands ) {
		if ( $flag ) {
			print "Send command '$command' to $site\n";
		} # IF
		$telnet->cmd( String => $command , Timeout => $timeout_seconds );
		if ( $telnet_error_flag != 0 ) {
			warn("Can't send command '$command' to $site\n");
			return -1;
		} # IF
	} # FOREACH

	return 0;
} # end of telnet_send_commands

1;

END # module clean-up code here (global destructor)
{
}
