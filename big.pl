#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : big.pl
#
# Author    : Barry Kimelman
#
# Created   : July 10, 2019
#
# Purpose   : List info for the biggest files under a directory tree
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Copy;
use File::stat;
use Fcntl;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_file_info.pl";
require "elapsed_time.pl";

my %options = ( "d" => 0 , "h" => 0 , "n" => 9 );
my @filenames = ();
my @sizes = ();
my $start_time;
my $end_time;

######################################################################
#
# Function  : scan_dir
#
# Purpose   : Scan a directory
#
# Inputs    : $_[0] - name of directory to be scanned
#
# Output    : appropriate diagnostics
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
	my ( %entries , @entries , $path , $status , @subdirs , @names );

	unless ( opendir(DIR,"$dirname") ) {
		die("opendir failed for \"$dirname\" : $!\n");
	} # UNLESS

	%entries = map { $_ , 1 } readdir DIR;
	closedir DIR;
	delete $entries{"."};
	delete $entries{".."};

	@subdirs = ();
	foreach my $entry ( keys %entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		if ( -d $path ) {
			push @subdirs,$path;
		} # IF
		else {
			$status = stat($path);
			unless ( $status ) {
				die("stat failed for '$path'\n");
			} # UNLESS
			push @filenames,$path;
			push @sizes,$status->size;
		} # ELSE
	} # FOREACH
	foreach my $subdir ( @subdirs ) {
		scan_dir($subdir);
	} # FOREACH

	return;
} # end of scan_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : List info for the biggest files under a directory tree
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : big.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $dirname , $status , $count , @indices , @list );

	$status = getopts("hdn:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [-n number_of_files]\n");
	} # UNLESS

	$start_time = time;
	scan_dir(".");
	$count = scalar @filenames;
	print "\nFound ${count} files under '.'\n\n";
	@indices = sort { $sizes[$a] <=> $sizes[$b] } (0 .. $#sizes);
	@filenames = @filenames[@indices];
	@sizes = @sizes[@indices];
	if ( $count > $options{'n'} ) {
		@list = @filenames[$count-$options{'n'} .. $#filenames];
	} # IF
	else {
		@list = @filenames;
	} # ELSE
	foreach my $path ( @list ) {
		list_file_info_full($path,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
	} # FOREACH
	$end_time = time;
	elapsed_time($start_time,$end_time,"\nElapsed Time : %d minutes %d seconds\n\n");

	exit 0;
} # end of MAIN
__END__
=head1 NAME

big.pl - List info for the biggest files under a directory tree

=head1 SYNOPSIS

big.pl [-hd]

=head1 DESCRIPTION

List info for the biggest files under a directory tree

=head1 PARAMETERS

  (none)

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -n number_of_files - number of files to be listed

=head1 EXAMPLES

big.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
