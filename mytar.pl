#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : mytar2.pl
#
# Author    : Barry Kimelman
#
# Created   : March 18, 2020
#
# Purpose   : Process TAR files.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Fcntl;
use File::stat;
use File::Basename;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;
use mytar;

require "time_date.pl";
require "format_mode.pl";
require "expand_tabs.pl";
require "list_file_info.pl";
require "display_pod_help.pl";
require "list_columns_style.pl";

my %options = ( "d" => 0 , "h" => 0 , "C" => 0 , "w" => 100 );
my $pager = "more";
my @matched_names = ();
my $exit_flag = 0;

my %cmds = (
	"l" => [ \&cmd_list_member_attributes , 'list member attributes (ala ls)' ],
	"c" => [ \&cmd_list_member_contents , 'list member contents (ala cat)' ],
	"y" => [ \&cmd_page_member_contents , 'list member contents (ala less)' ],
	"X" => [ \&cmd_expand_member_content_tabs , 'list member contents with expanded tabs (ala expand)' ],
	"w" => [ \&cmd_count_lines , 'count lines and characters (ala wc -lc)' ],
	"p" => [ \&cmd_print_member_contents , 'print member contents (only works on Windows)' ],
	"n" => [ \&cmd_list_member_contents_with_line_numbers , 'list member contents with line numbers(ala cat -n)' ],
	"e" => [ \&cmd_search_member_contents , 'search member contents (ala egrep)' ],
	"v" => [ \&cmd_search_member_contents_not_found , 'search members for non inclusion of patterns' ],
	"a" => [ \&cmd_search_member_contents_multiple , 'search member contents for multiple patterns (ala egrep)' ],
	"s" => [ \&cmd_save_member_contents , 'save member contents to disk' ],
	"S" => [ \&cmd_save_member_contents_with_overwrite , 'save member contents to disk (with overwrite)' ],
	"B" => [ \&cmd_save_member_contents_with_overwrite_basename , 'save member contents to disk by basename (with overwrite)' ],
	"m" => [ \&cmd_list_member_names , 'list all member names' ],
	"C" => [ \&cmd_list_member_names_compact , 'list all member names using a compact column style' ],
	"M" => [ \&cmd_list_member_names_with_attributes , 'list all member names with attributes' ],
	"t" => [ \&cmd_list_member_names_with_attributes_time_sorted , 'list member names with attributes sorted by time' ],
	"T" => [ \&cmd_list_member_names_with_attributes_time_sorted_desc , 'list member names with attributes sorted by time in descending order' ],
	"h" => [ \&cmd_summary , 'brief commnds summary' ],
	"?" => [ \&cmd_info , 'general information' ],
	"H" => [ \&cmd_help , 'detailed command help' ],
	"P" => [ \&cmd_set_pager , 'activate/deactivate paging' ],
	"x" => [ \&cmd_not_found , 'list names of members that do not include a pattern' ],
	"W" => [ \&cmd_notopics , 'list commands without detailed help' ],
);

my $general_help_info =<<GENERAL;
The 'h' command will display a summary of available commands.

The 'H' command will display detailed info for the specified command.

When specifying a member name you can enter a '{' immediately followed by an integer.
This represents an "index" into the list of member names from the most recent command
that matched member names.
GENERAL

my $helpsep = "=====";
my %helptext;
my $helptext = <<HELPTEXT;
l
This command will list member attributes similar to "ls -l" command output

${helpsep}
c
This command will list the contents of an archive member in the same style
as the "cat" command
${helpsep}
p
This command will print member contents to the system default printer
(this is only works on Windows)
${helpsep}
n
This command will list the contents of an archive member with line numbers.
In the same style as the "cat -n" command
${helpsep}
e
This command will search member contents for a pattern (ala egrep).
If the 1st character of the member name is a "!" the the remaining
portion of the member name is treated as a regular expressionb to be
matched against the entire list of archive member names.
${helpsep}
s
This command will save the contents of a member to disk.
Overwrite of an existing file will be decided by asking the user.
${helpsep}
S
This command will save the contents of a member to disk.
Overwrite of an existing file will not be allowed.
${helpsep}
q
Quit processing.
${helpsep}
m
This command will list the names of the archive members
${helpsep}
M
This command will list the names of the archive members and their attributes
(similar to "ls -l" command output)
${helpsep}
h
Display a brief commands summary
${helpsep}
H
Display detailed command help.
${helpsep}
t
List archive member with attributes sorted by time in ascending order
(similar to "ls -lt" command)
${helpsep}
T
List archive member with attributes sorted by time in descending order
(similar to "ls -ltr" command)
HELPTEXT

use constant TBLOCK_SIZE => 512;  # length of TAR header and data blocks
use constant TNAMLEN => 100;      # max length for TAR file names
use constant TMODLEN => 8;        # length of mode field
use constant TUIDLEN => 8;        # length of uid field
use constant TGIDLEN => 8;        # length of gid field
use constant TSIZLEN => 12;       # length of size field
use constant TTIMLEN => 12;       # length of modification time field

use constant TCRCLEN => 8;        # length of header checksum field

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
# Function  : cmd_info
#
# Purpose   : Display general info
#
# Inputs    : $_[0] - name of tar file
#             $_[1] - ref to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_info($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_info
{
	my ( $tarfile , $ref_parms ) = @_;

	print "$general_help_info\n";

	return;
} # end of cmd_info

