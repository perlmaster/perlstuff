#!/usr/bin/perl -w

######################################################################
#
# File      : print_lists.pl
#
# Author    : Barry Kimelman
#
# Created   : August 1, 2007
#
# Purpose   : Print the contents of a set of parallel arrays.
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use FindBin;
use lib $FindBin::Bin;

######################################################################
#
# Function  : print_lists
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - optional file handle
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_lists(\@arrays,\@headers,"=",\*STDOUT);
#
# Notes     : (none)
#
######################################################################

sub print_lists
{
	my ( $ref_arrays , $ref_headers , $underline , $handle ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines );

	unless ( defined $handle ) {
		$handle = \*STDOUT;
	} # UNLESS
	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print $handle "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print $handle "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			printf $handle "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		print $handle "\n";
	} # FOR

	return;
} # end of print_lists

######################################################################
#
# Function  : print_lists_with_trim
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - optional handle of open file
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_lists_with_trim(\@arrays,\@headers,"=",\*STDOUT);
#
# Notes     : The last column is not padded with blanks
#
######################################################################

sub print_lists_with_trim
{
	my ( $ref_arrays , $ref_headers , $underline , $handle ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines );

	unless ( defined $handle ) {
		$handle = \*STDOUT;
	} # UNLESS
	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print $handle "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print $handle "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			if ( $colnum+1 == $num_columns ) {
				print $handle "$value";
			} # IF
			else {
				printf $handle "%-${maxlen[$colnum]}s ",$value;
			} # ELSE
		} # FOR
		print $handle "\n";
	} # FOR

	return;
} # end of print_lists_with_trim

######################################################################
#
# Function  : print_sorted_lists
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - column index of sort column
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_sorted_lists(\@arrays,\@headers,"=",0);
#
# Notes     : (none)
#
######################################################################

sub print_sorted_lists
{
	my ( $ref_arrays , $ref_headers , $underline , $sort_column ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , @indices , @column1 , $index );

	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR

	@underlines = map { $underline x $_ } @maxlen;
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print "\n";

	$column_ref = $$ref_arrays[$sort_column];
	@column1 = @$column_ref;
	@indices = ( 0 .. $#column1 );
	@indices = sort { lc $column1[$a] cmp lc $column1[$b] } @indices;
	for ( $index = 0 ; $index < $num_rows ; ++$index ) {
		$rownum = $indices[$index];
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			printf "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		print "\n";
	} # FOR

	return;
} # end of print_sorted_lists

######################################################################
#
# Function  : print_list_of_rows
#
# Purpose   : Print the contents of a set of parallel arrays.
#
# Inputs    : $_[0] - reference to array containing array of row
#                     references
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - truncation size (if GT 0)
#             $_[4] - optional output handle
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_list_of_rows(\@rows,\@headers,"=",0,\*STDOUT);
#
# Notes     : (none)
#
######################################################################

sub print_list_of_rows
{
	my ( $ref_rows , $ref_headers , $underline , $trunc_size , $handle ) = @_;
	my ( $row_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines );

	unless ( defined $handle ) {
		$handle = \*STDOUT;
	} # UNLESS

	$num_rows = scalar @$ref_rows;
	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		$row_ref = $$ref_rows[$rownum];
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$value = $$row_ref[$colnum];
			unless ( defined $value ) {
				$value = "";
			} # UNLESS
			$length = length $value;
			if ( $trunc_size > 0 && $length > $trunc_size ) {
				$length = $trunc_size;
			} # IF
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;

	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}.${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print $handle "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}.${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print $handle "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		$row_ref = $$ref_rows[$rownum];
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$value = $$row_ref[$colnum];
			unless ( defined $value ) {
				$value = "";
			} # UNLESS
			$length = length $value;
			if ( $trunc_size > 0 && $length > $trunc_size ) {
				$length = $trunc_size;
				$value = substr ($value,0,$trunc_size);
			} # IF
			printf $handle "%-${maxlen[$colnum]}.${maxlen[$colnum]}s ",$value;
		} # FOR
		print $handle "\n";
	} # FOR

	return;
} # end of print_list_of_rows

######################################################################
#
# Function  : print_list_by_group
#
# Purpose   : Print the contents of a set of parallel arrays.
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - reference to array containing list of column indexes
#                     that specify the grouping
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_list_by_group(\@arrays,\@headers,"=",\@group_columns);
#
# Notes     : (none)
#
######################################################################

