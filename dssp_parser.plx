#!/usr/bin/perl
# dssp_parse.plx
use DBI;
use DBD::mysql;
use File::Find;
use File::Copy;
use Time::Piece;
use warnings;
use strict;

# my $base_path = "/home/valdeslab/PDB_files/_pdb_dssp";
my $base_path = "/home/valdeslab/PDB_files/TestDSSP";

my $database = "myproject";
# invoke subroutine to make db connection
my $connection = ConnectToDB($database);

ProcessFiles($base_path);


#######################################################################################################################################################
################################################		Begin Sub Routines		#######################################################
#######################################################################################################################################################

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ProcessFiles

Parameters	:	
Returns		:
Description	:

=cut

sub ProcessFiles {

	# Directory paths
	my $path = $_[0];

	# Set query for sql insert
	my $insert = "insert into phi_psi (protein, resName, phi, psi, alpha, kappa) values (?, ?, ?, ?, ?, ?) ";

	#--- Used to know where to start to process the file
	my $engage = "#";

	# Open directory
    	opendir(DIR, $path) || die "Unable to open $path: $!";

	# Read in files
	# Grep to eliminate '.', '..' files
    	my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    	# Close directory.
    	closedir (DIR);

	# Place file names into map to attach full path
    	@files = map { $path . '/' . $_ } @files;

    	for (@files) {

		# Open file
		open IN, $_ || die "Can't read source file $_: $!\n";

		# Protein
		my $protein = substr $_, -9, 4;

		# Begin processing data after set to #
		my $acknowledged = "";
		my $errors = 0;
		
		print "processing $_\n";

		while (<IN>) {
			# remove \n
			chomp $_;

			if ($acknowledged eq $engage) {
				# Data parsing and storing occurs here
				my $resName = AminoAbbr(Trim(substr $_, 13, 1));
				my $phi = Trim(substr $_, 103, 6);
				my $psi = Trim(substr $_, 109, 6);
				my $alpha = Trim(substr $_, 97, 6);
				my $kappa = Trim(substr $_, 91, 6);

				# if ($resName = "CBI") { db stuff here }  In case we don't want to record the chain breaks

				# Prepare statement to be connected to db
				my $statement = $connection -> prepare($insert);
				# Insert values
				$statement -> execute($protein, $resName, $phi, $psi, $alpha, $kappa);

					if ($statement -> err) {
						my @array;				
						ErrorHeader($protein) if $errors == 0;
						LogError($statement, \@array);
						$errors++;
					} # Close if ($statement -> err)

			} #Close if ($acknowledged eq $engage)

			# Find where to start parsing and storing data
			if ($acknowledged ne $engage) {
				$acknowledged = substr $_, 0, 4;
				$acknowledged = Trim($acknowledged);
			} # Close if ($acknowledged ne $engage)

		} # Close while (<IN>)

	} # Close for (@files)
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

#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Trim

Parameters	:	remove white space from string
Returns		:	string
Description	:	returns string w/ white space removed

=cut

sub  Trim { 
	my $s = shift; 
	$s =~ s/^\s+|\s+$//g; 
	return $s;
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 AminoAbbr

Parameters	:	Single character abbreviation for amino acid
Returns		:	Three character abbreviation for amino acid
Description	:	Converts amino acid abbreviation from single to three characters

=cut

sub AminoAbbr {

	my $amino_acid = shift;

	my %amino = (
		A	=>	"ALA",
		R	=>	"ARG",
		N	=>	"ASN",
		D	=>	"ASP",
		B	=>	"ASX",
		C	=>	"CYS",
		E	=>	"GLU",
		Q	=>	"GLN",
		Z	=>	"GLX",
		G	=>	"GLY",
		H	=>	"HIS",
		I	=>	"IIE",
		L	=>	"LEU",
		K	=>	"LYS",
		M	=>	"MET",
		F	=>	"PHE",
		P	=>	"PRO",
		S	=>	"SER",
		T	=>	"THR",
		W	=>	"TRP",
		Y	=>	"TYR",
		V	=>	"VAL",
		"!"	=>	"CBI"		# Chain break identifier
	);
	return $amino{$amino_acid};
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ErrorHeader

Parameters	:	protein
Returns		:	void
Description	:	writes to error file

=cut

sub ErrorHeader{

	my $id = $_[0];
	my $error_file = "/home/valdeslab/PDB_files/LogReports/dssp_errors.txt";

	open ERROR, ">> $error_file" || die "Can't write on file $error_file: $!\n";
	print ERROR "-----------------------------------------------------------------------------\n";
	print ERROR "Errors for protein: $id\n";
	close ERROR;
	
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 LogError

Parameters	:	protein, SQL error, SQL statement
Returns		:	void
Description	:	writes to error file

=cut

sub LogError{

	my $state = $_[0];
	my @line = @{$_[1]};
	my $error_line = "";
	my $error_file = "/home/valdeslab/PDB_files/LogReports/dssp_errors.txt";

	for (@line){
		$error_line .= $_." ";
	}
	open ERROR, ">> $error_file" || die "Can't write on file $error_file: $!\n";
	print ERROR "DBI ERROR: ", $state -> err, " : ", $state -> errstr, "\n";
	print ERROR "$error_line\n";
	close ERROR;
}
