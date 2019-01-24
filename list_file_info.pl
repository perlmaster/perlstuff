#!/usr/bin/perl
 
######################################################################
#
# File      : list_file_info.pl
#
# Author    : Barry Kimelman
#
# Created   : May 3, 2016
#
# Purpose   : Display info for files similar to "ls -ld" output
#
# Notes     : (none)
#
######################################################################
 
use strict;
use warnings;
use Getopt::Std;
use File::stat;
use Fcntl;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;
 
require "time_date.pl";
require "comma_format.pl";
require "format_mode.pl";
require "size_to_gb.pl";
 
my $kb = 1 << 10;
my $mb = 1 << 20;
my $gb = 1 << 30;
 
######################################################################
#
# Function  : list_file_info
#
# Purpose   : List the detailed information for the specified files.
#
# Inputs    : $_[0] - filename
#             $_[1] - reference to hash of options
#
# Output    : file info
#
# Returns   : IF problem THEN negative ELSE zero
#
# Example   : $status = list_file_info($path,\%options);
#
# Notes     : (none)
#
######################################################################
 
sub list_file_info
{
	my ( $path , $ref_options ) = @_;
	my ( $index , $status , $mode );
	my ( $perms , $string , $filesize , $count );
 
	$status = stat($path);
	unless ( $status ) {
		warn("stat failed for '$path' : $!\n");
		return -1;
	} # UNLESS
	else {
		if ( $ref_options->{"f"} ) {
			print "$path\n";
		} # IF
		else {
			$string = format_time_date($status->mtime,"hhmmss");
			$mode = format_mode($status->mode);
			if ( $ref_options->{"k"} ) {
				$filesize = size_to_gb($status->size);
			} # IF
			else {
				$filesize = comma_format($status->size);
			} # ELSE
			if ( $ref_options->{'i'} ) {
				printf "%11d ",$status->ino;
			} # IF
			printf "%s%12s %s %s\n",$mode,$filesize, $string,$path;
		} # ELSE
	} # ELSE
 
	return 0;
} # end of list_file_info
 
######################################################################
#
# Function  : list_file_info_full
#
# Purpose   : List the detailed information for the specified files.
#
# Inputs    : $_[0] - filename
#             $_[1] - reference to hash of options
#             $_[2] - reference to hash of owners (key = uid , value = owner name)
#             $_[3] - reference to hash of groups (key = gid , value = group name)
#
# Output    : file info
#
# Returns   : IF problem THEN negative ELSE zero
#
# Example   : $status = list_file_info_full($path,\%options,\%owners,\%groups);
#
# Notes     : (none)
#
######################################################################
 
sub list_file_info_full
{
	my ( $path , $ref_options , $ref_owners , $ref_groups ) = @_;
	my ( $index , $status , $mode , @list , $owner , $group );
	my ( $perms , $string , $filesize , $count );
 
	$status = stat($path);
	unless ( $status ) {
		warn("stat failed for '$path' : $!\n");
		return -1;
	} # UNLESS
	else {
		if ( $ref_options->{"f"} ) {
			print "$path\n";
		} # IF
		else {
			$string = format_time_date($status->mtime,"hhmmss");
			$mode = format_mode($status->mode);
			if ( $ref_options->{"k"} ) {
				if ( $status->size >= $gb ) {
					$filesize = sprintf "%.2f GB",$status->size / $gb;
				} elsif ( $status->size >= $mb ) {
					$filesize = sprintf "%.2f MB",$status->size / $mb;
				} # IF
				else {
					$filesize = sprintf "%.2f KB",$status->size / $kb;
				} # ELSE
			} # IF
			else {
				$filesize = comma_format($status->size);
			} # ELSE
			if ( $ref_options->{'i'} ) {
				printf "%11d ",$status->ino;
			} # IF
			if ( $ref_options->{'m'} ) {
				printf "[%s]",substr($mode,0,1);
			} # IF
			else {
				printf "%s",$mode;
			} # ELSE
			if ( $ref_options->{'n'} ) {
				printf " %3d",$status->nlink;
			} # IF

			unless ( $ref_options->{'o'} ) {
				if ( defined $ref_owners && exists $ref_owners->{$status->uid} ) {
					$owner = $ref_owners->{$status->uid};
				} # IF
				else {
					if ( $^O =~ m/MSWin/ ) {
						$owner = "owner";
					} # IF
					else {
						setpwent();
						@list = getpwuid($status->uid);
						if ( 0 < scalar @list ) {
							$owner = $list[0];
						} # IF
						else {
							$owner = sprintf "uid%d",$status->uid;
						} # ELSE
						endpwent();
					} # ELSE
				} # ELSE
				printf "%14s",$owner;
				if ( defined $ref_owners && ! exists $ref_owners->{$status->uid} ) {
					$ref_owners->{$status->uid} = $owner;
				} # IF
			} # UNLESS

			unless ( $ref_options->{'g'} ) {
				if ( defined $ref_groups && exists $ref_groups->{$status->gid} ) {
					$group = $ref_groups->{$status->gid};
				} # IF
				else {
					if ( $^O =~ m/MSWin/ ) {
						$group = "group";
					} # IF
					else {
						setgrent();
						@list = getgrgid($status->gid);
						if ( 0 < scalar @list ) {
							$group = $list[0];
						} # IF
						else {
							$group = sprintf "uid%d",$status->gid;
						} # ELSE
						endpwent();
					} # ELSE
				} # ELSE
				printf "%10s",$group;
				if ( defined $ref_groups && ! exists $ref_groups->{$status->gid} ) {
					$ref_groups->{$status->gid} = $group;
				} # IF
			} # UNLESS

			printf "%14s %s %s\n",$filesize, $string,$path;
		} # ELSE
	} # ELSE
 
	return 0;
} # end of list_file_info_full
 
1;
