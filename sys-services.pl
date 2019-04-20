#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : sys-services.pl
#
# Author    : Barry Kimelman
#
# Created   : June 11, 2012
#
# Purpose   : Display a list of Windows system services.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "print_lists.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 );

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
# Function  : MAIN
#
# Purpose   : Display a list of Windows system services.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : sys-services.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $command , @output , @matched , @fields );
	my ( $service_name , $display_name , $state , $pattern );
	my ( @services , @display , @states , %states , @counts );
	my ( $count , $maxlen , $index );

	$status = getopts("hd",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dh]\n");
	} # UNLESS
	$pattern = (0 < scalar @ARGV) ? $ARGV[0] : ".";

	$command = "sc query type= service";
	@output = `$command`;
	chomp @output;
	@matched = grep /SERVICE_NAME|DISPLAY_NAME|STATE/,@output;
##	print join("",@matched),"\n";

	@services = ();
	@display = ();
	@states = ();
	%states = ();
	$count = 0;
	while ( 0 < @matched ) {
		$count += 1;
		$service_name = shift @matched;
		$service_name =~ s/^\s*SERVICE_NAME:\s*//g;
		unless ( $service_name =~ m/${pattern}/i ) {
			next;
		} # UNLESS
		$display_name = shift @matched;
		$display_name =~ s/^\s*DISPLAY_NAME:\s*//g;
		$state = shift @matched;
		$state =~ s/^\s+STATE\s+:\s+//g;
		##  print "$service_name -- $display_name\n";
		push @services,$service_name;
		push @display,$display_name;
		$state =~ s/\s+$//g;
		push @states,$state;
		$states{$state} += 1;
	} # WHILE
	print_lists( [ \@services , \@display , \@states ] , [ "Service" , "Display Name" , "State" ] ,"=");
	@states = keys %states;
	@counts = map { $states{$_} } @states;
	$maxlen = (sort { $b <=> $a } map { length $_ } @states)[0];
	print "\n";
	printf "%-${maxlen}.${maxlen}s %s\n","State","Count";
	printf "%-${maxlen}.${maxlen}s %s\n","=====","=====";
	for ( $index = 0 ; $index <= $#states ; ++$index ) {
		printf "%-${maxlen}.${maxlen}s %d\n",$states[$index],$counts[$index];
	} # FOR

	exit 0;
} # end of MAIN
__END__
=head1 NAME

sys-services.pl - Display a list of Windows system services.

=head1 SYNOPSIS

sys-services.pl [-hd]

=head1 DESCRIPTION

Display a list of Windows system services.

=head1 OPTIONS

  -d - activate debug mode
  -h - produce this summary

=head1 PARAMETERS

  (none)

=head1 EXAMPLES

sys-services.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
