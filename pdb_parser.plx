#!/usr/bin/perl
# pdb_parser_v5.plx
use DBI;
use DBD::mysql;
use File::Find;
use File::Copy;
use Time::Piece;
use warnings;
use strict;

# Directory recursion path 
# my $base_path = "/home/valdeslab/PDB_files/_pdb/00";
my $base_path = "/home/valdeslab/PDB_files/TestPDB";
# my $base_path = "/home/valdeslab/PDB_files/_pdb";

# Log files
my $log_file = "/home/valdeslab/PDB_files/error_dir_logs/pdb_log.txt";

# time variables;
my $start = localtime;		
my $finish;
my $completion;

# variables
my $count = 0;
my $file_count = 125770;

# db variables and setup

# db name
my $database = "myproject";
#invoke subroutine to make db connection
my $connection = ConnectToDB($database);


# process pdb files 
ProcessFiles($base_path);

$completion = $finish - $start;
Complete($completion, $count);


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

    	# my $path = shift;
	my $path = $_[0];
	my $error_path = "/home/valdeslab/PDB_files/error_dir";

	#--- pdb variables ---
	my $header = "HEADER";

	# Title section
	my $method = "EXPDTA";

	# Coordinate section
	my $model = "MODEL";
	my $endmdl = "ENDMDL";
	my $atom = "ATOM";
	my $anisou = "ANISOU";
	my $hetatm = "HETATM";

	# variables to be inserted in db
	my($protein_id, $record, $serial, $name, $resName, $chain_id, $resSeq, $x_coord, $y_coord, $z_coord, $occupancy, $tempFactor, $element, $model_number);

   	# open directory
    	opendir(DIR, $path) || die "Unable to open $path: $!";

	# read in files
	# grep to eliminate '.', '..' files
    	my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    	# close directory.
    	closedir (DIR);

	# place file names into map to attach full path
    	@files = map { $path . '/' . $_ } @files;

	#
    	for (@files) {
        	#if file is a directory
		if (-d $_) {
			#recursive call w/ new directory
		    	ProcessFiles ($_);

		# process file
		} else { 
			$count++;
		 	# print number of pdb to be processed and path
			print "$count \t $_\n";
			my $current_file = $_;
			# open file
			open IN, $_ || die "Can't read source file $_: $!\n";
			my $file_start = localtime;
			my $errors = 0;
			$model_number = 1;
			
			while (<IN>) {
				# chomp each line. will remove \n from each string
				chomp $_;
				# remove white space
				$_ = Trim($_);
				# substr EXPR,OFFSET,LENGTH
				$record = Trim(substr $_, 0, 6);
				
				# Set the protein id
				if ($record eq $header){
					$protein_id = substr $_, -4, 4;
					print "$protein_id processing:\t$file_start\n";
				}

				# Get the method of experiment, insert into database
				if ($record eq $method) {

					my $expdta = Trim(substr $_, 10);
					my $method_query = "insert into experiment (protein, experiment_method) values (?, ?)";
					my $method_statement = $connection -> prepare($method_query);
					$method_statement -> execute($protein_id, $expdta);

					# Record errors
					if ($method_statement -> err) {	
						my @array;			
						ErrorHeader($protein_id) if $errors == 0;
						LogError($protein_id, $method_statement, \@array);
						$errors++;
					} # close if statement $statement -> err

				} # Close if ($record eq $method)
				
				if ($record eq $model) {		
					$model_number = Trim(substr $_, 11, 3);
				}

				# get atom data, insert into database
				if ($record eq $atom || $record eq $hetatm) {
					$serial = substr $_, 6, 5; 
					$name = substr $_, 12, 4; 
					$resName = substr $_, 17, 3; 
					$chain_id = substr $_, 21, 1; 
					$resSeq = substr $_, 22, 4; 

					$x_coord = Trim(substr $_, 30, 8);  
					$y_coord = Trim(substr $_, 38, 8); 
					$z_coord = Trim(substr $_, 46, 8); 
					$occupancy = substr $_, 55, 5; 
					$tempFactor = substr $_, 60, 6; 
					$element = substr $_, 76, 2; 

					# set query for sql insert
					my $query = "insert into atom (protein, record, serial, name, resName, chainId, resSeq, x_coord, y_coord, z_coord, occupancy, tempFactor, element, model) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ";

					# prepare statement to be connected to db
					my $statement = $connection -> prepare($query);

					$statement -> execute($protein_id, $record, $serial, $name, $resName, $chain_id, $resSeq, $x_coord, $y_coord, $z_coord, $occupancy, $tempFactor, $element, $model_number);

					# Record errors
					if ($statement -> err) {	
						my @array;			
						ErrorHeader($protein_id) if $errors == 0;
						LogError($protein_id, $statement, \@array);
						$errors++;
					} # close if statement $statement -> err

				} # close if statment  $record eq $atom

			} # close while loop <IN>

			copy($current_file, $error_path) if $errors > 0;
			close IN;

			LogProtein($protein_id, $file_start, localtime(), $errors);

        	} # close if statement -d $_

		$completion = localtime() - $start;
		Duration($completion);
		FilesProcessed($count);

    	} # close for loop @files
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ConnectToMySql

