#!/usr/bin/perl -w

######################################################################
#
# File      : find1.pl
#
# Author    : Barry Kimelman
#
# Created   : March 4, 2005
#
# Purpose   : Perl version of UNIX find command
#
######################################################################

use strict;
use warnings;
use constant;
use Class::Struct;
use Data::Dumper;
use File::stat;
use Fcntl;
use filetest 'access'; use File::Spec;
use Cwd;
use Sys::Hostname;
use File::Basename;
use Time::HiRes qw(gettimeofday tv_interval);
use FindBin;
use lib $FindBin::Bin;
use ANSIColor;

require "time_date.pl";
require "expand_tabs.pl";
require "hexdump.pl";
require "list_file_info.pl";
require "elapsed_time.pl";
require "elapsed_interval_time.pl";
require "display_pod_help.pl";
require "stack_backtrace.pl";
require "is_symlink_parent.pl";

use constant OPT_PRINT => 0;
use constant OPT_NAME => 1;
use constant OPT_TYPE => 2;
use constant OPT_DELETE => 3;
use constant OPT_KILL => 4;
use constant OPT_LS => 5;
use constant OPT_GREP => 6;
use constant OPT_WC => 7;
use constant OPT_DISPLAY => 8;
use constant OPT_PAGE => 9;
use constant OPT_HEAD => 10;
use constant OPT_IGREP => 11;
use constant OPT_LGREP => 12;
use constant OPT_INAME => 13;
use constant OPT_TAIL => 14;
use constant OPT_TOUCH => 15;
use constant OPT_MINSIZE => 16;
use constant OPT_MAXSIZE => 17;
use constant OPT_MINKB => 18;
use constant OPT_MAXKB => 19;
use constant OPT_MINMB => 20;
use constant OPT_MAXMB => 21;
use constant OPT_NUM => 22;
use constant OPT_LSK => 23;
use constant OPT_LSM => 24;
use constant OPT_NGREP => 25;
use constant OPT_EXPAND => 26;
use constant OPT_LEVELS => 27;
use constant OPT_HEXDUMP => 28;
use constant OPT_EMPTY => 29;
use constant OPT_MINGB => 30;
use constant OPT_EXT => 31;
use constant OPT_TEXT => 32;
use constant OPT_LS2 => 33;
use constant OPT_LS3 => 34;
use constant OPT_ECHO_PARMS => 35;
use constant OPT_AND => 36;
use constant OPT_EXACTNAME => 37;
use constant OPT_EXACTINAME => 38;
use constant OPT_INCLUDE => 39;
use constant OPT_IGNOREDIR => 40;
use constant OPT_HGREP => 41;
use constant OPT_IHGREP => 42;
use constant OPT_NOTGREP => 43;
use constant OPT_NEWLINE => 44;
use constant OPT_LISTDIR => 45;
use constant OPT_HLINE => 46;
use constant OPT_IMAGE => 47;
use constant OPT_IP_GREP => 47;
use constant OPT_NOTMINE => 48;
use constant OPT_COUNT => 49;
use constant OPT_LSN => 50;
use constant OPT_NUM_LINKS => 51;

use constant OPT_DATA_NONE => 0;
use constant OPT_DATA_STRING => 1;
use constant OPT_DATA_NUMBER => 2;

use constant OPT_BOOLEAN => 'b';
use constant OPT_STRING => 's';
use constant OPT_INTEGER => 'i';

use constant MEGABYTE => 1024 * 1024;
use constant GIGABYTE => 1024 * 1024 * 1024;

struct Find_Option => {
	opcode => '$',
	opt_name => '$' ,
	data => '$' ,
	function => '$'
} ;

our ( $entry_name , $entry_path , $entry_lstat , $entry_type , $entry_uid );
my ( @find_options , $start_dir , $current_opt , $start_time , $end_time );
my ( $int_start_time , $int_end_time , $int_elapsed_time );

my %flags = ( "d" => 0 , "l" => -1 , "e" => 0 , "s" => 0 , "i" =>"" , "S" => 0 );
my $count_flag = 0;
my $entry_count = 0;
my @prog_parms;

my @months = ( "Jan" , "Feb" , "Mar" , "Apr" , "May" , "Jun" , "Jul" , "Aug" ,
			"Sep" , "Oct" , "Nov" , "Dec" );
my $page_size = 35;

