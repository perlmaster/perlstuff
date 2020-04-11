#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : textfiles.pl
#
# Author    : Barry Kimelman
#
# Created   : April 8, 2020
#
# Purpose   : Traverse a directory tree looking for text files
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use File::Basename;
use File::Find;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_file_info.pl";
require "elapsed_time.pl";
require "comma_format.pl";

my %options = ( "d" => 0 , "h" => 0 , "l" => 0 , "p" => "." , "w" => 0 );
my $num_files = 0;
my $start_time;
my $end_time;
my $num_matching_dirs = 0;
my %matching_dirs = ();

######################################################################
#
# Function  : count_lines
#
# Purpose   : Count lines and characters in a file
#
# Inputs    : $_[0] - filename
#
# Output    : Count of lines and characters in named file
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

	$num_lines = 0;
	$num_chars = 0;
	unless ( open(INPUT,"<$filename") ) {
		warn("open failed for '$filename' : $!\n");
		return;
	} # UNLESS
	while ( $buffer = <INPUT> ) {
		$num_lines += 1;
		$num_chars += length $buffer;
	} # WHILE
	close INPUT;
	$buffer = comma_format($num_chars);
	print "$filename : ${num_lines} lines , ${buffer} bytes\n";

	return;
} # end of count_lines

######################################################################
#
# Function  : wanted
#
# Purpose   : Function called by File::Find.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   :
#
# Notes     : (none)
#
######################################################################

sub wanted
{
	my ( $buffer , $basename );

	if ( -f $File::Find::name && -T $File::Find::name ) {
		$basename = basename($File::Find::name);
		if ( $basename =~ m/${options{'p'}}/i ) {
			$num_files += 1;
			$matching_dirs{$File::Find::dir} += 1;
			if ( $options{'l'} ) {
				list_file_info_full($File::Find::name,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
			} # IF
			if ( $options{'w'} ) {
				count_lines($File::Find::name);
			} # IF
			if ( $options{'l'} + $options{'w'} == 0 ) {
				print "$File::Find::name\n";
			} # IF
		} # IF
	} # IF

	return;
} # end of wanted

######################################################################
#
# Function  : MAIN
#
# Purpose   : Traverse a directory tree looking for text files
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : textfiles.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , @incs2 , @list );

	$status = getopts("hdlp:w",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dhlw] [-p pattern]\n");
	} # UNLESS

	$start_time = time;
	@incs2 = grep !/^\.$/,@INC;
	find( { "wanted" => \&wanted , "no_chdir" => 1 } , "." );

	$end_time = time;
	print "\nFound $num_files files matching '$options{'p'}'\n";
	if ( $num_files > 0 ) {
		@list = sort { lc $a cmp lc $b } keys %matching_dirs;
		$status = scalar @list;
		print "Files found in $status directories\n";
		foreach my $dir ( @list ) {
			print "$dir --> $matching_dirs{$dir}\n";
		} # FOREACH
	} # IF
	elapsed_time("\nElapsed Time : %d minutes %d seconds\n\n",$start_time,$end_time);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

textfiles.pl - Traverse a directory tree looking for text files

=head1 SYNOPSIS

textfiles.pl [-hdlw] [-p pattern]

=head1 DESCRIPTION

Traverse a directory tree looking for text files

=head1 PARAMETERS

  filename - name of optional filename

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -l - list file information inb long format
  -p pattern - only list files whose name matches this pattern
  -w - count lines and characters in file

=head1 EXAMPLES

textfiles.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
