#!/usr/bin/perl -w

######################################################################
#
# File      : find-class.pl
#
# Author    : Barry Kimelman
#
# Created   : January 3, 2023
#
# Purpose   : Find *.class files in directories and jar files specified by CLASSPATH
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "list_file_info.pl";
require "find_zip_file_members.pl";

my %options = ( "d" => 0 , "h" => 0 );
my %list = ();

######################################################################
#
# Function  : process_dir
#
# Purpose   : Process a directory
#
# Inputs    : $_[0] - directory name
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : process_dir($dirname);
#
# Notes     : (none)
#
######################################################################

sub process_dir
{
	my ( $dirname ) = @_;
	my ( $handle , $entry , $name , $path );

	unless ( opendir($handle,"$dirname") ) {
		warn("opendir failed for '$dirname' : $!\n");
		return;
	} # UNLESS

	while ( $entry = readdir $handle ) {
		if ( $entry =~ m/\.class$/ ) {
			$name = $`;
			if ( exists $list{$name} ) {
				$path = File::Spec->catfile($dirname,$entry);
				print "\n";
				list_file_info_full($path,{ "g" => 0 , "o" => 0 , "k" => 0 , "n" => 0 , "m" => 0 } );
			} # IF
		} # IF
	} # WHILE
	closedir $handle;

	return;
} # end of process_dir

######################################################################
#
# Function  : process_jar
#
# Purpose   : Process a jar file
#
# Inputs    : $_[0] - jar file name
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : process_jar($jar);
#
# Notes     : (none)
#
######################################################################

sub process_jar
{
	my ( $jar ) = @_;
	my ( $zip , %members , @names , $errmsg , $count , @parts , $class_file );

	print "\nProcess jar file $jar\n";

	$zip = find_zip_file_members($jar,\%members,\@names,\$errmsg);
	unless ( defined $zip ) {
		warn("Can't scan jar file $jar : $errmsg\n");
		return;
	} # UNLESS
	$count = scalar @names;
	print "Found $count members in $jar\n";
	foreach my $name ( @names ) {
		if ( $name =~ m/\.class$/i ) {
			@parts = split(/\//,$name);
			$class_file = $parts[$#parts];
			$class_file =~ s/\.class$//i;
			if ( exists $list{$class_file} ) {
				# list_file_info_full($path,{ "g" => 0 , "o" => 0 , "k" => 0 , "n" => 0 , "m" => 0 } );
				print "\nFound class $class_file in $jar\n";
				print Dumper($members{$name});
			} # IF
		} # IF
	} # FOREACH

	undef $zip;
	return;
} # end of process_jar

######################################################################
#
# Function  : process_dir_or_jar_file
#
# Purpose   : Process a single directory
#
# Inputs    : $_[0] -= directory name or jar file name
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : process_dir_or_jar_file($dirname);
#
# Notes     : (none)
#
######################################################################

sub process_dir_or_jar_file
{
	my ( $path ) = @_;

	if ( -d $path ) {
		process_dir($path);
	} # IF
	else {
		if ( $path =~ m/\.jar$/i ) {
			process_jar($path);
		} # IF
		else {
			print "\nIgnore $path\n";
		} # ELSE
	} # ELSE

	return;
} # end of process_dir_or_jar_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Find *.class files in directories and jar files specified by CLASSPATH
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : find-class.pl -d arg1 arg2
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
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] class_name [... class_name]\n");
	} # UNLESS

	select STDERR;
	$| = 1; # automatic flushing for STDERR;
	select STDOUT;
	$| = 1; # automatic flushing for STDOUT

	%list = map { $_ , 0 } @ARGV;
	foreach my $path ( split(/:/,$ENV{"CLASSPATH"}) ) {
		process_dir_or_jar_file($path);
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

find-class.pl - Find *.class files in directories and jar files specified by CLASSPATH

=head1 SYNOPSIS

find-class.pl [-hd] class_name [... class_name]

=head1 DESCRIPTION

Find *.class files in directories and jar files specified by CLASSPATH

=head1 PARAMETERS

  class_name - the name of a class defined in *.java file

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

find-class.pl mysql_desc

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