my %options = (
	"debug" => [ "b" , -1 , \$flags{"d"} , undef , undef , "Activate debug mode" ] ,
	"parms" => [ "b" , -1 , \$flags{"e"} , undef , undef , "Display program parameters" ] ,
	"started" => [ "b" , -1 , \$flags{"s"} , undef , undef , "Display starting time" ] ,
	"summary" => [ "b" , -1 , \$flags{"S"} , undef , undef , "Display processing summary" ] ,
	"levels" => [ "i" , OPT_LEVELS , \$flags{'l'} , \&validate_number , undef , "Limit recursion depth" ] ,
	"ignoredir" => [ "s" , OPT_IGNOREDIR , \$flags{'i'} , \&validate_string , undef , "Ignore directories matching the specified pattern" ] ,

	"print" => [ "b" , OPT_PRINT , undef , \&validate_boolean , \&run_print , "Display entry name" ] ,
	"newline" => [ "b" , OPT_NEWLINE , undef , \&validate_boolean , \&run_newline , "Print a blank line" ] ,
	"name" => [ "s" , OPT_NAME , undef , \&validate_string , \&run_name , "Case sensitive pattern match against entry name" ] ,
	"exactname" => [ "s" , OPT_EXACTNAME , undef , \&validate_string , \&run_exactname , "Case sensitive comnparison against entry name" ] ,
	"exactiname" => [ "s" , OPT_EXACTINAME , undef , \&validate_string , \&run_exactiname , "Case insensitive comnparison against entry name" ] ,
	"ext" => [ "s" , OPT_EXT , undef , \&validate_string , \&run_ext , "check for filename extension" ] ,
	"iname" => [ "s" , OPT_INAME , undef , \&validate_string , \&run_iname , "Case insensitive pattern match against entry name" ] ,
	"type" => [ "s" , OPT_TYPE , undef , \&validate_string , \&run_type , "Test the entry file type" ] ,
	"delete" => [ "b" , OPT_DELETE , undef , \&validate_boolean , \&run_delete , "Delete a file with prompting" ],
	"kill" => [ "b" , OPT_KILL , undef , \&validate_boolean , \&run_kill , "Delete a file without prompting" ] ,
	"ls" => [ "b" , OPT_LS , undef , \&validate_boolean , \&run_ls , "Display file attributes" ] ,
	"ls2" => [ "b" , OPT_LS2 , undef , \&validate_boolean , \&run_ls2 , "Display file attributes without owner or group" ] ,
	"ls3" => [ "b" , OPT_LS3 , undef , \&validate_boolean , \&run_ls3 , "Display file attributes without owner or group or permissions" ] ,
	"lsk" => [ "b" , OPT_LSK , undef , \&validate_boolean , \&run_lsk , "Display file attributes with file size in KB" ] ,
	"lsm" => [ "b" , OPT_LSM , undef , \&validate_boolean , \&run_lsm , "Display file attributes with file size in MB" ] ,
	"lsn" => [ "b" , OPT_LSM , undef , \&validate_boolean , \&run_lsn , "Display file attributes along with the number of links and inode number" ] ,
	"grep" => [ "s" , OPT_GREP , undef , \&validate_string , \&run_grep , "Case sensitive search on file contents" ] ,
	"igrep" => [ "s" , OPT_IGREP , undef , \&validate_string , \&run_igrep , "Case insensitive search on file contents" ] ,
	"lgrep" => [ "s" , OPT_LGREP , undef , \&validate_string , \&run_lgrep , "List name of file matching pattern" ] ,
	"ngrep" => [ "s" , OPT_NGREP , undef , \&validate_string , \&run_ngrep , "List name of file not matching pattern" ] ,
	"notgrep" => [ "s" , OPT_NOTGREP , undef , \&validate_string , \&run_notgrep , "Test to see if a file does not contain a pattern" ] ,
	"hgrep" => [ "s" , OPT_HGREP , undef , \&validate_string , \&run_hgrep , "Case sensitive search on file contents with highliting" ] ,
	"ihgrep" => [ "s" , OPT_IHGREP , undef , \&validate_string , \&run_ihgrep , "Case sensitive search on file contents with highliting" ] ,
	"include" => [ "s" , OPT_INCLUDE , undef , \&validate_string , \&run_include , "Check to see if file includes the pattern" ] ,
	"wc" => [ "b" , OPT_WC , undef , \&validate_boolean , \&run_wc , "Count number of lines in file" ] ,
	"display" => [ "b" , OPT_DISPLAY , undef , \&validate_boolean , \&run_display , "Display contents of file without paging" ] ,
	"num" => [ "b" , OPT_NUM , undef , \&validate_boolean , \&run_num , "Display contents of file with line numers and without paging" ] ,
	"page" => [ "b" , OPT_PAGE , undef , \&validate_boolean , \&run_page , "Display contents of file with paging" ] ,
	"head" => [ "i" , OPT_HEAD , undef , \&validate_number , \&run_head , "List the first few lines of a file" ] ,
	"minsize" => [ "i" , OPT_MINSIZE , undef , \&validate_number , \&run_minsize , "Check file for minimum size" ] ,
	"maxsize" => [ "i" , OPT_MAXSIZE , undef , \&validate_number , \&run_maxsize , "Check file for minimum size" ] ,
	"tail" => [ "i" , OPT_TAIL , undef , \&validate_number , \&run_tail , "List the last few lines of a file" ] ,
	"touch" => [ "b" , OPT_TOUCH , undef , \&validate_number , \&run_touch , "Update last modified date for file" ] ,
	"minkb" => [ "i" , OPT_MINKB , undef , \&validate_number , \&run_minkb , "Check file for minimum size in terms of KB" ] ,
	"maxkb" => [ "i" , OPT_MAXKB , undef , \&validate_number , \&run_maxkb , "Check file for minimum size in terms of KB" ] ,
	"minmb" => [ "i" , OPT_MINMB , undef , \&validate_number , \&run_minmb , "Check file for minimum size in terms of MB" ] ,
	"maxmb" => [ "i" , OPT_MAXMB , undef , \&validate_number , \&run_maxmb , "Check file for minimum size in terms of MB" ] ,
	"expand" => [ "i" , OPT_EXPAND , undef , \&validate_number , \&run_expand , "Expand tabs to spaces" ] ,
	"hex" => [ "b" , OPT_HEXDUMP , undef , \&validate_boolean , \&run_hex , "Do a hex/char dump of a file" ] ,
	"empty" => [ "b" , OPT_EMPTY , undef , \&validate_boolean , \&run_empty , "Test to see if a file is empty" ] ,
	"text" => [ "b" , OPT_TEXT , undef , \&validate_boolean , \&run_text , "Test to see if a file is a text file" ] ,
	"image" => [ "b" , OPT_IMAGE , undef , \&validate_boolean , \&run_image , "Test to see if a file is an image file" ] ,
	"mingb" => [ "i" , OPT_MINGB , undef , \&validate_number , \&run_mingb , "Check file for minimum size in terms of GB" ] ,
	"and" => [ "s" , OPT_AND , undef , \&validate_string , \&run_and , "Check to see if a file contains all of the double-colon-separated patterns (case insensitive)" ] ,
	"listdir" => [ "b" , OPT_LISTDIR , undef , \&validate_boolean , \&run_listdir , "Display directory contents" ] ,
	"hline" => [ "i" , OPT_HLINE , undef , \&validate_number , \&run_hline , "Display a horizontal line" ] ,
	"ipgrep" => [ "b" , OPT_IP_GREP , undef , \&validate_boolean , \&run_ipgrep , "Search file contents for records with an ip address" ] ,
	"notmine" => [ "b" , OPT_NOTMINE , undef , \&validate_boolean , \&run_notmine , "Check to see if the file is not owned by the effective userid" ] ,
	"count" => [ "b" , OPT_COUNT , undef , \&validate_boolean , \&run_count , "Count matched entries" ] ,
	"numlinks" => [ "i" , OPT_NUM_LINKS , undef , \&validate_number , \&run_numlinks , "Look for files that do not have the specified number of links" ] ,
) ;

my $num_dirs_processed = 0;
my $num_names_matched = 0;
my ( $bold , $normal );
my $bold_color = 'white';
my $options_text;
my %img_extensions = ( "gif" => 0 , "jpg" => 0 , "jpeg" => 0 , "png" => 0 , "bmp" => 0 );

######################################################################
#
# Function  : debug_print
#
# Purpose   : Optionally print a debugging message.
#
# Inputs    : @_ - array comprising the message
#
# Output    : the specified message
#
# Returns   : nothing
#
# Example   : debug_print("Filename is $file\n");
#
# Notes     : (none)
#
######################################################################

sub debug_print
{
	if ( $flags{"d"} ) {
			print "+++ ",join("",@_);
	} # IF

	return;
} # end of debug_print

######################################################################
#
# Function  : build_options
#
# Purpose   : Build a string describing the list of options
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : build_options();
#
# Notes     : (none)
#
######################################################################

sub build_options
{
	my ( @opts , $maxlen , $ref , @info );

	@opts = sort { lc $a cmp lc $b } keys %options;
	$maxlen = (sort { $b <=> $a} map { length $_ } @opts)[0];
	$options_text = "";
	foreach my $opt ( @opts ) {
		$ref = $options{$opt};
		@info = @$ref;
		$options_text .= sprintf "%-${maxlen}.${maxlen}s %s\n",$opt,$info[5];
	} # FOREACH

	return;
} # end of build_options

######################################################################
#
# Function  : add_node
#
# Purpose   : Add a node to the list of options.
#
# Inputs    : $_[0] - opcode value
#             $_[1] - opcode name
#             $_[2] - data value
#             $_[3] - reference to process this opcode
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : add_node($dirname);
#
# Notes     : (none)
#
######################################################################

sub add_node
{
	my ( $opcode , $name , $data , $func ) = @_;
	my ( $node );

	if ( $opcode >= 0 ) {
		$node = Find_Option->new();
		$node->opcode($opcode);
		$node->opt_name($name);
		$node->data($data);
		$node->function($func);
		push @find_options,$node;
	} # IF

	return;
} # end of add_node

