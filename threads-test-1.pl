#!/usr/bin/perl -w

######################################################################
#
# File      : threads-test-1.pl
#
# Author    : Barry Kimelman
#
# Created   : September 18, 2020
#
# Purpose   : Test of threads and my threads support functions
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Spec;
use Config;
use threads;
use threads::shared;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";
require "start_threads.pl";

my %options = ( "d" => 0 , "h" => 0 );
my $debug_flag = 1;
my $shared1 :shared = 13;
my %shared_hash1 :shared = ();
my %shared_hash2 :shared = ();
my @shared_array1 :shared = ();

######################################################################
#
# Function  : thread_func
#
# Purpose   : entry point for threads
#
# Inputs    : $_[0] - name to be processed
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : $thread_id = threads->create(\&thread_func,$name);
#
# Notes     : (none)
#
######################################################################

sub thread_func
{
	my ( $name ) = @_;
	my ( $buffer );

	$shared1 += 1;
	$buffer = "this is the thread master\npid $$ , name = '$name' , shared1 = $shared1\nshared1 = $shared1\n";
	print "\n>>>$buffer\n\n";
	$shared_hash1{$name} = $$;
	push @shared_array1,"$name -- $$";

	return $buffer;
} # end of thread_func

######################################################################
#
# Function  : MAIN
#
# Purpose   : Test of threads and my threads support functions
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : threads-test-1.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $errors , @names , @threads , $errmsg , $thread_data );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh]\n");
	} # UNLESS
	unless ( $Config{useithreads} ) {
		die("threads are not supported.\n");
	} # UNLESS

	%shared_hash1 = ();
	%shared_hash2 = ();
	@shared_array1 = ();

	@names = ( "allan" , "barry" , "carl" );
	$errors = start_threads(\@names,\@threads,\&thread_func,\$errmsg,$debug_flag);
	if ( $errors > 0 ) {
		die("Error returned by start_threads()\n");
	}

	print "\nAll threads have been started , now do the joins()\n";
	foreach my $thread ( @threads ) {
		$thread_data = $thread->join();
	} # FOREACH

	print "\nMAIN : Final value for shared1 = $shared1\n";

	print "\nFinal contents of shared_hash1 are :\n",Dumper(\%shared_hash1),"\n";

	print "\nFinal contents of shared_array1 are :\n",Dumper(\@shared_array1),"\n";

	exit 0;
} # end of MAIN
__END__
=head1 NAME

threads-test-1.pl - Test of threads and my threads support functions

=head1 SYNOPSIS

threads-test-1.pl [-hd] [filename]

=head1 DESCRIPTION

Test of threads and my threads support functions

=head1 PARAMETERS

  filename - name of optional filename

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode

=head1 EXAMPLES

threads-test-1.pl junk.txt

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
