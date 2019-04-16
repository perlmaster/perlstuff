#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : ziplist.pl
#
# Author    : Barry Kimelman
#
# Created   : January 29, 2019
#
# Purpose   : List the members of a ZIP file or all ZIP files under a directory tree
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

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Basename;
use FindBin;
use lib $FindBin::Bin;

require "print_lists.pl";
require "comma_format.pl";
require "format_megabytes.pl";

my %options = ( "d" => 0 , "h" => 0 , "L" => -1 , "b" => -1 , "B" => -1 , "m" => 0 );

######################################################################
#
# Function  : search_dirtree
#
# Purpose   : Look for ZIP files under a directory tree
#
# Inputs    : $_[0] - directory name
#             $_[1] - member name pattern
#             $_[2] - nesting level
#
# Output    : (none)
#
# Returns   : number of matches
#
# Example   : $count = search_dirtree($dirname,$pattern,1);
#
# Notes     : (none)
#
######################################################################

sub search_dirtree
{
	my ( $dirname , $pattern , $dir_level ) = @_;
	my ( %entries , @entries , $path , @subdirs );

	if ( $options{"L"} > 0 && $dir_level > $options{"L"} ) {
		return 0;
	} # IF
	unless ( opendir(DIR,$dirname) ) {
		warn("opendir failed for \"$dirname\" : $!\n");
		return 0;
	} # UNLESS

	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@entries = keys %entries;
	@subdirs = ();
	foreach my $entry ( @entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		if ( -d $path ) {
			push @subdirs,$path;
		} # IF
		else {
			if ( $entry =~ m/\.zip$/i ) {
				process_zip_file($path,$pattern);
			} # IF
		} # ELSE
	} # FOREACH
	foreach my $subdir ( @subdirs ) {
		search_dirtree($subdir,$pattern,1+$dir_level);
	} # FOREACH

	return;
} # end of search_dirtree

######################################################################
#
# Function  : process_zip_file
#
# Purpose   : Process a ZIP file
#
# Inputs    : $_[0] - name of ZIP file
#             $_[1] - member name pattern
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : process_zip_file($zipfile,$pattern);
#
# Notes     : (none)
#
######################################################################

sub process_zip_file
{
	my ( $zipfile , $pattern ) = @_;
	my ( @members , @filenames , @dates , @sizes , $num_members , $num_matched );
	my ( $status , $filename , $basename , $td , $zip , @index , $bytes );

#                   'externalFileName' => 'foo.zip',
#                   'fileName' => 'charset.conv',
#                   'lastModFileDateTime' => 1149111825,
	$zip = Archive::Zip->new();
	if ( $zip->read( $zipfile ) != AZ_OK ) {
		die("Error reading zip file '$zipfile'\n");
	} # IF
	@members = $zip->members();
	@filenames = ();
	@dates = ();
	@sizes = ();
	$num_members = scalar @members;
	$num_matched = 0;
	$status = 0;
	@index = ();
	foreach my $element( @members ) {
		$status += 1;
		$filename = $element->{'fileName'};
		$basename = basename($filename);
		if ( $basename =~ m/${pattern}/i ) {
			$bytes = $element->{'uncompressedSize'};
			if ( $options{'b'} > 0 && $options{'b'} > $bytes ) {
				next;
			} # IF
			if ( $options{'B'} > 0 && $options{'B'} < $bytes ) {
				next;
			} # IF
			$num_matched += 1;
			push @index,$num_matched;
			push @filenames,$filename;
			if ( $options{'m'} ) {
				push @sizes,format_megabytes($bytes,0);
			} # IF
			else {
				push @sizes,comma_format($bytes);
			} # ELSe
			$td = localtime($element->lastModTime());
			push @dates,$td;
		} # IF
	} # FOREACH

	@index = map { "[$_ / $num_matched]" } (1 .. $num_matched);
	print "\n$zipfile : $num_matched of the $num_members members were matched by '$pattern'\n\n";
	print_lists([ \@index , \@filenames , \@sizes , \@dates],[ "#" , "Member","Size","Date" ],"=",\*STDOUT);

	return;
} # end of process_zip_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : List the members of a ZIP file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : ziplist.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $zip , $zipfile , $pattern );

	$status = getopts("hdb:B:m",\%options);
	if ( $options{"h"} ) {
		if ( $^O =~ m/MSWin/ ) {
# Windows stuff goes here
			system("pod2text $0 | more");
		} # IF
		else {
# Non-Windows stuff (i.e. UNIX) goes here
			system("pod2man $0 | nroff -man | less -M");
		} # ELSE
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dhm] [-b min_bytes] [-B max_bytes] zipfile [pattern [... pattern]]\n");
	} # UNLESS
	$zipfile = shift @ARGV;
	$pattern = (0 == scalar @ARGV) ? "." : join("|",@ARGV);

	if ( -d $zipfile ) {
		search_dirtree($zipfile,$pattern,1);
	} # IF
	else {
		process_zip_file($zipfile,$pattern);
	} # ELSE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

ziplist.pl - List the members of a ZIP file or all ZIP files under a directory tree

=head1 SYNOPSIS

ziplist.pl [-hdm] [-b min_bytes] [-B max_bytes] zipfile [pattern [... pattern]]

=head1 DESCRIPTION

List the members of a ZIP file or all ZIP files under a directory tree

=head1 PARAMETERS

  zipfile - name of ZIP archive file or directory
  parameter - optional pattern to match against member names

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -m - display size in terms of GB/MB/KB
  -b min_bytes - only show members with a minimum number of bytes
  -B max_bytes - only show members with a maximum number of bytes

=head1 EXAMPLES

ziplist.pl zip1.zip

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
