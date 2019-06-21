#!/usr/bin/perl -w

######################################################################
#
# File      : show-db.pl
#
# Author    : Barry Kimelman
#
# Created   : February 5, 2019
#
# Purpose   : Display a list of databases
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
use DBI;

require "mysql_utils.pl";
require "print_lists.pl";
require "display_pod_help.pl";

my %options = ( "d" => 0 , "h" => 0 , "t" => 0 );
my $dbh;

######################################################################
#
# Function  : list_tables
#
# Purpose   : List the tables under a database
#
# Inputs    : $_[0] - database name
#
# Output    : requested list
#
# Returns   : nothing
#
# Example   : list_tables($dbname)
#
# Notes     : (none)
#
######################################################################

sub list_tables
{
	my ( $dbname ) = @_;
	my ( $query , $sth , $ref );

	print "\nTables under $dbname\n\n";

	$query =<<QUERY;
SELECT TABLE_NAME FROM `information_schema`.`tables` where table_schema = '$dbname';
QUERY

	$sth = $dbh->prepare($query);
	unless ( defined $sth ) {
		warn("prepare failed for [$query] : $DBI::errstr\n");
		return -1;
	} # UNLESS
	unless ( $sth->execute() ) {
		warn("execute failed for [$query] : $DBI::errstr\n");
		$sth->finish();
		return -1;
	} # UNLESS

	while ( $ref = $sth->fetchrow_hashref() ) {
		print "$ref->{'TABLE_NAME'}\n";
	} # WHILE
	$sth->finish();

	return;
} # end of list_tables

######################################################################
#
# Function  : MAIN
#
# Purpose   : Display a list of databases
#
# Inputs    : @ARGV - optional arguments
#
# Output    : File contents
#
# Returns   : 0 --> success , non-zero --> failure
#
# Example   : show-db.pl -d
#
# Notes     : (none)
#
######################################################################

MAIN:
{
	my ( $status , $query , $ref , $sth , @schemas );

	$status = getopts("hdt",\%options);
	if ( $options{"h"} ) {
		display_pod_help($0);
		exit 0;
	} # IF
	unless ( $status ) {
		die("Usage : $0 [-dht]\n");
	} # UNLESS

	# connect to the database.
	$dbh = mysql_connect_to_db('qwlc',"127.0.0.1","root","archer-nx01");

	$query =<<QUERY;
SELECT schema_name FROM `information_schema`.`schemata`
QUERY

	$sth = $dbh->prepare($query);
	unless ( defined $sth ) {
		warn("prepare failed for [$query] : $DBI::errstr\n");
		$dbh->disconnect();
		exit 1;
	} # UNLESS
	unless ( $sth->execute() ) {
		warn("Execute failed for [$query] : $DBI::errstr\n");
		$sth->finish();
		$dbh->disconnect();
		exit 1;
	} # UNLESS

	@schemas = ();
	while ( $ref = $sth->fetchrow_hashref() ) {
		push @schemas,$ref->{'schema_name'};
	} # WHILE
	$sth->finish();
	@schemas = sort { lc $a cmp lc $b } @schemas;
	print join("\n",@schemas),"\n";
	if ( $options{'t'} ) {
		foreach my $dbname ( @schemas ) {
			list_tables($dbname);
		} # FOREACH
	} # IF

	$dbh->disconnect();
	exit 0;
} # end of MAIN
__END__
=head1 NAME

show-db.pl - Display a list of databases

=head1 SYNOPSIS

show-db.pl [-dht]

=head1 DESCRIPTION

Display a list of databases

=head1 PARAMETERS

  (none)

=head1 OPTIONS

  -h - produce this summary
  -d - activate debugging mode
  -t - display a list of tables under each database

=head1 EXAMPLES

show-db.pl

=head1 EXIT STATUS

 0 - successful completion
 nonzero - an error occurred

=head1 AUTHOR

Barry Kimelman

=cut
