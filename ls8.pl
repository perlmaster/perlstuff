#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : ls8.pl
#
# Author    : Barry Kimelman
#
# Created   : January 30, 2018
#
# Purpose   : Produce output similar to UNIX "ls" command.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::stat;
use Fcntl;
use File::Spec;
use Win32::Console;
use FindBin;
use lib $FindBin::Bin;

require "list_file_info.pl";
require "get_dir_entries.pl";
require "list_columns_style.pl";

require "time_date.pl";
require "comma_format.pl";
require "format_megabytes.pl";
require "format_mode.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "c" => 0 , "s" => 0 , "S" => 0 , "t" => 0 ,
					"m" => 0 , "D" => 0 , "p" => 0 , "f" => 0 , "h" => 0 ,
					"r" => 0 , "F" => 0 , "k" => 0 , "i" => 0 , "M" => 0 ,
					"a" => 0 , "P" => 0 );
my ( @list );
my ( $total_num_files , $total_num_directories  , $total_file_bytes );
my ( $pause_rate );
my ( $CONSOLE , @console_info , %console_info );

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
# Example   : debug_print("Tne answer is $reply\n");
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
# Function  : get_file_year
#
# Purpose   : Calculate a file's year of modification.
#
# Inputs    : $_[0] - file's time of modification
#
# Output    : (none)
#
# Returns   : calculated year of modification
#
# Example   : $year = get_file_year($file_status->mtime);
#
# Notes     : (none)
#
######################################################################

sub get_file_year
{
	my ( $file_time ) = @_;
	my ( $file_year );
	my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst );

	( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst ) =
              localtime($file_time);

	$file_year = 1900 + $year;
	return $file_year;
} # end of get_file_year

######################################################################
#
# Function  : get_file_month
#
# Purpose   : Calculate a file's year and month of modification.
#
# Inputs    : $_[0] - filename
#
# Output    : (none)
#
# Returns   : year and month of modification
#
# Example   : ($year , $month ) = get_file_month($filename);
#
# Notes     : (none)
#
######################################################################

sub get_file_month
{
	my ( $path ) = @_;
	my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday );
	my ( $isdst , $file_year , $status );

	$status = stat($path);
	if ( ! $status ) {
		die("stat failed for \"$path\"\n");
	} # IF
	( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst ) =
              localtime($status->mtime);
	$file_year = 1900 + $year;

	return ($file_year , $mon);
} # end of get_file_month

######################################################################
#
# Function  : list_compact
#
# Purpose   : List the specified files in a nulti-column compact format.
#
# Inputs    : (none)
#
# Output    : List of files
#
# Returns   : nothing
#
# Example   : list_compact();
#
# Notes     : (none)
#
######################################################################

sub list_compact
{
	my ( $line_limit );

	if ( @list > 0 ) {
		$line_limit = $console_info{'max_columns'};
		@list = sort { lc $a cmp lc $b } @list;
		list_columns_style(\@list,$line_limit,undef,\*STDOUT);
		print "\n";
	} # IF
	else {
		print "** empty list **\n";
	} # ELSE

} # end of list_compact

######################################################################
#
# Function  : list_file_information
#
# Purpose   : List the detailed information for the specified files.
#
# Inputs    : $_[0] - reference to array of names
#             $_[1] - reference to array of indices
#
# Output    : List of files
#
# Returns   : nothing
#
# Example   : list_file_information(\@names,\@sorted);
#
# Notes     : (none)
#
######################################################################

sub list_file_information
{
	my ( $names_ref , $indexes_ref ) = @_;
	my ( $year , $count , $reply , $index , $path , $status , $mode );
	my ( $perms , $string , $filesize , $kb , $mb , %opt );

	$count = 0;
	%opt = ( 'k' => $options{'k'} , "o" => 1 , "g" => 1 , "m" => $options{"M"} );
	foreach my $index ( @$indexes_ref ) {
		$path = $$names_ref[$index];
		if ( -d $path ) {
			$total_num_directories += 1;
		} # IF
		else {
			$total_num_files += 1;
			$status = stat($path);
			if ( ! $status ) {
				die("stat failed for \"$path\"\n");
			} # IF
			$total_file_bytes += $status->size;
		} # ELSE
		list_file_info_full($path,\%opt);
	} # FOREACH

	return;
} # end of list_file_information

######################################################################
#
# Function  : list_time
#
# Purpose   : List the detailed information for the specified files
#             sorted by time.
#
# Inputs    : (none)
#
# Output    : List of files
#
# Returns   : nothing
#
# Example   : list_time();
#
# Notes     : (none)
#
######################################################################

