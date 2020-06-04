#!/usr/local/bin/perl

######################################################################
#
# File      : hgrep.pl
#
# Author    : Barry Kimelman
#
# Created   : October 2, 2002
#
# Purpose   : Produce output similar to UNIX "grep" command.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;
use ANSIColor;

require "display_pod_help.pl";

my ( $num_files_searched , $tabwidth );
my ( $bold , $normal );
my %options = ( "d" => 0 , "i" => 0 , "b" => 0 , "n" => 0 , "p" => 0 , "B" => "white" );

######################################################################
#
# Function  : expand_tabs
#
# Purpose   : Expand tabs to spaces.
#
# Inputs    : $_[0] - record to be expanded
#
# Output    : (none)
#
# Returns   : expanded record
#
# Example   : $expanded = expand_tabs($buffer);
#
# Notes     : (none)
#
######################################################################

sub expand_tabs
{
	my ( $oldbuffer ) = @_;
	my ( $expanded , $loc );

	$expanded = $oldbuffer;
	while ($expanded =~ m/\t/g) {
		$loc = pos($expanded) - 1;
		substr ($expanded,$loc,1) = ' ' x ($tabwidth - ($loc % $tabwidth));
	} # WHILE

	return $expanded;
} # end of expand_tabs

######################################################################
#
# Function  : search_file
#
# Purpose   : Search the specified file for the specified pattern.
#
# Inputs    : $_[0] - pattern
#             $_[1] - filename
#             $_[2] - ref to array of records
#
# Output    : matched records
#
# Returns   : count of matched records
#
# Example   : $count = search_file($pattern,$filename,\@records);
#
# Notes     : (none)
#
######################################################################

sub search_file
{
	my ( $pattern , $filename , $ref_records ) = @_;
	my ( $buffer , $num_matched , $match , $exclude , $output , $buffer2 );
	my ( $oldbuffer , $recnum );

	$num_files_searched += 1;
	$num_matched = 0;
	$recnum = 0;
	while ( 0 < scalar @$ref_records ) {
		$recnum += 1;
		$oldbuffer = shift @$ref_records;
		chomp $oldbuffer;
		$buffer = expand_tabs($oldbuffer);
		if ( defined $options{"x"} ) {
			if ( $options{"i"} ) {
				$exclude = $buffer =~ m/${options{"x"}}/i;
			} # IF
			else {
				$exclude = $buffer =~ m/${options{"x"}}/;
			} # ELSE
			if ( $exclude ) {
				next;
			} # IF
		} # IF
		if ( $options{"i"} ) {
			$match = $buffer =~ m/${pattern}/i;
		} # IF
		else {
			$match = $buffer =~ m/${pattern}/;
		} # ELSE
		if ( $match ) {
			$num_matched += 1;
			if ( $num_matched == 1 ) {
				print "\n";
			} # IF
			print "$filename:";
			if ( $options{"n"} ) {
				printf "%5d:",$recnum;
			} # IF
			print "\t";

			$output = "";
			$buffer2 = $buffer;
			if ( $options{"i"} ) {
				while ( $buffer2 =~ m/${pattern}/i ) {
					$output .= $`;  # add on PREMATCH
					$output .= "${bold}$&${normal}";  # add on MATCH
					$buffer2 = $';  # buffer2 becomes POSTMATCH
				} # WHILE
				$output .= $buffer2;
			} # IF
			else {
				while ( $buffer2 =~ m/${pattern}/ ) {
					$output .= $`;  # add on PREMATCH
					$output .= "${bold}$&${normal}";  # add on MATCH
					$buffer2 = $';  # buffer2 becomes POSTMATCH
				} # WHILE
				$output .= $buffer2;
			} # ELSE
			print "$output";

			print "\n";
			if ( $options{"b"} ) {
				print "\n";
			} # IF
		} # IF
	} # WHILE
	close INPUT;

	return $num_matched;
} # end of search_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Produce output similar to the UNIX "grep" command.
#
# Inputs    : command line parameters
#
# Output    : Matching records.
#
# Returns   : nothing
#
# Example   : hgrep.pl -in foobar *.txt
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $pattern , @matched , $num_matches , %entries , @entries , @files );
	my ( $status , $filename , $startdir , $filename_pattern , @list );
	my ( @records );

	$status = getopts("dibnphB:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dinbp] [-B bold_color] [-t tabwidth] [-x exclude_pattern] pattern ",
				"filename [... filename]\n");
	} # UNLESS
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

	$bold = color "reverse $options{'B'}";  # used to be red
	$normal = color 'reset';

	$tabwidth = (exists $options{"t"}) ? $options{"t"} : 4;

	$pattern = shift @ARGV;
	$num_files_searched = 0;
	if ( $options{'p'} ) {
		@files = ();
		foreach my $pattern ( @ARGV ) {
			push @files, grep /${pattern}/i,@entries;
		} # FOREACH
	} # IF
	else {
		@files = @ARGV;
	} # ELSE
	if ( 0 == scalar @files ) {
			@records = <STDIN>;
			$num_matches += search_file($pattern,"--stdin--",\@records);
	} # IF
	else {
		foreach $filename ( @files ) {
			unless ( open(INPUT,"<$filename") ) {
				die("open failed for '$filename' : $!\n");
			} # UNLESS
			@records = <INPUT>;
			close INPUT;
			$num_matches += search_file($pattern,$filename,\@records);
		} # FOREACH
	} # ELSE


	if ( $num_matches >= 1 ) {
		print "\n$num_matches matches to '$pattern' ";
		if ( $options{"i"} ) {
			print "[nocase] ";
		} # IF
	} # IF
	else {
		print "\nNo matches to '$pattern'";
	} # ELSE
	print " in $num_files_searched files.\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

hhgrep.pl - grep with color highlighting

=head1 SYNOPSIS

hhgrep.pl [-dinbp] [-t tabwidth] [-x exclude_pattern] pattern filename [... filename]

=head1 DESCRIPTION

grep with color highlighting

=head1 PARAMETERS

  pattern - search pattern
  filename - name of file to be searched

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -i - use case insensitive searching
  -n - display line numbers for matched lines
  -b - display extra blank lines
  -p - treat filenames as patterns to be applied against current directory
  -B bold_color - the color for the reverse video bold highlighting

=head1 EXAMPLES

hhgrep.pl -in die foo.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
