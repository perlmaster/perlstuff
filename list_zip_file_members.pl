#!/usr/bin/perl -w

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
require "list_columns_style.pl";

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
# Example   : list_zip_file_members($zipfile,$pattern,{ "m" => 0 , "c" => 0 },\*STDOUT);
#     -c - list ZIP file members in a compact list with only names displayed
#     -C - list ZIP file members in a compact list with only names and size displayed
#     -m - display size in terms of GB/MB/KB
#
# Notes     : (none)
#
######################################################################

sub list_zip_file_members
{
	my ( $zipfile , $pattern , $ref_options , $handle ) = @_;
	my ( $bin_time , $total_bytes , @bindates , $comma );
	my ( @members , @filenames , @dates , @sizes , @perms , $num_members , $num_matched );
	my ( $num_listed , $filename , $basename , $td , $zip , @index , $bytes , $title );
	my ( $attr );

#                   'externalFileName' => 'foo.zip',
#                   'fileName' => 'charset.conv',
#                   'lastModFileDateTime' => 1149111825,
	print "\nlist_zip_file_members($zipfile)\n";

	$zip = Archive::Zip->new();
	if ( $zip->read( $zipfile ) != AZ_OK ) {
		warn("Error reading zip file '$zipfile'\n");
		return -1;
	} # IF
	@members = $zip->members();
	@filenames = ();
	@dates = ();
	@bindates = ();
	@sizes = ();
	@perms = ();

	$num_members = scalar @members;
	$num_matched = 0;
	$num_listed = 0;
	$total_bytes = 0;
	@index = ();
	foreach my $element( @members ) {
		$filename = $element->{'fileName'};
		$attr = $element->unixFileAttributes(); # get UNIX file attributes
		$basename = basename($filename);
		if ( $basename =~ m/${pattern}/i ) {
			$num_listed += 1;
			$bytes = $element->{'uncompressedSize'};
			$total_bytes += $bytes;
			$num_matched += 1;
			push @index,$num_matched;
			push @filenames,$filename;
			if ( $ref_options->{'m'} ) {
				push @sizes,format_megabytes($bytes,0);
			} # IF
			else {
				push @sizes,comma_format($bytes);
			} # ELSe
			$bin_time = $element->lastModTime();
			$td = localtime($bin_time);
			push @dates,$td;
			push @bindates,$bin_time;
			push @perms,sprintf "0%o",$attr; # save UNIX file attributes as octal
		} # IF
	} # FOREACH
	$bytes = format_megabytes($total_bytes,1);

	@index = map { "$_/$num_matched" } (1 .. $num_matched);
	$title = "$zipfile : $num_matched of the $num_members members were matched by '$pattern'\n";
	if ( $ref_options->{'c'} ) {
		print_lists( [ \@index , \@filenames ] , [ '#' , 'Member' ] , '=' , $handle);
	} elsif ( $ref_options->{"C"} ) {
		print_lists( [ \@index , \@filenames , \@sizes ] , [ '#' , 'Member' , 'Size' ] , '=' , $handle);
	} else {
		print $handle "\n$title\n";
		print_lists([ \@index , \@filenames , \@sizes , \@dates , \@bindates , \@perms ],
					[ "#" , "Member","Size","Date" , "Binary Date" , "Permissions" ],"=",$handle);
	} # ELSE
	$comma = comma_format($total_bytes);
	print "\n${comma} bytes [ $bytes ] in ${num_matched} listed members\n";

	return;
} # end of list_zip_file_members

1;
