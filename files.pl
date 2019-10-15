#!/usr/bin/perl -w

######################################################################
#
# File      : files.pl
#
# Author    : Barry Kimelman
#
# Created   : December 2, 2011
#
# Purpose   : Display file information (ala "ls -ld") for files matched by a regular expression
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::stat;
use Fcntl;
use File::Spec;
use File::Copy;
use Win32::Console;
use FindBin;
use lib $FindBin::Bin;

require "time_date.pl";
require "comma_format.pl";
require "list_file_info.pl";
require "display_pod_help.pl";
require "list_columns_style.pl";

my %options = (
	"d" => 0 , "h" => 0 , "t" => 0 , "T" => 0 ,"f" => 0 , "D" => '.' , "p" => 0 , "r" => 0 , "k" => 0 , "o" => 0 , "g" => 0 , "C" => 0
);
my %matched_files = ();
my @patterns;
my $maxlen;
my ( $CONSOLE , @console_info , %console_info );

######################################################################
#
# Function  : debug_print
#
# Purpose   : Optionally print a debugging message.
#
# Inputs    : @_ - array of strings comprising message
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : debug_print("Process the files : ",join(" ",@xx),"\n");
#
# Notes     : (none)
#
######################################################################

sub debug_print
{
	if ( $options{"d"} ) {
		print join("",@_);
	} # IF

	return;
} # end of debug_print

######################################################################
#
# Function  : count_lines
#
# Purpose   : Count lines and characters in a file
#
# Inputs    : $_[0] - filename
#
# Output    : (none)
#
# Returns   : (nothing)
#
# Example   : count_lines($filename);
#
# Notes     : (none)
#
######################################################################

sub count_lines
{
	my ( $filename ) = @_;
	my ( $buffer , $num_lines , $num_chars );

	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return -1;
	} # UNLESS

	$num_lines = 0;
	$num_chars = 0;
	while ( $buffer = <INPUT> ) {
		$num_lines += 1;
		$num_chars += length $buffer;
	} # WHILE
	printf "%-${maxlen}.${maxlen}s : %s %s\n",$filename,comma_format($num_lines),comma_format($num_chars);

	return;
} # end of count_lines

######################################################################
#
# Function  : get_file_mtime
#
# Purpose   : Optionally print a debugging message.
#
# Inputs    : @_ - array of strings comprising message
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : %entries = map { $_ , get_file_mtime("${dirname}/$_") } readdir DIR;
#
# Notes     : (none)
#
######################################################################

sub get_file_mtime
{
	my ( $path ) = @_;
	my ( $status );

	$status = stat($path);
	unless ( $status ) {
		die("stat failed for file '$path' : $!\n");
	} # UNLESS

	return $status->mtime;
} # end of get_file_mtime

######################################################################
#
# Function  : process_dir
#
# Purpose   : Process a directory
#
# Inputs    : $_[0] - directory name
#
# Output    : matching files
#
# Returns   : nothing
#
# Example   : process_dir($dirname);
#
# Notes     : (none)
#
######################################################################

