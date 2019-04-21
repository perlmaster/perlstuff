#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : antbuild.pl
#
# Author    : Barry Kimelman
#
# Created   : April 21, 2019
#
# Purpose   : Analyze a Ant build.xml file
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
require "print_lists.pl";
require "list_file_info.pl";

my %options = ( "d" => 0 , "h" => 0 );

######################################################################
#
# Function  : MAIN
#
# Purpose   : Analyze a Ant build.xml file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : antbuild.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , @records , $records , $total_records , $count );
	my ( @list , $project , $name , $desc , $default , @names , @descs );
	my ( $match );

	$status = getopts("hdc:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh] [-c comment_pattern] [filename]\n");
	} # UNLESS
	$filename = (0 == scalar @ARGV) ? "build.xml" : $ARGV[0];
	unless ( open(BUILD,"<$filename") ) {
		die("open failed for '$filename' : $!\n");
	} # UNLESS
	$status = localtime;
	print "\n$status\n\n";
	@records = <BUILD>;
	close BUILD;
	$total_records = scalar @records;
	print "\n${total_records} lines in '$filename'\n";
	list_file_info_full($filename,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
	print "\n";

	$records = join("",@records);
	$records =~ s/<!--.*?-->//igms;

	unless ( $records =~ m/<project\s+name="(.*?)"\s+default="(.*?)".*?>/igms ) {
		die("Could not find <project> tag in '$filename'\n");
	} # UNLESS
	$project = $1;
	$default = $2;
	print "Project = '$project' default = '$default'\n\n";

	@names = ();
	@descs = ();
	while ( $records =~ m/<target\s+name="(.*?)".*?>/igms ) {
		$name = $1;
		$match = $&;
		if ( $match =~ m/\sdescription="(.*?)"/igms ) {
			$desc = $1;
		} # IF
		else {
			$desc = "";
		} # ELSE
		push @names,$name;
		push @descs,$desc;
	} # WHILE
	print_lists( [ \@names , \@descs ] , [ "Name" , "Description" ] , "=");

	if ( exists $options{'c'} ) {
		print "\nScan for comments matching '$options{'c'}'\n\n";
		$records = join("",@records);
		while ( $records =~ m/<!--(.*?)-->/igms ) {
			$match = $1;
			$match = $&;
			if ( $match =~ m/${options{'c'}}/i ) {
				print "$match\n\n";
			} # IF
		} # WHILE
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

antbuild.pl - Analyze a Ant build.xml file

=head1 SYNOPSIS

antbuild.pl [-hd] [-c comment_pattern] [filename]

=head1 DESCRIPTION

Analyze a Ant build.xml file

=head1 PARAMETERS

  filename - name of optional filename

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -c comment_pattern - display comments whose content matches the pattern

=head1 EXAMPLES

antbuild.pl junk.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
