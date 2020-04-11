#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : clonetree.pl
#
# Author    : Barry Kimelman
#
# Created   : April 9, 2020
#
# Purpose   : Clone the structure of a directory tree
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

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : clone_tree
#
# Purpose   : Clone the structure of a directory tree
#
# Inputs    : $_[0] - name of existing directory
#             $_[1] - name of new directory
#             $_[2] - directory level ( 0 is top level )
#
# Output    : appropriate messages
#
# Returns   : nothing
#
# Example   : clone_tree($old_dir,$new_dir,0);
#
# Notes     : (none)
#
######################################################################

sub clone_tree
{
	my ( $old_dir , $new_dir , $dir_level ) = @_;
	my ( $path , %entries , @old_dirs , @new_dirs , $index );

	print "Clone '$old_dir' to '$new_dir' [ level = $dir_level]\n";
	unless ( opendir(DIR,"$old_dir") ) {
		die("opendir failed for '$old_dir' : $!\n");
	} # UNLESS
	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};

	@old_dirs = ();
	@new_dirs = ();
	foreach my $entry ( keys %entries ) {
		$path = File::Spec->catfile($old_dir,$entry);
		if ( -d $path ) {
			push @old_dirs,$path;
			$path = File::Spec->catfile($new_dir,$entry);
			unless ( mkdir($path) ) {
				die("mkdir failed for '$path' : $!\n");
			} # UNLESS
			push @new_dirs,$path;
		} # IF
	} # FOREACH
	for ( $index = 0 ; $index <= $#old_dirs ; ++$index ) {
		clone_tree($old_dirs[$index],$new_dirs[$index],1+$dir_level);
	} # FOREACH

	return;
} # end of clone_tree

######################################################################
#
# Function  : MAIN
#
# Purpose   : Clone the structure of a directory tree
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : clonetree.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 2 == scalar @ARGV ) {
		die("Usage : $0 [-dh] old_dir new_dir\n");
	} # UNLESS
	unless ( mkdir($ARGV[1]) ) {
		die("mkdir failed for '$ARGV[1]' : $!\n");
	} # UNLESS

	clone_tree($ARGV[0],$ARGV[1],0);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

clonetree.pl - Clone the structure of a directory tree

=head1 SYNOPSIS

clonetree.pl [-hd] old_dir new_dir

=head1 DESCRIPTION

Clone the structure of a directory tree

=head1 PARAMETERS

  old_dir - name of existing directory
  new_dir - name for cloned directory structure

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

clonetree.pl mydata mydata2

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
