#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : findmissing.pl
#
# Author    : Barry Kimelman
#
# Created   : September 11, 2009
#
# Purpose   : Find all elements in the 1st list not in the 2nd list.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;

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
# Purpose   : Find all elements in the 1st list not in the 2nd list.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : findmissing.pl -d list1 list2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , $filename2 , $count , $buffer , %list2 );

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
	unless ( $status && 2 == @ARGV ) {
		die("Usage : $0 [-dh] list1 list2\n");
	} # UNLESS

#
# Build hash of numbers from 2nd list
#
	$filename2 = $ARGV[1];
	unless ( open(INPUT,"<$filename2") ) {
		die("open failed for \"$filename2\" : $!\n");
	} # UNLESS
	%list2 = ();
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		$list2{uc $buffer} = 0;
	} # WHILE
	close INPUT;

#
# Read and process 1st list
#
	$filename = $ARGV[0];
	unless ( open(INPUT,"<$filename") ) {
		die("open failed for \"$filename\" : $!\n");
	} # UNLESS
	$count = 0;
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		unless ( exists $list2{uc $buffer} ) {
			if ( ++$count == 1 ) {
				print "Values from $filename missing from $filename2\n\n";
			} # IF
			print "$buffer\n";
		} # UNLESS
	} # WHILE
	close INPUT;
	print "\n${count} values from $filename are missing from $filename2\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

findmissing.pl

=head1 SYNOPSIS

findmissing.pl [-hd] list1 list2

=head1 DESCRIPTION

Find all elements in the 1st list not in the 2nd list.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary

=head1 PARAMETERS

  list1 - file containing 1st list
  list2 - file containing 2nd list

=head1 EXAMPLES

findmissing.pl list1 list2

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
