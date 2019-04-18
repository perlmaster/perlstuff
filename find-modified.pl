#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : find-modified.pl
#
# Author    : Barry Kimelman
#
# Created   : January 11, 2016
#
# Purpose   : Find files modified since a specified date
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use File::Spec;
use File::stat;
use Fcntl;
use FindBin;
use lib $FindBin::Bin;

my %options = ( "d" => 0 , "h" => 0 );
my ( $startdir );
my %extensions = ( "pl" => 0 , "pm" => 0 , "cgi" => 0 , "ksh" => 0 , "sh" => 0 );
my $last_mod_date;
my %last_mod_date = ();
my $num_found = 0;

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
# Function  : scan_dir
#
# Purpose   : Scan the specified directory looking for subdirs.
#
# Inputs    : $_[0] - directory name
#             $_[1] - directory level
#
# Output    : One line per matched file.
#
# Returns   : number of matches
#
# Example   : scan_dir($dirname,0);
#
# Notes     : (none)
#
######################################################################

sub scan_dir
{
	my ( $dirname , $dir_level ) = @_;
	my ( %entries , $path , @subdirs , @parts , $ext , $status );
	my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst );
	my ( $date );

	unless ( opendir(DIR,$dirname) ) {
		warn("opendir failed for \"$dirname\" : $!\n");
		return 0;
	} # UNLESS

	%entries = map { $_ , 1 } readdir DIR;
	closedir DIR;
	delete $entries{"."};
	delete $entries{".."};
	@subdirs = ();
	foreach my $entry ( keys %entries ) {
		##  $path = sprintf "%s/%s",$dirname,$entry;
		$path = File::Spec->catfile($dirname,$entry);
		if ( -l $path ) {
			next;
		} # IF
		if ( -d $path ) {
			push @subdirs,$path;
		} # IF a directory
		else {
			if ( $entry =~ m/\./ ) {
				@parts = split(/\./,$entry);
				$ext = pop @parts;
				if ( exists $extensions{lc $ext} ) {
					$status = stat($path);
					unless ( defined $status ) {
						warn("stat failed for \"$path\"\n");
						next;
					} # UNLESS
					( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst ) =
							  localtime($status->mtime);
					$year += 1900;
					$mon += 1;
					$date = sprintf "%04d%02d%02d",$year,$mon,$mday;
					if ( $date >= $last_mod_date ) {
						$num_found += 1;
						printf "%s %04d/%02d/%02d %02d:%02d:%02d\n",$path,$year,$mon,$mday,$hour,$min,$sec;
					} # IF
				} # IF
			} # IF
		} # ELSE
	} # FOREACH

	foreach my $subdir( @subdirs ) {
		scan_dir($subdir,$dir_level+1);
	} # FOREACH

	return;
} # end of scan_dir

######################################################################
#
# Function  : MAIN
#
# Purpose   : Program entry point
#
# Inputs    : @ARGV - optional flags and xxx
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : find-modified.pl dirname
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status );

	$status = getopts("dhe:",\%options);
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

	unless ( $status && 0 < scalar @ARGV ) {
		die("Usage : $0 [-dh] [-e extensions_list] last_mod_date [startdir]\n");
	} # UNLESS

	$last_mod_date = $ARGV[0];
	unless ( $last_mod_date =~ m/^(\d\d\d\d)(\d\d)(\d\d)$/ ) {
		die("Last modification date is not in formt YYYYMMDD\n");
	} # UNLESS
	%last_mod_date = ( "year" => $1 , "mon" => $2 , "mday" => $3 );
	$startdir = (2 > @ARGV) ? "." : $ARGV[1];
	if ( exists $options{'e'} ) {
		foreach my $ext ( split(/,/,$options{'e'}) ) {
			$ext =~ s/^\.+//g;
			$extensions{$ext} = 0;
		} # FOREACH
	} # IF
	$status = localtime;
	print "\n$status\n";

	print "\nStarting Directory is $startdir\n\n";

	scan_dir($startdir,1);
	print "\n";
	print "Found ${num_found} files modified since $last_mod_date that have one of the following extensions :\n",
				join(' , ',sort { lc $a cmp lc $b } keys %extensions),"\n";

	print "\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

find-modified.pl - Find files modified since a specified date

=head1 SYNOPSIS

find-modified.pl [-dn] [-e extensions_list] last_mod_date [startdir]

=head1 DESCRIPTION

Find files modified since a specified date

=head1 OPTIONS

=over 4

=item -d - activate debug mode

=item -n - display count indicating number of items under directory

=item -e exclude_pattern - pattern specifying which directories ate to be ignored

=item -l num_levels - pattern specifying which directories ate to be ignored

=item -h - produce this summary

=item -e <extensions_list> - comma separated list of additional extensions for search

=back

=head1 PARAMETERS

  last_mod_date - look for files whose last modification date is not before this date
  startdir - optional name of top level directory ("." is the default)

=head1 EXAMPLES

find-modified.pl 20160111

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
