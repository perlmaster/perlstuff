#!/usr/bin/perl -w

######################################################################
#
# File      : notfound.pl
#
# Author    : Barry Kimelman
#
# Created   : January 4, 2005
#
# Purpose   : List names of files that don't contain a pattern
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "get_dir_entries.pl";
require "display_pod_help.pl";
require "list_file_info.pl";

my %options = ( "d" => 0 , "i" => 0 , "h" => 0 , "f" => 0 , "p" => 0 , "l" => 0 );
my @patterns = ();
my $not_found = 0;
my $num_files = 0;

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
# Function  : process_file
#
# Purpose   : Scan a file for a pattern.
#
# Inputs    : $_[0] - filename
#
# Output    : filename
#
# Returns   : If pattern not found Then 1 Else 0
#
# Example   : process_file($filename)
#
# Notes     : (none)
#
######################################################################

sub process_file
{
	my ( $filename ) = @_;
	my ( $buffer , $found );

	$num_files += 1;
	unless ( open(INPUT,"<$filename") ) {
		die("Can't open file \"$filename\" : $!\n");
	} # UNLESS

	$found = 0;
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		foreach my $pattern ( @patterns ) {
			if ( $buffer =~ m/${pattern}/i ) {
				$found = 1;
				last;
			} # IF
		} # FOREACH
		if ( $found ) {
			last;
		} # IF
	} # WHILE
	close INPUT;
	unless ( $found ) {
		if ( $options{'l'} ) {
			list_file_info_full($filename,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
		} # IF
		else {
			print "$filename\n";
		} # ELSE
		$not_found += 1;
	} # UNLESS

	return ! $found;
} # end of process_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Program entry point
#
# Inputs    : @ARGV - optional flags and filename
#
# Output    : XML tags
#
# Returns   : nothing
#
# Example   : notfound.pl [-d] pattern filename [... filename]
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $filename , $status , $pattern , @entries , $errmsg , @list );
	my ( @files , %entries );

	$status = getopts("dihpl",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 1 < scalar @ARGV ) {
		die("Usage : $0 [-dihfpl] pattern filename [... filename]\n");
	} # UNLESS

	if ( $options{"f"} ) {
		$filename = shift @ARGV;
		unless ( open(PATTERNS,"<$filename") ) {
			die("open failed for file \"$filename\" : $!\n");
		} # UNLESS
		@patterns = <PATTERNS>;
		close PATTERNS;
		chomp @patterns;
	} # IF
	else {
		$pattern = shift @ARGV;
		@patterns = ( $pattern );
	} # ELSE

	if ( $options{'p'} ) {
		$status = get_dir_entries(".",{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
		if ( $status < 0 ) {
			die("$errmsg\n");
		} # IF
		@entries = sort { lc $a cmp lc $b } @entries;

		@list = ();
		foreach my $pattern ( @ARGV ) {
			@files = grep /${pattern}/i,@entries;
			if ( 1 > scalar @files ) {
				warn("No match for '$pattern' under '.'\n");
			} # IF
			else {
				push @list,@files;
			} # ELSE
		} # FOREACH
	} # IF
	else {
		@list = @ARGV;
	} # ELSE

	foreach $filename ( @list ) {
		process_file($filename);
	} # FOREACH
	print "\n${not_found} of ${num_files} files did not contain the pattern(s)\n";
	print join(" , ",map { "'$_'" } @patterns),"\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

notfound.pl - List names of files that don't contain a pattern

=head1 SYNOPSIS

notfound.pl [-dihfpl] pattern filename [... filename]

=head1 DESCRIPTION

List names of files that don't contain a pattern

=head1 OPTIONS 

  -i - case insensitive searching
  -d - activate debug mode
  -h - display this help summary
  -f - the pattern is assumed to be the name of a file containing a list of patterns
  -p - treat the filenames as patterns
  -l - list file info in the style of the ls command

=head1 EXAMPLES

notfound.pl something *.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
