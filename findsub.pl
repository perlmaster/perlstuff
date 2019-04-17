#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : findsub.pl
#
# Author    : Barry Kimelman
#
# Created   : August 5, 2014
#
# Purpose   : Find where a perl function is defined
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use FindBin;
use lib $FindBin::Bin;

require "list_file_info.pl";

my %options = ( "d" => 0 , "h" => 0 , "f" => 0 , "r" => 0 , "F" => 0 , "e" => 0 , "l" => 0 );
my %functions = (); # $functions{$filename}{$func} = $line;
my %funcs = (); # $funcs{$func} = $comma_separated_filenames;
my $maxlen_filename = 0;

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
	my ( %entries , $path , $dirname_prefix );

	unless ( opendir(DIR,"$dirname") ) {
		warn("opendir failed for '$dirname' : $!\n");
		return -1;
	} # UNLESS

	%entries = map { $_ , 0 } readdir DIR;
	closedir DIR;
	delete $entries{".."};
	delete $entries{"."};
	$dirname_prefix = ($dirname eq ".") ? "" : "${dirname}/";

	foreach my $entry ( keys %entries ) {
		##  $path = "${dirname}/${entry}";
		## $path = "${dirname_prefix}${entry}";
		$path = File::Spec->catfile($dirname,$entry);
		if ( -f $path && $entry =~ m/\.pl$|\.pm$|\.cgi$/ ) {
			process_perl_file($path);
		} elsif ( -d $path && $options{'r'} ) {
			process_dir($path);
		} # IF
	} # FOREACH

	return 0;
} # end of process_dir

######################################################################
#
# Function  : process_perl_file
#
# Purpose   : Find the functions defined in a perl file.
#
# Inputs    : $_[0] - name of perl file
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

	unless ( open(PERL,"<$perl_file") ) {
		warn("open failed for file '$perl_file' : $!\n");
		return;
	} # UNLESS
	@records = <PERL>;
	close PERL;
	$length = length $perl_file;
	if ( $length > $maxlen_filename ) {
		$maxlen_filename = $length;
	} # IF

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
		## print "\n$perl_file : == NONE  ==\n";
	} # IF

	return;
} # end of process_perl_file

######################################################################
#
# Function  : MAIN
#
# Purpose   : Find where a perl function is defined
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : findsub.pl -d arg1
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $ref , $function_name , @files , $count , @lines , $ref2 , $lnum , @funcs );
	my ( $buffer , $start_time , $end_time );
	my ( $elapsed_time , $minutes , $seconds );

	$status = getopts("hdrf:Fel",\%options);
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
	unless ( $status && 0 < @ARGV ) {
		die("Usage : $0 [-dhrFel] [-f count] function_name [filename [... filename]]\n");
	} # UNLESS
	$function_name = shift @ARGV;

	$start_time = time;
	$status = localtime;
	print "\n$status\n\n";
	$status = 0;
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
	if ( $options{'d'} ) {
		print Dumper(\%funcs),"\n";
		print Dumper(\%functions),"\n";
	} # IF

	if ( $options{'e'} ) {
		@funcs = grep /${function_name}/i,keys %funcs;
		if ( 1 > @funcs ) {
			die("No function matches the pattern '$function_name'\n");
		} # IF
		@files = ();
		print "\n'$function_name' matched : ",join(' , ',@funcs),"\n";
		foreach my $func ( @funcs ) {
			$buffer = $funcs{$func};
			push @files,split(/\s*,\s*/m,$buffer);
		} # FOREACH
	} # IF
	else {
		unless ( exists $funcs{$function_name} ) {
			die("\nNo definition found for '$function_name'\n\n");
		} # UNLESS
		@files = split(/\s*,\s*/m,$funcs{$function_name});
	} # ELSE

	$count = scalar @files;

	if ( $options{'e'} ) {
		print "\nI found function names matching '$function_name' defined in the following ${count} file(s)\n";
	} # IF
	else {
		print "\nI found $function_name defined in the following ${count} file(s)\n";
	} # ELSE

	if ( $options{'F'} ) {
		foreach my $filename ( @files ) {
			list_file_info_full($filename,{ "g" => 1 , "o" => 1 , "k" => 0 , "n" => 0 , "m" => 1 } );
		} # FOREACH
	} elsif ( $options{"l"} ) {
		print join("\n",@files),"\n";
	} else {
		print join(' , ',@files),"\n";
	} # ELSE

	if ( $options{'f'} > 0 ) {
		foreach my $filename ( @files ) {
			if ( open(INPUT,"<$filename") ) {
				@lines = <INPUT>;
				close INPUT;
				chomp @lines;
				$ref = $functions{$filename};
				$lnum = $ref->{$function_name};
				print "For $filename look on line $lnum\n";
				splice(@lines,0,$lnum-1);
				for ( $count = 1 ; $count <= $options{'f'} ; ++$count , ++$lnum ) {
					if ( 1 > @lines ) {
						last;
					} # IF
					printf "%5d %s\n",$lnum,$lines[0];
					shift @lines;
				} # FOR
			} # IF
			else {
				warn("open failed for file '$filename' : $!\n");
			} # ELSE
		} # FOREACH
	} # IF

	$status = localtime;
	print "\n$status\n";

	$end_time = time;
	$elapsed_time = $end_time - $start_time;
	$minutes = int( $elapsed_time / 60);
	$seconds = $elapsed_time - ($minutes * 60);
	print "\nElapsed Time : ${minutes} minutes ${seconds} seconds\n\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

findsub.pl

=head1 SYNOPSIS

findsub.pl [-dhre] [-f count] function_name [filename [... filename]]

=head1 DESCRIPTION

Find where a perl function is defined

=head1 OPTIONS

=over 4

=item -d - activate debug mode

=item -h - produce this summary

=item -e - the function name is a regular expression

=item -r - recursively process sub directories

=item -f count - display the first "count" lines of the source code from the file containing the function definition

=item -F - use the ls command to list file information

=back

=head1 PARAMETERS

  function_name - name of function to be located
  filename - optional name of Perl file

=head1 EXAMPLES

findsub.pl my_func stuff.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
