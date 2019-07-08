#!/usr/bin/perl -w

######################################################################
#
# File      : ext.pl
#
# Author    : Barry Kimelman
#
# Created   : August 29, 2001
#
# Purpose   : This module contains code to produce a list of filename
#             extensions.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::stat;
use Fcntl;
use FindBin;
use lib $FindBin::Bin;

require "comma_format.pl";
require "size_to_gb.pl";
require "print_lists.pl";
require "get_dir_entries.pl";
require "list_columns_style.pl";
require "display_pod_help.pl";

my %options = (
	"d" => 0 , "r" => 0 , "n" => 0 , "i" => 0 , "c" => 0 , "a" => 0 ,
	"R" => 0  , "b" => 0 , "h" => 0 , "p" => 0 , "C" => 0 , "L" => 119
);
my ( %extensions , $no_extension_total , @no_extension );
my ( %extension_bytes , %comma_bytes , $extension_pattern , $no_extension_bytes );
my ( $total_extension_files , $total_extension_bytes , $ext_summary_header );
my ( $line_limit , $num_cols , %extension_times );

######################################################################
#
# Function  : dump_class
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
# Example   : dump_class(\@class,$title);
#
# Notes     : (none)
#
######################################################################

sub dump_class
{
	my ( $class_ref , $title ) = @_;
	my ( $entry , $count , $maxlen , $line_size );

	$count = scalar @$class_ref;
	if ( $count > 0 ) {
		$maxlen = (sort { $b <=> $a } map { length $_ } @$class_ref)[0];
		print "\n$title [$count] :\n";
		$line_size = 0;
		$maxlen += 1;
		foreach $entry ( sort { lc $a cmp lc $b } @$class_ref ) {
			$line_size += $maxlen;
			if ( $line_size >= $line_limit ) {
				print "\n";
				$line_size = $maxlen;
			} # IF
			printf "%-${maxlen}.${maxlen}s",$entry;
		} # FOREACH
		print "\n";
	} # IF
	return;
} # end of dump_class

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
# Function  : scan_dir
#
# Purpose   : Scan a directory.
#
# Inputs    : $_[0] - name of directory
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : scan_dir($dirname);
#
# Notes     : (none)
#
######################################################################

