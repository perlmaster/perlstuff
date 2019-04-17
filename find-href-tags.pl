#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : find-href-tags.pl
#
# Author    : Barry Kimelman
#
# Created   : October 3, 2018
#
# Purpose   : Extract HREF tag information from a bookmarks file
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

my %options = ( "d" => 0 , "h" => 0 , "p" => 0 );
my $num_matching_hrefs = 0;
my %matching_href_files = ();

######################################################################
#
# Function  : find_hrefs
#
# Purpose   : Find the HREF tags in a file
#
# Inputs    : $_[0] - filename
#             $_[1] - pattern to match against label
#
# Output    : list of HREFs
#
# Returns   : nothing
#
# Example   : find_hrefs($filename,$pattern);
#
# Notes     : (none)
#
######################################################################

sub find_hrefs
{
	my ( $filename , $pattern ) = @_;
	my ( $records , @records , $url , $label , $count , $index );

	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return -1;
	} # UNLESS
	@records = <INPUT>;
	close INPUT;

	$records = join("",@records);
	$count = 0;
	while ( $records =~ m/<A\s*?HREF="(.*?)".*?>(.*?)<\/A>/igms ) {
		$url = $1;
		$label = $2;
		if ( $label =~ m/${pattern}/i ) {
			print "\nFile = $filename  URL = $url\nLABEL = [$label]\n";
			$num_matching_hrefs += 1;
			$count += 1;
		} # IF
	} # WHILE
	if ( $count > 0 ) {
		$matching_href_files{$filename} = $count;
	} # IF

	return;
} # end of find_hrefs

######################################################################
#
# Function  : MAIN
#
# Purpose   : Extract HREF tag information from a bookmarks file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : find-href-tags.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $pattern , %entries , @entries , @list , $maxlen );

	$status = getopts("hdp",\%options);
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
		die("Usage : $0 [-dhp] pattern filename [... filename]\n");
	} # UNLESS

	$pattern = shift @ARGV;
	if ( $options{'p'} ) {
		unless ( opendir(DIR,".") ) {
			die("opendir failed : $!\n");
		} # UNLESS
		%entries = map { $_ , 0 } readdir DIR;
		closedir DIR;
		delete $entries{".."};
		delete $entries{"."};
		@entries = sort { lc $a cmp lc $b } keys %entries;
	} # IF
	foreach my $filename ( @ARGV ) {
		if ( $options{'p'} ) {
			@list = grep /${filename}/i,@entries;
			if ( 0 == scalar @list ) {
				print "\nNo filename matches for '$filename'\n";
			} # IF
			else {
				foreach my $matched ( @list ) {
					find_hrefs($matched,$pattern);
				} # FOREACH
			} # ELSE
		} # IF
		else {
			find_hrefs($filename,$pattern);
		} # ELSE
	} # FOREACH
	@list = sort { lc $a cmp lc $b } keys %matching_href_files;
	$status = scalar @list;
	print "\n${num_matching_hrefs} found in ${status} files\n";
	if ( $num_matching_hrefs > 0 ) {
		$maxlen = (sort { $b <=> $a} map { length $_ } @list)[0];
		foreach my $filename ( @list ) {
			printf "%-${maxlen}.${maxlen}s -- %d\n",$filename,$matching_href_files{$filename};
		} # FOREACH
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

find-href-tags.pl - Extract HREF tag information from a bookmarks file

=head1 SYNOPSIS

find-href-tags.pl [-hdp] pattern [filename]

=head1 DESCRIPTION

Extract HREF tag information from a bookmarks file

=head1 PARAMETERS

  filename - name of optional filename

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -p - use the filename as a regular expression

=head1 EXAMPLES

find-href-tags.pl CANADA favs.htm

find-href-tags.pl -p CANADA htm

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
