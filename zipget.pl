#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : zipget.pl
#
# Author    : Barry Kimelman
#
# Created   : March 15, 2019
#
# Purpose   : Extract files from a ZIP file
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
require "list_file_info.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Extract files from a ZIP file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : zipget.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $zip , $zipfile , $ref , @members , $td );
	my ( @filenames , @dates , @sizes , $basename );
	my ( $count , $num_members , $filename );

	$status = getopts("hd",\%options);
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
	unless ( $status && 1 < scalar @ARGV ) {
		die("Usage : $0 [-dh] zipfile member [... member]\n");
	} # UNLESS
	$zipfile = shift @ARGV;

	$zip = Archive::Zip->new();
	if ( $zip->read( $zipfile ) != AZ_OK ) {
		die("Error reading zip file '$zipfile'\n");
	} # IF
	@members = $zip->members();
	@filenames = ();
	@dates = ();
	@sizes = ();
	$num_members = scalar @members;
	$status = 0;
	foreach my $element( @members ) {
		$status += 1;
		$filename = $element->{'fileName'};
		$basename = basename($filename);
		push @filenames,$filename;
		push @sizes,$element->{'uncompressedSize'};
		$td = localtime($element->lastModTime());
		push @dates,$td;
	} # FOREACH

	print_lists([ \@filenames , \@sizes , \@dates],[ "File","Size","Date" ],"=",\*STDOUT);
	print "\n$num_members members were found\n";

	foreach my $member ( @ARGV ) {
    	unless ( $zip->extractMember( $member , $member ) == AZ_OK ) {
			warn("Extract failed for '$member'\n");
		} # UNLESS
		else {
			list_file_info_full($member,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
		} # ELSE
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

zipget.pl - Extract files from a ZIP file

=head1 SYNOPSIS

zipget.pl [-hd] zipfile [pattern [... pattern]]

=head1 DESCRIPTION

Extract files from a ZIP file

=head1 PARAMETERS

  zipfile - name of ZIP archive file
  parameter - optional pattern to match against member names

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

zipget.pl zip1.zip

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
