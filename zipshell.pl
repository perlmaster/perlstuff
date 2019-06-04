#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : zipshell.pl
#
# Author    : Barry Kimelman
#
# Created   : January 29, 2019
#
# Purpose   : A shell for processing a ZIP file
#
# Notes     : Contents of ZIP file member object looks like the following
#  $VAR1 = bless( {
#                   'externalFileName' => 'foo.zip',
#                   'uncompressedSize' => 1820,
#                   'fileName' => 'charset.conv',
#                   'versionNeededToExtract' => 20,
#                   'fileAttributeFormat' => 0,
#                   'diskNumberStart' => 0,
#                   'compressionMethod' => 8,
#                   'eocdCrc32' => 4075145292,
#                   'fileComment' => '',
#                   'externalFileAttributes' => 32,
#                   'internalFileAttributes' => 0,
#                   'bitFlag' => 2,
#                   'lastModFileDateTime' => 1149111825,
#                   'crc32' => 4075145292,
#                   'versionMadeBy' => 20,
#                   'dataEnded' => 1,
#                   'localExtraField' => '',
#                   'localHeaderRelativeOffset' => 0,
#                   'readDataRemaining' => 0,
#                   'possibleEocdOffset' => 0,
#                   'desiredCompressionMethod' => 8,
#                   'compressedSize' => 549,
#                   'desiredCompressionLevel' => -1,
#                   'dataOffset' => 0,
#                   'fh' => undef,
#                   'isSymbolicLink' => 0,
#                   'cdExtraField' => 'stuff goes in here'
#                 }, 'Archive::Zip::ZipFileMember' );
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Basename;
use Win32::Console;
use Fcntl;
use File::Temp qw/ tempfile tempdir /;
use FindBin;
use lib $FindBin::Bin;

require "find_zip_file_members.pl";
require "display_pod_help.pl";
require "list_file_info.pl";
require "list_columns_style.pl";
require "time_date.pl";
require "comma_format.pl";
require "format_megabytes.pl";
require "hexdump.pl";
require "display_smooth_message_box.pl";
require "print_lists.pl";

my %options = (
	"d" => 0 , "h" => 0 , "s" => 0 , "t" => 0 , "r" => 0 , "H" => 10 , "T" => 10 ,
	"p" => "more" , "m" => 0 , "o" => 0 , "e" => "notepad" , "n" => 0 , "i" => 0
);
my %toggle_options = (
	"s" => "sort by size in ascending order" ,
	"t" => "sort by time/date in ascending order" , "r" => "reverse sorting order" ,
	"m" => "display member size in terms of TB/GB/MB/KB" ,
	"o" => "when saving allow file overwrite" , "n" => "display lines with line numbers" ,
	"i" => "use case insensitive searching"
);
my @toggle_options = values %toggle_options;
my $toggle_maxlen;
my @off_on = ( "off" , "on" );
my %members = ();
my @member_names = ();
my @basenames = ();
my $num_members = 0;
my $longest_name = -1;

my @main_menu = (
	[ "List member names without attributes" , \&list_names_only ] ,
	[ "Compact list member names without attributes" , \&list_compact_names_only ] ,
	[ "List member names with attributes" , \&list_members_info ] ,
	[ "List contents of member" , \&list_member_contents_with_line_numbers ] ,
	[ "List the first few lines of a member's content" , \&head_member ] ,
	[ "List the last few lines of a member's content" , \&tail_member ] ,
	[ "Save a member to disk" , \&save_member ] ,
	[ "Find member by path basename" , \&find_member_by_basename ] ,
	[ "Find member by complete path" , \&find_member_by_path ] ,
	[ "Display commands history" , \&display_history ] ,
	[ "Dump contents of member in hex" , \&hex_member_dump ] ,
	[ "Edit a copy of the contents of a member" , \&edit_member ] ,
	[ "Search member contents for lines containing a pattern" , \&grep_member ] ,
	[ "Manage toggle option flags" , \&toggle_options ] ,
	[ "Display Perl POD help" , \&display_perl_pod_help ] ,
	[ "Display help info" , \&display_help_info ] ,
	[ "Display a summary of filename extensions" , \&ext_summary ] ,
	[ "Display a list of files with no extension" , \&no_extension ] ,
);
my $num_menu_entries = scalar @main_menu;
my $CONSOLE;
my @console_info = ();
my %console_info = ();
my $sorting = 0;
my $command;
my $parameters;
my $num_parameters;
my @parameters;
my @quoted;
my @flags;
my $zipfile;
my $zip;
my @history = ();
my @times = ();
my $start_time;
my @copyright = (
	"ZIP Archive Command Shell" ,
	"Version 1 , 2019" ,
	"Created by Barry Kimelman" ,
	"Copyright (C) 2019"
);
my $help_info =<<HELP;
This Perl script is designed to access the information stored in a
ZIP archive file.

