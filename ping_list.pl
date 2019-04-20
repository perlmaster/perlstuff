#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : ping_list.pl
#
# Author    : Barry Kimelman
#
# Created   : March 2, 2017
#
# Purpose   : Run a ping test on each entry in a list of ip addresses
#
# Notes     : The system ping command is used instead of Perl's ping due
#             to some permission issues.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

my %options;
my @ip_address_list;
my $num_entries;
my $server_ip;
my @ssh_commands;

######################################################################
#
# Function  : run_system_ping
#
# Purpose   : Run the system ping utility.
#
# Inputs    : $_[0] - ip address/hostname
#             $_[1] - timeout interval in seconds
#
# Output    : (none)
#
# Returns   : IF system is reachable THEN 1 ELSE 0
#
# Example   : $status = run_system_ping("1.2.3.4",2);
#
# Notes     : This function is needed due to the fact that the "icmp"
#             protocol is a privileged protocol.
#
# The following command/output is assumed.
#
# >>> ping -c1 10.99.99.99
# PING 10.99.99.99 (10.99.99.99) 56(84) bytes of data.
# 
# --- 10.99.99.99 ping statistics ---
# 1 packets transmitted, 0 received, 100% packet loss, time 0ms
#
######################################################################

sub run_system_ping
{
	my ( $host , $timeout ) = @_;
	my ( @output , @matched , $status , @ping , @info );

	$status = 0;
	@output = `ping -c1 -W$timeout $host`;
	@matched = grep /packet loss/,@output;
	if ( 0 < @matched ) {
		if ( $matched[0] =~ m/(\S+)% packet loss/ ) {
			if ( $1 == 0 ) {
				$status = 1;
			} # IF
		} # IF
	} # IF

	return $status;
} # end of run_system_ping

######################################################################
#
# Function  : MAIN
#
# Purpose   : Run a ping test on each entry in a list of ip addresses
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : ping_list.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , $count , @list_bad , @list_good );

	%options = ( "d" => 0 , "h" => 0 , "r" => 5 , "t" => 2 , "e" => 0 );
	$status = getopts("hdr:t:e",\%options);
	if ( $options{"h"} ) {
		if ( $^O =~ m/MSWin/ ) {
# Windows stuff goes here
			system("pod2text $0 | more");
		} # IF
		else {
# Non-Windows stuff (i.e. UNIX) goes here
			system("pod2man $0 | nroff -man | less -M");
		} # ELSE
		exit 0;
	} # IF
	unless ( $status && 1 < scalar @ARGV ) {
		die("Usage : $0 [-dhe] [-t ping_command_timeout] [-r max_num_retries] server_ip ssh_commands_file [filename]\n");
	} # UNLESS
	$server_ip = $ARGV[0];
	$filename = $ARGV[1];
	unless ( open(SSH,"<$filename") ) {
		die("open failed for '$filename' : $!\n");
	} # UNLESS
	@ssh_commands = <SSH>;
	close SSH;
	chomp @ssh_commands;

	if ( 1 < scalar @ARGV ) {
		$filename = $ARGV[1];
		unless ( open(IP,"<$filename") ) {
			die("open failed for '$filename' : $!\n");
		} # UNLESS
		@ip_address_list = <IP>;
		close IP;
	} # IF
	else {
		$filename = "";
		@ip_address_list = <STDIN>;
	} # ELSE
	chomp @ip_address_list;

	while ( 1 ) {
		$status = localtime;
		print "\n$status -- Ping list of ip addresses\n";
		@list_bad = ();
		@list_good = ();
		foreach my $ip ( @ip_address_list ) {
			for ( $count = 1 ; $count <= $options{'r'} ; ++$count ) {
				$status = run_system_ping($ip,2);
			} # FOR
			unless ( $status == 1 ) {
				push @list_bad,$ip;
				# run the 2 shell/ssh commands here
				foreach my $ssh_command ( @ssh_commands ) {
				} # FOREACH
				if ( $options{'e'} ) {
					warn("Ping failed for $ip\n");
				} # IF
			} # UNLESS
			else {
				push @list_good,$ip;
			} # ELSE
		} # FOREACH over list of ip addresses
		@ip_address_list = @list_good;
		push @ip_address_list,@list_bad;
	} # WHILE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

ping_list.pl - Run a ping test on each entry in a list of ip addresses

=head1 SYNOPSIS

ping_list.pl [-dhe] [-t ping_command_timeout] [-r max_num_retries] server_ip ssh_commands_file [filename]\n");

=head1 DESCRIPTION

Run a ping test on each entry in a list of ip addresses

=head1 PARAMETERS

 server_ip - ip address of server to which all the ip addresses belong
 ssh_commands_file - name of file containing list of ssh commands
 filename - optional name of file containing list of ip addresses one per line

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -r max_num_retries - override default maximum number of retries
  -t timeout - override default ping command timeout (specified in seconds)
  -e - display an error message for failed ping tests

=head1 EXAMPLES

ping_list.pl 1.2.3.4 ssh.txt ping-list.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
