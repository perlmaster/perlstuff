#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : find-empty.pl
#
# Author    : Barry Kimelman
#
# Created   : January 14, 2013
#
# Purpose   : Find empty files in a directory.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "list_file_info.pl";

my %options = ( "h" => 0 , "l" => 0 , "r" => 0 );

######################################################################
#
# Function  : scan_dir
#
# Purpose   : scan a directory
#
# Inputs    : $_[0] - directory name
#
# Output    : list of empty files
#
# Returns   : nothing
#
# Example   : scan_dir($dirname);
#
# Notes     : (none)
#
######################################################################

sub scan_dir
{
	my ( $dirname ) = @_;
	my ( %entries , $path , $filesize , $dir_prefix , @subdirs );

	unless ( opendir(DIR,"$dirname") ) {
		die("opendir failed for \"$dirname\" : $!\n");
	} # UNLESS
	%entries = map { $_ , 1 } readdir DIR;
	closedir DIR;
	delete $entries{"."};
	delete $entries{".."};
	$dir_prefix = ($dirname eq ".") ? "" : "${dirname}/";

	@subdirs = ();
	foreach my $entry ( keys %entries ) {
		$path = $dir_prefix . $entry;
		if ( -f $path ) {
			$filesize = -s $path;
			if ( $filesize == 0 ) {
				if ( $options{"l"} ) {
					list_file_info_full($path,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
				} # IF
				else {
					print "$path\n";
				} # ELSE
			} # IF
		} # IF
		else {
			if ( -d $path ) {
				push @subdirs,$path;
			} # IF
		} # ELSE
	} # FOREACH
	if ( $options{'r'} ) {
		foreach my $subdir ( @subdirs ) {
			scan_dir($subdir);
		} # FOREACH
	} # IF

	return;
} # end of scan_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : Find empty files in a directory.
#
# Inputs    : command line parameters
#
# Output    : status messages
#
# Returns   : nothing
#
# Example   : find-empty.pl .
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $dirname );

	$status = getopts("hlr",\%options);
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
	unless ( $status ) {
		die("Usage : $0 [-hlr] [dirname]\n");
	} # UNLESS

	$dirname = (0 < @ARGV) ? $ARGV[0] : '.';
	scan_dir($dirname);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

find-empty.pl - Find empty files in a directory

=head1 SYNOPSIS

find-empty.pl [-hlr] dirname

=head1 DESCRIPTION

Find empty files in a directory.

=head1 PARAMETERS

  dirname - optional name of directory to be checked

=head1 OPTIONS

  -h - produce this summary
  -l - use "ls" to display file information
  -r - recursively scan sub-directories

=head1 EXAMPLES

find-empty.pl -l

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