######################################################################
#
# Function  : list_member_attributes
#
# Purpose   : List the attributs of a single TAR file member
#
# Inputs    : $_[0] - reference to hash of member attributes
#             $_[1] - member name
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : list_member_attributes($ref_attr,$member_name);
#
# Notes     : (none)
#
######################################################################

sub list_member_attributes
{
	my ( $ref_member_attributes , $member_name ) = @_;
	my ( $info );

	$info = generate_member_attributes($ref_member_attributes,$member_name);
	print "$info\n";

	return;
} # end of list_member_attributes

######################################################################
#
# Function  : generate_member_attributes
#
# Purpose   : Generate the attributs of a single TAR file member
#
# Inputs    : $_[0] - reference to hash of member attributes
#             $_[1] - member name
#
# Output    : List of TAR file members
#
# Returns   : string containing the attributes
#
# Example   : $info = generate_member_attributes($ref_attr,$member_name);
#
# Notes     : (none)
#
######################################################################

sub generate_member_attributes
{
	my ( $ref_member_attributes , $member_name ) = @_;
	my ( $info , $modtime , $buffer , $perms , $file_mode );

	$modtime = $ref_member_attributes->{member_modtime};
	$modtime =~ s/\0//g;
	$modtime = oct($modtime);
	$buffer = format_time_date($modtime,"");
	$file_mode = $ref_member_attributes->{member_mode};

	$perms = format_mode($file_mode);

	$info = sprintf "%08o %s %8s %8s %10d ",$file_mode,$perms,
				$ref_member_attributes->{member_uname},
				$ref_member_attributes->{member_gname},
				$ref_member_attributes->{member_size_decimal};
	$info .= "$buffer $member_name";

	return $info;
} # end of generate_member_attributes

######################################################################
#
# Function  : cmd_list_member_attributes
#
# Purpose   : List attributes of a TAR file member.
#
# Inputs    : $_[0] - name of tarfile
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_list_member_attributes($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_attributes
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $ref_member_attributes , @parms , $num_parms );
	my ( $num_names , $name_pattern );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$name_pattern = shift @parms;
	} # IF
	else {
		print "Enter member name pattern ==> ";
		$name_pattern = <STDIN>;
		chomp $name_pattern;
	} # ELSE

	@matched_names = grep /${name_pattern}/i,@mytar::members_names;
	$num_names = scalar @matched_names;
	if ( $num_names < 1 ) {
		print "\nNo member names matched '$name_pattern'\n\n";
		return;
	} # IF

	foreach my $member_name ( @matched_names ) {
		$ref_member_attributes = $mytar::members_info{$member_name};
		unless ( defined $ref_member_attributes ) {
			print "\n$member_name is not a member of $tarfile\n";
		} # UNLESS
		else {
			list_member_attributes($ref_member_attributes,$member_name);
		} # ELSE
	} # FOREACH

	return;
} # end of cmd_list_member_attributes

######################################################################
#
# Function  : cmd_summary
#
# Purpose   : Display a summary of available commands
#
# Inputs    : $_[0] - name of tar file
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_summary($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_summary
{
	my ( $tarfile ) = @_;
	my ( $ref , @array );

	foreach my $key ( sort { lc $a cmp lc $b } keys %cmds ) {
		$ref = $cmds{$key};
		@array = @$ref;
		print "$key - $array[1]\n";
	} # FOREACH

	return;
} # end of cmd_summary

######################################################################
#
# Function  : cmd_notopics
#
# Purpose   : Display a list of commands with no help.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : cmd_notopics();
#
# Notes     : (none)
#
######################################################################

sub cmd_notopics
{
	my ( $count , $ref , @array );

	$count = 0;
	foreach my $cmd ( sort { lc $a cmp lc $b } keys %cmds ) {
		unless ( exists $helptext{$cmd} ) {
			if ( ++$count == 1 ) {
				print "\nNo help exists for the following commands :\n";
			} # IF
			$ref = $cmds{$cmd};
			@array = @$ref;
			print "$cmd -- $array[1]\n";
		} # UNLESS
	} # FOREACH
	if ( $count == 0 ) {
		print "\nAll the commands have help text.\n";
	} # IF
	print "\n";

	return;
} # end of cmd_notopics

######################################################################
#
# Function  : cmd_not_found
#
# Purpose   : List the names of members that do not contain a pattern
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_not_found($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_not_found
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @parms , $num_parms , $pattern , $name_pattern , @nameslist , $num_names );
	my ( $file_size , $buffer , @lines , $num_lines , $num_not_found , @found );
	my ( $errmsg );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	if ( $num_parms > 0 ) {
		$pattern = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter pattern ==> ";
		$pattern = <STDIN>;
		chomp $pattern;
	} # ELSE

	if ( $num_parms > 0 ) {
		$name_pattern = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter names pattern ==> ";
		$name_pattern = <STDIN>;
		chomp $name_pattern;
	} # ELSE
	@nameslist = grep /${name_pattern}/i,@mytar::members_names;
	$num_names = scalar @nameslist;
	if ( $num_names < 1 ) {
		print "\nNo member names matched '$name_pattern'\n\n";
		return;
	} # IF

	$num_not_found = 0;
	@found = ();
	foreach my $name ( @nameslist ) {
		$file_size = mytar::read_member_contents($tarfile,$name,\$buffer,\$errmsg);
		if ( $file_size < 0 ) {
			print "$errmsg\n";
			next;
		} # IF
		@lines = split(/\n/,$buffer);
		if ( $buffer =~ m/\n\n$/ ) {
			push @lines,"";
			$num_lines += 1;
		} # IF
		$num_lines = scalar @lines;
		unless ( 0 < grep /${pattern}/i,@lines ) {
			print "$name\n";
			$num_not_found += 1;
		} # UNLESS
		else {
			push @found,$name;
		} # ELSE
	} # FOREACH
	print "\n${num_not_found} of the ${num_names} searched members did not contain the specified pattern\n";

	return;
} # end of cmd_not_found

