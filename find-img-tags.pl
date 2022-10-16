#!/usr/bin/perl -w

######################################################################
#
# File      : find-img-tags.pl
#
# Author    : Barry Kimelman
#
# Created   : October 3, 2018
#
# Purpose   : Find <IMG> tags in a file
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

my $num_matching_img_tags = 0;
my %matching_img_files = ();

######################################################################
#
# Function  : find_img_tags
#
# Purpose   : Find the IMG tags in a file
#
# Inputs    : $_[0] - filename
#
# Output    : list of HREFs
#
# Returns   : nothing
#
# Example   : find_img_tags($filename);
#
# Notes     : (none)
#
######################################################################

sub find_img_tags
{
	my ( $filename ) = @_;
	my ( $handle , $records , @records , $count , $img_tag );

	unless ( open($handle,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return -1;
	} # UNLESS
	@records = <$handle>;
	close $handle;

	$records = join("",@records);
	$count = 0;

##	WHILE ( $records =~ m/<A\s*?HREF="(.*?)".*?>(.*?)<\/A>/igms ) {
	while ( $records =~ m/<IMG\s+.*?>/igms ) {
		$img_tag = $&;
		$count += 1;
		print "$filename : $img_tag\n";
	} # WHILE
	print "\n$filename : count = $count\n";
	if ( $count > 0 ) {
		$matching_img_files{$filename} = $count;
	} # IF
	$num_matching_img_tags += $count;

	return;
} # end of find_img_tags

######################################################################
#
# Function  : MAIN
#
# Purpose   : Find <IMG> tags in a file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : find-img-tags.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , %entries , @entries , $maxlen , @list );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] filename [... filename]\n");
	} # UNLESS

	$Data::Dumper::Indent = 1;  # this is a somewhat more compact output style
	$Data::Dumper::Sortkeys = 1; # sort alphabetically

	foreach my $filename ( @ARGV ) {
		find_img_tags($filename);
	} # FOREACH

	@list = sort { lc $a cmp lc $b } keys %matching_img_files;
	$status = scalar @list;
	print "\n${num_matching_img_tags} IMG tags found in ${status} files\n";
	if ( $num_matching_img_tags > 0 ) {
		$maxlen = (sort { $b <=> $a} map { length $_ } @list)[0];
		foreach my $filename ( @list ) {
			printf "%-${maxlen}.${maxlen}s -- %d\n",$filename,$matching_img_files{$filename};
		} # FOREACH
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

find-img-tags.pl - Find <IMG> tags in a file

=head1 SYNOPSIS

find-img-tags.pl [-hd] [filename]

=head1 DESCRIPTION

Find <IMG> tags in a file

=head1 PARAMETERS

  filename - name of optional filename

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

find-img-tags.pl CANADA htm

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
