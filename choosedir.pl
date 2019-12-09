#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : choosedir.pl
#
# Author    : Barry Kimelman
#
# Created   : November 21, 2019
#
# Purpose   : Choose a sub-directory under the current directory
#
# Notes     : The name of the chosen sub-directory is copied to the clipboard
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use Win32::Clipboard;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "r" => 0 );
my @subdirs = ();

######################################################################
#
# Function  : scan_tree
#
# Purpose   : Scan a directory tree looking for sub-directories
#
# Inputs    : $_[0] - dirname
#
# Output    : appropriate messages
#
# Returns   : nothing
#
# Example   : scan_tree($dirname)
#
# Notes     : (none)
#
######################################################################

sub scan_tree
{
	my ( $dirname ) = @_;
	my ( %entries , @paths , @list );

	unless ( opendir(DIR,"$dirname") ) {
		die("opendir failed for '$dirname' : $!\n");
	} # UNLESS
	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@paths = map { File::Spec->catfile($dirname,$_) } sort { lc $a cmp lc $b } keys %entries;
	@list = grep { -d $_ } @paths;
	push @subdirs,@list;
	if ( $options{'r'} && 0 < scalar @list ) {
		foreach my $subdir ( @list ) {
			scan_tree($subdir);
		} # FOREACH
	} # IF

	return;
} # end of scan_tree

######################################################################
#
# Function  : MAIN
#
# Purpose   : Choose a sub-directory under the current directory
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : choosedir.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , %entries , $count , $index , @numbers , $buffer );
	my ( $clip );

	$status = getopts("hdr",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dhr]\n");
	} # UNLESS
	scan_tree(".");

	$count = scalar @subdirs;
	if ( $count == 0 ) {
		die("No sub-directories were found.\n");
	} # IF
	@numbers = (1 .. $count);
	print join("\n",map { "$numbers[$_] $subdirs[$_]" } (0 .. $#subdirs)),"\n";
	while ( 1 ) {
		print "\nEnter your choice [1 - $count] :";
		$buffer = <STDIN>;
		chomp $buffer;
		unless ( $buffer =~ m/^\d+$/ ) {
			print "Non numeric characters detected. Try again.\n";
			next;
		} # UNLESS
		if ( $buffer < 1 || $buffer > $count ) {
			print "Invalid number. Try again.\n";
			next;
		} # IF
		last;
	} # WHILE
	print "$subdirs[$buffer-1]\n";

	$clip = Win32::Clipboard();
	unless ( defined $clip ) {
		die("Can't create clipboard object : $!\n");
	} # UNLESS
	$clip->Empty();
	$clip->Set($subdirs[$buffer-1]);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

choosedir.pl - Choose a sub-directory under the current directory

=head1 SYNOPSIS

choosedir.pl [-hdr]

=head1 DESCRIPTION

Choose a sub-directory under the current directory

=head1 PARAMETERS

  (none)

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -r - recursively process entire directory tree

=head1 EXAMPLES

choosedir.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