######################################################################
#
# Function  : cmd_set_pager
#
# Purpose   : Activate / deactivate paging
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_set_pager($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_set_pager
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @parms , $num_parms );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$pager = join(" ",@parms);
		print "\nPager now set to '$pager'\n";
	} # IF
	else {
		print "\nPaging is currently handled by '$pager'\n";
	} # ELSE

	return;
} # end of cmd_set_pager

######################################################################
#
# Function  : cmd_help
#
# Purpose   : Perform "help" command.
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : help info.
#
# Returns   : nothing
#
# Example   : cmd_help();
#
# Notes     : (none)
#
######################################################################

sub cmd_help
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @parms , $num_parms , $command );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$command = shift @parms;
	} # IF
	else {
		print "Enter command name ==> ";
		$command = <STDIN>;
		chomp $command;
	} # ELSE

	if ( exists $helptext{$command} ) {
		print "$helptext{$command}\n";
	} # IF
	else {
		print "No help information exists for '$command'\n";
	} # ELSE

	return;
} # end of cmd_help

######################################################################
#
# Function  : cmd_list_member_names_with_attributes_time_sorted_desc
#
# Purpose   : List member names and attributes sorted by time in descending order
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names_with_attributes_time_sorted_desc($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names_with_attributes_time_sorted_desc
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @parms , $num_parms , $name_pattern , $num_names );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms < 1 ) {
		@matched_names = @mytar::members_names;
	} # IF
	else {
		$name_pattern = $parms[0];
		@matched_names = grep /${name_pattern}/i,@mytar::members_names;
		$num_names = scalar @matched_names;
		if ( $num_names < 1 ) {
			print "\nNo member names matched '$name_pattern'\n\n";
			return;
		} # IF
	} # ELSE

	list_members(1,$tarfile,\@matched_names);

	return;
} # end of cmd_list_member_names_with_attributes_time_sorted_desc

######################################################################
#
# Function  : list_members
#
# Purpose   : List tar file members and their attributes
#
# Inputs    : $_[0] - time sort direction flag
#                     (0 --> ascending , nonzero --> descending)
#             $_[1] - name of TAR file
#             $_[2] - reference to array of member names
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : list_members(0,$tarfile,\@names);
#
# Notes     : (none)
#
######################################################################

sub list_members
{
	my ( $direction , $tarfile , $ref_names ) = @_;
	my ( $ref_member_attributes , $modtime , @indices , @modtimes , $name );
	my ( $data , @names );

	@modtimes = ();
	@names = @$ref_names;
	foreach my $member_name ( @names ) {
		$ref_member_attributes = $mytar::members_info{$member_name};
		$modtime = $ref_member_attributes->{member_modtime};
		$modtime =~ s/\0//g;
		$modtime = oct($modtime);
		push @modtimes,$modtime;
	} # FOREACH
	if ( $direction ) {
		@indices = sort { $modtimes[$b] <=> $modtimes[$a] } (0 .. $#modtimes);
	} # IF
	else {
		@indices = sort { $modtimes[$a] <=> $modtimes[$b] } (0 .. $#modtimes);
	} # ELSE

	$data = "";
	foreach my $index ( @indices ) {
		$name = $names[$index];
		$ref_member_attributes = $mytar::members_info{$name};
		$data .= generate_member_attributes($ref_member_attributes,$name) . "\n";
	} # FOREACH
	$data .= "\n${mytar::num_members} members in TAR file ${tarfile}\n\n";

	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS

	print PIPE "$data";
	close PIPE;

	return;
} # end of list_members

######################################################################
#
# Function  : cmd_list_member_names_with_attributes_time_sorted
#
# Purpose   : List member names and attributes sorted by time in ascending order
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names_with_attributes_time_sorted($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names_with_attributes_time_sorted
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @parms , $num_parms , $name_pattern , $num_names );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms < 1 ) {
		@matched_names = @mytar::members_names;
	} # IF
	else {
		$name_pattern = $parms[0];
		@matched_names = grep /${name_pattern}/i,@mytar::members_names;
		$num_names = scalar @matched_names;
		if ( $num_names < 1 ) {
			print "\nNo member names matched '$name_pattern'\n\n";
			return;
		} # IF
	} # ELSE

	list_members(0,$tarfile,\@matched_names);

	return;
} # end of cmd_list_member_names_with_attributes_time_sorted

