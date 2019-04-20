#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : sys-tasklist.pl
#
# Author    : Barry Kimelman
#
# Created   : July 20, 2011
#
# Purpose   : Display a list of Windows tasks.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : debug_print
#
# Purpose   : Optionally print a debugging message.
#
# Inputs    : @_ - array of strings comprising message
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : debug_print("Process the files : ",join(" ",@xx),"\n");
#
# Notes     : (none)
#
######################################################################

sub debug_print
{
	if ( $options{"d"} ) {
		print join("",@_);
	} # IF

	return;
} # end of debug_print

######################################################################
#
# Function  : MAIN
#
# Purpose   : Display a list of Windows tasks.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : sys-tasklist.pl -d pattern1 pattern2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , @output , $header , @fields , $pattern );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [pattern [... pattern]]\n");
	} # UNLESS

	@output = `tasklist`;
	if ( $? != 0 ) {
		die("tasklist.exe failed\n");
	} # IF
	chomp @output;
	$header = shift @output;
	print "$header\n";
	$header = shift @output;
	print "$header\n";
	$header = shift @output;
	print "$header\n";
	if ( 0 < @ARGV ) {
		$pattern = $ARGV[0];
		foreach my $taskline ( @output ) {
			@fields = split(/\s+/,$taskline);
			if ( $fields[0] =~ m/${pattern}/i ) {
				print "$taskline\n";
			} # IF
		} # FOREACH
	} # IF
	else {
		print join("\n",@output),"\n";
	} # ELSE

	exit 0;
} # end of MAIN
__END__
=head1 NAME

sys-tasklist.pl - Display a list of Windows tasks.

=head1 SYNOPSIS

sys-tasklist.pl [-hd] [pattern [... pattern]]

=head1 DESCRIPTION

Display a list of Windows tasks.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary

=head1 PARAMETERS

  pattern - a pattern to be matched against the task names

=head1 EXAMPLES

sys-tasklist.pl xxx

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
