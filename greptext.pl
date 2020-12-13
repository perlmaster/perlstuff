#!/usr/bin/perl -w

######################################################################
#
# File      : greptext.pl
#
# Author    : Barry Kimelman
#
# Created   : November 15, 2018
#
# Purpose   : Search ASCII text files for a pattern
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use Data::Dumper;
use Sys::Hostname;
use Cwd;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "elapsed_time.pl";

my %options = (
	"d" => 0 , "h" => 0 , "i" => 0 , "n" => 0 , "D" => "." , "r" => 0 , "x" => 0 , "p" => 0 , "l" => 0 , "L" => 0 , "f" => 0 , "a" => 0
);

my $num_files_searched = 0;
my $num_files_matched = 0;
my $num_lines_matched = 0;
my @patterns = ();
my $all_patterns;
my $file_pattern;
my $start_time;
my $end_time;
my $startdir;
my %matching_dirs = ();
my %file_matching_lines = ();
my $num_dirs_scanned = 0;
my $hostname;
my @no_yes = ( 'no' , 'yes' );

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
	my ( $message );

	if ( $options{'d'} ) {
		$message = join('',@_);
		print "$message";
	} # IF

	return;
} # end of debug_print

######################################################################
#
# Function  : search_file
#
# Purpose   : Search a file for the specified pattern
#
# Inputs    : $_[0] - filename
#
# Output    : matches or errors
#
# Returns   : IF problem THEN negative ELSE number of matches
#
# Example   : $count = search_file($path);
#
# Notes     : (none)
#
######################################################################

sub search_file
{
	my ( $filename ) = @_;
	my ( $count , $match , $buffer , $pattern );

	debug_print("search_file($filename)\n");
	$pattern = join("|",@patterns);
	$num_files_searched += 1;
	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return 0;
	} # UNLESS
	$count = 0;
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		if ( exists $options{"E"} && $buffer =~ m/${options{"E"}}/i ) {
			next;
		} # IF
		$match = 0;
		if ( $options{'i'} && $buffer =~ m/${pattern}/i ) {
			$match = 1;
		} # IF
		if ( $options{'i'} == 0  && $buffer =~ m/${pattern}/ ) {
			$match = 1;
		} # IF
		if ( $match ) {
			$count += 1;
			unless ( $options{'l'} ) {
				if ( $count == 1 ) {
					print "\n";
				} # IF
				print "$filename:";
				if ( $options{'n'} ) {
					print "$.:";
				} # IF
				print "\t$buffer\n";
			} # UNLESS
			else {
				if ( $count == 1 ) {
					print "$filename\n";
				} # IF
			} # ELSE
		} # IF
	} # WHILE
	close INPUT;
	$num_lines_matched += $count;
	if ( $count ) {
		$num_files_matched += 1;
		$file_matching_lines{$filename} = $count;
	} # IF

	return $count;
} # end of search_file

######################################################################
#
# Function  : search_file_all
#
# Purpose   : Search a file for all of the specified patterns
#
# Inputs    : $_[0] - filename
#
# Output    : matches or errors
#
# Returns   : IF problem THEN negative ELSE number of matches
#
# Example   : $count = search_file_all($path);
#
# Notes     : (none)
#
######################################################################

