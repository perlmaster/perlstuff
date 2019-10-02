#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : and.pl
#
# Author    : Barry Kimelman
#
# Created   : December 14, 2012
#
# Purpose   : Check to see if files contain all patterns in a list of patterns.
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
use FindBin;
use lib $FindBin::Bin;

require "get_dir_entries.pl";
require "list_file_info.pl";
require "display_pod_help.pl";

my ( @matched_files );
my %options = ( "d" => 0 , "p" => 0 , "h" => 0 , "L" => 0 , "l" => 0 , "w" => 0 );

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
	close INPUT;
	print "$filename : ${num_lines} lines , ${num_chars} characters\n";

	return;
} # end of count_lines

######################################################################
#
# Function  : search_file
#
# Purpose   : Search a file for a set of patterns.
#
# Inputs    : $_[0] - filename
#             $_[1] - reference to array of patterns
#
# Output    : search result
#
# Returns   : nothing
#
# Example   : search_file($filename,\@patterns);
#
# Notes     : (none)
#
######################################################################

sub search_file
{
	my ( $filename , $ref_patterns ) = @_;
	my ( $flag , $buffer , @records , @matched , %matched_lines , $index , $pattern , @patterns , $index2 , @list );
	my ( $count );

	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for file '$filename' : $!\n");
		return;
	} # UNLESS
	@records = <INPUT>;
	close INPUT;
	chomp @records;

	@patterns = @$ref_patterns;
	$flag = 1;
	%matched_lines = ();
	for ( $index = 0 ; $index <= $#patterns ; ++$index ) {
		$flag = -1;
		$pattern = $patterns[$index];
		for ( $index2 = 0 ; $index2 <= $#records ; ++$index2 ) {
			if ( $records[$index2] =~ m/${pattern}/i ) {
				$flag = $index2;
				last;
			} # IF
		} # FOR
		if ( $flag < 0 ) {
			return;
		} # IF
		$matched_lines{$index2} = $pattern;
	} # FOR
	push @matched_files,$filename;
	unless ( $options{'l'} ) {
		$count = 0;
		foreach my $line ( sort { $a <=> $b } keys %matched_lines ) {
			if ( ++$count == 1 ) {
				print "\n";
			} # IF
			printf "%s : %d : %s\n",$filename,1+$line,$records[$line];
		} # FOREACH
	} # IF

	return;
} # end of search_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Check to see if files contain all patterns in a list of patterns.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : and.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $patterns , @patterns , $buffer , $matched_files );
	my ( @list , @entries , @matches , $string , $errmsg );

	$status = getopts("hdplLw",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 1 < @ARGV ) {
		die("Usage : $0 [-dphlLw] patterns_or_filename filename [... filename]\n");
	} # UNLESS

	$patterns = shift @ARGV;
	@matched_files = ();
	if ( $options{'p'} ) {
		@patterns = split(/::/,$patterns);
	} # IF
	else {
		@patterns = ();
		unless ( open(PATTERNS,"<$patterns") )  {
			die("open failed for file '$patterns' : $!\n");
		} # UNLESS
		while ( $buffer = <PATTERNS> ) {
			chomp $buffer;
			push @patterns,$buffer;
		} # WHILE
		close PATTERNS;
	} # ELSE

	@list = ();
	if ( 0 == scalar @ARGV ) {
		$status = get_dir_entries(".",{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@list,\$errmsg);
		if ( $status < 0 ) {
			die("$errmsg\n");
		} # IF
	} # IF
	else {
		foreach $string ( @ARGV ) {
			if ( -d $string && ! $options{"D"} ) {
				$status = get_dir_entries($string,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
				if ( $status < 0 ) {
					dir("$errmsg\n");
				} # IF
				push @list,@entries;
			} # IF
			else {
				@matches = glob($string);
				if ( @matches < 1 ) {
					print "'$string' : No match\n";
				} # IF
				else {
					push @list,@matches;
				} # IF
			} # ELSE
		} # FOREACH
	} # ELSE

	foreach my $filename ( @list ) {
		search_file($filename,\@patterns);
	} # FOREACH

	if ( 1 > @matched_files ) {
		print "\nNo file contained all of the patterns\n\n";
	} # IF
	else {
		print "\n";
		if ( $options{'l'} ) {
			print join("\n",@matched_files),"\n";
		} # IF
		else {
			if ( $options{'w'} || $options{'L'} ) {
				foreach my $match ( @matched_files ) {
					if ( $options{"L"} ) {
						list_file_info_full($match,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
					} # IF
					if ( $options{'w'} ) {
						count_lines($match);
					} # IF
				} # FOREACH
			} # IF
		} # ELSE
	} # ELSE
	print "\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

and.pl

=head1 SYNOPSIS

and.pl [-hdp] patterns_or_filename filename [... filename]

=head1 DESCRIPTION

Check to see if files contain all patterns in a list of patterns.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -p - 1st parameter is actually a comma separated list of patterns
  -L - use "ls" to display matching file information
  -w - use "wc -lc" to display matching file information
  -l - only list names of files containing matches to all of the patterns

=head1 PARAMETERS

  patterns_or_filename - either a double-colon-separated list of patterns or a filename

=head1 EXAMPLES

and.pl xxx

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
