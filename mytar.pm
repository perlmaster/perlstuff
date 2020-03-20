#!C:\Perl64\bin\perl.exe -w

package mytar;

######################################################################
#
# File      : mytar.pm
#
# Author    : Barry Kimelman
#
# Created   : March 18, 2020
#
# Purpose   : Module to process tar files
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

BEGIN
{
    use Exporter   ();
    use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 1.00;

    @ISA         = qw(Exporter);
    @EXPORT      = qw( );

    # your exported package globals go here,
    # as well as any optionally exported functions

    @EXPORT_OK   = qw( @members_names %members_info $num_members &init_tar_file_processing
						&read_member_contents );
}
use vars      @EXPORT_OK;

use constant TBLOCK_SIZE => 512;  # length of TAR header and data blocks
use constant TNAMLEN => 100;      # max length for TAR file names
use constant TMODLEN => 8;        # length of mode field
use constant TUIDLEN => 8;        # length of uid field
use constant TGIDLEN => 8;        # length of gid field
use constant TSIZLEN => 12;       # length of size field
use constant TTIMLEN => 12;       # length of modification time field

use constant TCRCLEN => 8;        # length of header checksum field

# initialize package globals, first exported ones

@members_names = ( );

######################################################################
#
# Function  : read_member_contents
#
# Purpose   : Read in the contents of a tar file member
#
# Inputs    : $_[0] - name of tarfile
#             $_[1] - name of tarfile member
#             $_[2] - reference to buffer to receive data
#             $_[3] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF problem THEN negative ELSE member file size
#
# Example   : $member_size = read_member_contents($tarfile,$member_name,\$buffer,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub read_member_contents
{
	my ( $tarfile , $member_name , $ref_buffer , $ref_errmsg ) = @_;
	my ( $ref_member_attributes , $offset , $file_size );

	$$ref_errmsg = "";
	$ref_member_attributes = $members_info{$member_name};
	unless ( defined $ref_member_attributes ) {
		$$ref_errmsg = "$member_name is not a member of $tarfile";
		return -1;
	} # UNLESS

	$offset = $ref_member_attributes->{member_offset};
	if ( seek(TAR,$offset,0) < 0 ) {
		$$ref_errmsg = "seek to $offset failed : $!";
		return -1;
	} # IF
	$file_size = $ref_member_attributes->{member_size_decimal};
	if ( sysread(TAR,$$ref_buffer,$file_size) != $file_size ) {
		$$ref_errmsg = "Could not read all $file_size bytes : $!";
		return -1;
	} # IF

	return $file_size;
} # end of read_member_contents

######################################################################
#
# Function  : init_tar_file_member
#
# Purpose   : Process a member from a TAR file.
#
# Inputs    : $_[0] - name of TAR file
#             $_[1] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF error THEN negative ELSE zero
#
# Example   : $status = init_tar_file_member($tarfile,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub init_tar_file_member
{
	my ( $tarfile , $ref_errmsg ) = @_;
	my ( $header1 , $num_bytes , $member_name , $member_offset , $member_mode );
	my ( $member_uid  , $member_gid  , $member_size , $member_modtime  , $member_crc );
	my ( $number , $member_data , $num_blocks , $last_block_size , $member_size_decimal ) ;
	my ( $member_allocated_bytes , $member_type_flag , $member_link_name , $member_magic );
	my ( $member_version , $member_uname  , $member_gname , $member_devmajor );
	my ( $member_devminor , $member_prefix );

	$$ref_errmsg = "";
	$num_bytes = sysread(TAR,$header1,TBLOCK_SIZE);
	if ( $num_bytes == 0 ) {
		$$ref_errmsg = "EOF on header read\n";
		return -1;
	} # IF
	if ( $num_bytes != TBLOCK_SIZE ) {
		$$ref_errmsg = "Failure reading header from $tarfile : $!";
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
		$$ref_errmsg = "Could only read $num_bytes of $member_allocated_bytes bytes for member $member_name : $!";
		return -1;
	} # IF
	$member_data = substr($member_data, 0, $member_size_decimal);

	return 0;
} # end of init_tar_file_member

######################################################################
#
# Function  : init_tar_file_processing
#
# Purpose   : Initialize the processing of a TAR file.
#
# Inputs    : $_[0] - name of TAR file
#             $_[1] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF problem THEN negative ELSE zero
#
# Example   : $status = init_tar_file_processing($tarfile,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub init_tar_file_processing
{
	my ( $tarfile , $ref_errmsg ) = @_;
	my ( $status , $count );

	$$ref_errmsg = "";
	unless ( sysopen(TAR,$tarfile,O_RDONLY) ) {
		$$ref_errmsg = "sysopen failed for '$tarfile' : $!";
		return -1;
	} # UNLESS

	%members_info = ();
	@members_names = ();
	$count = 0;
	$status = init_tar_file_member($tarfile,$ref_errmsg);
	while ( $status == 0 ) {
		$count += 1;
		$status = init_tar_file_member($tarfile,$ref_errmsg);
	} # WHILE

	if ( $status < 0 ) {
		close TAR;
		return -1;
	} # IF
	@members_names = sort { lc $a cmp lc $b } @members_names;
	$num_members = scalar @members_names;

	return 0;
} # end of init_tar_file_processing

1;

END # module clean-up code here (global destructor)
{
}