sub search_file_all
{
	my ( $filename ) = @_;
	my ( $count , $match , $buffer , $pattern , %patterns , @matched_lines , @line_numbers , $index );
	my ( $missed , $status );

	debug_print("search_file_all($filename)\n");
	$pattern = join("|",@patterns);
	$num_files_searched += 1;

	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return 0;
	} # UNLESS
	%patterns = map { $_ , 0 } @patterns;

	@matched_lines = ();
	@line_numbers = ();
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		if ( exists $options{"E"} && $buffer =~ m/${options{"E"}}/i ) {
			next;
		} # IF
		foreach my $pattern ( @patterns ) {
			$match = 0;
			if ( $options{'i'} && $buffer =~ m/${pattern}/i ) {
				$match = 1;
				push @line_numbers,$.;
				push @matched_lines,$buffer;
				$patterns{$pattern} += 1;
			} # IF
			if ( $options{'i'} == 0 && $buffer =~ m/${pattern}/ ) {
				$match = 1;
				push @line_numbers,$.;
				push @matched_lines,$buffer;
				$patterns{$pattern} += 1;
			} # IF
		} # FOREACH
	} # WHILE
	close INPUT;
	$missed = 0;
	foreach my $pattern ( @patterns ) {
		if ( $patterns{$pattern} < 1 ) {
			$missed += 1;
		} # IF
	} # FOREACH
	if ( $missed == 0 ) {
		$status = 1;
		$num_lines_matched += scalar @matched_lines;
		if ( $options{'l'} ) {
			print "$filename\n";
			return 1;
		} # IF
		$count = 0;
		for ( $index = 0 ; $index <= $#matched_lines ; ++$index ) {
			$count += 1;
			if ( $count == 1 ) {
				print "\n";
			} # IF
			print "$filename:";
			if ( $options{'n'} ) {
				print "$line_numbers[$index]:";
			} # IF
			print "\t$matched_lines[$index]\n";
		} # FOR
	} # IF
	else {
		$status = 0;
	} # ELSE

	return $status;
} # end of search_file_all

######################################################################
#
# Function  : process_dir
#
# Purpose   : Process a directory
#
# Inputs    : $_[0] - dirname
#             $_[1] - directory level (0 is top)
#
# Output    : appropriare messages
#
# Returns   : (nothing)
#
# Example   : process_dir($dirname,0);
#
# Notes     : (none)
#
######################################################################

sub process_dir
{
	my ( $dirname , $dir_level ) = @_;
	my ( $status , %entries , $path , @entries , $count , @subdirs );

	if ( exists $options{'m'} && $dir_level > $options{'m'} ) {
		return;
	} # IF

	debug_print("search_dir($dirname)\n");
	unless ( opendir(DIR,$dirname) ) {
		warn("opendir failed for $dirname : $!\n");
		return;
	} # UNLESS
	$num_dirs_scanned += 1;
	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@entries = keys %entries;
	$count = scalar @entries;
	debug_print("search_dir($dirname) , number of files = $count\n");
	foreach my $entry ( sort { lc $a cmp lc $b } @entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		if ( -d $path ) {
			push @subdirs,$path;
			next;
		} # IF
		if ( $entry =~ m/${file_pattern}/i ) {
			if ( $options{'L'} && -l $path ) {
				next;  # skip over symbolic link
			} # IF
			if ( -T "$path" ) {
				unless ( exists $options{'e'} && $entry =~ m/${options{'e'}}/i ) {
					if ( $options{'a'} ) {
						$count = search_file_all($path);
					} # IF
					else {
						$count = search_file($path);
					} # ELSE
					if ( $count > 0 ) {
						$matching_dirs{$dirname} += 1;
					} # IF
				} # UNLESS
			} # IF
		} # IF
	} # FOREACH

	if ( $options{'r'} ) {
		foreach my $subdir ( @subdirs ) {
			process_dir($subdir,1+$dir_level);
		} # FOREACH
	} # IF

	return;
} # end of process_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : Search ASCII text files for a pattern
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : greptext.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , @list , $num_dirs_matched , $index , $buffer );

	select STDERR;
	$| = 1; # automatic flushing for STDERR;
	select STDOUT;
	$| = 1; # automatic flushing for STDOUT

	$status = getopts("hdinD:re:m:xplLfaE:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dhinrxplLfa] [-m max_dir_level] [-E exclude_text_pattern] [-e exclude_file_pattern] [-D dirname] text_pattern [filename_pattern [... filename_pattern]]\n");
	} # UNLESS
	$hostname = hostname;
	$startdir = getcwd();
	$start_time = time;
	$buffer = shift @ARGV;
	if ( $options{'f'} ) {
		unless ( open(PATTERNS,"<$buffer") ) {
			die("open failed for '$buffer' : $!\n");
		} # UNLESS
		@patterns = <PATTERNS>;
		close PATTERNS;
		chomp @patterns;
	} # IF
	else {
		@patterns = ( $buffer );
	} # ELSE
	$all_patterns = join("|",@patterns);

	$file_pattern = (0 == scalar @ARGV) ? "." : join("|",@ARGV);
	if ( $options{'p'} ) {
		if ( 0 == scalar @ARGV ) {
			$file_pattern = '\.p[lm]$|\.cgi$'
		} # IF
		else {
			$file_pattern .= '|\.p[lm]$|\.cgi$'
		} # ELSE
	} # IF

	process_dir($options{"D"},0);
	$end_time = time;

	if ( $num_lines_matched > 0 ) {
		$num_dirs_matched = scalar keys %matching_dirs;
	} # IF
	else {
		$num_dirs_matched = 0;
	} # ELSE
	$buffer = localtime $start_time;
	print qq~
