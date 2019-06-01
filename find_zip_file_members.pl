#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : find_zip_file_members.pl
#
# Author    : Barry Kimelman
#
# Created   : May 26, 2019
#
# Purpose   : Function to get the list of members of a ZIP file
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

######################################################################
#
# Function  : find_zip_file_members
#
# Purpose   : Process a ZIP file
#
# Inputs    : $_[0] - name of ZIP file
#             $_[1] - reference to hash to receive list of ZIP file members
#             $_[2] - reference to array to receive list of member names
#             $_[3] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF problem THEN undef ELSE zip file class object
#
# Example   : $zip = find_zip_file_members($zipfile,\%members,\@names,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub find_zip_file_members
{
	my ( $zipfile , $ref_members , $ref_names , $ref_errmsg ) = @_;
	my ( @members , $num_members , $num_matched , $bin_time );
	my ( $status , $filename , $td , $zip , $bytes );

#                   'externalFileName' => 'foo.zip',
#                   'fileName' => 'charset.conv',
#                   'lastModFileDateTime' => 1149111825,
	$$ref_errmsg = "";
	%$ref_members = ();
	@$ref_names = ();
	$zip = Archive::Zip->new();
	if ( $zip->read( $zipfile ) != AZ_OK ) {
		$$ref_errmsg = "Error reading zip file '$zipfile'";
		return undef;
	} # IF
	@members = $zip->members();
	$num_members = scalar @members;
	foreach my $element( @members ) {
		$status += 1;
		$filename = $element->{'fileName'};
		push @$ref_names,$filename;
		$bytes = $element->{'uncompressedSize'};
		$num_matched += 1;
		$bin_time = $element->lastModTime();
		$td = localtime($bin_time);
		$ref_members->{$filename}{'size'} = $bytes;
		$ref_members->{$filename}{'date'} = $td;
		$ref_members->{$filename}{'clock'} = $bin_time;
	} # FOREACH

	return $zip;
} # end of find_zip_file_members

1;
