#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : zipgrep.pl
#
# Author    : Barry Kimelman
#
# Created   : October 19, 2019
#
# Purpose   : Search the members of a ZIP file for a regular expression
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Basename;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "i" => 0 , "n" => 0 );
my $member_pattern;
my $pattern;

######################################################################
#
# Function  : process_file
#
# Purpose   : Process a file
#
# Inputs    : $_[0] - filename
#
# Output    : matching lines
#
# Returns   : IF problem THEN negative ELSE number of matching lines
#
# Example   : $count = process_file($filename);
#
# Notes     : (none)
#
######################################################################

sub process_file
{
	my ( $filename ) = @_;
	my ( $status , $zip , @members , @filenames , $num_members );
	my ( $basename , $index , @basenames , $content , @lines , $index2 );
	my ( $num_lines , $matched , $num_matched );

	unless ( $filename =~ m/\.zip$/i ){
		return 0;
	} # UNLESS

	$zip = Archive::Zip->new();
	if ( $zip->read( $filename ) != AZ_OK ) {
		die("Error reading zip file '$filename'\n");
	} # IF
	@members = $zip->members();
	@filenames = ();
	@basenames = ();
	$num_members = scalar @members;
	$status = 0;
	foreach my $element( @members ) {
		$status += 1;
		$filename = $element->{'fileName'};
		$basename = basename($filename);
		push @filenames,$filename;
		push @basenames,$basename;
	} # FOREACH

	for ( $index = 0 ; $index < $num_members ; ++$index ) {
		if ( $basenames[$index] =~ m/${member_pattern}/i ) {
			($content, $status) = $zip->contents( $filenames[$index] );
			unless ( defined $content ) {
				print "Could not get content from $filename [ $filenames[$index] ]\n";
			} # UNLESS
			else {
				@lines = split(/\n/,$content);
				$num_lines = scalar @lines;
				$num_matched = 0;
				for ( $index2 = 1 ; $index2 <= $num_lines ; ++$index2 ) {
					$matched = 0;
					if ( $options{'i'} && $lines[$index2-1] =~ m/${pattern}/i ) {
						$matched = 1;
					} # IF
					if ( $options{'i'} == 0 && $lines[$index2-1] =~ m/${pattern}/i ) {
						$matched = 1;
					} # IF
					if ( $matched ) {
						if ( ++$num_matched == 1 ) {
							print "\n";
						} # IF
						print "$filename [ $filenames[$index] ]:";
						if ( $options{'n'} ) {
							print "${index2}:";
						} # IF
						print "\t$lines[$index2-1]\n";
					} # IF
				} # FOR
			} # ELSE
		} # IF
	} # FOR

	return;
} # end of process_file

######################################################################
#
# Function  : search_dirtree
#
# Purpose   : Look for ZIP files under a directory tree
#
# Inputs    : $_[0] - directory name
#             $_[2] - nesting level
#
# Output    : (none)
#
# Returns   : number of matches
#
# Example   : $count = search_dirtree($dirname,1);
#
# Notes     : (none)
#
######################################################################

sub search_dirtree
{
	my ( $dirname , $dir_level ) = @_;
	my ( %entries , $path , @subdirs );

	if ( $options{"L"} > 0 && $dir_level > $options{"L"} ) {
		return 0;
	} # IF
	unless ( opendir(DIR,$dirname) ) {
		warn("opendir failed for '$dirname' : $!\n");
		return 0;
	} # UNLESS

	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@subdirs = ();
	foreach my $entry ( keys %entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		if ( -d $path ) {
			push @subdirs,$path;
		} # IF
		else {
			if ( $entry =~ m/\.zip$/i ) {
				process_file($path);
			} # IF
		} # ELSE
	} # FOREACH
	foreach my $subdir ( @subdirs ) {
		search_dirtree($subdir,1+$dir_level);
	} # FOREACH

	return;
} # end of search_dirtree

######################################################################
#
# Function  : MAIN
#
# Purpose   : Search the members of a ZIP file for a regular expression
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : zipgrep.pl -d file_or_dir pattern
#
# Notes     : Contents of ZIP file member object looks like the following
#  $VAR1 = bless( {
#                   'externalFileName' => 'foo.zip',
#                   'uncompressedSize' => 1820,
#                   'fileName' => 'charset.conv',
#                   'versionNeededToExtract' => 20,
#                   'fileAttributeFormat' => 0,
#                   'diskNumberStart' => 0,
#                   'compressionMethod' => 8,
#                   'eocdCrc32' => 4075145292,
#                   'fileComment' => '',
#                   'externalFileAttributes' => 32,
#                   'internalFileAttributes' => 0,
#                   'bitFlag' => 2,
#                   'lastModFileDateTime' => 1149111825,
#                   'crc32' => 4075145292,
#                   'versionMadeBy' => 20,
#                   'dataEnded' => 1,
#                   'localExtraField' => '',
#                   'localHeaderRelativeOffset' => 0,
#                   'readDataRemaining' => 0,
#                   'possibleEocdOffset' => 0,
#                   'desiredCompressionMethod' => 8,
#                   'compressedSize' => 549,
#                   'desiredCompressionLevel' => -1,
#                   'dataOffset' => 0,
#                   'fh' => undef,
#                   'isSymbolicLink' => 0,
#                   'cdExtraField' => 'stuff goes in here'
#                 }, 'Archive::Zip::ZipFileMember' );
#
######################################################################

MAIN:
{
	my ( $status , $path );

	$status = getopts("hdinr",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 1 < scalar @ARGV ) {
		die("Usage : $0 [-hdinr] file_or_dir expression [member_pattern]\n");
	} # UNLESS
	$path = $ARGV[0];
	$pattern = $ARGV[1];
	$member_pattern = (2 == scalar @ARGV) ? "." : $ARGV[2];

	if ( -d "$path" ) {
		$status = search_dirtree($path,1);
	} # IF
	else {
		process_file($path);
	} # ELSE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

zipgrep.pl - Search the members of a ZIP file for a regular expression

=head1 SYNOPSIS

zipgrep.pl [-hdinr] file_or_dir expression member_pattern

=head1 DESCRIPTION

Search the members of a ZIP file for a regular expression

=head1 PARAMETERS

  file_or_dir - name of a file or directory
  expression - regular expression for searching ZIP file members
  member_pattern - only search members whose name matches this pattern

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -i - use case insensitive searching
  -n - display line numbers for matches lines
  -r - when processing a directory recursively process the entire tree

=head1 EXAMPLES

zipgrep.pl mystuff.zip "[a-z][0-9]"

zipgrep.pl \users\myname\mydata "[a-z][0-9]"

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
