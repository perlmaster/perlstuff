#!/usr/perl5/bin/perl -w

######################################################################
#
# File      : mysql_utils.pl
#
# Author    : Barry Kimelman
#
# Created   : May 13, 2007
#
# Purpose   : Utility routines for MySQL database access.
#
######################################################################

use strict;
use warnings;
use Getopt::Std;
use DBI;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;

######################################################################
#
# Function  : get_table_columns
#
# Purpose   : Get list of column names and corresponding data types for a table.
#
# Inputs    : $_[0] - name of table
#             $_[1] - name of schema containing table
#             $_[2] - reference to hash to receive data
#             $_[3] - reference to array to receive ordered list of column names
#
# Output    : (none)
#
# Returns   : Number of column names
#
# Example   : $numcols = get_table_columns($table,$schema,\%columns,\@colnames);
#
# Notes     : (none)
#
######################################################################

sub get_table_columns
{
	my ( $tablename , $schema , $ref_columns , $ref_colnames ) = @_;
	my ( $dbh , $sql , $sth , $ref , $db , $host , $user , $pwd , @fields , $colname );

	$db = "INFORMATION_SCHEMA";	# your username (= login name  = account name )
	$host = "127.0.0.1";    # = "localhost", the server your are on.
	$user = "root";		# your Database name is the same as your account name.
	$pwd = "archer-nx01";	# Your account password

	# connect to the database.

	$dbh = DBI->connect( "DBI:mysql:$db:$host", $user, $pwd);
	unless ( defined $dbh ) {
		die(undef,"Error connecting to $db : $DBI::errstr\n");
	} # UNLESS

## select TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,DATA_TYPE,ORDINAL_POSITION,IS_NULLABLE from columns
##       where table_name = 'hockey_teams';

	%$ref_columns = ();
	@$ref_colnames = ();
	$tablename = lc $tablename;
	$schema = lc $schema;
	$sql = "SELECT column_name,data_type,ordinal_position,is_nullable,column_comment,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_SCALE,COLUMN_TYPE " .
				"FROM columns " .
				"WHERE table_name = '$tablename'";

	$sth = $dbh->prepare($sql);
	unless ( defined $sth ) {
		warn("can't prepare sql : $sql\n$DBI::errstr\n");
		$dbh->disconnect();
		die("Goodbye ...\n");
	} # UNLESS
	unless ( $sth->execute ) {
		warn("can't execute sql : $sql\n$DBI::errstr\n");
		$dbh->disconnect();
		die("Goodbye ...\n");
	} # UNLESS

	%$ref_columns = ();
	while ( $ref = $sth->fetchrow_arrayref ) {
		@fields = @$ref;
		$colname = $fields[0];
		push @$ref_colnames,$colname;
		$$ref_columns{$colname} = $fields[1];
		if ( $$ref[1] eq "DATE" ) {
		} # IF
	} # WHILE
	$sth->finish();
	$dbh->disconnect();

	return scalar keys %$ref_columns;
} # end of get_table_columns

######################################################################
#
# Function  : get_table_columns_info
#
# Purpose   : Get list of column names and corresponding data types for a table.
#
# Inputs    : $_[0] - name of table
#             $_[1] - name of schema containing table
#             $_[2] - reference to hash to receive data
#             $_[3] - reference to array to receive ordered list of column names
#             $_[4] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF problem THEN negative ELSE number of columns
#
# Example   : $num_cols = get_table_columns_info($table,$schema,\%columns,\@colnames,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub get_table_columns_info
{
	my ( $tablename , $schema , $ref_columns , $ref_colnames , $ref_errmsg ) = @_;
	my ( $dbh , $sql , $sth , $ref , $db , $host , $user , $pwd , @fields , $colname );

	$$ref_errmsg = "";
	%$ref_columns = ();
	@$ref_colnames = ();

	$db = "INFORMATION_SCHEMA";	# your username (= login name  = account name )
	$host = "127.0.0.1";    # = "localhost", the server your are on.
	$user = "root";		# your Database name is the same as your account name.
	$pwd = "archer-nx01";	# Your account password

	# connect to the database.
	$dbh = DBI->connect( "DBI:mysql:$db:$host", $user, $pwd);
	unless ( defined $dbh ) {
		$$ref_errmsg = "Error connecting to $db : $DBI::errstr";
		return -1;
	} # UNLESS

	$tablename = lc $tablename;
	$schema = lc $schema;
	$sql = "SELECT column_name,data_type,ordinal_position,is_nullable,column_comment,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_SCALE,COLUMN_TYPE,COLUMN_KEY,EXTRA " .
				"FROM columns " .
				"WHERE table_name = '$tablename'";

	$sth = $dbh->prepare($sql);
	unless ( defined $sth ) {
		$$ref_errmsg = "can't prepare sql : $sql\n$DBI::errstr";
		$dbh->disconnect();
		return -1;
	} # UNLESS
	unless ( $sth->execute ) {
		$$ref_errmsg = "can't execute sql : $sql\n$DBI::errstr";
		$dbh->disconnect();
		return -1;
	} # UNLESS

	%$ref_columns = ();
	while ( $ref = $sth->fetchrow_arrayref ) {
		@fields = @$ref;
		$colname = $fields[0];
		push @$ref_colnames,$colname;
		$$ref_columns{$colname}{'data_type'} = $fields[1];
		$$ref_columns{$colname}{'ordinal'} = $fields[2];
		$$ref_columns{$colname}{'is_null'} = $fields[3];
		$$ref_columns{$colname}{'comment'} = $fields[4];
		$$ref_columns{$colname}{'char_maxlen'} = $fields[5];
		$$ref_columns{$colname}{'numeric_precision'} = $fields[6];
		$$ref_columns{$colname}{'numeric_scale'} = $fields[7];
		$$ref_columns{$colname}{'column_type'} = $fields[8];
		$$ref_columns{$colname}{'column_key'} = $fields[9];
		$$ref_columns{$colname}{'extra'} = $fields[10];
		if ( $$ref[1] eq "DATE" ) {
		} # IF
	} # WHILE
	$sth->finish();
	$dbh->disconnect();

	return scalar keys %$ref_columns;
} # end of get_table_columns_info