######################################################################
#
# Function  : cmd_list_member_names_with_attributes
#
# Purpose   : List member names and attributes sorted by name
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - ref to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names_with_attributes($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names_with_attributes
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $ref_member_attributes , $info , $data , $tempfile , @parms , $num_parms );
	my ( $name_pattern , $count );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$name_pattern = shift @parms;
		@matched_names = grep /${name_pattern}/i,@mytar::members_names;
		$count = scalar @matched_names;
		if ( $count == 0 ) {
			print "No member names were matched by '$name_pattern'\n";
			return;
		} # IF
	} # IF
	else {
		@matched_names = @mytar::members_names;
		$count = scalar @matched_names;
	} # ELSE

	$data = "";
	foreach my $member_name ( @matched_names ) {
		$ref_member_attributes = $mytar::members_info{$member_name};

		$info = generate_member_attributes($ref_member_attributes,$member_name);
		$data .= $info . "\n";
	} # FOREACH

	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS
	print "$data\n${mytar::num_members} members in TAR file ${tarfile}\n\n";
	close PIPE;

	return;
} # end of cmd_list_member_names_with_attributes

######################################################################
#
# Function  : cmd_list_member_names_compact
#
# Purpose   : List member names in a compact column style
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - ref to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names_compact($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names_compact
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @numbers , @parms , $name_pattern , $count );
	my ( $num_parms );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$name_pattern = shift @parms;
		@matched_names = grep /${name_pattern}/i,@mytar::members_names;
		$count = scalar @matched_names;
		if ( $count == 0 ) {
			print "No member names were matched by '$name_pattern'\n";
			return;
		} # IF
	} # IF
	else {
		@matched_names = @mytar::members_names;
		$count = scalar @matched_names;
	} # ELSE

	@numbers = ( map { sprintf "%4d",$_} (1 .. $count) );
	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS

	list_columns_style(\@matched_names,$options{'w'},"Member Names",\*PIPE);
	close PIPE;

	return;
} # end of cmd_list_member_names_compact

######################################################################
#
# Function  : cmd_list_member_names
#
# Purpose   : List member names
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - ref to array of parameters
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @numbers , @parms , $name_pattern , $count );
	my ( $num_parms );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$name_pattern = shift @parms;
		@matched_names = grep /${name_pattern}/i,@mytar::members_names;
		$count = scalar @matched_names;
		if ( $count == 0 ) {
			print "No member names were matched by '$name_pattern'\n";
			return;
		} # IF
	} # IF
	else {
		@matched_names = @mytar::members_names;
		$count = scalar @matched_names;
	} # ELSE

	@numbers = ( map { sprintf "%4d",$_} (1 .. $count) );
	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS

	print PIPE join("\n", map { "($numbers[$_]) $matched_names[$_]" } (0 .. $#matched_names)),"\n";
	close PIPE;

	return;
} # end of cmd_list_member_names

######################################################################
#
# Function  : cmd_save_member_contents_with_overwrite_basename
#
# Purpose   : Process a "save member by basename" command.
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : cmd_save_member_contents_with_overwrite_basename($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_save_member_contents_with_overwrite_basename
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $ref_member_attributes , @parms , $num_parms , $buffer );
	my ( $member_size , $user_reply , $member_base_name , $errmsg );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	$member_base_name = basename($member_name);

	$ref_member_attributes = $mytar::members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		print "$member_name is not a member of $tarfile\n";
		return;
	} # UNLESS

	$member_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $member_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF
	if ( -e $member_base_name ) {
		print "\nFile $member_base_name already exists , do you want to overwrite it ? (y/n) ";
		$user_reply = <STDIN>;
		$user_reply =~ s/^\s+//g;
		chomp $user_reply;
		unless ( $user_reply =~ m/^yes|^y/i ) {
			print "Request aborted at user's request.\n";
			return;
		} # UNLESS
	} # If
	unless ( open(OUTPUT,">$member_base_name") ) {
		print "open failed for file '$member_base_name' : $!\n";
		return;
	} # UNLESS
	print OUTPUT "$buffer";
	close OUTPUT;
	list_file_info_full($member_base_name,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );

	return;
} # end of cmd_save_member_contents_with_overwrite_basename

######################################################################
#
# Function  : cmd_save_member_contents_with_overwrite
#
# Purpose   : Process a "save member" command.
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : cmd_save_member_contents_with_overwrite($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_save_member_contents_with_overwrite
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $ref_member_attributes , @parms , $num_parms , $buffer );
	my ( $member_size , $user_reply , $errmsg );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	$ref_member_attributes = $mytar::members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		print "$member_name is not a member of $tarfile\n";
		return;
	} # UNLESS

	$member_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $member_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF
	if ( -e $member_name ) {
		print "\nFile $member_name already exists , do you want to overwrite it ? (y/n) ";
		$user_reply = <STDIN>;
		$user_reply =~ s/^\s+//g;
		chomp $user_reply;
		unless ( $user_reply =~ m/^yes|^y/i ) {
			print "Request aborted at user's request.\n";
			return;
		} # UNLESS
	} # If
	unless ( open(OUTPUT,">$member_name") ) {
		print "open failed for file '$member_name' : $!\n";
		return;
	} # UNLESS
	print OUTPUT "$buffer";
	close OUTPUT;
	list_file_info_full($member_name,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );

	return;
} # end of cmd_save_member_contents_with_overwrite

######################################################################
#
# Function  : cmd_save_member_contents
#
# Purpose   : Process a "save member" command.
#
# Inputs    : $_[0] - name of  tar file
#             $_[1] - reference to array of parameters
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : cmd_save_member_contents($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_save_member_contents
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $ref_member_attributes , @parms , $num_parms , $buffer );
	my ( $member_size , $errmsg );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	$ref_member_attributes = $mytar::members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		print "$member_name is not a member of $tarfile\n";
		return;
	} # UNLESS

	$member_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $member_size < 0 ) {
		print "$errmsg\n";
		return;
	}
	if ( -e $member_name ) {
		print "\nFile $member_name already exists , save request is ignored\n\n";
		return;
	} # If
	unless ( open(OUTPUT,">$member_name") ) {
		print "open failed for file '$member_name' : $!\n";
		return;
	} # UNLESS
	print OUTPUT "$buffer";
	close OUTPUT;
	list_file_info_full($member_name,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );

	return;
} # end of cmd_save_member_contents

