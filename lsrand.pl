#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : lsrand.pl
#
# Author    : Barry Kimelman
#
# Created   : February 19, 2013
#
# Purpose   : Display "ls" style info with random ordering
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "list_file_info.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "l" => 0  , "p" => "." , "o" => 1 , "g" => 1 , "k" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Display "ls" style info with random ordering
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : lsrand.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , %entries , @entries , $num_files , $random , $index , $temp );

	$status = getopts("hdlp:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dhl]\n");
	} # UNLESS

	unless ( opendir(DIR,'.') ) {
		die("opendir failed : $!\n");
	} # UNLESS
	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{'..'};
	delete $entries{'.'};
	@entries = keys %entries;
	@entries = grep /${options{'p'}}/i,@entries;
	$num_files = scalar @entries;

	srand( time() - ($$ + ($$ << 15)) );

	for ( $index = 0 ; $index < $num_files ; ++$index ) {
		$random = int(rand $num_files);
		$temp = $entries[$index];
		$entries[$index] = $entries[$random];
		$entries[$random] = $temp;
	} # FOR
	if ( $options{'l'} ) {
		foreach my $entry ( @entries ) {
			list_file_info_full($entry,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
		} # FOREACH
	} # IF
	else {
		print join("\n",@entries),"\n";
	} # ELSE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

lsrand.pl - Display "ls" style info with random ordering

=head1 SYNOPSIS

lsrand.pl [-dhl] [-p pattern]

=head1 DESCRIPTION

Display "ls" style info with random ordering

=head1 OPTIONS

=over 4

=item -d - activate debug mode

=item -h - produce this summary

=item -l - display long ls style info for files

=item -p <pattern> - only display filenames matching this pattern

=back

=head1 PARAMETERS

  (none)

=head1 EXAMPLES

lsrand.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
