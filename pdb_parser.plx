#!/usr/bin/perl
#pdb_parserV3.plx
use DBI;
use DBD::mysql;
use File::Find;
use File::Copy;
use Time::Piece;
use warnings;
use strict;
use Switch;

#--- Base directory path
my $base_path = "/path";


#--- Path to store log files
my $log_file = "/path/log.txt";

#--- time variables;
my $start = localtime;		
my $finish;
my $completion;

#--- variables
my $count = 0;
my $file_count = 125770;

#db variables and setup

#db name
my $database = "myproject";
#invoke subroutine to make db connection
my $connection = ConnectToMySql($database);
#set query for sql insert
my $query = "insert into atom_site_seq (atom, id, atom_id, comp_id, asym_id, seq_id, x_coord, y_coord, z_coord, occupancy, b_iso, type_symbol)
values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ";
#prepare statement to be connected to db
my $statement = $connection -> prepare($query);

#open file and append new info
open LOG, ">> $log_file" or die "Can't write on file $log_file: $!\n";
print LOG "Started Processing directory $base_path at: $start\n";

#process pdb files 
ProcessFiles ($base_path);

$finish = localtime;
print LOG "Completed Processing directory $base_path at: $finish\n\n";
$completion = $finish - $start;
Complete($completion, $count);

#close file
close ERROR;
close LOG;

#############################################################################################
########################		Begin Sub Routines		#####################################
#############################################################################################

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 ProcessFiles

Parameters	:	
Returns		:
Description	:

=cut

sub ProcessFiles {

    	#my $path = shift;
		my $path = $_[0];
		my $errors = 0;
		my @array;
		my $now;
		my $file_start;
		my $file_finish;
		my $current_file;
		my $error_file = "/path/error_dir_logs";
		my $error_path = "/path/error_dir";

		#--- pdb variables 
		my $header = "HEADER";
		#atom info
		my $atom = "ATOM";
		my $remark = "REMARK";
		my $compnd = "COMPND";
		my $hetatm = "HETATM";
	
		
		#variables to be inserted in db
		my($protein_id, $id, $atom_id, $comp_id, $asym_id, $seq_id, $x_coord, $y_coord, $z_coord, $occupancy, $b_iso, $type_symbol) = "";

   		#open directory
    	opendir(DIR, $path) || die "Unable to open $path: $!";

		#read in files
		#grep to eliminate '.', '..' files
    	my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    	#close directory.
    	closedir (DIR);

		#place file names into map to attach full path
    	@files = map { $path . '/' . $_ } @files;

		#
    	for (@files) {
        	#if file is a directory
		if (-d $_) {
			#recursive call w/ new directory
		    	ProcessFiles ($_);

		#process file
		} else { 
			$count++;
		    #print number of pdb to be processed and path
			print "$count \t $_\n";
			$current_file = $_;
			#open file
			open IN, $_ || die "Can't read source file $_: $!\n";
			$file_start = localtime;
			$errors = 0;
			
			while (<IN>) {
				#chomp each line. will remove \n from each string
				chomp $_;
				$_ = Trim($_);
				#split the line by ' ' and place each split into the array
				@array = split ' ', $_;
				my $tag = substr $_, 0, 7;
				# remove white space
				$tag = Trim($tag);


				if($tag eq $header){
					$protein_id = substr $_, -4, 4;
					print "$protein_id processing:\t$file_start\n";
					$error_file .= '/' .$protein_id.'.txt';
				}

				#location for other insertion statements

				if ($array[0] eq $atom) {
					$statement -> execute($protein_id, $array[1], $array[2], $array[3], $array[4], $array[5], 
						$array[6], $array[7], $array[8], $array[9], $array[10], $array[11]);
					if($statement -> err){				
						open ERROR, ">> $error_file" || die "Can't write on file $error_file: $!\n";
						ErrorHeader($protein_id) if $errors eq 0;
						LogError($statement, \@array);
						close ERROR;
						$errors++;
					}#close if statement
				}#close if statment
			}#close while loop
			copy($current_file, $error_path) if $errors > 0;
			close IN;
			$file_finish = localtime;
			LogProtein($protein_id, $file_start, $file_finish, $errors);
        	}#close if statement
		$now = localtime;
		$completion = $now - $start;
		Duration($completion);
		FilesProcessed($count);
		$error_file = "/path/error_dir_logs";

    	}#close for loop
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 ConnectToMySql

Parameters	:	Name of MySQL database
Returns		:	connection to database
Description	:	Connects to MySQL database

=cut

sub ConnectToMySql{

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

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 ErrorHeader

Parameters	:	protein id, SQL error, SQL statement
Returns		:	void
Description	:	writes to error file

=cut

sub ErrorHeader{
	my $id = $_[0];
	print ERROR "-----------------------------------------------------------------------------\n";
	print ERROR "Errors for protien: $id\n";
	
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 LogError

Parameters	:	protein id, SQL error, SQL statement
Returns		:	void
Description	:	writes to error file

=cut

sub LogError{
	my $state = $_[0];
	my @line = @{$_[1]};
	my $error_line;

	for (@line){
		$error_line .= $_." ";
	}
	print ERROR "DBI ERROR: ", $state -> err, " : ", $state -> errstr, "\n";
	print ERROR "$error_line\n";
}

#////////////////////////////////////////////////////////////////////////////////////////////

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
	print "$id completed:\t\t$finished\n";
	print LOG "-----------------------------------------------------------------\n";
	print LOG "$id started:\t$started\n";
	print LOG "$id completed:\t$finished\n";
	print LOG "Number of Errors:\t$error\n";
	print LOG "Time to process:\t", ($finished - $started), " seconds\n";
	
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Complete

Parameters	:	Duration of seconds, number of files processed
Returns		:	String
Description	:	returns program run time duration

=cut

sub Complete{
	my $time = $_[0];
	my $count = $_[1];
	print LOG "Time of completion:\nWeeks:\t".Weeks($time)."\tDays:\t".Days($time).
	"\tHours:\t".Hours($time)."\tMins:\t".Minutes($time)."\tSec:\t".Seconds($time)."\n";
	print LOG "Files processed:\t$count\n";
}

#////////////////////////////////////////////////////////////////////////////////////////////

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

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 FilesProcessed

Parameters	:	Number of files processed
Returns		:	void
Description	:	prints number of files currently processed

=cut

sub FilesProcessed{
	my $files = $_[0];
	print "Files processed:\t$files\n";
	
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Seconds

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of seconds

=cut

sub Seconds{
	return $_[0]%60;
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Minutes

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of minutes

=cut

sub Minutes{
	return ($_[0]/60)%60;
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Hours

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of hours

=cut

sub Hours{
	return ($_[0]/60/60)%24;
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Days

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of days

=cut

sub Days{
	return ($_[0]/60/60/24)%7;
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Weeks

Parameters	:	Duration of seconds
Returns		:	int
Description	:	returns number of weeks

=cut

sub Weeks{
	return ($_[0]/60/60/24/7)%52;
}

#////////////////////////////////////////////////////////////////////////////////////////////

=head1 Trim

Parameters	:	remove white space from string
Returns		:	string
Description	:	returns string w/ white space removed

=cut

sub  Trim { 
	my $s = shift; $s =~ s/^\s+|\s+$//g; return $s 
}

