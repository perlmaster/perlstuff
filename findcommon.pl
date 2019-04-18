#!/usr/bin/perl -w

######################################################################
#
# File      : findcommon.pl
#
# Author    : Barry Kimelman
#
# Created   : September 11, 2009
#
# Purpose   : Find all elements common to 2 lists.
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
# Purpose   : Find all elements common to 2 lists.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : findcommon.pl -d list1 list2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , $filename2 , $buffer , %list2 , $count );

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
		$buffer = uc $buffer;
		if ( exists $list2{$buffer} ) {
			if ( ++$count == 1 ) {
				print "Values common to $filename and $filename2\n\n";
			} # IF
			print "$buffer\n";
		} # IF
	} # WHILE
	close INPUT;
	print "\n${count} values from $filename are common to both\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

findcommon.pl

=head1 SYNOPSIS

findcommon.pl [-hd] list1 list2

=head1 DESCRIPTION

Find all elements common to 2 lists.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary

=head1 PARAMETERS

  list1 - file containing 1st list
  list2 - file containing 2nd list

=head1 EXAMPLES

findcommon.pl list1 list2

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