######################################################################
#
# Function  : search_file_multiple
#
# Purpose   : Scan a tarfile member for multiple patterns pattern
#
# Inputs    : $_[0] - name of member
#             $_[1] - name of tarfile
#             $_[2] - reference to array of patterns
#             $_[3] - case sensitivity flag
#
# Output    : search results
#
# Returns   : number of matched lines
#
# Example   : $count = search_file_multiple($member_name,$tarfile,\@patterns,1);
#
# Notes     : (none)
#
######################################################################

sub search_file_multiple
{
	my ( $member_name , $tarfile , $ref_patterns , $case ) = @_;
	my ( $file_size , $buffer , $num_lines , @lines , $index );
	my ( $pattern , @patterns , @matched , $found , @indices , %indices );
	my ( $index2 , $errmsg );

	@patterns = @$ref_patterns;
	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF
	@lines = split(/\n/,$buffer);
	if ( $buffer =~ m/\n\n$/ ) {
		push @lines,"";
		$num_lines += 1;
	} # IF
	$num_lines = scalar @lines;

	@matched = ();
	if ( $case ) {
		%indices = ();
		for ( $index = 0 ; $index <= $#patterns ; ++$index ) {
			$pattern = $patterns[$index];
			$found = 0;
			for ( $index2 = 0 ; $index2 <= $#lines ; ++$index2 ) {
				if ( $lines[$index2] =~ m/${pattern}/ ) {
					$found = 1;
					$indices{$index2} = 0;
					last;
				} # IF
			} # FOR
			unless ( $found ) {
				return 0;
			} # UNLESS
		} # FOR over patterns
		foreach my $key ( sort { $a <=> $b } keys %indices ) {
			push @matched,sprintf "%4d %s\n",1+$key,$lines[$key];
		} # FOREACH
	} # IF
	else {
		%indices = ();
		for ( $index = 0 ; $index <= $#patterns ; ++$index ) {
			$pattern = $patterns[$index];
			$found = 0;
			for ( $index2 = 0 ; $index2 <= $#lines ; ++$index2 ) {
				if ( $lines[$index2] =~ m/${pattern}/i ) {
					$found = 1;
					$indices{$index2} = 0;
					last;
				} # IF
			} # FOR
			unless ( $found ) {
				return 0;
			} # UNLESS
		} # FOR over patterns
		foreach my $key ( sort { $a <=> $b } keys %indices ) {
			push @matched,sprintf "%4d %s\n",1+$key,$lines[$key];
		} # FOREACH
	} # ELSE

	print "==  $member_name  ==\n",join("",@matched),"\n";
	return 1;
} # end for search_file_multiple

######################################################################
#
# Function  : cmd_search_member_contents_multiple
#
# Purpose   : Scan a tarfile member for multiple patterns
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of command parameters
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : cmd_search_member_contents_multiple($tarfile,\@fields);
#
# Notes     : (none)
#
######################################################################

sub cmd_search_member_contents_multiple
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , $pattern , @patterns );
	my ( @parms , $case , $num_parms , @members , $count );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	@patterns = @parms;
	if ( 1 > @patterns ) {
		print "Enter pattern ==> ";
		$pattern = <STDIN>;
		chomp $pattern;
		while ( $pattern =~ m/\S/ ) {
			push @patterns,$pattern;
			print "Enter pattern ==> ";
			$pattern = <STDIN>;
			chomp $pattern;
		} # WHILE
	} # IF
	if ( 1 > @patterns ) {
		print "\nNo patterns were specified.\n";
		return;
	} # IF

	print "Case sensitive search ? (yes/no) ==> ";
	$case = <STDIN>;
	chomp $case;
	if ( $case =~ m/^y$|^yes$/i ) {
		$case = 1;
	} # IF
	else {
		$case = 0;
	} # ELSE

	if ( $member_name =~ m/^!/ ) {
		$member_name = substr($member_name,1);
		@members = grep /${member_name}/i,@mytar::members_names;
		if ( 1 > @members ) {
			print "\nNo member names matched '$member_name'\n";
			return;
		} # IF
	} # IF
	else {
		@members = ( $member_name );
	} # ELSE

	$count = 0;
	foreach my $name ( @members ) {
		if ( search_file_multiple($name,$tarfile,\@patterns,$case) ) {
			$count += 1;
		} # IF
	} # FOREACH
	if ( $count < 1 ) {
		print "\nNo matches found for ",join(' , ',map { "'$_'" } @patterns)," in : ",
					join(' , ',@members),"\n\n";
	} # IF
	else {
		print "\n";
	} # ELSE

	return;
} # end of cmd_search_member_contents_multiple

######################################################################
#
# Function  : search_file_missing_multiple
#
# Purpose   : Scan a tarfile member for missing multiple patterns
#
# Inputs    : $_[0] - name of member
#             $_[1] - name of tarfile
#             $_[2] - reference to array of patterns
#             $_[3] - case sensitivity flag
#
# Output    : search results
#
# Returns   : number of matched lines
#
# Example   : $count = search_file_missing_multiple($member_name,$tarfile,\@patterns,1);
#
# Notes     : (none)
#
######################################################################

