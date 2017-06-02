#!/usr/bin/perl
# pdb_table_creator.plx
use DBI;
use DBD::mysql;
use warnings;
use strict;


# db name
my $database = "myproject";
#invoke subroutine to make db connection
my $connection = ConnectToDB($database);

DropTables();
CreateTables();


#######################################################################################################################################################
################################################		Begin Sub Routines		#######################################################
#######################################################################################################################################################


#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 DropTables

Parameters	:	Void
Returns		:	Void
Description	:	Drops the tables for pdb testing

=cut

sub DropTables {

	my @table_names = ("atom", "experiment", "phi_psi");

	for (@table_names) {
		my $drop_statement = $connection -> prepare("DROP TABLE $_;");
		$drop_statement -> execute();
	}
}


#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 CreateTables

Parameters	:	Void
Returns		:	Void
Description	:	Creates the tables for pdb testing

=cut

sub CreateTables {

	my $table_atom = "CREATE TABLE atom(_id integer NOT NULL auto_increment,
	protein varchar(4),  /*  the protein the record belongs to */
	record varchar(6), /*  the type of atom */
	serial integer, /*  atom serial number */
	name varchar(4), /*  atom name */
	resName varchar(3), /*  residue name */
	chainId varchar(1), /*  chain identifier */
	resSeq varchar(4), /*  residue sequence number */
	x_coord float, /*  x coordinate */
	y_coord float, /*  y coordinate */
	z_coord float, /*  z coordinate */
	occupancy float, /*  occupancy */
	tempFactor float, /*  temperature factor */
	element varchar(2), /*  element symbol */
	model integer, /*  model number */
	primary key (_id, protein, record, serial, name, resName, chainId, model)
	);";

	my $table_phi_psi = "CREATE TABLE phi_psi(
	_id integer NOT NULL auto_increment,
	protein varchar(4),  /*  the protein */
	resName varchar(3), /*  residue name */
	phi decimal(4,1), /*  phi value */
	psi decimal(4,1), /*  psi value */
	alpha decimal(4,1), /*  alpha value */
	kappa decimal(4,1), /*  kappa value */
	primary key (_id, protein, resName)
	);";

	my $table_experiment = "CREATE TABLE experiment(
	_id integer NOT NULL auto_increment,
	protein varchar(4),  /*  the protein */
	experiment_method ENUM('X-RAY DIFFRACTION', 'FIBER DIFFRACTION', 'NEUTRON DIFFRACTION', 'ELECTRON CRYSTALLOGRAPHY', 
	'ELECTRON MICROSCOPY', 'SOLID-STATE NMR', 'SOLUTION NMR', 'SOLUTION SCATTERING'),  /*  the type of experiment to get protein data */
	primary key (_id, protein)
	);";

	my @tables = ($table_phi_psi, $table_atom, $table_experiment);

	for (@tables) {
		my $statement = $connection -> prepare($_);
		$statement -> execute();
	}
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ConnectToMySql

Parameters	:	Name of MySQL database
Returns		:	connection to database
Description	:	Connects to MySQL database

=cut

sub ConnectToDB {

	my ($db) = @_;

	#open the accessAdd file to retrieve the database name, user name and password
	#if necesary, here is where host name would be as well 
	open(ACCESS_INFO, "accessAdd") || die "Can't access login credentials";
	# assign the values in the accessDB file to the variables
	my $database = <ACCESS_INFO>;
	my $userid = <ACCESS_INFO>;
	my $passwd = <ACCESS_INFO>;

	#assign the values to your connection variable and pass db name in $db
	my $connectionInfo = "dbi:mysql:$db";

	#close the accessAdd file
	close(ACCESS_INFO);

	#the chomp() function will remove any newline character from the end of a string
	chomp ($database, $userid, $passwd);

	# make connection to database
	my $l_connection = DBI->connect($connectionInfo,$userid,$passwd) or die $DBI::errstr;
	
	# the value of this connection is returned by the sub-routine
	return $l_connection;
}