sub print_list_by_group
{
	my ( $ref_arrays , $ref_headers , $underline , $ref_group_columns ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , $prev_group_key , $curr_group_key );
	my ( $sep );

	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print "\n";
	$prev_group_key = "";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		$curr_group_key = "";
		$sep = "";
		foreach $colnum ( @$ref_group_columns ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$curr_group_key .= $sep . $value;
			$sep = ".";
		} # FOREACH
		if ( $prev_group_key ne $curr_group_key ) {
			print "\n";
			$prev_group_key = $curr_group_key;
		} # IF
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			printf "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		print "\n";
	} # FOR

	return;
} # end of print_list_by_group

######################################################################
#
# Function  : print_boxed_lists
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_boxed_lists(\@arrays,\@headers,"=");
#
# Notes     : (none)
#
######################################################################

sub print_boxed_lists
{
	my ( $ref_arrays , $ref_headers , $underline ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , $maxlen_sum , $width , $top );

	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	$maxlen_sum = 0;
	foreach my $max ( @maxlen ) {
		$maxlen_sum += $max
	} # FOREACH
	$width = $maxlen_sum + $num_columns + 4;
	$top = "-" x $width;
	$top =~ s/^./#/;
	$top =~ s/.$/#/;

	print "${top}\n";
	@underlines = map { $underline x $_ } @maxlen;
	print "# ";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print " #\n# ";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print " #\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		print "# ";
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			printf "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		print " #\n";
	} # FOR
	print "${top}\n";

	return;
} # end of print_boxed_lists

######################################################################
#
# Function  : print_lists_from_temp_file
#
# Purpose   : Print the contents of a set of parallel arrays
#             (i.e. each array represents a column) by first placing the
#             data in a temporary file and then displaying the file's
#             content.
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - reference to error message buffer
#             $_[4] - initial part of file display command
#                     (ie. 'less -M')
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_lists_from_temp_file(\@arrays,\@headers,"=",\$errmsg,'less -M');
#
# Notes     : (none)
#
######################################################################

sub print_lists_from_temp_file
{
	my ( $ref_arrays , $ref_headers , $underline , $ref_errmsg , $paging ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , $tempfile , $command );

	$$ref_errmsg = '';
	$tempfile = "/var/tmp/$ENV{'LOGNAME'}-list-$$";
	unless ( open(LIST,">$tempfile") ) {
		$$ref_errmsg = "Can't open temporary file '$tempfile' : $!";
		return -1;
	} # UNLESS

	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf LIST "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	print LIST "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf LIST "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print LIST "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			printf LIST "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		print LIST "\n";
	} # FOR
	close LIST;
	$command = "${paging} ${tempfile}";
	system($command);
	unlink $tempfile;

	return;
} # end of print_lists_from_temp_file

######################################################################
#
# Function  : print_lists_to_array
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - reference to array to receive strings
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_lists_to_array(\@arrays,\@headers,"=",\@output);
#
# Notes     : (none)
#
######################################################################

sub print_lists_to_array
{
	my ( $ref_arrays , $ref_headers , $underline , $ref_output ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , $buffer , $buffer2 );

	@$ref_output = ();

	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;
	$buffer2 = '';
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		$buffer = sprintf "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
		$buffer2 .= $buffer;
	} # FOR
	push @$ref_output,$buffer2;
	$buffer2 = '';
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		$buffer = sprintf "%-${maxlen[$colnum]}s ",$underlines[$colnum];
		$buffer2 .= $buffer;
	} # FOR
	push @$ref_output,$buffer2;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		$buffer2 = '';
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$buffer = sprintf "%-${maxlen[$colnum]}s ",$value;
			$buffer2 .= $buffer;
		} # FOR
		push @$ref_output,$buffer2;
	} # FOR

	return;
} # end of print_lists_to_array

######################################################################
#
# Function  : print_lists_with_index
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_lists_with_index(\@arrays,\@headers,"=");
#
# Notes     : (none)
#
######################################################################

sub print_lists_with_index
{
	my ( $ref_arrays , $ref_headers , $underline , $pager ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , $list_buffer , $tempfile );

	$list_buffer = "";

	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR

	@underlines = map { $underline x $_ } @maxlen;
	$list_buffer .= sprintf "%-7.7s ","#";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		$list_buffer .= sprintf "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR

	$list_buffer .= "\n======= ";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		$list_buffer .= sprintf "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	$list_buffer .= "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		$list_buffer .= sprintf "(%5d) ",1+$rownum;
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$list_buffer .= sprintf "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		$list_buffer .= "\n";
	} # FOR
	if ( defined $pager && $pager =~ m/\S/ ) {
		$tempfile = "/var/tmp/" . $ENV{"LOGNAME"} . "-PRINTLIST-$$";
		if ( open(LIST,">$tempfile") ) {
			print LIST $list_buffer;
			close LIST;
			system("${pager} $tempfile");
			unlink $tempfile;
		} # IF
		else {
			print "open failed for file '$tempfile' : $!\n";
		} # ELSE
	} # IF
	else {
		print "$list_buffer";
	} # ELSE

	return;
} # end of print_lists_with_index

