#!/usr/bin/perl -w

######################################################################
#
# File      : tcp-server.pl
#
# Author    : Barry Kimelman
#
# Created   : March 16, 2017
#
# Purpose   : TCP server written in Perl
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
# Purpose   : TCP server written in Perl
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : tcp-server.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [dirname]\n");
	} # UNLESS
	# auto-flush on socket
	$| = 1;
 
	# creating a listening socket
	my $socket = new IO::Socket::INET (
		LocalHost => '0.0.0.0',
		LocalPort => $tcpdata::peerport ,
		Proto => 'tcp',
		Listen => 5,
		Reuse => 1
	);
	unless ( defined $socket ) {
		die("Server can't create socket : $!\n");
	} # UNLESS

	print "server waiting for client connection on port $tcpdata::peerport\n";

	while(1)
	{
		# waiting for a new client connection
		my $client_socket = $socket->accept();
		 
		# get information about a newly connected client
		my $client_address = $client_socket->peerhost();
		my $client_port = $client_socket->peerport();
		print "connection from $client_address:$client_port\n";
		 
		# read up to $tcpdata::buffer_size characters from the connected client
		my $data = "";
		$client_socket->recv($data, $tcpdata::buffer_size);
		print "received data from client : $data\n";

		# write response data to the connected client
		$data = "ok";
		$client_socket->send($data);
		 
		# notify client that response has been sent
		shutdown($client_socket, 1);
	}
 
$socket->close();

	exit 0;
} # end of MAIN
__END__
=head1 NAME

tcp-server.pl - TCP server written in Perl

=head1 SYNOPSIS

tcp-server.pl [-dh]

=head1 DESCRIPTION

TCP server written in Perl

=head1 PARAMETERS

  (none)

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

tcp-server.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
