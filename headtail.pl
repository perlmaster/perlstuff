#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : headtail.pl
#
# Author    : Barry Kimelman
#
# Created   : August 29, 2014
#
# Purpose   : List the head and tail of a file.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "n" => 20 , "N" => 0 );

######################################################################
#
# Function  : display_head_tail
#
# Purpose   : Display the head and tail of a file
#
# Inputs    : $_[0] - name of file
#             $_[1] - reference to array of lines
#             $_[2] - handle of open file to receive listing
#
# Output    : (none)
#
# Returns   : nothing
#
# Example   : display_head_tail($filename,\@lines,\*STDOUT);
#
# Notes     : (none)
#
######################################################################

sub display_head_tail
{
	my ( $filename , $ref_lines , $handle ) = @_;
	my ( $num_lines , @numbers , @rec2 , $count , $snip1 , $snip2 , $buffer );
	my ( @rec3 , $index2 , $index3 , @records );

	@records = @$ref_lines;
	$num_lines = scalar @records;
	@numbers = map { sprintf "%5d",$_ } ( 1 .. $num_lines );
	if ( $options{"N"} ) {
		@rec2 = map { "$numbers[$_]\t$records[$_]" } ( 0 .. $#records );
	} # IF
	else {
		@rec2 = @records;
	} # ELSE
	$count = $options{'n'} << 1;
	if ( $count >= $num_lines ) {
		print join("",@rec2),"\n";
	} # IF
	else {
		$snip1 = 1 + $options{'n'};
		$snip2 = $num_lines - $options{'n'};
		$buffer = '=' x 20;
		@rec3 = @rec2[0 .. $options{'n'}-1];
		print $handle join("",@rec3),"${buffer} lines ${snip1} - ${snip2} not shown ${buffer}\n";
		$index2 = $#records;
		$index3 = $index2;
		$index3 -= $options{'n'};
		$index3 += 1;
		@rec3 = @rec2[$index3 .. $index2];
		print $handle join("",@rec3),"\n";
	} # ELSE
	if ( exists $options{'t'} ) {
		print $handle "${num_lines} lines in $options{'t'}\n";
	} # IF

	return;
} # end of display_head_tail

######################################################################
#
# Function  : MAIN
#
# Purpose   : List the head and tail of a file.
#
# Inputs    : @ARGV - optional arguments
#
# Output    : (none)
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : headtail.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $filename , @records );

	$status = getopts("hdn:t:N",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dhN] [-t title] [-n number_of_lines] [filename]]\n");
	} # UNLESS

	if ( 0 < @ARGV ) {
		$filename = $ARGV[0];
		unless ( open(INPUT,"<$filename") ) {
			die("open failed for file '$filename' : $!\n");
		} # UNLESS
		@records = <INPUT>;
		close INPUT;
	} # IF
	else {
		$filename = '-- STDIN --';
		@records = <STDIN>;
	} # ELSE

	display_head_tail($filename,\@records,\*STDOUT);

	exit 0;
} # end of MAIN
__END__
=head1 NAME

headtail.pl

=head1 SYNOPSIS

headtail.pl [-dhN] [-n number_of_lines] [-t title] [filename]

=head1 DESCRIPTION

List the head and tail of a file.

=head1 OPTIONS

=over 4

=item -d - activate debug mode

=item -h - produce this summary

=item -n <num_lines> - number of lines for the header and tail sections

=item -t <title> - summary line sub-title

=item -N - display line numbers

=back

=head1 PARAMETERS

  filename - name of input file

=head1 EXAMPLES

headtail.pl filename

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
