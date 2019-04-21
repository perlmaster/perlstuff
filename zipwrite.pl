#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : zipwrite.pl
#
# Author    : Barry Kimelman
#
# Created   : February 17, 2019
#
# Purpose   : Use the Archive::Zip module to create a ZIP file
#
# Notes     :
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
require "list_zip_file_members.pl";

my %options = ( "d" => 0 , "h" => 0 , "t" => "mytopdir" , "l" => 0 , "p" => 0 , "m" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Use the Archive::Zip module to create a ZIP file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : zipwrite.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $zip , $zipfile , $ref , $file_member , $dir_member );
	my ( $top_dir , $file_path , @list , @matched , %entries , @entries );

	$status = getopts("hdt:lpm",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 1 < scalar @ARGV ) {
		die("Usage : $0 [-dhlpm] [-t topdir] zipfile filename [... filename]\n");
	} # UNLESS

	$zipfile = shift @ARGV;
	if ( -e "$zipfile" ) {
		die("'$zipfile' already exists.\n");
	} # IF
	if ( $options{'p'} ) {
		@list = ();
		unless ( opendir(DIR,".") ) {
			die("opendir failed : $!\n");
		} # UNLESS
		%entries = map { $_ , 0 } readdir DIR;
		closedir DIR;
		delete $entries{".."};
		delete $entries{"."};
		@entries = keys %entries;
		foreach my $pattern ( @ARGV ) {
			@matched = grep /${pattern}/i,@entries;
			if ( 0 == scalar @matched ) {
				print "No matches for '$pattern'\n";
			} # IF
			else {
				push @list,@matched;
			} # ELSE
		} # FOREACH
		if ( 0 == scalar @list ) {
			die("Nothing matched your patterns\n");
		} # IF
	} # IF
	else {
		@list = @ARGV;
	} # ELSE
	$zip = Archive::Zip->new();
	unless ( defined $zip ) {
		die("Can't create ZIP object : $!\n");
	} # UNLESS
	$top_dir = $options{'t'};
	$dir_member = $zip->addDirectory( $top_dir );

	foreach my $filename ( @list ) {
		$file_path = $top_dir . '/' . $filename;
		$file_member = $zip->addFile( $filename , $file_path );
		unless ( defined $file_member ) {
			die("addFile failed for '$filename' : $!\n");
		} # UNLESS
	} # FOREACH

	# Save the Zip file
	unless ( $zip->writeToFileNamed($zipfile) == AZ_OK ) {
		die("write error during save of zip file : $!\n");
	} # UNLESS
	if ( $options{'l'} ) {
		list_zip_file_members($zipfile,".",{ "m" => $options{'m'} },\*STDOUT);
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

zipwrite.pl - Use the Archive::Zip module to create a ZIP file

=head1 SYNOPSIS

zipwrite.pl [-hdlm] [-t topdir] zipfilefilename [... filename]

=head1 DESCRIPTION

Use the Archive::Zip module to create a ZIP file

=head1 PARAMETERS

  zipfile - name of ZIP archive file
  filename - file to be added to ZIP file

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -t topdir - use this name as the top directory in the generated ZIP file
  -l - after ZIP file is created list all its members
  -p - treat filenames as patterns to be matched against files in current directory
  -m - when listing ZIP file members list size in terms of GB/MB/KB

=head1 EXAMPLES

zipwrite.pl zip1.zip junk.txt foo.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