Parameters	:	Name of MySQL database
Returns		:	connection to database
Description	:	Connects to MySQL database

=cut

sub ConnectToDB{

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

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ErrorHeader

Parameters	:	protein id, SQL error, SQL statement
Returns		:	void
Description	:	writes to error file

=cut

sub ErrorHeader{
	my $id = $_[0];
	my $error_file = "/home/valdeslab/PDB_files/LogReports/error_dir_logs";
	$error_file = $error_file .= '/' .$id.'.txt';

	open ERROR, ">> $error_file" || die "Can't write on file $error_file: $!\n";
	print ERROR "-----------------------------------------------------------------------------\n";
	print ERROR "Errors for protien: $id\n";
	close ERROR;
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 LogError

Parameters	:	protein id, SQL error, SQL statement
Returns		:	void
Description	:	writes to error file

=cut

sub LogError{
	my $id = $_[0];
	my $state = $_[1];
	my @line = @{$_[2]};
	my $error_line = "";
	my $error_file = "/home/valdeslab/PDB_files/LogReports/error_dir_logs";
	$error_file = $error_file .= '/' .$id.'.txt';
	
	for (@line){
		$error_line .= $_." ";
	}
	open ERROR, ">> $error_file" || die "Can't write on file $error_file: $!\n";
	print ERROR "DBI ERROR: ", $state -> err, " : ", $state -> errstr, "\n";
	print ERROR "$error_line\n";
	close ERROR;
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 LogProtein

Parameters	:	Protein id, start time, finish time, number of errors
Returns		:	void
Description	:	writes to log file

=cut

sub LogProtein{
	my $id = $_[0];
	my $started = $_[1];
	my $finished = $_[2];
	my $error = $_[3];
	my $log_file = "/home/valdeslab/PDB_files/LogReports/pdb_protein_log.txt";

	print "$id completed:\t\t$finished\n";
	open LOG, ">> $log_file" || die "Can't write on file $log_file: $!\n";
	print LOG "-----------------------------------------------------------------\n";
	print LOG "$id started:\t$started\n";
	print LOG "$id completed:\t$finished\n";
	print LOG "Number of Errors:\t$error\n";
	print LOG "Time to process:\t", ($finished - $started), " seconds\n";
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Complete

Parameters	:	Duration of seconds, number of files processed
Returns		:	String
Description	:	returns program run time duration

=cut

sub Complete{
	my $time = $_[0];
	my $count = $_[1];
	my $log_file = "/home/valdeslab/PDB_files/LogReports/pdb_completion_log.txt";

	open LOG, ">> $log_file" || die "Can't write on file $log_file: $!\n";
	print LOG "Time of completion:\nWeeks:\t".Weeks($time)."\tDays:\t".Days($time).
	"\tHours:\t".Hours($time)."\tMins:\t".Minutes($time)."\tSec:\t".Seconds($time)."\n";
	print LOG "Files processed:\t$count\n";
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Duration

Parameters	:	Duration of seconds
Returns		:	String
Description	:	returns program run time duration

=cut

sub Duration{
	my $time = $_[0];
	print "Duration:\nWeeks:\t".Weeks($time)."\tDays:\t".Days($time).
			"\tHours:\t".Hours($time)."\tMins:\t".Minutes($time)."\tSec:\t".Seconds($time)."\n";
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 FilesProcessed

Parameters	:	Number of files processed
Returns		:	void
Description	:	prints number of files currently processed

=cut

sub FilesProcessed{
	my $files = $_[0];
	print "Files processed:\t$files\n";
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Seconds

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of seconds

=cut

sub Seconds{
	return $_[0]%60;
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Minutes

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of minutes

=cut

sub Minutes{
	return ($_[0]/60)%60;
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Hours

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of hours

=cut

sub Hours{
	return ($_[0]/60/60)%24;
}

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Days

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of days

=cut

sub Days{
	return ($_[0]/60/60/24)%7;
}

#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 Weeks

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of weeks

=cut

sub Weeks{
	return ($_[0]/60/60/24/7)%52;
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