sub search_file_missing_multiple
{
	my ( $member_name , $tarfile , $ref_patterns , $case ) = @_;
	my ( $file_size , $buffer , $num_lines , @lines , $index );
	my ( $pattern , @patterns , $errmsg , $index2 );

	@patterns = @$ref_patterns;
	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF
	@lines = split(/\n/,$buffer);
	if ( $buffer =~ m/\n\n$/ ) {
		push @lines,"";
		$num_lines += 1;
	} # IF
	$num_lines = scalar @lines;
	if ( $case ) {
		for ( $index = 0 ; $index <= $#patterns ; ++$index ) {
			$pattern = $patterns[$index];
			if ( 0 < grep /${pattern}/,@lines ) {
				return 0;
			} # IF
		} # FOR over patterns
	} # IF
	else {
		for ( $index = 0 ; $index <= $#patterns ; ++$index ) {
			$pattern = $patterns[$index];
			if ( 0 < grep /${pattern}/i,@lines ) {
				return 0;
			} # IF
		} # FOR over patterns
	} # ELSE
	print "$member_name\n";

	return 1;
} # end for search_file_missing_multiple

######################################################################
#
# Function  : cmd_search_member_contents_not_found
#
# Purpose   : Scan a tarfile member for multiple patterns
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of command parameters
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : cmd_search_member_contents_not_found($tarfile,\@fields);
#
# Notes     : (none)
#
######################################################################

sub cmd_search_member_contents_not_found
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , $pattern , @patterns );
	my ( @parms , $case , $num_parms , @members , $count );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	@patterns = @parms;
	if ( 1 > @patterns ) {
		print "Enter pattern ==> ";
		$pattern = <STDIN>;
		chomp $pattern;
		while ( $pattern =~ m/\S/ ) {
			push @patterns,$pattern;
			print "Enter pattern ==> ";
			$pattern = <STDIN>;
			chomp $pattern;
		} # WHILE
	} # IF
	if ( 1 > @patterns ) {
		print "\nNo patterns were specified.\n";
		return;
	} # IF

	print "Case sensitive search ? (yes/no) ==> ";
	$case = <STDIN>;
	chomp $case;
	if ( $case =~ m/^y$|^yes$/i ) {
		$case = 1;
	} # IF
	else {
		$case = 0;
	} # ELSE

	if ( $member_name =~ m/^!/ ) {
		$member_name = substr($member_name,1);
		@members = grep /${member_name}/i,@mytar::members_names;
		if ( 1 > @members ) {
			print "\nNo member names matched '$member_name'\n";
			return;
		} # IF
	} # IF
	else {
		@members = ( $member_name );
	} # ELSE

	$count = 0;
	foreach my $name ( @members ) {
		if ( search_file_missing_multiple($name,$tarfile,\@patterns,$case) ) {
			$count += 1;
		} # IF
	} # FOREACH
	if ( $count < 1 ) {
		print "\nNone of the files : ",join(' , ',@members),
					"\n\nwere missing all of the patterns : ",
					join(' , ',map { "'$_'" } @patterns),"\n";
	} # IF
	else {
		print "\n";
	} # ELSE

	return;
} # end of cmd_search_member_contents_not_found

######################################################################
#
# Function  : cmd_search_member_contents
#
# Purpose   : Scan a tarfile member for a pattern
#
# Inputs    : $_[0] - name of member
#             $_[1] - name of tarfile
#             $_[2] - search pattern
#             $_[3] - case sensitivity flag
#
# Output    : search results
#
# Returns   : number of matched lines
#
# Example   : $count = search_file($member_name,$tarfile,$pattern,1);
#
# Notes     : (none)
#
######################################################################

sub search_file
{
	my ( $member_name , $tarfile , $pattern , $case ) = @_;
	my ( $file_size , $buffer , $num_matched , $num_lines , @lines , $index );
	my ( $errmsg );

	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF
	@lines = split(/\n/,$buffer);
	if ( $buffer =~ m/\n\n$/ ) {
		push @lines,"";
		$num_lines += 1;
	} # IF
	$num_lines = scalar @lines;

	$num_matched = 0;
	if ( $case ) {
		for ( $index = 1 ; $index <= $num_lines ; ++$index ) {
			if ( $lines[$index-1] =~ m/${pattern}/ ) {
				if ( ++$num_matched == 1 ) {
					print "\n";
				} # IF
				printf "%s:%5d %s\n",$member_name,$index,$lines[$index-1];
			} # IF
		} # FOR
	} # IF
	else {
		for ( $index = 1 ; $index <= $num_lines ; ++$index ) {
			if ( $lines[$index-1] =~ m/${pattern}/i ) {
				if ( ++$num_matched == 1 ) {
					print "\n";
				} # IF
				printf "%s:%5d %s\n",$member_name,$index,$lines[$index-1];
			} # IF
		} # FOR
	} # ELSE

	return $num_matched;
} # end for search_file

######################################################################
#
# Function  : cmd_search_member_contents
#
# Purpose   : Scan a tarfile member for a pattern
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of command parameters
#
# Output    : search results
#
# Returns   : nothing
#
# Example   : cmd_search_member_contents($tarfile,\@fields);
#
# Notes     : (none)
#
######################################################################