You can list the members of the archive with or without attributes,
display the contents of a member and more.

When entering parameters for a command if a parameter contains whitespace
then you must enclose the parameter value in quotes.

A number of the command line options can be changed while the script is
running by using the "toggle" command.

The default text editor is "notepad" which can be overriden.

The default paging program is "more" which can be overriden.
HELP

my $single_quote = 1;
my $double_quote = 2;
my %quoted = ( "'" => $single_quote , '"' => $double_quote );
my $tempdir;

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
# Notes     : The message is prefixed with "DEBUG : "
#
######################################################################

sub debug_print
{
	my ( $message );

	if ( $options{'d'} ) {
		$message = join('',@_);
		while ( $message =~ m/^\n/g ) {
			print "\n";
			$message = $';
		} # WHILE
		print "DEBUG : ${message}";
	} # IF

	return;
} # end of debug_print

######################################################################
#
# Function  : display_error
#
# Purpose   : Display an error message
#
# Inputs    : @_ - array of strings comprising message
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : display_error("Required parameter was omitted\n");
#
# Notes     : The message is prefixed with "ERROR : "
#
######################################################################

sub display_error
{
	my ( $message );

	$message = join('',@_);
	while ( $message =~ m/^\n/g ) {
		print "\n";
		$message = $';
	} # WHILE
	print "Error : ${message}";

	return;
} # end of display_error

######################################################################
#
# Function  : toggle_options
#
# Purpose   : Manage toggle option flags
#
# Inputs    : (none)
#
# Output    : appropriate messages
#
# Returns   : nothing
#
# Example   : toggle_options();
#
# Notes     : (none)
#
######################################################################

sub toggle_options
{
	my ( $message , $opt );

	if ( $num_parameters == 0 ) {
		foreach my $flag ( keys %toggle_options ) {
			printf "'%s' - %-${toggle_maxlen}.${toggle_maxlen}s - %s\n",$flag,$toggle_options{$flag},$off_on[$options{$flag}];
		} # FOREACH
	} # IF
	else {
		$opt = $parameters[0];
		if ( exists $toggle_options{$opt} ) {
			$options{$opt} ^= 1;
			print "'${opt}' - $toggle_options{$opt} - $off_on[$options{$opt}]\n";
		} # IF
		else {
			display_error("'$opt' is not a valid toggle option\n");
		} # ELSE
	} # ELSE

	return;
} # end of toggle_options

######################################################################
#
# Function  : display_perl_pod_help
#
# Purpose   : Display Perl POD help information
#
# Inputs    : (none)
#
# Output    : help information
#
# Returns   : nothing
#
# Example   : display_perl_pod_help();
#
# Notes     : (none)
#
######################################################################

sub display_perl_pod_help
{
	my ( $buffer );

	display_pod_help($0);
	print "\nPress <Enter> to continue : ";
	$buffer = <STDIN>;

	return;
} # end of display_perl_pod_help

######################################################################
#
# Function  : display_help_info
#
# Purpose   : Display Perl POD help information
#
# Inputs    : (none)
#
# Output    : help information
#
# Returns   : nothing
#
# Example   : display_help_info();
#
# Notes     : (none)
#
######################################################################

sub display_help_info
{
	my ( $buffer );

	unless ( open(PIPE,"|$options{'p'}") ) {
		die("open of pipe to '$options{'p'}' failed : $!\n");
	} # UNLESS
	print PIPE "$help_info\n";
	close PIPE;
	print "\nPress <Enter> to continue : ";
	$buffer = <STDIN>;

	return;
} # end of display_help_info

######################################################################
#
# Function  : ext_summary
#
# Purpose   : Display a summary of filename extensions
#
# Inputs    : (none)
#
# Output    : Summary of filename extensions
#
# Returns   : nothing
#
# Example   : ext_summary();
#
# Notes     : (none)
#
######################################################################

