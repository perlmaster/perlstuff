package worldperms;

######################################################################
#
# File      : worldperms.pm
#
# Author    : Barry Kimelman
#
# Created   : March 31, 2017
#
# Purpose   : Perl module to recursively change the world permissions
#             of files under a chosen directory.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use File::Spec;
use File::stat;
use Fcntl;

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

	@EXPORT_OK   = qw( $errmsg );
}
use vars      @EXPORT_OK;

# initialize package globals, first exported ones

$errmsg = "";

######################################################################
#
# Function  : change_world_perms
#
# Purpose   : Change world permissions under a directory tree
#
# Inputs    : $_[0] - directory name
#
# Output    : (none)
#
# Returns   : IF problem THEN zero ELSE Negative
#
# Example   : $status = change_world_perms($dirname);
#
# Notes     : (none)
#
######################################################################

sub change_world_perms
{
	my ( $dirname ) = @_;
	my ( $path , $stats , %entries , @subdirs , $world_mode , $new_perms );

	unless ( opendir(DIR,"$dirname") ) {
		$errmsg = "opendir failed for '$dirname' : $!";
		return -1;
	} # UNLESS

	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	@subdirs = ();
	foreach my $entry ( keys %entries ) {
		$path = File::Spec->catfile($dirname,$entry);
		if ( -d "$path" ) {
			push @subdirs,$path;
		} # IF
		else {
			$stats = stat($path);
			unless ( defined $stats ) {
				$errmsg = "Can't get statsa for file '$path' : $!";
				return -1;
			} # UNLESS
			$new_perms = $stats->mode;
			if ( $new_perms & 2 ) {
				$new_perms ^= 2;  # turn off the world write permission bit with XOR
				unless ( 1 == chmod $new_perms,$path ) {
					$errmsg = "chmod failed for file '$path' : $!";
					return -1;
				} # UNLESS
			} # IF
		} # ELSE
	} # FOREACH over all entries in a directory
	foreach my $subdir ( @subdirs ) {
		if ( change_world_perms($subdir) < 0 ) {
			return -1;
		} # IF
	} # FOREACH over all sub-directories for a directory

	return 0;
} # end of change_world_perms

1;

END # module clean-up code here (global destructor)
{
}