sub process_dir
{
	my ( $dirname ) = @_;
	my ( %entries , @all_matches , $style , $command , @paths , @matched );
	my ( @files , @mtimes , @indices , $path , @subdirs );

	unless ( opendir(DIR,$dirname) ) {
		warn("opendir failed for '$dirname' : $!\n");
		return -1;
	} # UNLESS

	%entries = map { $_ , get_file_mtime("${dirname}/$_") } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};

	@all_matches = ();
	foreach my $pattern ( @patterns ) {
		@matched = grep /${pattern}/i,keys %entries;
		if ( 0 < @matched ) {
			push @all_matches,@matched;
		} # IF
		else {
			##  print "No matches for '$pattern' under $dirname\n";
		} # ELSE
	} # FOREACH
	if ( exists $options{'e'} ) {
		@all_matches = grep /\.${options{'e'}}$/i,@all_matches;
	} # IF
	if ( $options{'p'} ) {
		@all_matches = grep /\.p[lm]$|\.cgi$/i,@all_matches;
	} # IF
	debug_print("\nall_matches : " , join(" , ",@all_matches),"\n\n");

	@subdirs = ();
	foreach my $file ( keys %entries ) {
		$path = File::Spec->catfile($dirname,$file);
		if ( -d $path ) {
			push @subdirs,$path;
		} # IF
	} # FOREACH
	foreach my $file ( @all_matches ) {
		$path = File::Spec->catfile($dirname,$file);
		$matched_files{$path} = $entries{$file};
	} # FOREACH

	if ( 1 > @all_matches ) {
		##  print "\nNo matches to any pattern under '$dirname'\n";
	} # ELSE

	if ( $options{'r'} ) {
		foreach my $subdir ( @subdirs ) {
			process_dir($subdir);
		} # FOREACH
	} # IF

	return;
} # end of process_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : Display file information (ala "ls -ld") for files matched by a regular expression
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : files.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $dirname , $command , @files , @mtimes , @indices , $style );
	my ( $path , $destpath );

	$status = getopts("ChdtTfD:e:prkogwc:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < @ARGV ) {
		die("Usage : $0 [-CdhtTfprkogw] [-c dirname] [-e extension] [-D dirname] pattern [... pattern]\n");
	} # UNLESS

	if ( $options{"t"} && $options{"T"} ) {
		die("options 't' and 'T' are mutually exclusive\n");
	} # IF
	if ( exists $options{'c'} && ! -d $options{'c'} ) {
		die("'$options{'c'} is not an existing directory.\n");
	} # IF

	if ( $^O =~ m/MSWin/ ) {
		$options{"o"} = 1;
		$options{"g"} = 1;
	} # IF

	$CONSOLE = new Win32::Console();
	unless ( defined $CONSOLE ) {
		die("Can't create console object : $!\n");
		exit 1;
	} # UNLESS
	@console_info = $CONSOLE->Info();
	%console_info = (
		"columns" => $console_info[0] ,
		"rows" => $console_info[1] ,
		"max_columns" => $console_info[9] ,
		"max_rows" => $console_info[10]
	);

	$dirname = $options{'D'};
	@patterns = @ARGV;
	process_dir($dirname);

	$style = "";
	@files = sort { lc $a cmp lc $b } keys %matched_files;
	@mtimes = map { $matched_files{$_} } @files;
	if ( $options{'t'} ) {
		@indices = sort { $mtimes[$a] <=> $mtimes[$b] } (0 .. $#mtimes);
	} elsif ( $options{'T'} ) {
		@indices = sort { $mtimes[$b] <=> $mtimes[$a] } (0 .. $#mtimes);
	} else {
		@indices = ( 0 .. $#mtimes );
	} # ELSE

	if ( $options{'w'} ) {
		$maxlen = (sort { $b <=> $a } map { length $_ } @files)[0];
		foreach my $index ( @indices ) {
			count_lines($files[$index]);
		} # FOREACH
	} # IF
	else {
		if ( $options{"C"} ) {
			@files = @files[@indices];
			list_columns_style(\@files,$console_info{'columns'},undef,\*STDOUT);
		} # IF
		else {
			foreach my $index ( @indices ) {
				list_file_info_full($files[$index],\%options);
			} # FOREACH
		} # ELSE
	} # ELSE

	if ( exists $options{"c"} ) {
		foreach my $entry ( @files ) {
			$path = File::Spec->catfile($dirname,$entry);
			$destpath = File::Spec->catfile($options{"c"},$entry);
			unless ( copy($path,$destpath) ) {
				warn("copy from $path to $destpath failed : $!<BR>");
			} # UNLESS
			else {
				print "Copied $path to $destpath\n";
			} # ELSE
		} # FOREACH
	} # IF


	exit 0;
} # end of MAIN
__END__
=head1 NAME

files.pl

=head1 SYNOPSIS

files.pl [-dhtTfkogw] [-e pattern] [-c dirname] [-D dirname] pattern

=head1 DESCRIPTION

Display file information (ala "ls -ld") for files matched by a regular expression

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -f - just list the filenames
  -T - sort by time of modification , newest first
  -t - sort by time of modification , oldest first
  -e pattern - only report on files with an extension matching this pattern
  -D dirname - name of directory (default is ".")
  -p - only show Perl code relted files
  -r - recursively process sub-directories
  -k - display file size in terms of GB / MB / KB
  -g - do not display group name
  -o - do not display owner name
  -w - count lines and characters just like the wc command
  -c dirname - copy listed files to the named directory
  -C - list filenames in a compact format

=head1 PARAMETERS

  pattern - filename pattern

=head1 EXAMPLES

files.pl '[a-z][0-9]'

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