######################################################################
#
# Function  : valaidate_number
#
# Purpose   : Validate a numeric value.
#
# Inputs    : $_[0] - numeric value
#
# Output    : (none)
#
# Returns   : If valid Then 1 Else 0
#
# Example   : validate_number($number);
#
# Notes     : (none)
#
######################################################################

sub validate_number
{
	my ( $value ) = @_;
	my ( $status );
	
	$status = ($value =~ m/\D/) ? 0 : 1;
	return $status;
} # end of validate_number

######################################################################
#
# Function  : validate_string
#
# Purpose   : Validate a character string.
#
# Inputs    : $_[0] - character string
#
# Output    : (none)
#
# Returns   : If valid Then 1 Else 0
#
# Example   : validate_string($string);
#
# Notes     : (none)
#
######################################################################

sub validate_string
{
	my ( $value ) = @_;
	my ( $status );
	
	$status = 1;
	return $status;
} # end of validate_string

######################################################################
#
# Function  : run_print
#
# Purpose   : Execute a "-print" option.
#
# Inputs    : (none)
#
# Output    : name of current entry
#
# Returns   : 1
#
# Example   : $status = run_print();
#
# Notes     : (none)
#
######################################################################

sub run_print
{
	my ( $status );
	
	print "$entry_path\n";
	$status = 1;
	return $status;
} # end of run_print

######################################################################
#
# Function  : dump_class
#
# Purpose   : List the members of a class list.
#
# Inputs    : $_[0] - reference to class list array
#             $_[1] - title for listing of class
#             $_[2] - directory name
#
# Output    : Listing of class members
#
# Returns   : nothing
#
# Example   : dump_class(\@class,$title,$dirname);
#
# Notes     : (none)
#
######################################################################

sub dump_class
{
	my ( $class_ref , $title , $dirname ) = @_;
	my ( $entry , $count , $maxlen , $line_size , $line_limit );

	$line_limit = 100;
	$count = scalar @$class_ref;
	if ( $count > 0 ) {
		$maxlen = (sort { $b <=> $a } map { length $_ } @$class_ref)[0];
		print "\nFound $count $title under $dirname\n";
		unless ( $options{"F"} ) {
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
		} # UNLESS
	} # IF
	return;
} # end of dump_class

######################################################################
#
# Function  : run_listdir
#
# Purpose   : Execute a "-listdir" option.
#
# Inputs    : (none)
#
# Output    : listing of directory contents
#
# Returns   : 1
#
# Example   : $status = run_listdir();
#
# Notes     : (none)
#
######################################################################

sub run_listdir
{
	my ( $status , %entries , $path );
	my ( @files , @dirs , @symlinks , @fifo , @sockets , @blocks , @chars , @misc );
	
	## print "$entry_path\n";
	if ( opendir(DIR,"$entry_path") ) {
		$status = 1;
		%entries = map { $_ , 0 } readdir DIR;
		closedir DIR;
		delete $entries{".."};
		delete $entries{"."};
		@files = ();
		@dirs = ();
		@symlinks = ();
		@fifo = ();
		@sockets = ();
		@blocks = ();
		@chars = ();
		@misc = ();
		foreach my $entry ( keys %entries ) {
			$path = File::Spec->catfile($entry_path,$entry);
			if ( -l $path ) {
				push @symlinks,$entry;
			} # IF
			elsif ( -d $path ) {
				push @dirs,$entry;
			} # ELSIF
			elsif ( -f $path ) {
				push @files,$entry;
			} # ELSIF
			elsif ( -p $path ) {
				push @fifo,$entry;
			} # ELSIF
			elsif ( -S $path ) {
				push @sockets,$entry;
			} # ELSIF
			elsif ( -r $path ) {
				push @blocks,$entry;
			} # ELSIF
			elsif ( -c $path ) {
				push @chars,$entry;
			} # ELSIF
			else {
				push @misc,$entry;
			} # ELSIF
		} # FOREACH
		dump_class(\@files,"Files",$entry_path);
		dump_class(\@dirs,"Directories",$entry_path);
		dump_class(\@symlinks,"Symbolic Links",$entry_path);
		dump_class(\@fifo,"Named Pipes (FIFO)",$entry_path);
		dump_class(\@sockets,"Sockets",$entry_path);
		dump_class(\@blocks,"Block Special Files",$entry_path);
		dump_class(\@chars,"Character Special Files",$entry_path);
		dump_class(\@misc,"Miscellaneous",$entry_path);
	} # IF
	else {
		warn("opendir failed for '$entry_path' : $!\n");
		$status = 0;
	} # ELSE
	print "\n";

	return $status;
} # end of run_listdir

######################################################################
#
# Function  : run_newline
#
# Purpose   : Execute a "-newline" option.
#
# Inputs    : (none)
#
# Output    : blank line
#
# Returns   : 1
#
# Example   : $status = run_newline();
#
# Notes     : (none)
#
######################################################################

sub run_newline
{
	my ( $status );
	
	print "\n";
	$status = 1;
	return $status;
} # end of run_newline

######################################################################
#
# Function  : run_touch
#
# Purpose   : Execute a "-touch" option.
#
# Inputs    : (none)
#
# Output    : name of current entry
#
# Returns   : 1
#
# Example   : $status = run_touch();
#
# Notes     : (none)
#
######################################################################

sub run_touch
{
	my ( $status , $clock );
	
	$clock = time;
	if ( utime $clock,$clock,$entry_path ) {
		$status = 1;
	} # IF
	else {
		$status = 0;
		print "touch failed for $entry_path : $!\n";
	} # ELSE

	return $status;
} # end of run_touch

######################################################################
#
# Function  : run_name
#
# Purpose   : Execute a "-name" option.
#
# Inputs    : $_[0] - name pattern
#
# Output    : (none)
#
# Returns   : If name matches pattern Then 1 Else 0
#
# Example   : $status = run_name($name_pattern);
#
# Notes     : (none)
#
######################################################################