sub ext_summary
{
	my ( $ref , %extensions , $num_no_ext , $basename , @list , $ext , $ref2 );
	my ( $count , @count , @bytes , $buffer );

	$num_no_ext = 0;
	%extensions = ();
	foreach my $name ( @member_names ) {
		$ref = $members{$name};
		$basename = basename($name);
		if ( $basename =~ m/\./ ) {
			@list = split(/\./,$basename);
			$ext = pop @list;
			$ref2 = $extensions{$ext};
			if ( defined $ref2 ) {
				$extensions{$ext}{'count'} += 1;
				$extensions{$ext}{'bytes'} += $ref->{'size'};
			} # IF
			else {
				$extensions{$ext}{'count'} = 1;
				$extensions{$ext}{'bytes'} = $ref->{'size'};
			} # ELSE
		} # IF
		else {
			$num_no_ext += 1;
		} # ELSE
	} # FOREACH
	print "\n${num_no_ext} entries with no extension\n";
	@list = sort { lc $a cmp lc $b } keys %extensions;
	$count = scalar @list;
	print "${count} different extensions detected\n";
	@count = map { $extensions{$_}{'count'} } @list;
	if ( $options{'m'} ) {
		@bytes = map { format_megabytes($extensions{$_}{'bytes'},1) } @list;
	} # IF
	else {
		@bytes = map { comma_format($extensions{$_}{'bytes'}) } @list;
	} # ELSE
	unless ( open(PIPE,"|$options{'p'}") ) {
		die("open of pipe to '$options{'p'}' failed : $!\n");
	} # UNLESS
	print_lists([ \@list , \@count , \@bytes ],[ "Ext" , "Count" , "Bytes" ],"=",\*PIPE);
	close PIPE;
	print "\nPress <Enter> to continue : ";
	$buffer = <STDIN>;

	return;
} # end of ext_summary

######################################################################
#
# Function  : no_extension
#
# Purpose   : Display a list of entries with no filename extension
#
# Inputs    : (none)
#
# Output    : List of entries with no filename extension
#
# Returns   : nothing
#
# Example   : no_extension();
#
# Notes     : (none)
#
######################################################################

sub no_extension
{
	my ( $ref , $basename , @list , $count , $maxlen , $size );

	$count = 0;
	@list = ();
	foreach my $name ( @member_names ) {
		$ref = $members{$name};
		$basename = basename($name);
		if ( $basename !~ m/\./ ) {
			$count += 1;
			push @list,$name;
		} # IF
	} # FOREACH
	print "count = $count\n";
	if ( $count == 0 ) {
		print "All the members filenames have an extension.\n";
	} # IF
	else {
		$maxlen = (reverse sort { $a <=> $b} map { length $_ } @list)[0];
		unless ( open(PIPE,"|$options{'p'}") ) {
			die("open of pipe to '$options{'p'}' failed : $!\n");
		} # UNLESS
		foreach my $name ( @list ) {
			$ref = $members{$name};
			if ( $options{'m'} ) {
				$size = format_megabytes($ref->{'size'},1);
			} # IF
			else {
				$size = comma_format($ref->{'size'});
			} # ELSE
			printf PIPE "%-${longest_name}.${longest_name}s : %12s %s\n",$name,$size,$ref->{'date'};
		} # FOREACH
		close PIPE;
	} # ELSE

	return;
} # end of no_extension

######################################################################
#
# Function  : parse_parameters
#
# Purpose   : Parse command parameters
#
# Inputs    : $_[0] - buffer to be parsed
#             $_[1] - reference to array to receive parsed parameters
#             $_[2] - reference to array to receive quoting indicators
#                     ( 0 = no quote , 1 = single quote , 2 = double quote)
#             $_[3] - reference to array to receive optional flag parameters
#
# Output    : (none)
#
# Returns   : parameters count
#
# Example   : $count = parse_parameters($buffer,\@parms,\@quoted,\@flags);
#
# Notes     : (none)
#
######################################################################

