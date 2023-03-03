#!/usr/bin/perl -w

######################################################################
#
# File      : follow-synlinks.pl
#
# Author    : Barry Kimelman
#
# Created   : December 8, 2020
#
# Purpose   : Follow symbolic links until a non-symbolic link
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use File::Spec::Link;
use File::stat;
use Fcntl;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_file_info.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Follow symbolic links until a non-symbolic link
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : follow-synlinks.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $start_path , $linkpath , $current_path );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] [filename]\n");
	} # UNLESS
	$start_path = $ARGV[0];
	$current_path = $ARGV[0];
	while ( -l $current_path ) {
		list_file_info_full($current_path,{ "g" => 0 , "o" => 0 , "k" => 0 , "n" => 0 , "m" => 0 } );
		# $linkpath = readlink $current_path;
		$linkpath = File::Spec::Link->linked($current_path);
		unless ( defined $linkpath ) {
			warn("readlink failed for '$current_path' : $!\n");
			last;
		} # UNLESS
		else {
			$current_path = $linkpath;
		} # ELSE
	} # UNLESS
	list_file_info_full($current_path,{ "g" => 0 , "o" => 0 , "k" => 0 , "n" => 0 , "m" => 0 } );

	exit 0;
} # end of MAIN
__END__
=head1 NAME

follow-synlinks.pl - Follow symbolic links until a non-symbolic link

=head1 SYNOPSIS

follow-synlinks.pl [-hd] filename

=head1 DESCRIPTION

Follow symbolic links until a non-symbolic link

=head1 PARAMETERS

  filename - name of file/symlink

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

follow-synlinks.pl junk.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
