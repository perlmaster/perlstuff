#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : mytar.pl
#
# Author    : Barry Kimelman
#
# Created   : August 1, 2011
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
use Mail::Sendmail;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

require "time_date.pl";
require "format_mode.pl";
require "expand_tabs.pl";

my ( %options , %members_info , @members_names , $num_members );
my $pager = "";

my %cmds = (
	"l" => [ \&cmd_list_member_attributes , 'list member attributes (ala ls)' ],
	"c" => [ \&cmd_list_member_contents , 'list member contents (ala cat)' ],
	"X" => [ \&cmd_expand_member_content_tabs , 'list member contents with expanded tabs (ala expand)' ],
	"w" => [ \&cmd_count_lines , 'count lines and characters (ala wc -lc)' ],
	"E" => [ \&cmd_email_member_contents , 'Email member contents' ],
	"p" => [ \&cmd_print_member_contents , 'print member contents (only works on Windows)' ],
	"n" => [ \&cmd_list_member_contents_with_line_numbers , 'list member contents with line numbers(ala cat -n)' ],
	"e" => [ \&cmd_search_member_contents , 'search member contents (ala egrep)' ],
	"v" => [ \&cmd_search_member_contents_not_found , 'search members for non inclusion of patterns' ],
	"a" => [ \&cmd_search_member_contents_multiple , 'search member contents for multiple (ala egrep)' ],
	"s" => [ \&cmd_save_member_contents , 'save member contents to disk' ],
	"S" => [ \&cmd_save_member_contents_with_overwrite , 'save member contents to disk (with overwrite)' ],
	"m" => [ \&cmd_list_member_names , 'list all member names' ],
	"M" => [ \&cmd_list_member_names_with_attributes , 'list all member names with attributes' ],
	"t" => [ \&cmd_list_member_names_with_attributes_time_sorted , 'list member names with attributes sorted by time' ],
	"T" => [ \&cmd_list_member_names_with_attributes_time_sorted_desc , 'list member names with attributes sorted by time in descending order' ],
	"h" => [ \&cmd_summary , 'brief commnds summary' ],
	"H" => [ \&cmd_help , 'detailed command help' ],
	"P" => [ \&cmd_paging , 'activate/deactivate paging' ],
	"x" => [ \&cmd_not_found , 'list names of members that do noy include a pattern' ],
	"W" => [ \&cmd_notopics , 'list commands without detailed help' ],
);

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
# Function  : process_tar_file_member
#
# Purpose   : Process a member from a TAR file.
#
# Inputs    : $_[0] - name of TAR file
#
# Output    : TAR file information
#
# Returns   : nothing
#
# Example   : process_tar_file_member($tarfile);
#
# Notes     : (none)
#
######################################################################