sub parse_parameters
{
	my ( $buffer , $ref_parms , $ref_quoted , $ref_flags ) = @_;
	my ( $buffer2 , $count , $buffer3 , $quote , $string , $index );
	my ( @parms );

	$buffer2 = $buffer;
	@$ref_parms = ();
	@$ref_quoted = ();
	@$ref_flags = ();
	$count = 0;
	@parms = ();
	while ( $buffer2 =~ m/\S/ ) {
		$buffer2 =~ m/^\s*/;
		$buffer3 = $'; # data after whitespace
		if ( $buffer3 =~ m/^(['"])/ ) {
			$quote = $1;
			push @$ref_quoted,$quoted{$quote};
			if ( $buffer3 =~ m/^${quote}(.*?)${quote}/ ) {
				$buffer2 = $';
				$string = $1;
				push @$ref_parms,$string;
				push @parms,$string;
			} # IF
			else {
				$string = $buffer3;
				$string =~ s/^${quote}//g;
				$buffer2 = "";
				push @$ref_parms,$string;
				push @parms,$string;
			} # ELSE
		} # IF
		else {
			$buffer3 =~ m/^(\S+)/;
			$buffer2 = $';
			push @$ref_parms,$&;
			push @$ref_quoted,0;
			push @parms,$&;
		} # ELSE
	} # WHILE
	$count = scalar @$ref_parms;
	for ( $index = 0 ; $index < $count ; ++$index ) {
		unless ( '-' eq substr($parms[$index],0,1) ) {
			last;
		} # UNLESS
		push @$ref_flags,$parms[$index];
		shift @$ref_parms;
	} # FOR
	$count = scalar @$ref_parms;

	return $count;
} # end of parse_parameters

######################################################################
#
# Function  : display_menu
#
# Purpose   : Display commands menu
#
# Inputs    : (none)
#
# Output    : Commands Menu
#
# Returns   : nothing
#
# Example   : display_menu();
#
# Notes     : (none)
#
######################################################################

sub display_menu
{
	my ( $index , $ref , @list );

	printf "\n%2d - %s\n",0,"Exit";
	for ( $index = 1 ; $index <= $num_menu_entries ; ++$index ) {
		$ref = $main_menu[$index-1];
		@list = @$ref;
		printf "%2d - %s\n",$index,$list[0];
	} # FOR

	return;
} # end of display_menu

######################################################################
#
# Function  : display_history
#
# Purpose   : Display commands history
#
# Inputs    : (none)
#
# Output    : Commands history
#
# Returns   : nothing
#
# Example   : display_history();
#
# Notes     : (none)
#
######################################################################

sub display_history
{
	my ( $index , $ref , @list , $td );

	print "\nCommands History\n\n";
	for ( $index = 0 ; $index <= $#history ; ++$index ) {
		$td = format_time_date($times[$index],"hms");
		printf "%2d - %s - %s\n",1+$index,$td,$history[$index];
	} # FOR

	return;
} # end of display_history

######################################################################
#
# Function  : find_member_by_basename
#
# Purpose   : Find member by the path basename
#
# Inputs    : (none)
#
# Output    : Matching member names
#
# Returns   : nothing
#
# Example   : find_member_by_basename();
#
# Notes     : (none)
#
######################################################################

sub find_member_by_basename
{
	my ( $index , $ref , $count , $longest_name , @matches );

	if ( $num_parameters > 0 ) {
		$count = 0;
		@matches = ();
		for ( $index = 0 ; $index <= $#basenames ; ++$index ) {
			if ( $basenames[$index] =~ m/${parameters[0]}/i ) {
				$count += 1;
				push @matches, $member_names[$index];
			} # IF
		} # FOR
		if ( $count == 0 ) {
			print "No matches found for '$parameters[0]\n";
		} # IF
		else {
			unless ( open(PIPE,"|$options{'p'}") ) {
				die("open of pipe to '$options{'p'}' failed : $!\n");
			} # UNLESS
			$longest_name = (sort { $b <=> $a} map { length $_ } @matches)[0];
			foreach my $name ( @matches ) {
				$ref = $members{$name};
				printf PIPE "%-${longest_name}.${longest_name}s : %10d %s\n",$name,$ref->{'size'},$ref->{'date'};
			} # FOREACH
			close PIPE;
		} # ELSE
	} # IF
	else {
		display_error("Required file name was not specified\n");
	} # ELSE

	return;
} # end of find_member_by_basename

######################################################################
#
# Function  : find_member_by_path
#
# Purpose   : Find member by the complete path
#
# Inputs    : (none)
#
# Output    : Matching member names
#
# Returns   : nothing
#
# Example   : find_member_by_path();
#
# Notes     : (none)
#
######################################################################

sub find_member_by_path
{
	my ( $index , $ref , $count , $longest_name , @matches );

	if ( $num_parameters > 0 ) {
		$count = 0;
		@matches = ();
		for ( $index = 0 ; $index <= $#basenames ; ++$index ) {
			if ( $member_names[$index] =~ m/${parameters[0]}/i ) {
				$count += 1;
				push @matches, $member_names[$index];
			} # IF
		} # FOR
		if ( $count == 0 ) {
			print "No matches found for '$parameters[0]\n";
		} # IF
		else {
			unless ( open(PIPE,"|$options{'p'}") ) {
				die("open of pipe to '$options{'p'}' failed : $!\n");
			} # UNLESS
			$longest_name = (sort { $b <=> $a} map { length $_ } @matches)[0];
			foreach my $name ( @matches ) {
				$ref = $members{$name};
				printf PIPE "%-${longest_name}.${longest_name}s : %10d %s\n",$name,$ref->{'size'},$ref->{'date'};
			} # FOREACH
			close PIPE;
		} # ELSE
	} # IF
	else {
		display_error("Required file name was not specified\n");
	} # ELSE

	return;
} # end of find_member_by_path

######################################################################
#
# Function  : list_names_only
#
# Purpose   : List only the member names
#
# Inputs    : (none)
#
# Output    : member names
#
# Returns   : nothing
#
# Example   : list_names_only();
#
# Notes     : (none)
#
######################################################################

sub list_names_only
{
	my ( $index , $ref , @list , @indices , @extra , $sort );

	unless ( open(PIPE,"|$options{'p'}") ) {
		die("open of pipe to '$options{'p'}' failed : $!\n");
	} # UNLESS
	@list = @member_names;
	if ( $sorting > 0 ) {
		if ( $options{'t'} ) {
			$sort = 'clock';
		} # IF
		else {
			$sort = 'size';
		} # ELSE
		@extra = ();
		foreach my $name ( @member_names ) {
			$ref = $members{$name};
			push @extra,$ref->{$sort};
		} # FOREACH
		@indices = sort { $extra[$a] <=> $extra[$b] } (0 .. $#member_names);
		@list = @list[@indices];
	} # IF
	if ( $options{'r'} ) {
		@list = reverse @list;
	} # IF

	print PIPE join("\n",@list),"\n";
	close PIPE;

	return;
} # end of list_names_only

######################################################################
#
# Function  : list_compact_names_only
#
# Purpose   : List only the member names
#
# Inputs    : (none)
#
# Output    : member names
#
# Returns   : nothing
#
# Example   : list_compact_names_only();
#
# Notes     : (none)
#
######################################################################

sub list_compact_names_only
{
	my ( $index , $ref , @list , @indices , @extra , $sort );

	unless ( open(PIPE,"|$options{'p'}") ) {
		die("open of pipe to '$options{'p'}' failed : $!\n");
	} # UNLESS
	@list = @member_names;
	if ( $sorting > 0 ) {
		if ( $options{'t'} ) {
			$sort = 'clock';
		} # IF
		else {
			$sort = 'size';
		} # ELSE
		@extra = ();
		foreach my $name ( @member_names ) {
			$ref = $members{$name};
			push @extra,$ref->{$sort};
		} # FOREACH
		@indices = sort { $extra[$a] <=> $extra[$b] } (0 .. $#member_names);
		@list = @list[@indices];
	} # IF
	if ( $options{'r'} ) {
		@list = reverse @list;
	} # IF

	list_columns_style(\@list,$console_info{"columns"},undef,\*PIPE);

	close PIPE;

	return;
} # end of list_compact_names_only

######################################################################
#
# Function  : list_members_info
#
# Purpose   : List members info
#
# Inputs    : (none)
#
# Output    : members info
#
# Returns   : nothing
#
# Example   : list_members_info();
#
# Notes     : (none)
#
######################################################################

sub list_members_info
{
	my ( $index , $ref , @list , @indices , @extra , $sort , $size );

	unless ( open(PIPE,"|$options{'p'}") ) {
		die("open of pipe to '$options{'p'}' failed : $!\n");
	} # UNLESS
	@list = @member_names;
	if ( $sorting > 0 ) {
		if ( $options{'t'} ) {
			$sort = 'clock';
		} # IF
		else {
			$sort = 'size';
		} # ELSE
		@extra = ();
		foreach my $name ( @member_names ) {
			$ref = $members{$name};
			push @extra,$ref->{$sort};
		} # FOREACH
		@indices = sort { $extra[$a] <=> $extra[$b] } (0 .. $#member_names);
		@list = @list[@indices];
	} # IF
	if ( $options{'r'} ) {
		@list = reverse @list;
	} # IF

	foreach my $name ( @list ) {
		$ref = $members{$name};
		if ( $options{'m'} ) {
			$size = format_megabytes($ref->{'size'},1);
		} # IF
		else {
			$size = comma_format($ref->{'size'});
		} # ELSE
		printf PIPE "%-${longest_name}.${longest_name}s : %12s %s\n",$name,$size,$ref->{'date'};
	} # FOREACH
	close PIPE;

	return;
} # end of list_members_info

######################################################################
#
# Function  : edit_member
#
# Purpose   : List contents of a member
#
# Inputs    : (none)
#
# Output    : member contents
#
# Returns   : nothing
#
# Example   : edit_member();
#
# Notes     : (none)
#
######################################################################

sub edit_member
{
	my ( $ref , $content , $status , $path , $fh );

	if ( $num_parameters > 0 ) {
		$ref = $members{$parameters[0]};
		if ( defined $ref ) {
			($content, $status) = $zip->contents( $parameters[0] );
			unless ( defined $tempdir ) {
				print "Could not determine TEMPORARY files directory\n";
			} # UNLESS
			else {
      			($fh, $path) = tempfile();
				if ( defined $fh ) {
					print $fh "$content";
					close $fh;
					list_file_info_full($path,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
					system("$options{'e'} \"$path\"");
					unlink $path;
				} # IF
				else {
					print "Could not create temporary file : $!\n";
				} # ELSE
			} # ELSE
		} # IF
		else {
			print "'$parameters[0]' is not a member in '$zipfile'\n";
		} # ELSE
	} # IF
	else {
		display_error("Required member name was not specified\n");
	} # ELSE

	return;
} # end of edit_member

######################################################################
#
# Function  : hex_member_dump
#
# Purpose   : Generate a hex/character dump of the contents of a member
#
# Inputs    : (none)
#
# Output    : member contents
#
# Returns   : nothing
#
# Example   : hex_member_dump();
#
# Notes     : (none)
#
######################################################################

sub hex_member_dump
{
	my ( $ref , $content , $status , $count , $buffer , $offset , $width , $hex );

	if ( $num_parameters > 0 ) {
		$ref = $members{$parameters[0]};
		if ( defined $ref ) {
			($content, $status) = $zip->contents( $parameters[0] );
			unless ( open(PIPE,"|$options{'p'}") ) {
				die("open of pipe to '$options{'p'}' failed : $!\n");
			} # UNLESS
			$width = 16;
			for ( $offset = 0 ; 0 < length $content ; $offset += $width ) {
				if ( $width >= length $content ) {
					$hex = hexdump($content,$offset);
					$content = "";
				} # IF
				else {
					$buffer = substr($content,0,$width);
					$hex = hexdump($buffer,$offset);
					$content = substr($content,$width);
				} # ELSE
				print PIPE "$hex";
			} # WHILE
			print PIPE "\n";
			close PIPE;
		} # IF
		else {
			print "'$parameters[0]' is not a member in '$zipfile'\n";
		} # ELSE
	} # IF
	else {
		display_error("Required member name was not specified\n");
	} # ELSE

	return;
} # end of hex_member_dump

######################################################################
#
# Function  : list_member_contents_with_line_numbers
#
# Purpose   : List contents of a member with line numbers
#
# Inputs    : (none)
#
# Output    : member contents
#
# Returns   : nothing
#
# Example   : list_member_contents_with_line_numbers();
#
# Notes     : (none)
#
######################################################################

sub list_member_contents_with_line_numbers
{
	my ( $ref , @lines , $content , $status , $index );

	if ( $num_parameters > 0 ) {
		$ref = $members{$parameters[0]};
		if ( defined $ref ) {
			($content, $status) = $zip->contents( $parameters[0] );
			@lines = split(/\n/,$content);
			unless ( open(PIPE,"|$options{'p'}") ) {
				die("open of pipe to '$options{'p'}' failed : $!\n");
			} # UNLESS
			for ( $index = 0 ; $index <= $#lines ; ++$index ) {
				if ( $options{'n'} ) {
					printf PIPE "%5d\t",1+$index;
				} # IF
				print PIPE "$lines[$index]\n";
			} # FOR
			close PIPE;
		} # IF
		else {
			print "'$parameters[0]' is not a member in '$zipfile'\n";
		} # ELSE
	} # IF
	else {
		display_error("Required member name was not specified\n");
	} # ELSE

	return;
} # end of list_member_contents_with_line_numbers

######################################################################
#
# Function  : grep_member
#
# Purpose   : Search member contents for lines matching a pattern
#
# Inputs    : (none)
#
# Output    : matching member content lines
#
# Returns   : nothing
#
# Example   : grep_member();
#
# Notes     : (none)
#
######################################################################

sub grep_member
{
	my ( $ref , @lines , $content , $status , $index , $name , $pattern );
	my ( $count , $match );

	if ( $num_parameters > 1 ) {
		$name = shift @parameters;
		$pattern = join("|",@parameters);
		$ref = $members{$name};
		if ( defined $ref ) {
			($content, $status) = $zip->contents( $name );
			@lines = split(/\n/,$content);
			unless ( open(PIPE,"|$options{'p'}") ) {
				die("open of pipe to '$options{'p'}' failed : $!\n");
			} # UNLESS
			$count = 0;
			for ( $index = 0 ; $index <= $#lines ; ++$index ) {
				if ( ($options{'i'} == 0 && $lines[$index] =~ m/${pattern}/) ||
							($options{'i'} && $lines[$index] =~ m/${pattern}/i) ) {
					$count += 1;
					if ( $options{'n'} ) {
						printf PIPE "%5d\t",1+$index;
					} # IF
					print PIPE "$lines[$index]\n";
				} # IF
			} # FOR
			if ( $count == 0 ) {
				print PIPE "No matches to '$pattern' found in '$name'\n";
			} # IF
			close PIPE;
		} # IF
		else {
			print "'$name' is not a member in '$zipfile'\n";
		} # ELSE
	} # IF
	else {
		display_error("Required parameters were not specified\n");
	} # ELSE

	return;
} # end of grep_member

######################################################################
#
# Function  : head_member
#
# Purpose   : List the first few lines of a member's content
#
# Inputs    : (none)
#
# Output    : member contents
#
# Returns   : nothing
#
# Example   : head_member();
#
# Notes     : (none)
#
######################################################################

sub head_member
{
	my ( $ref , @lines , $content , $status , $count );

	if ( $num_parameters > 0 ) {
		$ref = $members{$parameters[0]};
		if ( defined $ref ) {
			($content, $status) = $zip->contents( $parameters[0] );
			@lines = split(/\n/,$content);
			unless ( open(PIPE,"|$options{'p'}") ) {
				die("open of pipe to '$options{'p'}' failed : $!\n");
			} # UNLESS
			$count = scalar @lines;
			if ( $count > $options{"H"} ) {
				@lines = @lines[0 .. $options{"H"}-1];
			} # IF
			print PIPE join("\n",map { "$_ $lines[$_-1]" } (1 .. scalar @lines)),"\n";
			close PIPE;
		} # IF
		else {
			print "'$parameters[0]' is not a member in '$zipfile'\n";
		} # ELSE
	} # IF
	else {
		display_error("Required member name was not specified\n");
	} # ELSE

	return;
} # end of head_member

######################################################################
#
# Function  : save_member
#
# Purpose   : Save the contents of a member to disk
#
# Inputs    : (none)
#
# Output    : appropriate diagnostics
#
# Returns   : nothing
#
# Example   : save_member();
#
# Notes     : (none)
#
######################################################################

sub save_member
{
	my ( $ref , @lines , $content , $status , $basename , $count );

	if ( $num_parameters > 0 ) {
		$ref = $members{$parameters[0]};
		if ( defined $ref ) {
			($content, $status) = $zip->contents( $parameters[0] );
			$basename = basename($parameters[0]);
			if ( $options{'o'} == 0 && -e $basename ) {
				print "File '$basename' already exists. Save request ignored.\n";
			} # IF
			else {
				unless ( open(MEMBER,">$basename") ) {
					die("open failed for '$basename : $!\n");
				} # UNLESS
				binmode MEMBER;
				print MEMBER "$content";
				close MEMBER;
				list_file_info_full($basename,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
			} # ELSE
		} # IF
		else {
			print "'$parameters[0]' is not a member in '$zipfile'\n";
		} # ELSE
	} # IF
	else {
		display_error("Required member name was not specified\n");
	} # ELSE

	return;
} # end of save_member

######################################################################
#
# Function  : MAIN
#
# Purpose   : A shell for processing a ZIP file
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : zipshell.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $errmsg , $choice , $ref , @list );

	$status = getopts("dhstrH:T:p:moe:ni",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dhstrmon] [-e editor] [-H head_size] [-T tail_size] [-p pager_command] zipfile\n");
	} # UNLESS
	$sorting = $options{'s'} + $options{'t'};
	if ( $sorting > 1 ) {
		die("Options 's' and 't' are mutually exclusive\n");
	} # IF
	$toggle_maxlen = (reverse sort { $a <=> $b} map { length $_ } @toggle_options)[0];

	$CONSOLE = new Win32::Console();
	unless ( defined $CONSOLE ) {
		die("Can't create console object : $!\n");
		exit 1;
	} # UNLESS
	@console_info = $CONSOLE->Info();
	%console_info = (
		"columns" => $console_info[0] ,
		"rows" => $console_info[1] ,
		"max_columns" => $console_info[9] ,
		"max_rows" => $console_info[10]
	);
	$tempdir = $ENV{"TEMP"};
	unless ( defined $tempdir ) {
		$tempdir = $ENV{"TMP"};
	} # UNLESS
	display_smooth_multi_line_message_box(0,@copyright);

	$zipfile = shift @ARGV;
	$zip = find_zip_file_members($zipfile,\%members,\@member_names,\$errmsg);
	unless ( defined $zip ) {
		die("$errmsg\n");
	} # IF
	$num_members = scalar @member_names;
	$longest_name = (sort { $b <=> $a} map { length $_ } @member_names)[0];
	foreach my $path ( @member_names ) {
		push @basenames,basename($path);
	} # FOREACH

	print "\nFound ${num_members} members in '$zipfile'\n\n";
	while ( 1 ) {
		display_menu();
		print "\nEnter your selection (1 - $num_menu_entries) : ";
		$command = <STDIN>;
		chomp $command;
		unless ( $command =~ m/\S/ ) {
			next;
		} # UNLESS
		unless ( $command =~ m/^\d+$|^\d+\s/ ) {
			next;
		} # UNLESS
		$choice = $&;
		if ( $choice == 0 ) {
			last;
		} # IF
		if ( $choice > $num_menu_entries ) {
			next;
		} # IF
		$parameters = $';  # save the POSTMATCH for parameter parsing
		$num_parameters = parse_parameters($parameters,\@parameters,\@quoted,\@flags);

		$ref = $main_menu[$choice-1];
		@list = @$ref;
		$list[1]->();
		push @history,$list[0];
		push @times,time;
	} # WHILE
	display_history();

	exit 0;
} # end of MAIN
__END__
=head1 NAME

zipshell.pl - A shell for processing a ZIP file

=head1 SYNOPSIS

zipshell.pl [-hdstrmoni] [-e editor] [-H head_size] [-T tail_size] [-p pager_command] zipfile

=head1 DESCRIPTION

A shell for processing a ZIP file

=head1 PARAMETERS

  zipfile - name of ZIP archive file or directory

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -s - sort by size in ascending order
  -t - sort by time/date in ascending order
  -r - reverse sorting order
  -H head_size - lines count for "head" command
  -T tail_size - lines count for "tail" command
  -p pager_command - command to be used for paging
  -m - when displaying member size display it in terms of TB/GB/MB/KB
  -o - when saving members to disk allow overwrite of existing files
  -e editor - program to be used to edit files
  -n - display line numbers when displaying lines of text
  -i - when searching member contents use case insensitive matching

=head1 EXAMPLES

zipshell.pl zip1.zip

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