Hostname                                  : $hostname
Start Time                                : $buffer
Starting Directory ( current directory )  : $options{"D"} ( $startdir )
Text Pattern                              : $all_patterns
Case Insensitive                          : $no_yes[$options{'i'}]
All Patterns Must Exist In File           : $no_yes[$options{'a'}]
Skip over symbolic links                  : $no_yes[$options{'L'}]
Look at Perl files ( *.pl and *.pm )      : $no_yes[$options{'i'}]
Recursive search                          : $no_yes[$options{'r'}]
Filename Pattern                          : $file_pattern
Number of files searched / matched        : $num_files_searched / $num_files_matched
Number of lines matched                   : $num_lines_matched
Number of directories scanned / matched   : $num_dirs_scanned / $num_dirs_matched
~;
	if ( $options{'x'} ) {
		@list = sort { lc $a cmp lc $b } keys %file_matching_lines;
		print "\nThe $num_files_matched files with matching lines\n";
		for ( $index = 0 ; $index < $num_files_matched ; ++$index ) {
			printf "%3d\t%s\n",1+$index,$list[$index];
		} # FOR

		@list = sort { lc $a cmp lc $b } keys %matching_dirs;
		print "\nThe $num_dirs_matched directories with matching files\n";
		for ( $index = 0 ; $index < $num_dirs_matched ; ++$index ) {
			printf "%3d\t%s\n",1+$index,$list[$index];
		} # FOR
	} # IF
	if ( $options{'l'} ) {
		print "\nMatching lines were not listed\n";
	} # IF
	elapsed_time("\nElapsed Time : %d minutes %d seconds\n\n",$start_time,$end_time);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

greptext.pl - Search ASCII text files for a pattern

=head1 SYNOPSIS

greptext.pl [-hdinrxplLfa] [-m max_dir_level] [-E exclude_text_pattern] [-e exclude_file_pattern] [-D dirname] text_pattern [filename_pattern [... filename_pattern]]

=head1 DESCRIPTION

Search ASCII text files for a pattern

=head1 PARAMETERS

  pattern - pattern to be matched against file records

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -i - case insensitive searching
  -n - display line numbers for matched lines
  -D dirname - name of directory to be processed
  -r - recursively process sub-directories
  -e exclude_file_pattern - pattern used to exclude files from being searched
  -m max_dir_level - maximum directory level for descent
  -x - print some extra info with the summary
  -p - match Perl files (*.pl and *.pm and *.cgi)
  -l - do not list matching lines
  -L - do not process symbolic links
  -f - treat the text_pattern as a file containing a list of patterns
  -a - the file must contain all of the patterns
  -E exclude_text_pattern - pattern used to exclude lines

=head1 EXAMPLES

greptext.pl something

greptext.pl -rn something    # recursively search

greptext.pl -prn something    # recursively search perl files

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
