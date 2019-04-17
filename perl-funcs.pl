#!/usr/local/bin/perl -w

######################################################################
#
# File      : perl-funcs.pl
#
# Author    : Barry Kimelman
#
# Created   : August 5, 2014
#
# Purpose   : List the functions defined in a perl file.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Win32::Console;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;

my %options = ( "d" => 0 , "h" => 0 , "l" => 120 , "f" => 0 );
my %functions = (); # $functions{$filename}{$func} = $line;
my %funcs = (); # $funcs{$func} = $comma_separated_filenames;
my $maxlen_filename = 0;
my ( $CONSOLE , @console_info , %console_info );

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
# Function  : process_dir
#
# Purpose   : Process a directory.
#
# Inputs    : $_[0] - directory name
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : process_dir(".");
#
# Notes     : (none)
#
######################################################################

sub process_dir
{
	my ( $dirname ) = @_;
	my ( %entries , $path );

	unless ( opendir(DIR,"$dirname") ) {
		warn("opendir failed for '$dirname' : $!\n");
		return -1;
	} # UNLESS

	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};

	foreach my $entry ( keys %entries ) {
		$path = "${dirname}/${entry}";
		if ( -f $path && $entry =~ m/\.pl$|\.pm$|\.cgi$/i ) {
			process_perl_file($path);
		} # IF
	} # FOREACH

	return;
} # end of process_dir

######################################################################
#
# Function  : process_perl_file
#
# Purpose   : Find the functions defined in a perl file.
#
# Inputs    : $_[0] - name of CSS styles file
#
# Output    : appropriare messages
#
# Returns   : nothing
#
# Example   : process_perl_file("stuff.pl");
#
# Notes     : (none)
#
######################################################################

sub process_perl_file
{
	my ( $perl_file ) = @_;
	my ( $length ,, @records , $records , $function , $count , $index , $num_records , @recs2 , $buffer );
	my ( $non_whitespace , $comments , $matched );

	unless ( open(CSS,"<$perl_file") ) {
		warn("open failed for file '$perl_file' : $!\n");
		return;
	} # UNLESS
	@records = <CSS>;
	close CSS;
	$length = length $perl_file;
	if ( $length > $maxlen_filename ) {
		$maxlen_filename = $length;
	} # IF

	print "\n";
	$num_records = scalar @records;
	$count = 0;
	@recs2 = ( '' );
	push @recs2,@records;
	$non_whitespace = 0;
	$comments = 0;
	for ( $index = 1 ; $index <= $num_records ; ++$index ) {
		shift @recs2;
		$buffer = $recs2[0];
		$records = join('',@recs2);
		if ( $buffer =~ m/\S/ && $buffer !~ m/^\s*#/ && $records =~ m/^\s*sub\s+(\w+)/is ) {
			$function = $1;
			$count += 1;
			##  print "$perl_file : $function -- $index\n";
			$functions{$perl_file}{$function} = $index;
			if ( exists $funcs{$function} ) {
				$funcs{$function} .= ' , ' . $perl_file
			} # IF
			else {
				$funcs{$function} = $perl_file
			} # ELSE
		} # IF
	} # FOR

	if ( $count < 1 ) {
		print "$perl_file : == NONE  ==\n";
	} # IF

	return;
} # end of process_perl_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : List the functions defined in a perl file.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : perl-funcs.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $ref , @keys , $buffer , $maxlen , $buffer2 , $spaces , $num_bytes );
	my ( $line_limit , $sep , $seplen );

	$status = getopts("hdl:f",\%options);
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
	unless ( $status ) {
		die("Usage : $0 [-dhf] [-l line_length_limit] [filename [... filename]]\n");
	} # UNLESS

	$CONSOLE = new Win32::Console STD_OUTPUT_HANDLE;
	unless ( defined $CONSOLE ) {
		die("Can't create console object : $!\n");
		exit 1;
	} # UNLESS
	@console_info = $CONSOLE->Info();
	if ( 0 == scalar @console_info ) {
		die("Can't get console info : $!\n");
	} # IF
	%console_info = (
		"columns" => $console_info[0] ,
		"rows" => $console_info[1] ,
		"max_columns" => $console_info[9] ,
		"max_rows" => $console_info[10]
	);
	$options{'l'} = $console_info{'columns'};
	$line_limit = $options{'l'};

	$status = localtime;
	print "\n$status\n\n";
	if ( 1 > @ARGV ) {
		process_dir(".");
	} # IF
	else {
		foreach my $filename ( @ARGV ) {
			if ( -d $filename ) {
				process_dir($filename);
			} # IF
			else {
				process_perl_file($filename);
			} # ELSE
		} # FOREACH
	} # ELSE

	$buffer = 'Filename';
	$buffer2 = '=' x length $buffer;
	if ( $maxlen_filename < length $buffer ) {
		$maxlen_filename = length $buffer;
	} # IF
	printf "%-${maxlen_filename}.${maxlen_filename}s Functions\n",$buffer;
	printf "%-${maxlen_filename}.${maxlen_filename}s =========\n",$buffer2;
	$spaces = ' ' x $maxlen_filename;

	foreach my $filename ( sort { lc $a cmp lc $b } keys %functions ) {
		printf "%-${maxlen_filename}.${maxlen_filename}s",$filename;
		$ref = $functions{$filename};
		@keys = keys %$ref;
		##  $buffer = join(" , ",map { "$_ / $functions{$filename}{$_}" } @keys);
		##  print "$buffer";
		$num_bytes = $maxlen_filename;
		$sep = ' ';
		$seplen = 1;
		foreach my $funcname ( sort { lc $a cmp lc $b } @keys ) {
			$buffer = $funcname . ' / ' . $functions{$filename}{$funcname};
			$num_bytes += $seplen + length $buffer;
			if ( $num_bytes >= $line_limit ) {
				print "\n$spaces";
				$num_bytes = $maxlen_filename + 1 + length $buffer;
				$sep = ' ';
				$seplen = 1;
			} # IF
			print "${sep}$buffer";
			$sep = ' , ';
			$seplen = 3;
		} # FOREACH

		print "\n";
	} # FOREACH

	if ( $options{'f'} ) {
		@keys = keys %funcs;
		$maxlen = (sort { $b <=> $a} map { length $_ } @keys)[0];
		$buffer = "Function";
		if ( $maxlen < length $buffer ) {
			$maxlen = length $buffer;
		} # IF
		print "\n";
		printf "%-${maxlen}.${maxlen}s Files\n",$buffer;
		$buffer = "=" x length $buffer;
		printf "%-${maxlen}.${maxlen}s =====\n",$buffer;
		foreach my $function ( sort { lc $a cmp lc $b } @keys ) {
			printf "%-${maxlen}.${maxlen}s %s\n",$function,$funcs{$function};
		} # FOREACH
	} # IF

	print "\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

perl-funcs.pl

=head1 SYNOPSIS

perl-funcs.pl [-dhf] filename

=head1 DESCRIPTION

List the functions defined in a perl file.

=head1 OPTIONS

=over 4

=item -d - activate debug mode

=item -h - produce this summary

=item -f - produce the function vs. file summary

=item -l maxlen - maximum length of output line

=back

=head1 PARAMETERS

  filename - name of css file

=head1 EXAMPLES

jsfuncs.p stuff.js

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
