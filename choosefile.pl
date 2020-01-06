#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : choosefile.pl
#
# Author    : Barry Kimelman
#
# Created   : January 4, 2020
#
# Purpose   : Choose a file from a list of matching files
#
# Notes     : The name of the chosen file is copied to the clipboard
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use Win32::Clipboard;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_file_info.pl";

my %options = ( "d" => 0 , "h" => 0 , "r" => 0 );
my @matching_files = ();

######################################################################
#
# Function  : scan_tree
#
# Purpose   : Scan a directory tree looking for sub-directories
#
# Inputs    : $_[0] - dirname
#             $_[1] - filename pattern
#
# Output    : appropriate messages
#
# Returns   : nothing
#
# Example   : scan_tree($dirname,"\.txt$")
#
# Notes     : (none)
#
######################################################################

sub scan_tree
{
	my ( $dirname , $pattern ) = @_;
	my ( %entries , @entries , @paths , @list , @dirs , @matched );

	unless ( opendir(DIR,"$dirname") ) {
		die("opendir failed for '$dirname' : $!\n");
	} # UNLESS
	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@entries = keys %entries;
	@paths = map { File::Spec->catfile($dirname,$_) } sort { lc $a cmp lc $b } @entries;
	@dirs = grep { -d $_ } @paths;
	@dirs = grep !/\.git$/i,@dirs;

	@matched = grep /${pattern}/i,@entries;
	if ( 0 < scalar @matched ) {
		push @matching_files,map { File::Spec->catfile($dirname,$_) } sort { lc $a cmp lc $b } @matched;
	} # IF
	if ( $options{'r'} && 0 < scalar @dirs ) {
		foreach my $subdir ( @dirs ) {
			unless ( $subdir =~ m/\.git$/i ) {
				scan_tree($subdir);
			} # UNLESS
		} # FOREACH
	} # IF

	return;
} # end of scan_tree

######################################################################
#
# Function  : MAIN
#
# Purpose   : Choose a file from a list of matching files
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : choosefile.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , %entries , $count , $index , @numbers , $buffer );
	my ( $clip );

	$status = getopts("hdr",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 1 == scalar @ARGV ) {
		die("Usage : $0 [-dhr] pattern\n");
	} # UNLESS
	print "\nChoose one of the following files.\n\n";
	scan_tree(".",$ARGV[0]);

	$count = scalar @matching_files;
	if ( $count == 0 ) {
		die("No files were found.\n");
	} # IF
	@numbers = (1 .. $count);
	print join("\n",map { "$numbers[$_] $matching_files[$_]" } (0 .. $#matching_files)),"\n";
	while ( 1 ) {
		print "\nEnter your choice [1 - $count] : ";
		$buffer = <STDIN>;
		chomp $buffer;
		unless ( $buffer =~ m/^\d+$/ ) {
			print "Non numeric characters detected. Try again.\n";
			next;
		} # UNLESS
		if ( $buffer == 0 ) {
			exit 0;
		} # if
		if ( $buffer < 1 || $buffer > $count ) {
			print "Invalid number. Try again.\n";
			next;
		} # IF
		last;
	} # WHILE
	print "\nYou chose $matching_files[$buffer-1]\n";
	list_file_info_full($matching_files[$buffer-1],{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );

	$clip = Win32::Clipboard();
	unless ( defined $clip ) {
		die("Can't create clipboard object : $!\n");
	} # UNLESS
	$clip->Empty();
	$clip->Set($matching_files[$buffer-1]);
	print "[[ copied to clipboard ]]\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

choosefile.pl - Choose a file from a list of matching files

=head1 SYNOPSIS

choosefile.pl [-hdr] pattern

=head1 DESCRIPTION

Choose a file from a list of matching files

=head1 PARAMETERS

  pattern - pattern to be matched against file names

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -r - recursively process entire directory tree

=head1 EXAMPLES

choosefile.pl "\.txt$"

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