sub cmd_search_member_contents
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , $pattern );
	my ( @parms , $case , $num_parms , @members , $count );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	if ( 0 < @parms ) {
		$pattern = shift @parms;
	} # IF
	else {
		print "Enter pattern ==> ";
		$pattern = <STDIN>;
		chomp $pattern;
	} # ELSE

	print "Case sensitive search ? (yes/no) ==> ";
	$case = <STDIN>;
	chomp $case;
	if ( $case =~ m/^y$|^yes$/i ) {
		$case = 1;
	} # IF
	else {
		$case = 0;
	} # ELSE

	if ( $member_name =~ m/^!/ ) {
		$member_name = substr($member_name,1);
		@members = grep /${member_name}/i,@mytar::members_names;
		if ( 1 > @members ) {
			print "\nNo member names matched '$member_name'\n";
			return;
		} # IF
	} # IF
	else {
		@members = ( $member_name );
	} # ELSE

	$count = 0;
	foreach my $name ( @members ) {
		$count += search_file($name,$tarfile,$pattern,$case);
	} # FOREACH
	if ( $count < 1 ) {
		print "\nNo matches for '$pattern' in : ",join(' , ',@members),"\n\n";
	} # IF
	else {
		print "\n";
	} # ELSE

	return;
} # end of cmd_search_member_contents

######################################################################
#
# Function  : cmd_list_member_contents_with_line_numbers
#
# Purpose   : List attributes of a TAR file member.
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_list_member_contents_with_line_numbers($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_contents_with_line_numbers
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $ref_member_attributes , $offset , $file_size , $buffer , @lines );
	my ( $index , @parms , $num_parms , $data , $errmsg );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF

	if ( $buffer =~ m/\n$/ ) {
		$buffer .= " ";
		@lines = split(/\n/,$buffer);
		pop @lines;
	} # IF
	else {
		@lines = split(/\n/,$buffer);
	} # ELSE
	$data = "";
	for ( $index = 0 ; $index <= $#lines ; ++$index ) {
		$data .= sprintf "%3d\t%s\n",$index+1,$lines[$index];
	} # FOR

	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS
	print "$data";
	close PIPE;

	return;
} # end of cmd_list_member_contents_with_line_numbers

######################################################################
#
# Function  : cmd_print_member_contents
#
# Purpose   : Print the contents of a TAR file member on Windows
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_print_member_contents($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_print_member_contents
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , $tempfile , @parms , $num_parms );
	my ( $errmsg );

	unless ( $^O =~ m/MSWin/ ) {
		print "This function is only supported on Windows\n";
		return;
	} # UNLESS

	unless ( exists $ENV{"TEMP"} ) {
		print "You do not have a temporary directory environment variable\n";
		return;
	} # UNLESS

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF

	$tempfile = $ENV{"TEMP"} . "\\" . $$ . "-" . $member_name;
	unless ( open(TEMP,">$tempfile") ) {
		print "open for writing failed for file '$tempfile' : $!\n";
		return;
	} # UNLESS
	print TEMP "$buffer";
	close TEMP;
	system("notepad /p $tempfile");
	unlink $tempfile;

	return;
} # end of cmd_print_member_contents

######################################################################
#
# Function  : cmd_count_lines
#
# Purpose   : Count lines and characters in a TAR file member
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_count_lines($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_count_lines
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $file_size , $buffer , @parms , $num_parms , $tempfile );
	my ( @lines , $num_lines , $name_pattern , $num_names , $errmsg );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$name_pattern = shift @parms;
	} # IF
	else {
		print "Enter member name ==> ";
		$name_pattern = <STDIN>;
		chomp $name_pattern;
	} # ELSE

	@matched_names = grep /${name_pattern}/i,@mytar::members_names;
	$num_names = scalar @matched_names;
	if ( $num_names < 1 ) {
		print "\nNo member names matched '$name_pattern'\n\n";
		return;
	} # IF

	foreach my $member_name ( @matched_names ) {
		$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
		if ( $file_size < 0 ) {
			print "$errmsg\n";
			return;
		} # IF
		@lines = split(/\n/,$buffer);
		if ( $buffer =~ m/\n\n$/ ) {
			push @lines,"";
			$num_lines += 1;
		} # IF
		$num_lines = scalar @lines;
		print "\n${num_lines} ${file_size} ${member_name}\n";
	} # FOREACH

	return;
} # end of cmd_count_lines

######################################################################
#
# Function  : cmd_expand_member_content_tabs
#
# Purpose   : Display the contents of a TAR file member.
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_expand_member_content_tabs($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_expand_member_content_tabs
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , @parms , $num_parms , $tempfile );
	my ( $tabsize , @lines , $num_lines , $expanded , $errmsg );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	if ( $num_parms > 0 ) {
		$tabsize = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter tabsize ==> ";
		$tabsize = <STDIN>;
		chomp $tabsize;
	} # ELSE

	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF
	@lines = split(/\n/,$buffer);
	if ( $buffer =~ m/\n\n$/ ) {
		push @lines,"";
		$num_lines += 1;
	} # IF
	$num_lines = scalar @lines;
	foreach my $line ( @lines ) {
		$expanded = expand_tabs($line,$tabsize);
		print "$expanded\n";
	} # FOREACH

	return;
} # end of cmd_expand_member_content_tabs

