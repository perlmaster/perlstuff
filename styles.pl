#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : styles.pl
#
# Author    : Barry Kimelman
#
# Created   : October 3, 2018
#
# Purpose   : Extract the CSS styles from a styles file
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "p" => 0 );
my $num_matching_css_styles = 0;
my %matching_css_files = ();

######################################################################
#
# Function  : find_css_styles
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
# Example   : find_css_styles($filename,$pattern);
#
# Notes     : (none)
#
######################################################################

sub find_css_styles
{
	my ( $filename , $pattern ) = @_;
	my ( $records , @records , $style , $details , $count , $index , %style );

	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return -1;
	} # UNLESS
	@records = <INPUT>;
	close INPUT;

	$records = join("",@records);
	$count = 0;
	%style = ();
	while ( $records =~ m/\.(\w+)\s*{(.*?)}/igms ) {
		$style = $1;
		$details = $2;
		##  print "\nDEBUG : File = $filename  style = $style\nINFO = [$details]\n";
		if ( $style =~ m/${pattern}/i ) {
			unless ( exists $style{$style} ) {
				print "\nFile = $filename  style = $style\nDetails = {$details}\n";
				$num_matching_css_styles += 1;
				$count += 1;
				$style{$style} += 1;
			} # UNLESS
		} # IF
	} # WHILE
	if ( $count > 0 ) {
		$matching_css_files{$filename} = $count;
	} # IF

	return;
} # end of find_css_styles

######################################################################
#
# Function  : MAIN
#
# Purpose   : Extract the CSS styles from a styles file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : styles.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $pattern , %entries , @entries , @list , $maxlen );

	$status = getopts("hdp",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
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
		@entries = grep { -f $_ } @entries;
	} # IF
	foreach my $filename ( @ARGV ) {
		if ( $options{'p'} ) {
			@list = grep /${filename}/i,@entries;
			if ( 0 == scalar @list ) {
				print "\nNo filename matches for '$filename'\n";
			} # IF
			else {
				foreach my $matched ( @list ) {
					find_css_styles($matched,$pattern);
				} # FOREACH
			} # ELSE
		} # IF
		else {
			find_css_styles($filename,$pattern);
		} # ELSE
	} # FOREACH
	@list = sort { lc $a cmp lc $b } keys %matching_css_files;
	$status = scalar @list;
	print "\n${num_matching_css_styles} found in ${status} files\n";
	if ( $num_matching_css_styles > 0 ) {
		$maxlen = (sort { $b <=> $a} map { length $_ } @list)[0];
		foreach my $filename ( @list ) {
			printf "%-${maxlen}.${maxlen}s -- %d\n",$filename,$matching_css_files{$filename};
		} # FOREACH
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

styles.pl - Extract the CSS styles from a styles file

=head1 SYNOPSIS

styles.pl [-hdp] pattern [filename]

=head1 DESCRIPTION

Extract the CSS styles from a styles file

=head1 PARAMETERS

  filename - name of optional filename

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -p - use the filename as a regular expression

=head1 EXAMPLES

styles.pl CANADA favs.htm

styles.pl -p CANADA htm

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
