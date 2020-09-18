#!/usr/bin/perl -w

######################################################################
#
# File      : start_threads.pl
#
# Author    : Barry Kimelman
#
# Created   : March 14, 2016
#
# Purpose   : Threads support routines.
#
######################################################################

use strict;
use threads;
use FindBin;
use lib $FindBin::Bin;

######################################################################
#
# Function  : start_threads
#
# Purpose   : Start a series of threads for a list of names.
#
# Inputs    : $_[0] - reference to array of names/ip's
#             $_[1] - reference to array of thread objects
#             $_[2] - reference to thread function
#             $_[3] - reference to error message buffer
#             $_[4] - optional debugging flag
#
# Output    : appropriate diagnostics
#
# Returns   : number of errors encountered during threads creation
#
# Example   : $errors = start_threads(\@names,\@threads,\&thread_func,\$errmsg,$debug_glag);
#             if ( $errors > 0 ) {
#                 return;
#             }
#
# Notes     : (none)
#
######################################################################

sub start_threads
{
	my ( $ref_names , $ref_threads , $ref_thread_func , $ref_errmsg , $debug_flag ) = @_;
	my ( $thread , $errors , @data , $index , $num_names , @names );

	$$ref_errmsg = "";
	@names = @$ref_names;
	$num_names = scalar @names;
	if ( defined $debug_flag ) {
		print "\nDEBUG : start_threads() called with ${num_names} names\n";
	} # IF

	@$ref_threads = ( 1 .. $num_names );  # create array to hold thread objects
	@$ref_threads = ( );
	$errors = 0;
	foreach my $name ( @names ) {
		eval {
			$thread = threads->create($ref_thread_func,$name);
			push @$ref_threads,$thread;
		} ;
		if ( $@ ) {
			$errors += 1;
			$$ref_errmsg = "Death detected during creation of thread for $name";
			if ( defined $debug_flag ) {
				print "\nDEBUG : start_threads() : Death detected during startup of thread for '$name' : $@\n";
			} # IF
			next;
		} # IF
		unless ( defined $thread ) {
			$errors += 1;
			$$ref_errmsg = "Can't create thread for $name";
			if ( defined $debug_flag ) {
				print "\nDEBUG : start_threads() : Error detected during startup of thread for '$name' : $@\n";
			} # IF
		} # UNLESS
		else {
		} # ELSE
	} # FOR loop creating threads

	if ( defined $debug_flag ) {
		print "\nDEBUG : start_threads() : all threads started , errors = $errors\n";
	} # IF
#-----------------------------------------------#
# If any errors occurred during thread creation #
# cleanup and return                            #
#-----------------------------------------------#
	if ( $errors > 0 ) {
		for ( $index = 0 ; $index < $num_names ; ++$index ) {
			if ( defined $$ref_threads[$index] ) {
				$$ref_threads[$index]->join();
			} # IF
		} # FOR
		return $errors;
	} # IF error during thread creation

	return 0;
} # end of start_threads

1;