sub run_name
{
	my ( $name ) = @_;
	my ( $status );
	
	if ( $entry_name =~ m/${name}/ ) {
		$status = 1;
		$num_names_matched += 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	return $status;
} # end of run_name

######################################################################
#
# Function  : run_exactname
#
# Purpose   : Execute a "-exactname" option.
#
# Inputs    : $_[0] - full name
#
# Output    : (none)
#
# Returns   : If name matches pattern Then 1 Else 0
#
# Example   : $status = run_exactname($exactname);
#
# Notes     : (none)
#
######################################################################

sub run_exactname
{
	my ( $name ) = @_;
	my ( $status );
	
	if ( $entry_name eq $name ) {
		$status = 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	return $status;
} # end of run_exactname

######################################################################
#
# Function  : run_exactiname
#
# Purpose   : Execute a "-exactiname" option.
#
# Inputs    : $_[0] - full name
#
# Output    : (none)
#
# Returns   : If name matches pattern Then 1 Else 0
#
# Example   : $status = run_exactiname($exactiname);
#
# Notes     : (none)
#
######################################################################

sub run_exactiname
{
	my ( $name ) = @_;
	my ( $status );
	
	if ( lc $entry_name eq lc $name ) {
		$status = 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	return $status;
} # end of run_exactiname

######################################################################
#
# Function  : run_ext
#
# Purpose   : Execute a "-ext" option.
#
# Inputs    : $_[0] - extension pattern
#
# Output    : (none)
#
# Returns   : If extension matches pattern Then 1 Else 0
#
# Example   : $status = run_ext($name_pattern);
#
# Notes     : (none)
#
######################################################################

sub run_ext
{
	my ( $name ) = @_;
	my ( $status , @fields );
	
	$status = 0;
	if ( $entry_name =~ m/\./ ) {
		@fields = split(/\./,$entry_name);
		if ( lc $fields[$#fields] eq lc $name ) {
			$status = 1;
		} # IF
	} # IF

	return $status;
} # end of run_ext

######################################################################
#
# Function  : run_iname
#
# Purpose   : Execute a "-iname" option.
#
# Inputs    : $_[0] - name pattern
#
# Output    : (none)
#
# Returns   : If name matches pattern Then 1 Else 0
#
# Example   : $status = run_iname($name_pattern);
#
# Notes     : (none)
#
######################################################################

sub run_iname
{
	my ( $name ) = @_;
	my ( $status );
	
	if ( $entry_name =~ m/${name}/i ) {
		$status = 1;
		$num_names_matched += 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	return $status;
} # end of run_iname

######################################################################
#
# Function  : run_type
#
# Purpose   : Execute a "-type" option.
#
# Inputs    : $_[0] - file type selection
#
# Output    : (none)
#
# Returns   : If type of current entry matches argument Then 1 Else 0
#
# Example   : $status = run_type($ftype);
#
# Notes     : (none)
#
######################################################################

sub run_type
{
	my ( $type ) = @_;
	my ( $status , $value );

	$value = $current_opt->data();
	if ( $entry_type eq $value ) {
		$status = 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	debug_print "run_type() : return status = $status\n";
	return $status;
} # end of run_type

######################################################################
#
# Function  : run_delete
#
# Purpose   : Execute a "-delete" option.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : If file successfully deleted Then 1 Else 0
#
# Example   : $status = run_delete();
#
# Notes     : (none)
#
######################################################################

sub run_delete
{
	my ( $reply , $status );
	
	print "Delete ${entry_path} ? ";
	$reply = lc <STDIN>;
	chomp $reply;
	$status = 1;
	if ( $reply eq "y" || $reply eq "yes" ) {
		unless ( 1 == unlink ${entry_path} ) {
			warn("unlink() failed for '$entry_path' : $!\n");
			$status = 0;
		} # UNLESS
	} # IF
	return $status;
} # end of run_delete

######################################################################
#
# Function  : run_kill
#
# Purpose   : Execute a "-kill" option.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : If file successfully deleted Then 1 Else 0
#
# Example   : $status = run_kill();
#
# Notes     : (none)
#
######################################################################

sub run_kill
{
	my ( $status );
	
	$status = 1;
	unless ( 1 == unlink ${entry_path} ) {
		warn("unlink() failed for '$entry_path' : $!\n");
		$status = 0;
	} # UNLESS
	return $status;
} # end of run_kill

######################################################################
#
# Function  : run_ls
#
# Purpose   : Execute a "-ls" option.
#
# Inputs    : (none)
#
# Output    : Information for current file
#
# Returns   : 1
#
# Example   : $status = run_ls();
#
# Notes     : (none)
#
######################################################################

sub run_ls
{
	my ( %opt );

	%opt = ( "l" => 1 , "g" => 0 , "o" => 0 , "k" => 0 );
	list_file_info_full($entry_path,\%opt);

	return 1;
} # end of run_ls

######################################################################
#
# Function  : run_lsn
#
# Purpose   : Execute a "-lsn" option.
#
# Inputs    : (none)
#
# Output    : Information for current file
#
# Returns   : 1
#
# Example   : $status = run_lsn();
#
# Notes     : (none)
#
######################################################################

sub run_lsn
{
	my ( %opt );

	%opt = ( "l" => 1 , "g" => 0 , "o" => 0 , "k" => 0 , "n" => 1 , "i" => 1 );
	list_file_info_full($entry_path,\%opt);

	return 1;
} # end of run_lsn

######################################################################
#
# Function  : run_ls2
#
# Purpose   : Execute a "-ls2" option.
#
# Inputs    : (none)
#
# Output    : Information for current file
#
# Returns   : 1
#
# Example   : $status = run_ls2();
#
# Notes     : (none)
#
######################################################################

sub run_ls2
{
	my ( %opt );

	%opt = ( "l" => 1 , "g" => 1 , "o" => 1 , "k" => 0 , "m" => 0 );
	list_file_info_full($entry_path,\%opt);

	return 1;
} # end of run_ls2

######################################################################
#
# Function  : run_ls3
#
# Purpose   : Execute a "-ls3" option.
#
# Inputs    : (none)
#
# Output    : Information for current file
#
# Returns   : 1
#
# Example   : $status = run_ls3();
#
# Notes     : (none)
#
######################################################################

sub run_ls3
{
	my ( %opt );

	%opt = ( "l" => 1 , "g" => 1 , "o" => 1 , "k" => 0 , "m" => 1 );
	list_file_info_full($entry_path,\%opt);

	return 1;
} # end of run_ls3

######################################################################
#
# Function  : run_lsk
#
# Purpose   : Execute a "-lsk" option.
#
# Inputs    : (none)
#
# Output    : Information for current file
#
# Returns   : 1
#
# Example   : $status = run_lsk();
#
# Notes     : (none)
#
######################################################################

sub run_lsk
{
	my ( %opt );

	%opt = ( "l" => 1 , "g" => 0 , "o" => 0 , "k" => 1 );
	list_file_info_full($entry_path,\%opt);

	return 1;
} # end of run_lsk

######################################################################
#
# Function  : run_lsm
#
# Purpose   : Execute a "-lsm" option.
#
# Inputs    : (none)
#
# Output    : Information for current file
#
# Returns   : 1
#
# Example   : $status = run_lsm();
#
# Notes     : (none)
#
######################################################################

sub run_lsm
{
	my ( %opt );

	%opt = ( "l" => 1 , "g" => 0 , "o" => 0 , "k" => 1 );
	list_file_info_full($entry_path,\%opt);

	return 1;
} # end of run_lsm

######################################################################
#
# Function  : run_grep
#
# Purpose   : Execute a "-grep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_grep();
#
# Notes     : (none)
#
######################################################################

sub run_grep
{
	my ( $pattern ) = @_;
	my ( @records , @matches );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	chomp @records;
	@matches = grep /${pattern}/,@records;
	close INPUT;
	if ( 0 < scalar @matches ) {
		print "\n",join("\n",map { "${entry_path}:$_" } @matches),"\n\n";
	} # IF
	return 1;
} # end of run_grep

######################################################################
#
# Function  : run_igrep
#
# Purpose   : Execute a "-igrep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_igrep();
#
# Notes     : (none)
#
######################################################################

sub run_igrep
{
	my ( $pattern ) = @_;
	my ( @matches , @records );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	chomp @records;
	@matches = grep /${pattern}/i,@records;
	close INPUT;
	if ( 0 < scalar @matches ) {
		print "\n",join("\n",map { "${entry_path}:$_" } @matches),"\n\n";
	} # IF
	return 1;
} # end of run_igrep

######################################################################
#
# Function  : run_hgrep
#
# Purpose   : Execute a "-hgrep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_hgrep();
#
# Notes     : (none)
#
######################################################################

sub run_hgrep
{
	my ( $pattern ) = @_;
	my ( @records , $recnum , $buffer , $output , $buffer2 , $oldbuffer , $num_matched );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	close INPUT;
	chomp @records;

	$recnum = 0;
	while ( 0 < scalar @records ) {
		$recnum += 1;
		$oldbuffer = shift @records;
		chomp $oldbuffer;
		$buffer = $oldbuffer;
		if ( $buffer =~ m/${pattern}/ ) {
			$num_matched += 1;
			print "$entry_path:";
			printf "%5d:",$recnum;
			print "\t";

			$output = "";
			$buffer2 = $buffer;
			while ( $buffer2 =~ m/${pattern}/ ) {
				$output .= $`;  # add on PREMATCH
				$output .= "${bold}$&${normal}";  # add on MATCH
				$buffer2 = $';  # buffer2 becomes POSTMATCH
			} # WHILE
			$output .= $buffer2;
			print "$output";

			print "\n";
		} # IF match
	} # WHILE

	return 1;
} # end of run_hgrep

######################################################################
#
# Function  : run_ihgrep
#
# Purpose   : Execute a "-ihgrep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_ihgrep();
#
# Notes     : (none)
#
######################################################################

sub run_ihgrep
{
	my ( $pattern ) = @_;
	my ( @records , $recnum , $buffer , $output , $buffer2 , $oldbuffer , $num_matched );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	close INPUT;
	chomp @records;

	$recnum = 0;
	while ( 0 < scalar @records ) {
		$recnum += 1;
		$oldbuffer = shift @records;
		chomp $oldbuffer;
		$buffer = $oldbuffer;
		if ( $buffer =~ m/${pattern}/i ) {
			$num_matched += 1;
			print "$entry_path:";
			printf "%5d:",$recnum;
			print "\t";

			$output = "";
			$buffer2 = $buffer;
			while ( $buffer2 =~ m/${pattern}/i ) {
				$output .= $`;  # add on PREMATCH
				$output .= "${bold}$&${normal}";  # add on MATCH
				$buffer2 = $';  # buffer2 becomes POSTMATCH
			} # WHILE
			$output .= $buffer2;
			print "$output";

			print "\n";
		} # IF match
	} # WHILE

	return 1;
} # end of run_ihgrep

######################################################################
#
# Function  : run_lgrep
#
# Purpose   : Execute a "-lgrep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : IF match found THEN filename ELSE nothing
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_lgrep();
#
# Notes     : (none)
#
######################################################################

sub run_lgrep
{
	my ( $pattern ) = @_;
	my ( @matches , $status , @records );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	chomp @records;
	@matches = grep /${pattern}/,@records;
	close INPUT;
	if ( 0 < @matches ) {
		print "$entry_path\n";
		$status = 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	return $status;
} # end of run_lgrep

######################################################################
#
# Function  : run_include
#
# Purpose   : Execute a "-include" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : (none)
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_include();
#
# Notes     : (none)
#
######################################################################

sub run_include
{
	my ( $pattern ) = @_;
	my ( @matches , $status , @records );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	chomp @records;
	@matches = grep /${pattern}/,@records;
	close INPUT;
	if ( 0 < @matches ) {
		$status = 1;
	} # IF
	else {
		$status = 0;
	} # ELSE
	return $status;
} # end of run_include

######################################################################
#
# Function  : run_ngrep
#
# Purpose   : Execute a "-ngrep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_ngrep();
#
# Notes     : List the name of the file if it does not contain the specified pattern
#
######################################################################

sub run_ngrep
{
	my ( $pattern ) = @_;
	my ( $buffer );

	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		if ( $buffer =~ m/${pattern}/i ) {
			close INPUT;
			return 0;
		} # IF
	} # WHILE
	
	print "$entry_path\n";
	return 1;
} # end of run_ngrep

######################################################################
#
# Function  : run_notgrep
#
# Purpose   : Execute a "-notgrep" option.
#
# Inputs    : $_[0] - pattern
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_notgrep();
#
# Notes     : Test to see if a file does not contain a pattern
#
######################################################################

sub run_notgrep
{
	my ( $pattern ) = @_;
	my ( $buffer );

	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	while ( $buffer = <INPUT> ) {
		chomp $buffer;
		if ( $buffer =~ m/${pattern}/i ) {
			close INPUT;
			return 0;
		} # IF
	} # WHILE

	return 1;
} # end of run_notgrep

######################################################################
#
# Function  : run_and
#
# Purpose   : Execute a "-and" option.
#
# Inputs    : $_[0] - string containing double colon separated list of patterns
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_and();
#
# Notes     : (none)
#
######################################################################

sub run_and
{
	my ( $pattern ) = @_;
	my ( @patterns , @records , @matches , $num_patterns , $count , $index );
	
	@patterns = split(/::/,$pattern);
	$num_patterns = scalar @patterns;

	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@records = <INPUT>;
	chomp @records;
	$count = 0;
	for ( $index = 0 ; $index < $num_patterns ; ++$index ) {
		@matches = grep /${patterns[$index]}/i,@records;
		if ( 0 == scalar @matches ) {
			return 0;
		} # IF
	} # FOR

	return 1;
} # end of run_and

######################################################################
#
# Function  : run_ipgrep
#
# Purpose   : Execute a "-ipgrep" option.
#
# Inputs    : (none)
#
# Output    : matching lines
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_ipgrep();
#
# Notes     : (none)
#
######################################################################

sub run_ipgrep
{
	my ( @records , $buffer , $save , $handle );
	
	unless ( open($handle,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS


	while ( $buffer = <$handle> ) {
		$save = $buffer;
		$buffer = ":" . $buffer;
		if ( $buffer =~ m/\D(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\D/gms ) {
			print "$entry_path:$save";
		} # IF
	} # WHILE
	close $handle;

	return 1;
} # end of run_ipgrep

######################################################################
#
# Function  : run_wc
#
# Purpose   : Execute a "-wc" option.
#
# Inputs    : (none)
#
# Output    : message indicating number of lines in current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_wc();
#
# Notes     : (none)
#
######################################################################

sub run_wc
{
	my ( @lines , $num_lines , $num_chars );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	$num_lines = scalar @lines;
	$num_chars = 0;
	map { $num_chars += length $_ } @lines;

	print "${entry_path} $num_lines lines , $num_chars bytes\n";
	return 1;
} # end of run_wc

######################################################################
#
# Function  : run_display
#
# Purpose   : Execute a "-display" option.
#
# Inputs    : (none)
#
# Output    : contents of current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_display();
#
# Notes     : (none)
#
######################################################################

sub run_display
{
	my ( @lines );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	print "*** ${entry_path} ***\n",join("", @lines),"\n";
	print "\n*** end of ${entry_path} : ";

	return 1;
} # end of run_display

######################################################################
#
# Function  : run_hex
#
# Purpose   : Execute a "-hex" option.
#
# Inputs    : (none)
#
# Output    : contents of current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_hex();
#
# Notes     : (none)
#
######################################################################

sub run_hex
{
	my ( @lines , $lines , $hex );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	$lines = join("",@lines);
	$hex = hexdump($lines);

	print "*** ${entry_path} ***\n$hex\n";
	print "\n*** end of ${entry_path} : ";

	return 1;
} # end of run_hex

######################################################################
#
# Function  : run_num
#
# Purpose   : Execute a "-num" option.
#
# Inputs    : (none)
#
# Output    : contents of current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_num();
#
# Notes     : (none)
#
######################################################################

sub run_num
{
	my ( @lines , $index );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	print "*** ${entry_path} ***\n";
	for ( $index = 1 ; $index <= scalar @lines ; ++$index ) {
		printf "%3d\t%s",$index,$lines[$index-1];
	} # FOR
	print "\n*** end of ${entry_path} : ";

	return 1;
} # end of run_num

######################################################################
#
# Function  : run_page
#
# Purpose   : Execute a "-page" option.
#
# Inputs    : (none)
#
# Output    : contents of current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_page();
#
# Notes     : (none)
#
######################################################################

sub run_page
{
	my ( @lines , $count , $line , $reply );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	print "*** ${entry_path} ***\n";
	$count = 0;
	foreach $line ( @lines ) {
		if ( $count > 0 && $count%$page_size == 0 ) {
			print "Press <Enter> to continue : ";
			$reply = lc <STDIN>;
			if ( $reply eq "q\n" || $reply eq "quit\n" ) {
				last;
			} # IF
		} # IF
		++$count;
		print $line;
	} # FOREACH
	print "\n*** end of ${entry_path} : ";
	<STDIN>;

	return 1;
} # end of run_page

######################################################################
#
# Function  : run_head
#
# Purpose   : Execute a "-head" option.
#
# Inputs    : $_[0] - head size
#
# Output    : contents of current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_head(10);
#
# Notes     : (none)
#
######################################################################

sub run_head
{
	my ( $head_size ) = @_;
	my ( @lines , $num_lines , @numbers );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	$num_lines = scalar @lines;
	if ( $num_lines <= $head_size ) {
		print "\n*** First $num_lines lines of ${entry_path} ***\n";
		@numbers = map { sprintf "%2d",$_ } ( 1 .. $num_lines );
		print join("", map { "$numbers[$_] $lines[$_]" } (0 .. $num_lines-1));
	} # IF
	else {
		print "\n*** First $head_size lines of ${entry_path} ***\n";
		@numbers = map { sprintf "%2d",$_ } ( 1 .. $head_size );
		print join("", map { "$numbers[$_] $lines[$_]" } (0 .. $head_size-1));
	} # ELSE
	print "\n";

	return 1;
} # end of run_head

######################################################################
#
# Function  : run_minsize
#
# Purpose   : Execute a "-minsize" option.
#
# Inputs    : $_[0] - minimum file size size
#
# Output    : (none)
#
# Returns   : If filesize meets minimum size requirement Then 1 Else 0
#
# Example   : $status = run_minsize(1000);
#
# Notes     : (none)
#
######################################################################

sub run_minsize
{
	my ( $minimum_size ) = @_;
	my ( $status );

	$status = ( $entry_lstat->size >= $minimum_size ) ? 1 : 0;
	
	return $status;
} # end of run_minsize

######################################################################
#
# Function  : run_minkb
#
# Purpose   : Execute a "-minkb" option.
#
# Inputs    : $_[0] - minimum number of KB for filesize
#
# Output    : (none)
#
# Returns   : If filesize meets minimum size requirement Then 1 Else 0
#
# Example   : $status = run_minkb(1000);
#
# Notes     : (none)
#
######################################################################

sub run_minkb
{
	my ( $minimum_size ) = @_;
	my ( $status );

	##  $status = ( ( $entry_lstat->size / 1024 ) >= $minimum_size ) ? 1 : 0;
	$status = ( ( $entry_lstat->size >> 10 ) >= $minimum_size ) ? 1 : 0;
	
	return $status;
} # end of run_minkb

######################################################################
#
# Function  : run_minmb
#
# Purpose   : Execute a "-minmb" option.
#
# Inputs    : $_[0] - minimum number of MB for filesize
#
# Output    : (none)
#
# Returns   : If filesize meets minimum size requirement Then 1 Else 0
#
# Example   : $status = run_minmb(1000);
#
# Notes     : (none)
#
######################################################################

sub run_minmb
{
	my ( $minimum_size ) = @_;
	my ( $status );

	##  $status = ( ( $entry_lstat->size / MEGABYTE ) >= $minimum_size ) ? 1 : 0;
	$status = ( ( $entry_lstat->size >> 20 ) >= $minimum_size ) ? 1 : 0;
	
	return $status;
} # end of run_minmb

######################################################################
#
# Function  : run_mingb
#
# Purpose   : Execute a "-mingb" option.
#
# Inputs    : $_[0] - minimum number of GB for filesize
#
# Output    : (none)
#
# Returns   : If filesize meets minimum size requirement Then 1 Else 0
#
# Example   : $status = run_mingb(1000);
#
# Notes     : (none)
#
######################################################################

sub run_mingb
{
	my ( $minimum_size ) = @_;
	my ( $status );

	##  $status = ( ( $entry_lstat->size / GIGABYTE ) >= $minimum_size ) ? 1 : 0;
	$status = ( ( $entry_lstat->size >> 30 ) >= $minimum_size ) ? 1 : 0;
	
	return $status;
} # end of run_mingb

######################################################################
#
# Function  : run_maxsize
#
# Purpose   : Execute a "-maxsize" option.
#
# Inputs    : $_[0] - maximum file size size
#
# Output    : (none)
#
# Returns   : If filesize meets maximum size requirement Then 1 Else 0
#
# Example   : $status = run_maxsize(1000);
#
# Notes     : (none)
#
######################################################################

sub run_maxsize
{
	my ( $maximum_size ) = @_;
	my ( $status );

	$status = ( $entry_lstat->size <= $maximum_size ) ? 1 : 0;
	
	return $status;
} # end of run_maxsize

######################################################################
#
# Function  : run_maxkb
#
# Purpose   : Execute a "-maxkb" option.
#
# Inputs    : $_[0] - maximum number of KB for filesize
#
# Output    : (none)
#
# Returns   : If filesize meets maximum size requirement Then 1 Else 0
#
# Example   : $status = run_maxkb(1000);
#
# Notes     : (none)
#
######################################################################

sub run_maxkb
{
	my ( $maximum_size ) = @_;
	my ( $status );

	##  $status = ( ( $entry_lstat->size / 1024 ) <= $maximum_size ) ? 1 : 0;
	$status = ( ( $entry_lstat->size >> 10 ) <= $maximum_size ) ? 1 : 0;
	
	return $status;
} # end of run_maxkb

######################################################################
#
# Function  : run_maxmb
#
# Purpose   : Execute a "-maxmb" option.
#
# Inputs    : $_[0] - maximum number of MB for filesize
#
# Output    : (none)
#
# Returns   : If filesize meets maximum size requirement Then 1 Else 0
#
# Example   : $status = run_maxmb(1000);
#
# Notes     : (none)
#
######################################################################

sub run_maxmb
{
	my ( $maximum_size ) = @_;
	my ( $status );

	##  $status = ( ( $entry_lstat->size / MEGABYTE ) <= $maximum_size ) ? 1 : 0;
	$status = ( ( $entry_lstat->size >> 20 ) <= $maximum_size ) ? 1 : 0;
	
	return $status;
} # end of run_maxmb

######################################################################
#
# Function  : run_hline
#
# Purpose   : Execute a "-hline" option.
#
# Inputs    : $_[0] - length of horizontal line to be displayed
#
# Output    : (none)
#
# Returns   : 1
#
# Example   : $status = run_hline(20);
#
# Notes     : (none)
#
######################################################################

sub run_hline
{
	my ( $length ) = @_;
	my ( $line );

	$line = "-" x $length;
	print "$line\n";
	
	return 1;
} # end of run_hline

######################################################################
#
# Function  : run_empty
#
# Purpose   : Execute a "-empty" option.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : If file is empty Then 1 Else 0
#
# Example   : $status = run_empty();
#
# Notes     : (none)
#
######################################################################

sub run_empty
{
	my ( $status );

	$status = ( $entry_lstat->size == 0 ) ? 1 : 0;
	
	return $status;
} # end of run_empty

######################################################################
#
# Function  : run_text
#
# Purpose   : Execute a "-text" option.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : If file is a text file Then 1 Else 0
#
# Example   : $status = run_text();
#
# Notes     : (none)
#
######################################################################

sub run_text
{
	my ( $status );

	$status = ( -T $entry_path ) ? 1 : 0;
	
	return $status;
} # end of run_text

######################################################################
#
# Function  : run_image
#
# Purpose   : Execute a "-image" option.
#
# Inputs    : (none)
#
# Output    : (none)
#
# Returns   : If file is an image file Then 1 Else 0
#
# Example   : $status = run_image();
#
# Notes     : (none)
#
######################################################################

sub run_image
{
	my ( $status , @parts );

	$status = 0;
	if ( $entry_name =~ m/\./ ) {
		@parts = split(/\./,$entry_name);
		if ( exists $img_extensions{$parts[$#parts]} ) {
			$status = 1;
		} # IF
	} # IF
	
	return $status;
} # end of run_image

######################################################################
#
# Function  : run_tail
#
# Purpose   : Execute a "-tail" option.
#
# Inputs    : $_[0] - tail size
#
# Output    : contents of current file
#
# Returns   : If no I/O problems Then 1 Else 0
#
# Example   : $status = run_tail(10);
#
# Notes     : (none)
#
######################################################################

sub run_tail
{
	my ( $tail_size ) = @_;
	my ( @lines , $num_lines , $count , @numbers , $line1 , @index );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	$num_lines = scalar @lines;

	if ( $num_lines <= $tail_size ) {
		print "\n*** Last $num_lines lines of ${entry_path} ***\n";
		@numbers = map { sprintf "%2d",$_ } ( 1 .. $num_lines );
		print join("", map { "$numbers[$_] $lines[$_]" } (0 .. $num_lines-1));
	} # IF
	else {
		print "\n*** Last $tail_size lines of ${entry_path} ***\n";
		$line1 = ($num_lines - $tail_size) + 1;
		@numbers = map { sprintf "%2d",$_ } ( $line1 .. $num_lines );
		@index = ( $num_lines - $tail_size .. $#lines );
		## print join("" , map { "$numbers[$_] $lines[$_]" } ( $num_lines - $tail_size .. $#lines ) );
		print join("" , map { "$numbers[$_] $lines[$index[$_]]" } ( 0 .. $#index ));
	} # ELSE
	print "\n";

	return 1;
} # end of run_tail

######################################################################
#
# Function  : run_expand
#
# Purpose   : Execute a "-expand" option.
#
# Inputs    : $_[0] - tab width
#
# Output    : (none)
#
# Returns   : IF problem Then 0 Else 1
#
# Example   : $status = run_expand(4);
#
# Notes     : (none)
#
######################################################################

sub run_expand
{
	my ( $tab_width ) = @_;
	my ( @lines , $expanded );
	
	unless ( open(INPUT,"<$entry_path") ) {
		warn("open failed for '$entry_path' : $!\n");
		return 0;
	} # UNLESS
	@lines = <INPUT>;
	close INPUT;
	print "*** ${entry_path} ***\n";
	chomp @lines;
	foreach my $line ( @lines ) {
		$expanded = expand_tabs($line,$tab_width);
		print "$expanded\n";
	} # FOREACH

	print "\n*** end of ${entry_path} : ";

	return 1;
} # end of run_expand

######################################################################
#
# Function  : run_notmine
#
# Purpose   : Execute a "-notmine" option.
#
# Inputs    : (none)
#
# Output    : name of current entry
#
# Returns   : 1
#
# Example   : $status = run_notmine();
#
# Notes     : (none)
#
######################################################################

sub run_notmine
{
	my ( $status );

	$status = ( $> == $entry_uid ) ? 0 : 1;
	
	return $status;
} # end of run_notmine

######################################################################
#
# Function  : run_count
#
# Purpose   : Execute a "-count" option.
#
# Inputs    : (none)
#
# Output    : name of current entry
#
# Returns   : 1
#
# Example   : $status = run_count();
#
# Notes     : (none)
#
######################################################################

sub run_count
{
	my ( $status );
	
	$entry_count += 1;
	$count_flag = 1;

	return 1;
} # end of run_print

######################################################################
#
# Function  : run_numlinks
#
# Purpose   : Execute a "-numlinks" option.
#
# Inputs    : $_[0] - number of links
#
# Output    : (none)
#
# Returns   : If file does not have the specified number of links THEN 1 Else 0
#
# Example   : $status = run_numlinks(1);
#
# Notes     : (none)
#
######################################################################

sub run_numlinks
{
	my ( $num_links ) = @_;
	my ( $status );

	$status = ( $entry_lstat->nlink != $num_links ) ? 1 : 0;
	
	return $status;
} # end of run_numlinks

######################################################################
#
# Function  : ParseOptions
#
# Purpose   : Add a node to the list of options.
#
# Inputs    : $_[0] - reference to hash describing valid options
#
# Output    : appropriate messages
#
# Returns   : If no problems Then 1 Else 0
#
# Example   : ParseOptions($dirname);
#
# Notes     : (none)
#
######################################################################

sub ParseOptions
{
	my ( $ref_options ) = @_;
	my ( $ref , $option , $count , @option , $type , $ref_data , $equal );
	my ( $validate , $opt_name , $opt_value , $node , $code , $run_func );

	$ref = ref $ref_options;
	unless ( $ref ) {
		warn("Parameter passed to ParseOptions() is not a reference\n");
		return 0;
	} # UNLESS

	unless ( $ref eq "HASH" ) {
		warn("Parameter passed to ParseOptions() is not a reference to a hash\n");
		return 0;
	} # UNLESS

	while ( 0 < scalar @ARGV ) {
		unless ( "-" eq substr($ARGV[0],0,1) ) {
			last;
		} # UNLESS
		$opt_name = shift @ARGV;
		$opt_name = substr $opt_name,1; # trim the "-"

		unless ( exists $$ref_options{$opt_name} ) {
			warn("Invalid option '$opt_name'\n");
			return 0;
		} # UNLESS
		$ref = $$ref_options{$opt_name};
		@option = @$ref;
		$count = scalar @option;
		$type = $option[0];
		$code = $option[1];
		$ref_data = $option[2];
		$validate = $option[3];
		$run_func = $option[4];
		if ( $type eq OPT_BOOLEAN ) {
			if ( defined $ref_data ) {
				$$ref_data = 1;
			} # IF
			add_node($code,$opt_name,1,$run_func);
		} elsif ( $type eq OPT_STRING ) {
			unless ( 0 < @ARGV ) {
				warn("Missing string for parameter '$opt_name'\n");
				return 0;
			} # UNLESS
			$opt_value = shift @ARGV;
			if ( defined $validate && ! &$validate($opt_value) ) {
				warn("Value [$opt_value] for parameter $opt_name failed validation\n");
				return 0;
			} # IF
			##  $$ref_data = $opt_value;
			##  add_node($code,$opt_name,$opt_value,$run_func);
			if ( defined $ref_data ) {
				$$ref_data = $opt_value;
			} # IF
			else {
				add_node($code,$opt_name,$opt_value,$run_func);
			} # ELSE
		} elsif ( $type eq OPT_INTEGER ) {
			unless ( 0 < @ARGV ) {
				warn("Missing numeric value for parameter '$opt_name'\n");
				return 0;
			} # UNLESS
			$opt_value = shift @ARGV;
			if ( defined $validate && ! &$validate($opt_value) ) {
				warn("Value [$opt_value] for parameter $opt_name failed validation\n");
				return 0;
			} # IF
			if ( $opt_value =~ m/\D/ ) {
				warn("Non-numeric characters in '$opt_value'\n");
				return 0;
			} # IF
			if ( defined $ref_data ) {
				$$ref_data = $opt_value;
			} # IF
			else {
				add_node($code,$opt_name,$opt_value,$run_func);
			} # ELSE
		} else {
			warn("Unsupported parameter type '$type'\n");
			return 0;
		} # ELSE
	} # WHILE

	return 1;
} # end of ParseOptions

######################################################################
#
# Function  : process_tree
#
# Purpose   : Recursively process a directory tree.
#
# Inputs    : $_[0] - name of directory
#             $_[1] - directory nesting level
#
# Output    : (none)
#
# Returns   : If no problems Then 1 Else 0
#
# Example   : $status = process_tree($dirname,0);
#
# Notes     : (none)
#
######################################################################

sub process_tree
{
	my ( $dirpath , $dir_level ) = @_;
	my ( $path , $status , @entries , @subdirs , $opcode , $func , $value );
	my ( $count , %entries , $basename );

	if ( $flags{'i'} ne "" ) {
		$basename = basename($dirpath);
		if ( $basename =~ m/${flags{'i'}}/i ) {
			return 1;
		} # IF
	}# IF

	$basename = basename($dirpath);
	if ( $flags{"l"} > -1 && $dir_level > $flags{"l"} ) {
		debug_print("\nSkip directory '$dirpath' due to depth\n");
		return 0;
	} # IF

	$num_dirs_processed += 1;
	@subdirs = ();
	if ( $dir_level > 0 && ! (-x $dirpath && -r $dirpath) ) { # skip over subdirs without search and read perms
		return 1;
	} # IF

	unless ( opendir(DIR,"$dirpath") ) {
		warn("opendir failed for '$dirpath' : $!\n");
		return -1;
	} # UNLESS
	@entries = readdir DIR;
	%entries = map { $_ , 1 } @entries;
	delete $entries{"."};
	delete $entries{".."};
	@entries = keys %entries;
	closedir DIR;

	$status = 1;
	foreach $entry_name ( @entries ) {
		$entry_path = File::Spec->catfile($dirpath,$entry_name);
		unless ( $entry_lstat = lstat $entry_path ) {
			die("lstat failed for '$entry_path' : $!\n");
		} # UNLESS
		$entry_uid = $entry_lstat->uid;
		if ( -l $entry_path ) {
			$entry_type = 'l';
			if ( -d $entry_path && is_symlink_parent($entry_path) == 0 ) {
				push @subdirs,$entry_path;
			} # IF
		} elsif ( -f $entry_path ) {
			$entry_type = 'f';
		} elsif ( -d $entry_path ) {
			$entry_type = 'd';
			push @subdirs,$entry_path;
		} elsif ( -p $entry_path ) {
			$entry_type = 'p';
		} elsif ( -S $entry_path ) {
			$entry_type = 's';
		} elsif ( -b $entry_path ) {
			$entry_type = 'b';
		} elsif ( -c $entry_path ) {
			$entry_type = 'c';
		} else {
			$entry_type = '?';
		} # ELSE
		for ( $count = 0 ; $count <= $#find_options ; ++$count ) {
			$current_opt = $find_options[$count];
			$value = $current_opt->data();
			$func = $current_opt->function();
			unless ( defined $func ) {
				print "Option information with undefined function reference\n",Dumper($current_opt),"\n";
				stack_backtrace(\*STDERR,0,"Start of stack dump","End of stack dump",1);
				exit 1;
			} # UNLESS
			unless ( &$func($value) ) {
				$status = 0;
				last;
			} # UNLESS
		} # FOREACH
	} # FOREACH

	foreach $path ( @subdirs ) {
		process_tree($path,1+$dir_level);
	} # FOREACH

	return $status;
} # end of process_tree

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
# Example   : find1.pl . -type f -print
#
# Notes     : (none)
#
######################################################################

MAIN:
{
my ( $status , $count , $startdir , $buffer , $hostname , $message );

build_options();

@prog_parms = @ARGV;
$count = scalar @ARGV;
if ( $count > 0 && ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") ) {
	display_pod_help($0);
	print "$options_text\n";
	exit 0;
} # IF

if ( $count == 0 || "-" eq substr$ARGV[0],0,1 ) {
	$buffer = basename($0);

	$message = "Usage : $buffer dirname {options}\n";
	$message .= "\n$options_text\n";

	die("\n$message\nGoodbye ...\n");
} # IF
$start_dir = shift @ARGV;
$start_time = time;
$int_start_time = [gettimeofday()];

$bold = color "reverse $bold_color";
$normal = color 'reset';

@find_options = ();

$status = ParseOptions(\%options);
unless ( $status ) {
	die("Error in parameters\n");
} # UNLESS
if ( $flags{"e"} ) {
	$startdir = getcwd();
	print "$0",join(" ",@prog_parms),"\nstarting directory = '$startdir'\n\n";
} # IF

$status = process_tree($start_dir,0);

if ( $count_flag ) {
	print "\nentry count = $entry_count\n";
} # IF

$end_time = time;
$int_end_time = [gettimeofday()];
$int_elapsed_time = tv_interval($int_start_time,$int_end_time);
elapsed_time("\nElapsed Time : %d minutes %d seconds\n",$start_time,$end_time);
elapsed_interval_time("\nElapsed Time : (%s seconds) %d minutes %d seconds\n",$int_start_time,$int_end_time);

if ( $flags{'s'} ) {
	$buffer = localtime $start_time;
	$hostname = hostname;
	print "\nStarted $buffer on $hostname\n";
} # IF

if ( $flags{"S"} ) {
	print "\nNUmber of directories processed = $num_dirs_processed\n";
	print "\nNumber of names matched = $num_names_matched\n";
} # IF

print "\n";

exit 0;
} # end of MAIN
__END__
=head1 NAME

myfind.pl - Perl version of UNIX find command

=head1 SYNOPSIS

myfind.pl dirname [options]

=head1 DESCRIPTION

Perl version of UNIX find command

=head1 OPTIONS

  (many)
  Just issue the command without any parameters and you will see a list of options

=head1 EXAMPLES

myfind.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
