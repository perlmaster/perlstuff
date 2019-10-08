#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : dir-missing.pl
#
# Author    : Barry Kimelman
#
# Created   : September 8, 2006
#
# Purpose   : List all the file in one directory that are missing in
#             a second directory.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use File::stat;
use Fcntl;
use FindBin;
use lib $FindBin::Bin;
use File::Spec;

require "get_dir_entries.pl";
require "list_file_info.pl";
require "display_pod_help.pl";
require "list_columns_style.pl";

my %options = (
	"d" => 0 , "l" => 0 , "h" => 0 , "r" => 0 , "g" => 1 , "o" => 1 , "k" => 0 , "c" => 0
);
my $num_missing = 0;

######################################################################
#
# Function  : MAIN
#
# Purpose   : List all the file in on directory that are missing in
#             a second directory.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : dir-missing.pl -d dir1 dir2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $dirname1 , $dirname , $status , %files1 , %files2 , $count1 , @missing );
	my ( $path , $dirs , @entries , $errmsg );

	$status = getopts("dlhre:c",\%options);

	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status  && 1 < scalar @ARGV ) {
		die("Usage : $0 [-dlhrc] [-e exclude_pattern_list] dirname1 dirname2 [... dirname_n]\n");
	} # UNLESS
	if ( $options{'l'} && $options{'c'} ) {
		die("Options 'l' and 'c' are mutually exclusive\n");
	} # IF
	$dirname1 = shift @ARGV;
	%files1 = ();
	$count1 = get_dir_entries($dirname1,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
	if ( $count1 < 0 ) {
		die("$errmsg\n");
	} # IF
	@entries = map { lc $_ } @entries;
	%files1 = map { $_ , 0 } @entries;
	print "\nFound ${count1} files under $dirname1\n";
	if ( exists $options{'e'} ) {
		foreach my $pattern ( split(',',$options{'e'}) ) {
			foreach my $key ( keys %files1 ) {
				if ( $key =~ m/${pattern}/i ) {
					delete $files1{$key};
				} # IF
			} # FOREACH over files
		} # FOREACH over patterns
		$count1 = scalar %files1;
		print "\nFinal : ${count1} files under $dirname1\n";
	} # IF

	%files2 = ();
	$dirs = join(' , ',@ARGV);
	foreach my $dirname ( @ARGV ) {
		$status = get_dir_entries($dirname,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
		if ( $status < 0 ) {
			die("$errmsg\n");
		} # IF
		@entries = map { lc $_ } @entries;
		foreach my $entry ( @entries ) {
			$files2{$entry} = 0;
		} # FOREACH
	} # FOREACH

	@missing = ();
	foreach my $filename ( keys %files1 ) {
		unless ( exists $files2{$filename} ) {
			$num_missing += 1;
			push @missing,$filename;
		} # UNLESS
	} # FOREACH
	if ( $num_missing > 0 ) {
		print "\n$num_missing file(s) under \"$dirname1\" are missing from under $dirs\n\n";
		@missing = sort { lc $a cmp lc $b } @missing;
		if ( $options{'l'} ) {
			foreach my $entry ( @missing ) {
				$path = File::Spec->catfile($dirname1,$entry);
				list_file_info_full($path,\%options);
			} # FOREACH
		} elsif ( $options{'c'} ) {
			list_columns_style(\@missing,100,undef,\*STDOUT);
		} else {
			print join("\n",@missing),"\n";
		} # ELSE
		print "\n$num_missing file(s) under \"$dirname1\" are missing from under $dirs\n";
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

dir-missing.pl - Look for files from one directory missing from a 2nd directory

=head1 SYNOPSIS

dir-missing.pl [-dhlrc] dirname1 dirname2

=head1 DESCRIPTION

Look for files from one directory missing from a 2nd directory.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -l - use "ls" command to show missing files files
  -r - recursively process sub-directories
  -c - display list of missing files in a compact style

=head1 PARAMETERS

  dirname1 - name of 1st directory
  dirname2 - name of 2nd directory
  dirname_n - name of nth directory

=head1 EXAMPLES

dir-missing.pl dir1 dir2 dir3

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
