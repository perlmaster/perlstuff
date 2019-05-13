#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : get-links.pl
#
# Author    : Barry Kimelman
#
# Created   : May 13, 2019
#
# Purpose   : Get a list of links from a web page
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use LWP::Simple;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "box_message.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : process_webpage
#
# Purpose   : Get the list of links from a webpage
#
# Inputs    : $_[0] - the URL for the webpage
#
# Output    : List of links
#
# Returns   : IF problem THEN negative ELSE number of links
#
# Example   : process_webpage("http://www.somewhere.com");
#
# Notes     : (none)
#
######################################################################

sub process_webpage
{
	my ( $url ) = @_;
	my ( $content , $count , $href , $label );

	print_box_message("\n","Links found in ${url}","\n");
	$content = get("$url");
	unless ( defined $content ) {
		warn("Could not get content for $url : $!\n");
		return -1;
	} # UNLESS
	$count = length $content;
	print "Retrieved ${count} bytes of content data from $url\n\n";

	$count = 0;
	while ( $content =~ m/<A\s*?HREF="(.*?)".*?>(.*?)<\/A>/igms ) {
		$href = $1;
		$label = $2;
		print "\nHREF = $href\nLABEL = [$label]\n";
		$count += 1;
	} # WHILE

	return $count;
} # end of process_webpage

######################################################################
#
# Function  : MAIN
#
# Purpose   : Use the LWP::Simple module.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : get-links.pl -d arg1
#
# Notes     : (none)
#
######################################################################

	my ( $status );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [url]\n");
	} # UNLESS

	$status = localtime;
	print "\n${status}\n\n";
	foreach my $url ( @ARGV ) {
		process_webpage($url);
	} # FOREACH

	exit 0;

__END__
=head1 NAME

get-links.pl

=head1 SYNOPSIS

get-links.pl [-hd] dirname

=head1 DESCRIPTION

This perl script will collect xxxx

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary

=head1 PARAMETERS

  dirname - name of directory

=head1 EXAMPLES

get-links.pl xxx

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