######################################################################
#
# Function  : find_matching_tables
#
# Purpose   : Get list of column names and corresponding data types for a table.
#
# Inputs    : $_[0] - name of table
#             $_[1] - name of schema containing table
#             $_[2] - reference to hash to receive list of table names
#                     (key = tablename , value = table type)
#
# Output    : (none)
#
# Returns   : Number of column names
#
# Example   : $num_tables = find_matching_tables($table_patern,$schema,\%columns);
#
# Notes     : (none)
#
######################################################################

sub find_matching_tables
{
	my ( $tablename_pattern , $schema , $ref_tablenames ) = @_;
	my ( $dbh , $sql , $sth , $ref , $db , $host , $user , $pwd );

	$db = "INFORMATION_SCHEMA";	# your username (= login name  = account name )
	$host = "127.0.0.1";    # = "localhost", the server your are on.
	$user = "root";		# your Database name is the same as your account name.
	$pwd = "archer-nx01";	# Your account password

	# connect to the database.
	$dbh = DBI->connect( "DBI:mysql:$db:$host", $user, $pwd);
	unless ( defined $dbh ) {
		die(undef,"Error connecting to $db : $DBI::errstr\n");
	} # UNLESS

	%$ref_tablenames = ();
	$schema = lc $schema;
	$sql = "select TABLE_NAME,TABLE_TYPE from tables " .
				"WHERE TABLE_SCHEMA = '$schema';";

	$sth = $dbh->prepare($sql);
	unless ( defined $sth ) {
		warn("can't prepare sql : $sql\n$DBI::errstr\n");
		$dbh->disconnect();
		die("Goodbye ...\n");
	} # UNLESS
	unless ( $sth->execute ) {
		warn("can't execute sql : $sql\n$DBI::errstr\n");
		$dbh->disconnect();
		die("Goodbye ...\n");
	} # UNLESS

	while ( $ref = $sth->fetchrow_arrayref ) {
		if ( $$ref[0] =~ m/${tablename_pattern}/i ) {
			$$ref_tablenames{$$ref[0]} = $$ref[1];
		} # IF
	} # WHILE
	$sth->finish();
	$dbh->disconnect();

	return scalar keys %$ref_tablenames;
} # end of find_matching_tables

######################################################################
#
# Function  : mysql_connect_to_db
#
# Purpose   : Get a connection to a MySQL database.
#
# Inputs    : $_[0] - name of database (i.e. the schema)
#             $_[1] - name of host (or i.p. address)
#             $_[2] - username
#             $_[3] - password
#             $_[4] - reference to error message buffer
#             $_[5] - reference to hash of connection parameters
#                     (eg.  %attr = ( "PrintError" => 0 , "RaiseError" => 0 );
#
# Output    : (none)
#
# Returns   : IF no problem THEN database handle ELSE undefined
#
# Example   : $dbh = mysql_connect_to_db($db,$host,$user,$pwd,\$errmsg,\%attr);
#
# Notes     : (none)
#
######################################################################

sub mysql_connect_to_db
{
	my ( $db , $host , $user , $pwd , $ref_errmsg , $ref_attr ) = @_;
	my ( $dbh );

	$$ref_errmsg = "";
	$dbh = DBI->connect( "DBI:mysql:$db:$host", $user, $pwd, $ref_attr);
	unless ( defined $dbh ) {
		$$ref_errmsg = "Error connecting to '$db' on '$host'  : $DBI::errstr\n ";
		return undef;
	} # UNLESS

	return $dbh;
} # end of mysql_connect_to_db

1;
