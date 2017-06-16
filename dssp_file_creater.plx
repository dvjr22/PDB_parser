#!/usr/bin/perl
# dssp_file_creater.plx
use warnings;
use strict;

# pdb file locations
my $base_path = "/home/valdeslab/PDB_files/_pdb";
# my $base_path = "/home/valdeslab/PDB_files/_pdb/00";
# my $base_path = "/home/valdeslab/PDB_files/TestPDB";

# Keep track of errors
my $error_count = 0;
my $file_count = 0;

# process pdb files to get dssp files
ProcessFiles ($base_path);


#######################################################################################################################################################
################################################		Begin Sub Routines		#######################################################
#######################################################################################################################################################

#//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

=head1 ProcessFiles

Parameters	:	Base path of directory
Returns		:	Void
Description	:	Run through directories and execute dssp on pdb*.ent files. Store dssp files in proper directroy. Record any errors.

=cut

sub ProcessFiles {

	# Paths for recursion, storing dssp, and log file
	my $path = $_[0];
	my $dssp_path = "/home/valdeslab/PDB_files/_pdb_dssp";
	my $log_file = "/home/valdeslab/PDB_files/dssp_log.txt";
	my $progress_file = "/home/valdeslab/PDB_files/dssp_progress.txt";

	# open directory
    	opendir(DIR, $path) || die "Unable to open $path: $!";
	# read in files
	# grep to eliminate '.', '..' files
    	my @files = grep { !/^\.{1,2}$/ } readdir (DIR);
    	# close directory.
    	closedir (DIR);
	# place file names into map to attach full path
    	@files = map { $path . '/' . $_ } @files;

	# cycle throuch files
    	for (@files) {
        	#if file is a directory
		if (-d $_) {
			#recursive call w/ new directory
		    	ProcessFiles ($_);
		# create dssp file
		} else {
			$file_count++;
			print "$file_count\tProcessing $_\n";
			# get pdb file name and append to path for storing *.dssp
			my $file_name = substr $_, -11, 7;
			$dssp_path .= '/' .$file_name. '.dssp';
			# execute dssp with path of *.ent and path for *.dssp to be stored
			my $output = system("dssp -i $_ -o $dssp_path");
			# Catch errors
			if ($output != 0) {
				$error_count++;
				# open file and append proteins that don't have a *.dssp
				open LOG, ">> $log_file" or die "Can't write on file $log_file: $!\n";
				print LOG "$file_name\nThe current file $_ threw error $output\n";
				print LOG "Number of errors:\t$error_count\n";
				print LOG "----------------------------------------------------------------------------------\n";
			} # Close if $output == 0
		} #Close if else
		# Reset path
		$dssp_path = "/home/valdeslab/PDB_files/_pdb_dssp";
		
	} # Close for @files
	# Log progress and print to screen
	open FILE, "> $progress_file" or die "Can't write on file $progress_file: $!\n";
	print FILE "Files processed:\t$file_count\tFiles with errors:\t$error_count\n";
	print FILE "----------------------------------------------------------------------------------\n";
	print "Files processed:\t$file_count\tFiles with errors:\t$error_count\n";
	print "----------------------------------------------------------------------------------\n";
} # Close subroutine

