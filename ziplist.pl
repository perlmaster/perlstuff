#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : ziplist.pl
#
# Author    : Barry Kimelman
#
# Created   : January 29, 2019
#
# Purpose   : List the members of a ZIP file
#
# Notes     : Contents of ZIp file member object looks like the following
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
use FindBin;
use lib $FindBin::Bin;

require "print_lists.pl";

my %options = ( "d" => 0 , "h" => 0 );

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
	my ( $status , $zip , $zipfile , $ref , @members , $td );
	my ( @filenames , @dates , @sizes );

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
	unless ( $status && 1 == scalar @ARGV ) {
		die("Usage : $0 [-dh] zipfile\n");
	} # UNLESS
	$zipfile = $ARGV[0];

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
	foreach my $element( @members ) {
		push @filenames,$element->{'fileName'};
		push @sizes,$element->{'uncompressedSize'};
		$td = localtime($element->lastModTime());
		push @dates,$td;
	}

	print_lists([ \@filenames , \@sizes , \@dates],[ "File","Size","Date" ],"=",\*STDOUT);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

ziplist.pl - List the members of a ZIP file

=head1 SYNOPSIS

ziplist.pl [-hd] zipfile

=head1 DESCRIPTION

List the members of a ZIP file

=head1 PARAMETERS

  zipfile - name of ZIP archive file

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

ziplist.pl zip1.zip

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
