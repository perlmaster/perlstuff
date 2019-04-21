#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : zipbackup.pl
#
# Author    : Barry Kimelman
#
# Created   : February 17, 2019
#
# Purpose   : Test the Archive::Zip module
#
# Notes     :
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_zip_file_members.pl";

my %options = ( "d" => 0 , "h" => 0 , "l" => 0, "m" => 0 , "a" => 0 );
my $zip;
my $zipfile;

######################################################################
#
# Function  : backup_dirtree
#
# Purpose   : Backup a directory tree to the ZIP file
#
# Inputs    : $_[0] - directory name
#
# Output    : (none)
#
# Returns   : (nothing)
#
# Example   : backup_dirtree($dirname);
#
# Notes     : (none)
#
######################################################################

sub backup_dirtree
{
	my ( $dirname ) = @_;
	my ( %entries , @entries , $path , $dir_member , $count );
	my ( @subdirs , $file_member , $zip_dir , $zip_path );

	print "\nBackup directory $dirname\n";
	unless ( opendir(DIR,$dirname) ) {
		die("opendir failed for \"$dirname\" : $!\n");
	} # UNLESS
	$zip_dir = $dirname;
	$zip_dir =~ s/\\/\//g;
	$dir_member = $zip->addDirectory( $zip_dir );
	unless ( defined $dir_member ) {
		die("addDirectory failed for '$zip_dir' : $!\n");
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
			unless ( -f $path && -r $path ) {
				print "***   skipping over $path\n";
			} # UNLESS
			$zip_path = $path;
			$zip_path =~ s/\\/\//g;
			if ( $options{'a'} ) {
				print "Add file '$entry' under '$zip_dir' as '$zip_path'\n";
			} # IF
			$file_member = $zip->addFile( $path , $zip_path );
			unless ( defined $file_member ) {
				die("addFile failed for '$path' : $!\n");
			} # UNLESS
			$file_member->desiredCompressionLevel(5);
		} # ELSE
	} # FOREACH
	foreach my $subdir ( @subdirs ) {
		backup_dirtree($subdir);
	} # FOREACH

	return;
} # end of backup_dirtree

######################################################################
#
# Function  : MAIN
#
# Purpose   : Test the Archive::Zip module
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : zipbackup.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $top_dir );

	$status = getopts("hdlma",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 2 == scalar @ARGV ) {
		die("Usage : $0 [-dhlma] zipfile dirname\n");
	} # UNLESS
	( $zipfile , $top_dir ) = @ARGV;
	##  $top_dir .= '/';
	if ( -e "$zipfile" ) {
		die("'$zipfile' already exists.\n");
	} # IF

	$zip = Archive::Zip->new();
	unless ( defined $zip ) {
		die("Can't create ZIP object : $!\n");
	} # UNLESS
	backup_dirtree($top_dir);

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

zipbackup.pl - Test the Archive::Zip module

=head1 SYNOPSIS

zipbackup.pl [-hdlm] zipfile [pattern [... pattern]]

=head1 DESCRIPTION

Test the Archive::Zip module

=head1 PARAMETERS

  zipfile - name of ZIP archive file

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -l - after ZIP file is created list the ZIP file members
  -m - when listing ZIP file members list size in terms of GB/MB/KB

=head1 EXAMPLES

zipbackup.pl zip1.zip

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
