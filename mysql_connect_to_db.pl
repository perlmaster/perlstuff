#!C:\Perl64\bin\perl.exe -w

######################################################################
#
# File      : mysql_connect_to_db.pl
#
# Author    : Barry Kimelman
#
# Created   : January 23, 2017
#
# Purpose   : Connect to a MySQL database
#
# Notes     : (none)
#
######################################################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;

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
#             $_[4] - reference to attributes hash
#             $[5] - reference to error message buffer
#
# Output    : (none)
#
# Returns   : IF success THEN database handle ELSE undefined
#
# Example   : $dbh = mysql_connect_to_db($db,$host,$user,$pwd,\%attr,\$errmsg);
#
# Notes     : (none)
#
######################################################################

sub mysql_connect_to_db
{
	my ( $db , $host , $user , $pwd , $ref_attr , $ref_errmsg ) = @_;
	my ( $dbh );

	$$ref_errmsg = "";
	$dbh = DBI->connect( "DBI:mysql:$db:$host", $user, $pwd, $ref_attr);
	unless ( $dbh ) {
		$$ref_errmsg = "Error connecting to $db on $host : $DBI::errstr";
		return undef;
	} # UNLESS

	return $dbh;
} # end of mysql_connect_to_db

1;
