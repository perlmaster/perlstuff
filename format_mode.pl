#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : format_mode.pl
#
# Author    : Barry Kimelman
#
# Created   : January 12, 2015
#
# Purpose   : Format file permission bits into a printable string
#
######################################################################

use strict;
use warnings;

my @perms = qw(--- --x -w- -wx r-- r-x rw- rwx);

######################################################################
#
# Function  : format_mode
#
# Purpose   : Format file permission bits into a printable string
#
# Inputs    : $_[0] - file permission bits
#
# Output    : (none)
#
# Returns   : formatted string of permission bits info
#
# Example   : $mode = format_mode($stat->mode);
#
# Notes     : (none)
#
######################################################################

sub format_mode
{
	my $mode = shift;
	my %opts = @_;
	my @ftype = qw(. p c ? d ? b ? - ? l ? s ? ? ?);
	$ftype[0] = '';

	my $setids = ($mode & 07000)>>9;
	my @permstrs = @perms[($mode&0700)>>6, ($mode&0070)>>3, $mode&0007];
	my $ftype = $ftype[($mode & 0170000)>>12];

	if ($setids) {
		if ($setids & 01) {		# Sticky bit
		$permstrs[2] =~ s/([-x])$/$1 eq 'x' ? 't' : 'T'/e;
		}
		if ($setids & 04) {		# Setuid bit
			$permstrs[0] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
		}
		if ($setids & 02) {		# Setgid bit
			$permstrs[1] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
		}
	}

	return join '', $ftype, @permstrs;
} # end of format_mode

1;
