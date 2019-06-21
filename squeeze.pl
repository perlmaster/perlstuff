#!/usr/local/bin/perl -w

######################################################################
#
# File      : squeeze.pl
#
# Author    : Barry Kimelman
#
# Created   : March 22, 2017
#
# Purpose   : Squeeze multiple blank lines into a single blank line
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use File::stat;
use Fcntl;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : process_input
#
# Purpose   : Process the input data.
#
# Inputs    : $_[0] - handle of openned file
#             $_[1] - filename
#
# Output    : (none)
#
# Returns   : (nothing)
#
# Example   : process_input(\*STDIN,$filename);
#
# Notes     : (none)
#
######################################################################

sub process_input
{
	my ( $handle , $filename ) = @_;
	my ( $buffer , $prev_blank );

	$prev_blank = 0;
	while ( $buffer = <$handle> ) {
		chomp $buffer;
		if ( $buffer eq "" || $buffer =~ m/^\s+$/ ) {
			$prev_blank = 1;
		} # IF
		else {
			if ( $prev_blank ) {
				print "\n";
			} # IF
			print "$buffer\n";
			$prev_blank = 0;
		} # ELSE
	} # FOREACH

	return;
} # end of process_input

######################################################################
#
# Function  : MAIN
#
# Purpose   : Entry point for this program.
#
# Inputs    : @ARGV - array of filenames and directory names
#
# Output    : progress messages on standard output
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : squeeze.pl filename
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
		die("Usage : $0 [-dh] [filename [... filename]]\n");
	} # UNLESS

	if ( @ARGV < 1 ) {
		process_input(\*STDIN,"-- stdin --");
	} # IF
	else {
		foreach my $filename ( @ARGV ) {
			unless ( open(INPUT,"<$filename") ) {
				die("Can't open file \"$filename\" : $!\n");
			} # UNLESS
			process_input(\*INPUT,$filename);
			close INPUT;
		} # FOREACH
	} # ELSE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

squeeze.pl - squeeze consecutive blank lines into a single blank line

=head1 SYNOPSIS

squeeze.pl [-hd] [filename [... filename]]

=head1 DESCRIPTION

squeeze consecutive blank lines into a single blank line

=head1 PARAMETERS

  filename - name of input file

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

squeeze.pl data.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
