#!/usr/bin/perl
# connect.plx
use DBI;
use DBD::mysql;
use warnings;
use strict;

# Place the below in every file that needs to access the db
# Require a connection to the db
# require 'connect.plx';
# my $database = "pdb";
# invoke subroutine to make db connection
# my $connection = ConnectToDB($database);

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ConnectToMySql

Parameters	:	Name of MySQL database
Returns		:	connection to database
Description	:	Connects to MySQL database
			Needs a file with database info formated as follows:
			"dbname\n"
			"userid\n"
			"password"
			Host name would go in this file if it were needed
=cut

sub ConnectToDB {

	my ($db) = @_;

	# Open the accessAdd file to retrieve the database name, user name and password
	# If necesary, here is where host name would be as well 
	open(ACCESS_INFO, "accessAdd") || die "Can't access login credentials";
	# Assign the values in the accessDB file to the variables
	my $database = <ACCESS_INFO>;
	my $user = <ACCESS_INFO>;
	my $password = <ACCESS_INFO>;

	# assign the values to your connection variable and pass db name in $db
	my $connection = "dbi:mysql:$db";

	#close the accessAdd file
	close(ACCESS_INFO);

	#the chomp() function will remove any newline character from the end of a string
	chomp ($database, $user, $password);

	# make connection to database
	my $l_connection = DBI -> connect($connection, $user, $password) or die $DBI::errstr;
	
	# the value of this connection is returned by the sub-routine
	return $l_connection;
}
1;