sub process_tar_file_member
{
	my ( $tarfile ) = @_;
	my ( $header1 , $num_bytes , $member_name , $member_offset , $member_mode );
	my ( $member_uid  , $member_gid  , $member_size , $member_modtime  , $member_crc );
	my ( $number , $member_data , $num_blocks , $last_block_size , $member_size_decimal ) ;
	my ( $member_allocated_bytes , $member_type_flag , $member_link_name , $member_magic );
	my ( $member_version , $member_uname  , $member_gname , $member_devmajor );
	my ( $member_devminor , $member_prefix );

	$num_bytes = sysread(TAR,$header1,TBLOCK_SIZE);
	if ( $num_bytes == 0 ) {
		print "EOF on header read\n";
		return 1;
	} # IF
	if ( $num_bytes != TBLOCK_SIZE ) {
		warn("Failure reading header from $tarfile : $!\n");
		return -1;
	} # IF
	$member_name = substr($header1,0,TNAMLEN);
	$member_name =~ s/\0//g;
	if ( $member_name eq "" ) {
		return 1;
	} # IF

	push @members_names,$member_name;

	$member_offset = sysseek(TAR , 0 , 1);  # seek from current to get file offset
	$members_info{$member_name}{'member_offset'} = $member_offset;

	$member_mode = substr($header1,TNAMLEN,TMODLEN);
	$member_mode =~ s/\0//g;
	$members_info{$member_name}{'member_mode'} = oct($member_mode);

	$member_uid = substr($header1,TNAMLEN+TMODLEN,TUIDLEN);
	$member_uid =~ s/\0//g;
	$members_info{$member_name}{'member_uid'} = $member_uid;

	$member_gid = substr($header1,TNAMLEN+TMODLEN+TUIDLEN,TGIDLEN);
	$member_gid =~ s/\0//g;
	$members_info{$member_name}{'member_gid'} = $member_gid;

	$member_size = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN,TSIZLEN);
	$member_size =~ s/\0//g;
	$member_size_decimal = oct $member_size;
	$members_info{$member_name}{'member_size_decimal'} = $member_size_decimal;
	$num_blocks = int ( ($member_size_decimal + TBLOCK_SIZE - 1) / TBLOCK_SIZE );
	$members_info{$member_name}{'num_blocks'} = $num_blocks;
	$member_allocated_bytes = $num_blocks * TBLOCK_SIZE;
	$members_info{$member_name}{'member_allocated_bytes'} = $member_allocated_bytes;
	$last_block_size = $member_allocated_bytes - $member_size_decimal;
	$members_info{$member_name}{'last_block_size'} = $last_block_size;

	$member_modtime = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN,TTIMLEN);
	$member_modtime =~ s/\0//g;
	$members_info{$member_name}{'member_modtime'} = $member_modtime;

	$member_crc = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN,TCRCLEN);
	$member_crc =~ s/\0//g;
	$members_info{$member_name}{'member_crc'} = $member_crc;

	$member_type_flag = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN,1);
	$member_type_flag =~ s/\0//g;
	$members_info{$member_name}{'member_type_flag'} = $member_type_flag;

	$member_link_name = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1,TNAMLEN);
	$member_link_name =~ s/\0//g;
	$members_info{$member_name}{'member_link_name'} = $member_link_name;

	$member_magic = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN,6);
	$member_magic =~ s/\0//g;
	$members_info{$member_name}{'member_magic'} = $member_magic;

	$member_version = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN+6,2);
	$member_version =~ s/\0//g;
	$members_info{$member_name}{'member_version'} = $member_version;

	$member_uname = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN+6+2,32);
	$member_uname =~ s/\0//g;
	$members_info{$member_name}{'member_uname'} = $member_uname;

	$member_gname = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN+6+2+32,32);
	$member_gname =~ s/\0//g;
	$members_info{$member_name}{'member_gname'} = $member_gname;

	$member_devmajor = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN+6+2+32+32,8);
	$member_devmajor =~ s/\0//g;
	$members_info{$member_name}{'member_devmajor'} = $member_devmajor;

	$member_devminor = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN+6+2+32+32+8,8);
	$member_devminor =~ s/\0//g;
	$members_info{$member_name}{'member_devminor'} = $member_devminor;

	$member_prefix = substr($header1,TNAMLEN+TMODLEN+TUIDLEN+TGIDLEN+TSIZLEN+TTIMLEN+TCRCLEN+1+TNAMLEN+6+2+32+32+8+8,155);
	$member_prefix =~ s/\0//g;
	$members_info{$member_name}{'member_prefix'} = $member_prefix;

	$num_bytes = sysread(TAR, $member_data, $member_allocated_bytes);
	if ( $num_bytes != $member_allocated_bytes ) {
		warn("Could only read $num_bytes of $member_allocated_bytes bytes for member $member_name : !$\n");
		return -1;
	} # IF
	$member_data = substr($member_data, 0, $member_size_decimal);

	return 0;
} # end of process_tar_file_member