######################################################################
#
# Function  : cmd_page_member_contents
#
# Purpose   : Display the contents of a TAR file member.
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_page_member_contents($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_page_member_contents
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , @parms , $num_parms , $tempfile );
	my ( $errmsg );

	if ( $pager eq "" ) {
		print "\nPager not yet defined.\n";
		return;
	} # IF

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;

	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF

	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS

	print PIPE "$buffer";
	close PIPE;

	return;
} # end of cmd_page_member_contents

######################################################################
#
# Function  : get_member_name
#
# Purpose   : Get a member name for a command
#
# Inputs    : $_[0] - reference to array of parameters
#
# Output    : (none)
#
# Returns   : IF problem THEN empty string ELSE member name
#
# Example   : $member_name = get_member_name(\@parms);
#
# Notes     : (none)
#
######################################################################

sub get_member_name
{
	my ( $ref_parms ) = @_;
	my ( $member_name , @parms , $num_parms , $count , $index );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
	} # IF
	else {
		print "Enter member name ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE
	@$ref_parms = @parms;
	if ( $member_name =~ m/^{(\d+)$/ ) {
		$count = scalar @matched_names;
		if ( $count == 0 ) {
			print "\nNo matched names currently defined.\n";
		} # IF
		else {
			$index = $1;
			if ( $index < 1 || $index > $count ) {
				print "\nmatched names index out of range (1 - $count)\n";
				$member_name = "";
			} # IF
			else {
				$member_name = $matched_names[$index-1];
			} # ELSE
		} # ELSE
	} # IF

	return $member_name;
} # end of get_member_name

######################################################################
#
# Function  : cmd_list_member_contents
#
# Purpose   : Display the contents of a TAR file member.
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_list_member_contents($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_contents
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , @parms , $num_parms , $errmsg );

	$member_name = get_member_name($ref_parms);
	if ( $member_name eq "" ) {
		return;
	} # IF
	@parms = @$ref_parms;

	$file_size = mytar::read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
	if ( $file_size < 0 ) {
		print "$errmsg\n";
		return;
	} # IF

	unless ( open(PIPE,"|$pager") ) {
		warn("open of pipe to '$pager' failed : $!\n");
		return;
	} # UNLESS
	print "$buffer\n";
	close PIPE;

	return;
} # end of cmd_list_member_contents

######################################################################
#
# Function  : process_command
#
# Purpose   : Process a command on a tarfile
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - command buffer
#
# Output    : command results
#
# Returns   : nothing
#
# Example   : process_command($tarfile,$commmand);
#
# Notes     : (none)
#
######################################################################

sub process_command
{
	my ( $tarfile , $buffer ) = @_;
	my ( @fields , $ref , @array , $command );

	$buffer =~ s/^\s+//g;
	$buffer =~ s/\s+$//g;
	@fields = split(/\s+/,$buffer);
	$command = shift @fields;
	$buffer = $';
	if ( $command =~ m/^q$|^exit$|^bye$|^quit$/i ) {
		$exit_flag = 1;
		return;
	} # IF
	$ref = $cmds{$command};
	if ( defined $ref ) {
		@array = @$ref;
		$array[0]->($tarfile,\@fields);
	} # IF
	else {
		print "Unknown command '$command'\n";
	} # ELSE

	return;
} # end of process_command

######################################################################
#
# Function  : process_tar_file
#
# Purpose   : Process a TAR file.
#
# Inputs    : $_[0] - name of TAR file
#
# Output    : TAR file information
#
# Returns   : nothing
#
# Example   : process_tar_file($tarfile);
#
# Notes     : (none)
#
######################################################################

sub process_tar_file
{
	my ( $tarfile ) = @_;
	my ( $status , $buffer , @fields , $count , $command , $prompt );
	my ( $ref , @array , $errmsg );

	$status = mytar::init_tar_file_processing($tarfile,\$errmsg);
	if ( $status < 0 ) {
		die("$errmsg\n");
	} # IF

	print "\nFound ${mytar::num_members} members in '$tarfile'\n";
	if ( exists $options{'c'} ) {
		$buffer = $options{'c'};
		process_command($tarfile,$buffer);
	} # IF

	print "\n";

	$prompt = "\nEnter command ==> ";
	$exit_flag = 0;
	while ( ! $exit_flag ) {
		print $prompt;
		$buffer = <STDIN>;
		chomp $buffer;
		unless ( $buffer =~ m/\S/ ) {
			next;
		} # UNLESS
		process_command($tarfile,$buffer);
	} # WHILE

##	close TAR;
	return;
} # end of process_tar_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Process TAR files.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : mytar.pl -d arg1 arg2
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $tarfile , $errmsg , @blocks , @text , $buffer );

	$status = getopts("hdp:c:Cw:",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status  && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dhC] [-w line_width] [-c initial_command] [-p pager] filename [... filename]\n");
	} # UNLESS
	if ( exists $options{'p'} ) {
		$pager = $options{'p'};
	} # IF

	@blocks = split(/${helpsep}\n/,$helptext);
	$status = scalar @blocks;
	%helptext = ();
	foreach my $block ( @blocks ) {
		@text = split(/\n/,$block);
		chomp @text;
		$buffer = shift @text;
		$helptext{$buffer} = join("\n",@text);
	} # FOREACH

	print "\n";
	cmd_info();

	foreach my $tarfile ( @ARGV ) {
		process_tar_file($tarfile);
	} # FOREACH

	exit 0;
} # end of MAIN
