#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : list_zip_file_members.pl
#
# Author    : Barry Kimelman
#
# Created   : April 21, 2019
#
# Purpose   : Function to list the members of a ZIP file
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
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use FindBin;
use lib $FindBin::Bin;

require "print_lists.pl";
require "comma_format.pl";
require "format_megabytes.pl";

######################################################################
#
# Function  : list_zip_file_members
#
# Purpose   : Process a ZIP file
#
# Inputs    : $_[0] - name of ZIP file
#             $_[1] - member name pattern
#             $_[2] - reference to hash of options
#             $_[3] - output file handle
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : list_zip_file_members($zipfile,$pattern,{ "m" => 0 },\*STDOUT);
#
# Notes     : (none)
#
######################################################################

sub list_zip_file_members
{
	my ( $zipfile , $pattern , $ref_options , $handle ) = @_;
	my ( @members , @filenames , @dates , @sizes , $num_members , $num_matched );
	my ( $status , $filename , $basename , $td , $zip , @index , $bytes );

#                   'externalFileName' => 'foo.zip',
#                   'fileName' => 'charset.conv',
#                   'lastModFileDateTime' => 1149111825,
	$zip = Archive::Zip->new();
	if ( $zip->read( $zipfile ) != AZ_OK ) {
		warn("Error reading zip file '$zipfile'\n");
		return -1;
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
			$num_matched += 1;
			push @index,$num_matched;
			push @filenames,$filename;
			if ( $ref_options->{'m'} ) {
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
	print $handle "\n$zipfile : $num_matched of the $num_members members were matched by '$pattern'\n\n";
	print_lists([ \@index , \@filenames , \@sizes , \@dates],[ "#" , "Member","Size","Date" ],"=",$handle);

	return;
} # end of list_zip_file_members

1;
