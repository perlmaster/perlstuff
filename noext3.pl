#!/usr/bin/perl -w

######################################################################
#
# File      : noext3.pl
#
# Author    : Barry Kimelman
#
# Created   : May 9, 2019
#
# Purpose   : Display list of files with no extension
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
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_file_info.pl";

my %options = ( "d" => 0 , "h" => 0 , "l" => 0 );
my $num_cols = `tput cols`;
my ( @files , @dirs , @symlinks , @fifo , @sockets , @blocks , @chars , @misc );

######################################################################
#
# Function  : list_files_in_class
#
# Purpose   : List the members of a class list.
#
# Inputs    : $_[0] - reference to class list array
#             $_[1] - title for listing of class
#
# Output    : Listing of class members
#
# Returns   : nothing
#
# Example   : list_files_in_class(\@class,$title);
#
# Notes     : (none)
#
######################################################################

sub list_files_in_class
{
	my ( $class_ref , $title ) = @_;
	my ( $entry , $count , $maxlen , $line_size );

	$count = scalar @$class_ref;
	if ( $count > 0 ) {
		$maxlen = (sort { $b <=> $a } map { length $_ } @$class_ref)[0];
		print "\n$title [ $count ]\n";
		$line_size = 0;
		$maxlen += 1;
		foreach $entry ( sort { lc $a cmp lc $b } @$class_ref ) {
			$line_size += $maxlen;
			if ( $line_size >= $num_cols ) {
				print "\n";
				$line_size = $maxlen;
			} # IF
			printf "%-${maxlen}.${maxlen}s",$entry;
		} # FOREACH
		print "\n";
	} # IF
	return;
} # end of list_files_in_class

######################################################################
#
# Function  : MAIN
#
# Purpose   : Display list of files with no extension
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : noext3.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $handle , $status , %entries , @entries , $path , $dest , @textfiles , $buffer );
	my ( @mtimes , @indices );

	$status = getopts("hdl",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dhl]\n");
	} # UNLESS

	unless ( opendir($handle,".") ) {
		die("opendir failed : $!\n");
	} # UNLESS
	%entries = map { $_ , 0 } readdir $handle;
	closedir $handle;
	@entries = grep !/\./, keys %entries;
	if ( 0 == scalar @entries ) {
		print "None found.\n";
		exit 0;
	} # IF
	@entries = sort { lc $a cmp lc $b } @entries;

	if ( $options{'l'} ) {
		foreach my $filename ( @entries ) {
			list_file_info_full($filename,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 0 } );
		} # FOREACH
		exit 0;
	} # IF

	@files = ();
	@dirs = ();
	@symlinks = ();
	@fifo = ();
	@sockets = ();
	@blocks = ();
	@chars = ();
	@misc = ();

	foreach my $entry ( @entries ) {
		if ( -l $entry ) {
			push @symlinks,$entry;
		} # IF
		elsif ( -d $entry ) {
			push @dirs,$entry;
		} # ELSIF
		elsif ( -f $entry ) {
			push @files,$entry;
		} # ELSIF
		elsif ( -p $entry ) {
			push @fifo,$entry;
		} # ELSIF
		elsif ( -S $entry ) {
			push @sockets,$entry;
		} # ELSIF
		elsif ( -r $entry ) {
			push @blocks,$entry;
		} # ELSIF
		elsif ( -c $entry ) {
			push @chars,$entry;
		} # ELSIF
		else {
			push @misc,$entry;
		} # ELSIF
	} # FOREACH

	list_files_in_class(\@files,"Files");
	list_files_in_class(\@dirs,"Directories");
	list_files_in_class(\@symlinks,"Symbolic Links");
	list_files_in_class(\@fifo,"Named Pipes (FIFO)");
	list_files_in_class(\@sockets,"Sockets");
	list_files_in_class(\@blocks,"Block Special Files");
	list_files_in_class(\@chars,"Character Special Files");
	list_files_in_class(\@misc,"Miscellaneous");

	exit 0;
} # end of MAIN
__END__
=head1 NAME

noext3.pl - Display list of files with no extension

=head1 SYNOPSIS

noext3.pl [-hdl]

=head1 DESCRIPTION

Display list of files with no extension

=head1 PARAMETERS

  (none)

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -l - list file info in the style of the ls command

=head1 EXAMPLES

noext3.pl  # display list of files with no extension grouped by file type

noext3.pl -l  # display list of files with no extension ala ls command

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