######################################################################
#
# Function  : print_lists_multiple_header_lines
#
# Purpose   : Print the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#             $_[3] - optional file handle
#
# Output    : The array contents
#
# Returns   : (nothing)
#
# Example   : print_lists_multiple_header_lines(\@arrays,\@headers,"=",\*STDOUT);
#
# Notes     : The headers can consist of multiple lines separated by newlines
#
######################################################################

sub print_lists_multiple_header_lines
{
	my ( $ref_arrays , $ref_headers , $underline , $handle ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , @headers , @num_header_lines , $index , @parts );
	my ( $max_lines , $maxlen , $index2 , $num_headers );

	@headers = @$ref_headers;
	@num_header_lines = ();
	@maxlen = ();
	$num_headers = scalar @headers;
	for ( $index = 0 ; $index < $num_headers ; ++$index ) {
		@parts = split(/\n/,$headers[$index]);
		$maxlen = (sort { $b <=> $a } map { length $_ } @parts)[0];
		push @maxlen,$maxlen;
		push @num_header_lines,scalar @parts;
	} # FOR
	$max_lines = (sort { $b <=> $a } map { $_ } @num_header_lines)[0];

	unless ( defined $handle ) {
		$handle = \*STDOUT;
	} # UNLESS
	$num_columns = scalar @headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR
	@underlines = map { $underline x $_ } @maxlen;

	for ( $index = 0 ; $index < $max_lines ; ++$index ) {
		for ( $index2 = 0 ; $index2 < $num_headers ; ++$index2 ) {
			@parts = split(/\n/,$headers[$index2]);
			if ( $index <= $#parts ) {
				printf $handle "%-${maxlen[$index2]}s ",$parts[$index];
			} # IF
			else {
				printf $handle "%-${maxlen[$index2]}s ","";
			} # ELSE
		} # FOR
		print $handle "\n";
	} # FOR
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		printf $handle "%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	print $handle "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			printf $handle "%-${maxlen[$colnum]}s ",$value;
		} # FOR
		print $handle "\n";
	} # FOR

	return;
} # end of print_lists_multiple_header_lines

######################################################################
#
# Function  : build_lists_with_trim
#
# Purpose   : Build a report using the contents of a set of parallel arrays.
#             (i.e. each array represents a column)
#
# Inputs    : $_[0] - reference to array containing references to arrays
#                     of columns to be displayed
#             $_[1] - reference to an array of column headers
#             $_[2] - column header underline character
#
# Output    : (none)
#
# Returns   : the report
#
# Example   : $report = build_lists_with_trim(\@arrays,\@headers,"=");
#
# Notes     : The last column is not padded with blanks
#
######################################################################

sub build_lists_with_trim
{
	my ( $ref_arrays , $ref_headers , $underline ) = @_;
	my ( $column_ref , $num_rows , $num_columns , $rownum , $colnum , @maxlen );
	my ( $value , $length , @underlines , $report );

	$report = "";
	$num_columns = scalar @$ref_headers;
	@maxlen = map { length $_ } @$ref_headers;
	$column_ref = $$ref_arrays[0];
	$num_rows = scalar @$column_ref;
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			$length = length $value;
			if ( $length > $maxlen[$colnum] ) {
				$maxlen[$colnum] = $length;
			} # IF
		} # FOR
	} # FOR

	@underlines = map { $underline x $_ } @maxlen;
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		$report .= sprintf "%-${maxlen[$colnum]}s ",$$ref_headers[$colnum];
	} # FOR
	$report.= "\n";
	for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
		$report .= sprintf"%-${maxlen[$colnum]}s ",$underlines[$colnum];
	} # FOR
	$report .= "\n";
	for ( $rownum = 0 ; $rownum < $num_rows ; ++$rownum ) {
		for ( $colnum = 0 ; $colnum < $num_columns ; ++$colnum ) {
			$column_ref = $$ref_arrays[$colnum];
			$value = $$column_ref[$rownum];
			if ( $colnum+1 == $num_columns ) {
				$report .= "$value";
			} # IF
			else {
				$report .= sprintf "%-${maxlen[$colnum]}s ",$value;
			} # ELSE
		} # FOR
		$report .= "\n";
	} # FOR

	return $report;
} # end of build_lists_with_trim

1;
