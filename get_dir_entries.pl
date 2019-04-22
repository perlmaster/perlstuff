#!/usr/bin/perl

######################################################################
#
# File      : get_dir_entries.pl
#
# Author    : Barry Kimelman
#
# Created   : May 15, 2017
#
# Purpose   : Get the entries from a directory
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Switch;
use Fcntl ':mode';
use File::Spec;

######################################################################
#
# Function  : get_dir_entries
#
# Purpose   : Get the entries from a directory
#
# Inputs    : $_[0] - directory name
#             $_[1] - reference to hash of options
#                     { 'dot' - keep (1) or delete (0) '.' and '..' )
#                     ( 'qual' - add (1) or do not add (0) path qualification )
#                     ( 'sort' - sort names (1) or do not sort names (0) )
#             $_[2] - reference to array to receive list of directory entries
#             $_[3] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF problem THEN negative ELSE zero
#
# Example   : $status = get_dir_entries($dirname,{ 'dot' => 0 , 'qual' => 0 , 'sort' => 0 },\@entries,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub get_dir_entries
{
	my ( $dirname , $ref_options , $ref_entries , $ref_errmsg ) = @_;
	my ( %entries , @entries );

	$$ref_errmsg = "";
	@$ref_entries = ();
	unless ( opendir(DIR,"$dirname") ) {
		$$ref_errmsg = "opendir failed for '$dirname' : $!";
		return -1;
	} # UNLESS
	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	unless ( $ref_options->{'dot'} ) {
		delete $entries{'..'};
		delete $entries{'.'};
	} # UNLESS
	@entries = keys %entries;
	if ( $ref_options->{'sort'} ) {
		@entries = sort { lc $a cmp lc $b } @entries;
	} # IF
	if ( $ref_options->{'qual'} ) {
		@$ref_entries = map { File::Spec->catfile($dirname,$_) } @entries;
	} # IF
	else {
		@$ref_entries = @entries;
	} # ELSE

	return scalar @$ref_entries;
} # end of get_dir_entries

1;
