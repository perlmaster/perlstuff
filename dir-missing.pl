#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : missing.pl
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

my %options = ( "d" => 0 , "l" => 0 , "h" => 0 , "r" => 0 , "g" => 1 , "o" => 1 , "k" => 0 );
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
# Example   : missing.pl -d dir1 dir2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $dirname1 , $dirname , $status , %files1 , %files2 , $count1 , @missing );
	my ( $path , $dirs , @entries , $errmsg );

	$status = getopts("dlhre:",\%options);

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
	unless ( $status  && 1 < @ARGV ) {
		die("Usage : $0 [-dlhr] [-e exclude_pattern_list] dirname1 dirname2 [... dirname_n]\n");
	} # UNLESS
	$dirname1 = shift @ARGV;
	%files1 = ();
	$count1 = get_dir_entries($dirname,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
	if ( $count1 <  ) {
		die("$errmsg\n");
	} # IF
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
		if ( $status <  ) {
			die("$errmsg\n");
		} # IF
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
		print "\n$num_missing file(s) under \"$dirname1\" are missing from under $dirs\n";
		@missing = sort { lc $a cmp lc $b } @missing;
		if ( $options{'l'} ) {
			foreach my $entry ( @missing ) {
				$path = File::Spec->catfile($dirname1,$entry);
				list_file_info_full($path,\%options);
			} # FOREACH
		} # IF
		else {
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

dir-missing.pl [-dhlr] dirname1 dirname2

=head1 DESCRIPTION

Look for files from one directory missing from a 2nd directory.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -l - use "ls" command to show missing files files
  -r - recursively process sub-directories

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
