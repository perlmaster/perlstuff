#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : dir-common.pl
#
# Author    : Barry Kimelman
#
# Created   : April 22, 2019
#
# Purpose   : List all the files common to two directories.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "get_dir_entries.pl";
require "list_file_info.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "l" => 0 , "h" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : List all the files common to two directories.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : dir-common.pl -d dir1 dir2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $dirname1 , $dirname2 , $status , %files1 , %files2 , $count1 , @missing );
	my ( $path , $dirs , @entries , $errmsg , $count2 , @common );

	$status = getopts("dlh",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status  && 1 < scalar @ARGV ) {
		die("Usage : $0 [-dlh] dirname1 dirname2\n");
	} # UNLESS
	( $dirname1 , $dirname2 ) = @ARGV;

	$count1 = get_dir_entries($dirname1,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
	if ( $count1 < 0 ) {
		die("$errmsg\n");
	} # IF
	%files1 = map { $_ , 0 } @entries;
	print "\nFound ${count1} files under $dirname1\n";

	$count2 = get_dir_entries($dirname2,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
	if ( $count2 < 0 ) {
		die("$errmsg\n");
	} # IF
	%files2 = map { $_ , 0 } @entries;
	print "\nFound ${count2} files under $dirname2\n";

	@common = ();
	foreach my $file1 ( sort { lc $a cmp lc $b } keys %files1 ) {
		if ( exists $files2{$file1} ) {
			push @common,$file1;
		} # IF
	} # FOREACH
	$status = scalar @common;
	print "\n${status} common files.\n";
	if ( $status > 0 ) {
		if ( $options{'l'} ) {
			foreach my $common ( @common ) {
				print "\n";
				$path = File::Spec->catfile($dirname1,$common);
				list_file_info_full($path,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
				$path = File::Spec->catfile($dirname2,$common);
				list_file_info_full($path,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
			} # FOREACH
		} # IF
		else {
			print join("\n",@common),"\n";
		} # ELSE
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

dir-common.pl - List all the files common to two directories.
=head1 SYNOPSIS

dir-common.pl [-dhl] dirname1 dirname2

=head1 DESCRIPTION

List all the files common to two directories.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -l - display "ls" style info for common files

=head1 PARAMETERS

  dirname1 - name of 1st directory
  dirname2 - name of 2nd directory

=head1 EXAMPLES

dir-common.pl dir1 dir2 dir3

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
