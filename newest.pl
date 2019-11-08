#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : newest.pl
#
# Author    : Barry Kimelman
#
# Created   : August 3, 2014
#
# Purpose   : Find the "newest" file.
#
# Notes     : The name of the newest file will be copied to the clipboard
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use File::Basename;
use Win32::Clipboard;
use FindBin;
use lib $FindBin::Bin;

require "list_file_info.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "r" => 0 , "o" => 0 , "e" => 0 , "p" => "." , "E" => 0 );
my $ext =".COM|.EXE|.BAT|.CMD|.VBS|.VBE|.JS|.JSE|.WSF|.WSH|.MSC|.py|.pyw|.RB|.RBW";
my $newest_file = "";
my $newest_file_age = undef;

######################################################################
#
# Function  : get_newest_file_under_dir
#
# Purpose   : Find the newest file under a directory.
#
# Inputs    : $_[0] - directory
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : get_newest_file_under_dir($dirname);
#
# Notes     : (none)
#
######################################################################

sub get_newest_file_under_dir
{
	my ( $dirname ) = @_;
	my ( $age , %entries , @subdirs , $path , @entries , @age , @paths , @indices );
	my ( $index );

	unless ( opendir(DIR,$dirname) ) {
		die("opendir failed for '$dirname' : $!\n");
	} # UNLESS

	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@entries = keys %entries;
	@entries = grep /${options{'p'}}/i,@entries;
	@paths = map { File::Spec->catfile($dirname,$_) } @entries;
	@age = map { -M $_ } @paths;
	if ( $options{'o'} ) {
		@indices = sort { $age[$b] <=> $age[$a] } (0 .. $#age);
	} # IF
	else {
		@indices = sort { $age[$a] <=> $age[$b] } (0 .. $#age);
	} # ELSE
	$index = $indices[0];
	if ( defined $newest_file_age ) {
		if ( $options{'o'} ) {
			if ( $newest_file_age > $age[$index] ) {
				$newest_file_age = $age[$index];
				$newest_file = $paths[$index];
			} # IF
		} # IF
		else {
			if ( $newest_file_age < $age[$index] ) {
				$newest_file_age = $age[$index];
				$newest_file = $paths[$index];
			} # IF
		} # ELSE
	} # IF
	else {
		$newest_file = $paths[$index];
		$newest_file_age = $age[$index];
	} # ELSE

	if ( $options{'r'} ) {
		@subdirs = grep { -d $_ } @paths;
		foreach my $dirpath ( @subdirs ) {
			get_newest_file_under_dir($dirpath);
		} # FOREACH
	} # IF

	return;
} # end of get_newest_file_under_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : Find the "newest" file.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : newest.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $dirname , $status , %entries , $reply , $count , $clip );
	my ( $basename );

	$status = getopts("rhdoep:E",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-rdhoeE] [-p pattern] [dirname]\n");
	} # UNLESS

	$count = scalar @ARGV;
	$dirname = (0 < $count) ? $ARGV[0] : ".";
	get_newest_file_under_dir($dirname);

	if ( $newest_file eq "" ) {
		print "No files found under '$dirname'\n";
	} # IF
	else {
		list_file_info_full($newest_file,{ "k" => 0 , "g" => 1 , "o" =>  1});
		$clip = Win32::Clipboard();
		unless ( defined $clip ) {
			die("Can't create clipboard object : $!\n");
		} # UNLESS
		$clip->Empty();
		if ( $newest_file =~ m/\s/ ) {
			$clip->Set('"' . $newest_file . '"');
		} # IF
		else {
			$clip->Set($newest_file);
		} # ELSE
		print "[ '$newest_file' copied to clipboard ]\n";
		if ( $options{'e'} ) {
			system("notepad \"$newest_file\"");
		} # IF
		if ( $options{'E'} ) {
			$basename = uc basename($newest_file);
			if ( $basename =~ m/${ext}$/i ) {
				system("\"$newest_file\"");
			} # IF
		} # IF
	} # ELSE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

newest.pl

=head1 SYNOPSIS

newest.pl [-hdroeE] [dirname]

=head1 DESCRIPTION

Find the "newest" file.

=head1 OPTIONS

   -d - activate debug mode
   -h - produce this summary
   -r - recursively process sub-directories
   -o - find the oldest file
   -e - edit newest file with notepad
   -E - if filename ends with an executable extension then execute the file
   -p pattern - only process files matching the pattern

=head1 PARAMETERS

   dirname - name of directory

=head1 EXAMPLES

newest.pl

=head1 EXIT STATUS

  0 - successful completion
  nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