######################################################################
#
# Function  : open_tempfile
#
# Purpose   : Open a temporary file
#
# Inputs    : $_[0] - reference to buffer to receive tempfile name
#
# Output    : appropriate diagnostics
#
# Returns   : IF error THEN negative ELSE zero
#
# Example   : $status = open_tempfile(\$tempfile);
#
# Notes     : (none)
#
######################################################################

sub open_tempfile
{
	my ( $ref_tempfile ) = @_;
	my ( $tempfile );

	$$ref_tempfile = "";
	if ( $^O =~ m/MSWin/ ) {
		$tempfile = $ENV{"TEMP"} . "\\" . "mytar-$$";
	} # IF
	else {
		$tempfile = "/var/tmp/" . $ENV{"LOGNAME"} . "-mytar-$$";
	} # ELSE
	unless ( open(TEMP,">$tempfile") ) {
		print "\nopen failed for file '$tempfile' : $!\n";
		return -1;
	} # UNLESS
	else {
		$$ref_tempfile = $tempfile;
		return 0;
	} # ELSE

} # end of open_tempfile

######################################################################
#
# Function  : cmd_paging
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
# Example   : cmd_paging($tarfile,\@parms);
#
# Notes     : (none)
#
######################################################################

sub cmd_paging
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( @parms , $num_parms );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$pager = $parms[0];
		print "\nPager now set to '$pager'\n";
	} # IF
	else {
		$pager = "";
		print "\nPaging is now off\n";
	} # ELSE

	return;
} # end of cmd_paging

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
	@nameslist = grep /${name_pattern}/i,@members_names;
	$num_names = scalar @nameslist;
	if ( $num_names < 1 ) {
		print "\nNo member names matched '$name_pattern'\n\n";
		return;
	} # IF

	$num_not_found = 0;
	@found = ();
	foreach my $name ( @nameslist ) {
		$file_size = read_member_contents($tarfile,$name,\$buffer);
		if ( $file_size < 0 ) {
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
# Function  : cmd_list_member_names
#
# Purpose   : Process a TAR file.
#
# Inputs    : $_[0] - name of  tar file
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names
{
	my ( $tarfile ) = @_;
	my ( @numbers , $tempfile );

	@numbers = ( map { sprintf "%4d",$_} (1 .. $num_members) );

	if ( $pager ne "" ) {
		if ( open_tempfile(\$tempfile) < 0 ) {
			return;
		} # IF
		print TEMP join("\n", map { "($numbers[$_]) $members_names[$_]" } (0 .. $#members_names)),"\n";
		system("${pager} ${tempfile}");
		unlink $tempfile;
	} # IF
	else {
		print join("\n", map { "($numbers[$_]) $members_names[$_]" } (0 .. $#members_names)),"\n";
	} # ELSE

	return;
} # end of cmd_list_member_names

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
	my ( $modtime , $buffer , $perms , $file_mode );

	$modtime = $ref_member_attributes->{member_modtime};
	$modtime =~ s/\0//g;
	$modtime = oct($modtime);
	$buffer = format_time_date($modtime,"");
	$file_mode = $ref_member_attributes->{member_mode};

	$perms = format_mode($file_mode);

	printf "%08o %s %8s %8s %10d ",$file_mode,$perms,
				$ref_member_attributes->{member_uname},
				$ref_member_attributes->{member_gname},
				$ref_member_attributes->{member_size_decimal};
	print "$buffer $member_name\n";

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
	my ( $data , $tempfile , @names );

	@modtimes = ();
	@names = @$ref_names;
	foreach my $member_name ( @names ) {
		$ref_member_attributes = $members_info{$member_name};
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
		$ref_member_attributes = $members_info{$name};
		$data .= generate_member_attributes($ref_member_attributes,$name) . "\n";
	} # FOREACH
	$data .= "\n${num_members} members in TAR file ${tarfile}\n\n";

	if ( $pager ne "" ) {
		if ( open_tempfile(\$tempfile) < 0 ) {
			return;
		} # IF
		print TEMP "$data";
		system("${pager} ${tempfile}");
		unlink $tempfile;
	} # IF
	else {
		print "$data";
	} # ELSE

	return;
} # end of list_members

######################################################################
#
# Function  : cmd_list_member_names_with_attributes_time_sorted_desc
#
# Purpose   : Process a TAR file.
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
	my ( @parms , $num_parms , $name_pattern , @nameslist , $num_names );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms < 1 ) {
		@nameslist = @members_names;
	} # IF
	else {
		$name_pattern = $parms[0];
		@nameslist = grep /${name_pattern}/i,@members_names;
		$num_names = scalar @nameslist;
		if ( $num_names < 1 ) {
			print "\nNo member names matched '$name_pattern'\n\n";
			return;
		} # IF
	} # ELSE

	list_members(1,$tarfile,\@nameslist);

	return;
} # end of cmd_list_member_names_with_attributes_time_sorted_desc

######################################################################
#
# Function  : cmd_list_member_names_with_attributes_time_sorted
#
# Purpose   : Process a TAR file.
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
	my ( @parms , $num_parms , $name_pattern , @nameslist , $num_names );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms < 1 ) {
		@nameslist = @members_names;
	} # IF
	else {
		$name_pattern = $parms[0];
		@nameslist = grep /${name_pattern}/i,@members_names;
		$num_names = scalar @nameslist;
		if ( $num_names < 1 ) {
			print "\nNo member names matched '$name_pattern'\n\n";
			return;
		} # IF
	} # ELSE

	list_members(0,$tarfile,\@nameslist);

	return;
} # end of cmd_list_member_names_with_attributes_time_sorted

######################################################################
#
# Function  : cmd_list_member_names_with_attributes
#
# Purpose   : Process a TAR file.
#
# Inputs    : $_[0] - name of  tar file
#
# Output    : List of TAR file members
#
# Returns   : nothing
#
# Example   : cmd_list_member_names_with_attributes($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_list_member_names_with_attributes
{
	my ( $tarfile ) = @_;
	my ( $ref_member_attributes , $info , $data , $tempfile );

	$data = "";
	foreach my $member_name ( @members_names ) {
		$ref_member_attributes = $members_info{$member_name};

		$info = generate_member_attributes($ref_member_attributes,$member_name);
		$data .= $info . "\n";
	} # FOREACH

	if ( $pager ne "" ) {
		if ( open_tempfile(\$tempfile) < 0 ) {
			return;
		} # IF
		print TEMP "$data\n${num_members} members in TAR file ${tarfile}\n\n";
		system("${pager} ${tempfile}");
		unlink $tempfile;
	} # IF
	else {
		print "$data\n${num_members} members in TAR file ${tarfile}\n\n";
	} # ELSE

	return;
} # end of cmd_list_member_names_with_attributes

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
	my ( @nameslist , $num_names , $name_pattern );

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

	@nameslist = grep /${name_pattern}/i,@members_names;
	$num_names = scalar @nameslist;
	if ( $num_names < 1 ) {
		print "\nNo member names matched '$name_pattern'\n\n";
		return;
	} # IF

	foreach my $member_name ( @nameslist ) {
		$ref_member_attributes = $members_info{$member_name};
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
# Purpose   : Process a TAR file.
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
	my ( $member_name , $file_size , $buffer , @parms , $num_parms , $tempfile );

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

	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
		return;
	} # IF

	if ( $pager ne "" ) {
		if ( open_tempfile(\$tempfile) < 0 ) {
			return;
		} # IF
		print TEMP "$buffer\n";
		system("${pager} ${tempfile}");
		unlink $tempfile;
	} # IF
	else {
		print "$buffer\n";
	} # ELSE

	return;
} # end of cmd_list_member_contents

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
	my ( $tabsize , @lines , $num_lines , $expanded );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;

	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

	if ( $num_parms > 0 ) {
		$tabsize = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter tabsize ==> ";
		$tabsize = <STDIN>;
		chomp $tabsize;
	} # ELSE

	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
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
	my ( @lines , $num_lines , $name_pattern , $num_names , @nameslist );

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

	@nameslist = grep /${name_pattern}/i,@members_names;
	$num_names = scalar @nameslist;
	if ( $num_names < 1 ) {
		print "\nNo member names matched '$name_pattern'\n\n";
		return;
	} # IF

	foreach my $member_name ( @nameslist ) {
		$file_size = read_member_contents($tarfile,$member_name,\$buffer);
		if ( $file_size < 0 ) {
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
# Function  : cmd_email_member_contents
#
# Purpose   : Email the contents of a TAR file member.
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - reference to array of parameters
#
# Output    : requested data
#
# Returns   : nothing
#
# Example   : cmd_email_member_contents($tarfile);
#
# Notes     : (none)
#
######################################################################

sub cmd_email_member_contents
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , @parms , $num_parms );
	my ( %mail , $to );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

	if ( $num_parms > 0 ) {
		$to = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter emil address of recipient ==> ";
		$to = <STDIN>;
		chomp $to;
	} # ELSE

	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
		return;
	} # IF

	%mail = (
		To      => $to ,
		smtp	=> 'smtp.inside.somewhere.com' ,
		From    => 'TAR File Shell <toto@oz.com>',
		Message => $buffer ,
		Subject => "Contents of tarfile member $member_name from $tarfile"
	);

	sendmail(%mail) or print "Sendmail failed : ".$Mail::Sendmail::error . "\n";

	return;
} # end of cmd_email_member_contents

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

	unless ( $^O =~ m/MSWin/ ) {
		print "This function is only supported on Windows\n";
		return;
	} # UNLESS

	unless ( exists $ENV{"TEMP"} ) {
		print "You do not have a temporary directory environment variable\n";
		return;
	} # UNLESS

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

	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
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
# Function  : read_member_contents
#
# Purpose   : Read in the contents of a tar file member
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - name of tarfile member
#             $_[2] - reference to buffer to receive data
#
# Output    : search results
#
# Returns   : IF problem THEN negative ELSE member file size
#
# Example   : $member_size = read_member_contents($tarfile,$member_name,\$buffer);
#
# Notes     : (none)
#
######################################################################

