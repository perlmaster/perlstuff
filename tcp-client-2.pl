#!/usr/bin/perl -w

######################################################################
#
# File      : tcp-client.pl
#
# Author    : Barry Kimelman
#
# Created   : March 16, 2017
#
# Purpose   : TCP client written in Perl
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use IO::Socket::INET;
use FindBin;
use lib $FindBin::Bin;
use tcpdata;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : TCP client written in Perl
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : tcp-client.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $socket , $req , $size , $response , $req_len , $prompt );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [string]\n");
	} # UNLESS
	# auto-flush on socket
	$| = 1;
 
	$prompt = "Enter data to be sent to server ==> ";
	while ( 1 ) {
		# create a connecting socket
		$socket = new IO::Socket::INET (
			PeerHost => $tcpdata::peerhost ,
			PeerPort => $tcpdata::peerport,
			Proto => 'tcp',
		);
		unless ( defined $socket ) {
			die("Can't connect to the server at $tcpdata::peerhost on port $tcpdata::peerport : $!\n");
		} # UNLESS
		print "connected to the server at $tcpdata::peerhost on port $tcpdata::peerport\n";

		# data to send to a server
		print "\n${prompt}";
		$req = <STDIN>;
		chomp $req;
		unless ( $req =~ m/\S/ ) {
			last;
		}
		$req_len = length $req;
		$size = $socket->send($req);
		print "req_len = $req_len , sent data of length $size to server\n";
	 
		# notify server that request has been sent
		shutdown($socket, 1);
	 
		# receive a response of up to $tcpdata::buffer_size characters from server
		$response = "";
		$socket->recv($response, $tcpdata::buffer_size);
		print "received response from server : $response\n";
		$socket->close(); 
	} # WHILE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

tcp-client.pl - TCP client written in Perl

=head1 SYNOPSIS

tcp-client.pl [-dh]

=head1 DESCRIPTION

TCP client written in Perl

=head1 PARAMETERS

  (none)

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

tcp-client.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