sub list_time
{
	my ( $path , $status , @indexes , $index , @filetimes );

	@filetimes = ();
	foreach my $path ( @list ) {
		$status = stat($path);
		push @filetimes,$status->mtime;
	} # FOREACH
	@indexes = sort { $filetimes[$a] <=> $filetimes[$b] } (0..$#list);
	if ( $options{"T"} ) {
		@indexes = reverse @indexes;
	} # ELSE
	list_file_information(\@list,\@indexes);

	return;
} # end of list_time

######################################################################
#
# Function  : list_size
#
# Purpose   : List the detailed information for the specified files
#             after sorting the files by size.
#
# Inputs    : (none)
#
# Output    : List of files
#
# Returns   : nothing
#
# Example   : list_size();
#
# Notes     : (none)
#
######################################################################

sub list_size
{
	my ( $path , $status , @indexes , $index , @filesizes );

	@filesizes = ();
	foreach my $path ( @list ) {
		$status = stat($path);
		push @filesizes,$status->size;
	} # FOREACH
	@indexes = (0..$#list);
	@indexes = sort { $filesizes[$a] <=> $filesizes[$b] } @indexes;
	if ( $options{"S"} ) {
		@indexes = reverse @indexes;
	} # IF
	list_file_information(\@list,\@indexes);

} # end of list_size

######################################################################
#
# Function  : list_long
#
# Purpose   : List the detailed information for the specified files
#             after sorting the files by name.
#
# Inputs    : (none)
#
# Output    : List of files
#
# Returns   : nothing
#
# Example   : list_long();
#
# Notes     : (none)
#
######################################################################

sub list_long
{
	my ( @indexes );

	if ( @list > 0 ) {
		@indexes = (0..$#list);
		@indexes = sort { lc($list[$a]) cmp lc($list[$b]) } @indexes;
		list_file_information(\@list,\@indexes);
	} # IF
	else {
		print "** empty list **\n";
	} # ELSE

} # end of list_long

######################################################################
#
# Function  : add_tree_to_list
#
# Purpose   : Recursively add directory entries to list.
#
# Inputs    : $_[0] - directory name
#             $_[1] - reference to array containing list of entries
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : add_tree_to_list($dirname,\@list);
#
# Notes     : (none)
#
######################################################################

sub add_tree_to_list
{
	my ( $dirname , $ref_list ) = @_;
	my ( %entries , $entry , $path );

	unless ( opendir(DIR,$dirname) ) {
		die("opendir failed for '$dirname' : $!\n");
	} # UNLESS
	%entries = map { $_ , 1 } readdir DIR;
	closedir DIR;
	unless ( $options{'a'} ) {
		delete $entries{"."};
		delete $entries{".."};
	} # UNLESS

	foreach my $entry ( keys %entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		push @$ref_list,$path;
		if ( -d $path && $entry ne '.' && $entry ne '..' ) {
			add_tree_to_list($path,$ref_list);
		} # IF
	} # FOREACH
	return;
} # end of add_tree_to_list

######################################################################
#
# Function  : MAIN
#
# Purpose   : Produce output similar to the UNIX "ls" command.
#
# Inputs    : command line parameters
#
# Output    : List of files
#
# Returns   : nothing
#
# Example   : ls8.pl -t
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $string , @matches , $status , $megabyte , $kilobyte );
	my ( $count , $path , @parts , $new_matches , $clock , @list2 );
	my ( $current_year , $current_month , $file_year , $file_month );
	my ( @new_matches , $last_part , @entries , $errmsg , @matched );

	$total_num_files = 0;
	$total_num_directories = 0;
	$clock = time;
	@list2 = localtime($clock);
	$current_year = 1900 + $list2[5];
	$current_month = $list2[4];
	$pause_rate = 40;

	$CONSOLE = new Win32::Console();
	unless ( defined $CONSOLE ) {
		die("Can't create console object : $!\n");
	} # UNLESS
	@console_info = $CONSOLE->Info();
	if ( 0 == scalar @console_info ) {
		die("Can't get console info : $!\n");
	} # IF
	%console_info = (
		"columns" => $console_info[0] ,
		"rows" => $console_info[1] ,
		"max_columns" => $console_info[9] ,
		"max_rows" => $console_info[10]
	);

	$status = getopts("hkDdfFtTspScmy:e:riMaP",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("\nUsage : $0 [-hDdftTsScmpFiMaP] [-e exclude_pattern] [-y year] [filename [... filename]]\n");
	} # IF

	@list = ();
	$count = scalar @ARGV;
	if ( $count == 0 ) {
		$status = get_dir_entries(".",{ 'dot' => $options{'a'} , 'qual' => 0 , 'sort' => 0 },\@list,\$errmsg);
		if ( $status < 0 ) {
			die("$errmsg\n");
		} # IF
	} # IF
	else {
		if ( $options{"P"} ) {
			$status = get_dir_entries(".",{ 'dot' => $options{'a'} , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
			if ( $status < 0 ) {
				die("$errmsg\n");
			} # IF
			foreach my $pattern ( @ARGV ) {
				@matched = grep /${pattern}/i,@entries;
				if ( 0 == scalar @matched ) {
					print "No matches for '$pattern'\n";
				} # IF
				else {
					push @list,@matched;
				} # ELSE
			} # FOREACH
			if ( 0 == scalar @list ) {
				die("Nothing matched yuour patterns\n");
			} # IF
		} # IF
		else {
			@list = @ARGV;
		} # ELSE
	} # ELSE

	if ( defined $options{"e"} ) {
		@new_matches = ();
		foreach my $path ( @list ) {
			@parts = split(/[\\\/]/,$path);
			$last_part = $parts[$#parts];
			unless ( $last_part =~ m/${options{"e"}}/ ) {
				push(@new_matches,$path);
			} # UNLESS
		} # FOREACH
		if ( 1 > @new_matches ) {
			die("No matches after exclude pattern applied\n");
		} # IF
		@list = @new_matches;
	} # IF

	if ( $options{"m"} ) {
		@list2 = ();
		foreach my $path ( @list ) {
			($file_year , $file_month) = get_file_month($path);
			if ( $file_year == $current_year && $file_month == $current_month ) {
				debug_print("Month match on \"$path\"\n");
				push(@list2,$path);
			} # IF
		} # FOREACH
		@list = @list2;
	} # IF

	if ( $options{"F"} ) {
		@list2 = ();
		foreach my $path ( @list ) {
			if ( -f $path ) {
				push @list2,$path;
			} # IF
		} # FOREACH
		@list = @list2;
	} # IF

	if ( 1 > @list ) {
		die("\nAll matching criteria failed.\n");
	} # IF

	if ( $options{"r"} ) {
		@list2 = ();
		foreach my $path ( @list ) {
			if ( -d $path ) {
				add_tree_to_list($path,\@list2);
			} # IF
		} # FOREACH
		push @list,@list2;
	} # IF

	$total_file_bytes = 0;
	if ( $options{"c"} ) {
		list_compact();
	} elsif ( $options{"s"} || $options{"S"} ) {
		list_size();
	} elsif ( $options{"t"} || $options{"T"} ) {
		list_time();
	} else {
		list_long();
	} # ELSE

	if ( $options{'i'} ) {
		print "\n$total_num_files file(s) , ",comma_format($total_file_bytes)," bytes";
		$megabyte = 1 << 20;
		$kilobyte = 1 << 10;
		print " ",format_megabytes($total_file_bytes),"\n";
		
		print "$total_num_directories directories.\n";
	} # IF

	exit 0;
} # end of MAIN
__END__
=head1 NAME

ls8.pl - display output similar to UNIX ls command

=head1 SYNOPSIS

ls8.pl [-hDdftTsScmpFiMaP] [-e exclude_pattern] [-y year] [filename [... filename]]

=head1 DESCRIPTION

display output similar to UNIX ls command

=head1 PARAMETERS

  filename - name of file or directory

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -D - do not list entries under directories
  -d - activate debug mode
  -f - only print the filename for each file/directory
  -t - sort by time of modification in ascending order
  -T - sort by time of modification in descending order
  -s - sort by size in ascending order
  -S - sort by size in descending order
  -p - pause the display every $pause_rate lines
  -c - produce a compact multi-column listing
  -m - only list files that have been modified within the current month
  -e <pattern> - do not list entries matching the specified pattern
  -y <year> - only list files that have been modified within the specified year
  -r - recursively process directories
  -F - only list regular files
  -k - list file size in terms of KB and MB instead of bytes
  -h - produce this summary
  -i - display an information summary
  -M - do not list the mode bits
  -a - include '.' and '..'
  -P - treat filenames as patterns to be applied against current directory

=head1 EXAMPLES

ls8.pl junk.txt

ls8.pl -P txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