sub scan_dir
{
	my ( $dirname ) = @_;
	my ( $extension , @fields , $entry , $status , @entries );
	my ( $path , @subdirs , $count , $bytes , $errmsg );

	if ( get_dir_entries($dirname,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 1 },\@entries,\$errmsg) < 0 ) {
		warn($errmsg);
		return;
	} # IF

	@subdirs = ();
	foreach $entry ( @entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		@fields = split(/\./,$entry);
		$count = scalar @fields;
		$bytes = -s $path;
		unless ( defined $bytes ) {
			$bytes = 0;
		} # UNLESS
		if ( $count < 2 ) {
			$no_extension_total += 1;
			$no_extension_bytes += $bytes;
			push(@no_extension,$entry);
		} # IF no extension
		else { # Process the extension
			$extension = $fields[$#fields];
			if ( $options{"i"} ) {
				$extension = lc $extension;
			} # IF
			if ( $extension =~ m/${extension_pattern}/i ) {
				$status = stat $path;
				unless ( defined $status ) {
					die("stat failed for '$path' : $!\n");
				} # UNLESS
				if ( exists $extensions{$extension} ) {
					$extensions{$extension} += 1;
					$extension_bytes{$extension} += $bytes;

					if ( $options{'a'} ) {
						if ( $status->mtime > $extension_times{$extension}{'newest'} ) {
							$extension_times{$extension}{'newest'} = $status->mtime;
							$extension_times{$extension}{'newest_file'} = $path;
						} # IF
						if ( $status->mtime < $extension_times{$extension}{'oldest'} ) {
							$extension_times{$extension}{'oldest'} = $status->mtime;
							$extension_times{$extension}{'oldest_file'} = $path;
						} # IF
					} # IF
				} # IF
				else {
					$extensions{$extension} = 1;
					$extension_bytes{$extension} = $bytes;
					if ( $options{'a'} ) {
						$extension_times{$extension}{'newest'} = $status->mtime;
						$extension_times{$extension}{'newest_file'} = $path;
						$extension_times{$extension}{'oldest'} = $status->mtime;
						$extension_times{$extension}{'oldest_file'} = $path;
					} # IF
				} # ELSE
			} # IF extension matches pattern
		} # ELSE file has an extension
		if ( $options{"r"} ) {
			if ( -d $path ) {
				push @subdirs,$path;
			} # IF
		} # IF
	} # FOREACH

	if ( $options{"r"} ) {
		foreach $path ( @subdirs ) {
			scan_dir($path);
		} # FOREACH
	} # IF

	return;
} # end of scan_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : Entry point for this program.
#
# Inputs    : @ARGV - array of filenames and directory names
#
# Output    : list of file extensions
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : ext.pl
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $dirname , $count , $maxlen , $status , $extension );
	my ( @headers , @underline , $maxlen_comma , @indices , @ext_list );
	my ( @ext_bytes , @ext_kb , @ext_count , @arrays , @newest , @oldest );

	$status = getopts("bcRindre:hpCL:a",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-L line_length_limit] [-{c|b|C}hindrRpa] [-e ext_pattern] [dirname]\n");
	} # UNLESS
	if ( $options{"c"} + $options{"b"} > 1 ) {
		die("Options 'c' and 'b' are mutually exclusive.\n");
	} # IF
	if ( $options{"p"} + $options{"C"} > 1 ) {
		die("Options 'p' and 'C' are mutually exclusive.\n");
	} # IF

	if ( $^O =~ m/MSWin/ ) {
		$num_cols = 100;
	} # IF
	else {
		$num_cols = `tput cols`;
		chomp $num_cols;
	} # ELSE
	if ( defined $num_cols && $num_cols > 0 ) {
		$options{"L"} = $num_cols;
	} # IF
	$line_limit = $options{"L"};

	if ( $^O =~ m/MSWin/ ) {
		$options{"i"} = 1;
	} # IF
	else {
	} # ELSE

	$dirname = (@ARGV < 1) ? "." : $ARGV[0];
	%extensions = ();
	%extension_bytes = ();
	@no_extension = ();
	$no_extension_total = 0;
	$no_extension_bytes = 0;
	%extension_times = ();
	if ( $options{'p'} ) {
		$extension_pattern = 'cgi$|p[lm]$';
	} elsif ( $options{'C'} ) {
		$extension_pattern = 'cgi$|p[lm]$|css$|js$|htm$|html$';
	} else {
		$extension_pattern = exists $options{"e"} ? $options{"e"} : ".";
	} # ELSE

	scan_dir($dirname);

	print "$no_extension_total file(s) with no extension(s)\n";
	if ( $no_extension_total > 0 && $options{"n"} ) {
		list_columns_style(\@no_extension,$num_cols,undef,\*STDOUT);
	} # IF
	print size_to_gb($no_extension_bytes),"\n\n";

	@headers = ( "Extension" , "Count" , "Bytes" );
	$ext_summary_header = "(total)";

	if ( 0 < keys %extensions ) {
		$maxlen = (sort { $b <=> $a} map { length $_ } keys %extensions)[0];
		if ( $maxlen < length $headers[0] ) {
			$maxlen = length $headers[0];
		} # IF
	} # IF
	else {
		$maxlen = length $headers[0];
	} # ELSE
	if ( $maxlen < length $ext_summary_header ) {
		$maxlen = length $ext_summary_header;
	} # IF
	$underline[0] = '=' x length $headers[0];
	$underline[1] = '=' x length $headers[1];
	$underline[2] = '=' x length $headers[2];
	%comma_bytes = ();
	foreach $extension ( keys %extensions ) {
		$comma_bytes{$extension} = comma_format($extension_bytes{$extension});
	} # FOREACH
	$maxlen_comma = (reverse sort { $a <=> $b} map { length $_ } values %comma_bytes)[0];
	unless ( defined $maxlen_comma ) {
		$maxlen_comma = 1;
	} # UNLESS

	$total_extension_files = 0;
	$total_extension_bytes = 0;
	@ext_list = keys %extensions;
	if ( $options{"c"} ) {
		@indices = sort { $extensions{$ext_list[$a]} <=> $extensions{$ext_list[$b]} } ( 0 .. $#ext_list );
	} # IF
	elsif ( $options{"b"} ) {
		@indices = sort { $extension_bytes{$ext_list[$a]} <=> $extension_bytes{$ext_list[$b]} } ( 0 .. $#ext_list );
	} else {
		@indices = sort { lc $ext_list[$a] cmp lc $ext_list[$b] } ( 0 .. $#ext_list );
	} # ELSE
	if ( $options{"R"} ) {
		@indices = reverse @indices;
	} # IF
	$maxlen_comma += 5;
	@ext_list = @ext_list[@indices];
	@ext_bytes = ();
	@ext_kb = ();
	@ext_count = ();
	@newest = ();
	@oldest = ();
	foreach my $ext ( @ext_list ) {
		push @ext_bytes , $comma_bytes{$ext};
		push @ext_kb , size_to_gb($extension_bytes{$ext});
		push @ext_count , $extensions{$ext};
		$total_extension_files += $extensions{$ext};
		$total_extension_bytes += $extension_bytes{$ext};
		if ( $options{'a'} ) {
			push @newest,$extension_times{$ext}{'newest_file'};
			push @oldest,$extension_times{$ext}{'oldest_file'};
		} # IF
	} # FOREACH
	@arrays = ( \@ext_list , \@ext_count , \@ext_bytes , \@ext_kb );
	if ( $options{'a'} ) {
		push @arrays, \@newest;
		push @arrays, \@oldest;
	} # IF
	@headers = ( "Extension" , "Count" , "Bytes" , "KB/MB/GB/TB" );
	if ( $options{'a'} ) {
		push @headers,"Newest";
		push @headers,"Oldest";
	} # IF

	push @ext_list," ";
	push @ext_count," ";
	push @ext_bytes," ";
	push @ext_kb," ";
	if ( $options{'a'} ) {
		push @newest," ";
		push @oldest," ";
	} # IF

	push @ext_list,"(total)";
	push @ext_count,$total_extension_files;
	push @ext_bytes,comma_format($total_extension_bytes);
	push @ext_kb,size_to_gb($total_extension_bytes);
	if ( $options{'a'} ) {
		push @newest," ";
		push @oldest," ";
	} # IF

	print_lists( \@arrays , \@headers , '-' );

	exit 0;
} # end of MAIN
__END__
=head1 NAME

ext.pl - summarize files by extension

=head1 SYNOPSIS

ext.pl [-L line_length_limit] [-{c|b}indrRa] [-e ext_pattern] [dirname]

=head1 DESCRIPTION

This perl script will summarize the files in a directory by their extensions.

=head1 OPTIONS

  -i - case insensitive sorting
  -b - sort extensions by total number of bytes of files
  -c - sort extensions by total number of files
  -n - list names of files with no extension
  -d - activate debug mode
  -r - recursively process sub-directories
  -R - reverse the order of sorting
  -e <pattern> - a regular expression to match extensions
  -p - only show for Perl files (.cgi , .pl , .pm)
  -C - only show for CGI files (.cgi , .pl , .pm , .css , .js , .htm , .html)
  -h - produce this summary
  -L length - override line length limit
  -a - show the age limits (youngest and oldest files for each extension)

=head1 EXAMPLES

ext.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