sub read_member_contents
{
	my ( $tarfile , $member_name , $ref_buffer ) = @_;
	my ( $ref_member_attributes , $offset , $file_size );

	$ref_member_attributes = $members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		print "$member_name is not a member of $tarfile\n";
		return -1;
	} # UNLESS

	$offset = $ref_member_attributes->{member_offset};
	if ( seek(TAR,$offset,0) < 0 ) {
		die("seek to $offset failed : $!\n");
	} # IF
	$file_size = $ref_member_attributes->{member_size_decimal};
	if ( sysread(TAR,$$ref_buffer,$file_size) != $file_size ) {
		die("Could not read all $file_size bytes : $!\n");
	} # IF

	return $file_size;
} # end of read_member_contents

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

	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
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
	my ( $index2 );

	@patterns = @$ref_patterns;
	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
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
	my ( $pattern , @patterns );
	my ( $index2 );

	@patterns = @$ref_patterns;
	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
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

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

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
		@members = grep /${member_name}/i,@members_names;
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
# Example   : cmd_search_member_contents($tarfile,\@fields);
#
# Notes     : (none)
#
######################################################################

sub cmd_search_member_contents_multiple
{
	my ( $tarfile , $ref_parms ) = @_;
	my ( $member_name , $file_size , $buffer , $pattern , @patterns );
	my ( @parms , $case , $num_parms , @members , $count );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name pattern ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

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
		@members = grep /${member_name}/i,@members_names;
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

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name pattern ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

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
		@members = grep /${member_name}/i,@members_names;
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
	my ( $index , @parms , $num_parms , $data , $tempfile );

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

	$file_size = read_member_contents($tarfile,$member_name,\$buffer);
	if ( $file_size < 0 ) {
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

	if ( $pager ne "" ) {
		if ( open_tempfile(\$tempfile) < 0 ) {
			return;
		} # IF
		print TEMP "$data";
		system("${pager} ${tempfile}");
		unlink $tempfile;
	} # IF
	else {
		print "$data";
	} # ELSE

	return;
} # end of cmd_list_member_contents_with_line_numbers

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
	my ( $member_size );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

	$ref_member_attributes = $members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		print "$member_name is not a member of $tarfile\n";
		return;
	} # UNLESS

	$member_size = read_member_contents($tarfile,$member_name,\$buffer);
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
	system("ls -ld $member_name");

	return;
} # end of cmd_save_member_contents

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
	my ( $member_size , $user_reply );

	@parms = @$ref_parms;
	$num_parms = scalar @parms;
	if ( $num_parms > 0 ) {
		$member_name = shift @parms;
		$num_parms -= 1;
	} # IF
	else {
		print "Enter member name ==> ";
		$member_name = <STDIN>;
		chomp $member_name;
	} # ELSE

	$ref_member_attributes = $members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		print "$member_name is not a member of $tarfile\n";
		return;
	} # UNLESS

	$member_size = read_member_contents($tarfile,$member_name,\$buffer);
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
	system("ls -ld $member_name");

	return;
} # end of cmd_save_member_contents_with_overwrite

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
	my ( $ref , @array );

	unless ( sysopen(TAR,$tarfile,O_RDONLY) ) {
		die("sysopen failed for \"$tarfile\" : $!\n");
	} # UNLESS

	%members_info = ();
	@members_names = ();
	$count = 0;
	$status = process_tar_file_member($tarfile);
	while ( $status == 0 ) {
		$count += 1;
		$status = process_tar_file_member($tarfile);
	} # WHILE

	if ( $status < 0 ) {
		close TAR;
		return;
	} # IF
	@members_names = sort { lc $a cmp lc $b } @members_names;
	$num_members = scalar @members_names;

	print "\n";

	$ref = $cmds{'M'};
	@array = @$ref;
	$array[0]->($tarfile);

	print "\n";

	$prompt = "\nEnter command ==> ";
	while ( 1 ) {
		print $prompt;
		$buffer = <STDIN>;
		chomp $buffer;
		unless ( $buffer =~ m/\S/ ) {
			next;
		} # UNLESS
		$buffer =~ s/^\s+//g;
		$buffer =~ s/\s+$//g;
		@fields = split(/\s+/,$buffer);
		$command = shift @fields;
		$buffer = $';
		if ( $command =~ m/^q$|^exit$|^bye$/i ) {
			last;
		} # IF
		$ref = $cmds{$command};
		if ( defined $ref ) {
			@array = @$ref;
			$array[0]->($tarfile,\@fields);
		} # IF
		else {
			print "Unknown command '$command'\n";
		} # ELSE
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
	my ( $status , @blocks , @text , $buffer );

	%options = ( "d" => 0 , "h" => 0 );
	$status = getopts("hdp:",\%options);
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
	unless ( $status  && 0 < @ARGV ) {
		die("Usage : $0 [-dh] [-p pager] filename [... filename]\n");
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
	cmd_summary();

	foreach my $tarfile ( @ARGV ) {
		process_tar_file($tarfile);
	} # FOREACH

	exit 0;
} # end of MAIN
__END__
=head1 NAME

mytar.pl

=head1 SYNOPSIS

mytar.pl [-hd] tarfile

=head1 DESCRIPTION

Process TAR files.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary
  -p <pager> - name of "paging" program for displaying output

=head1 PARAMETERS

  tarfile - name of TAR archive file

=head1 EXAMPLES

mytar.pl stuff.tar

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
