# PDB Parser
Perl scripts used to create a RDBMS of the PDB.  Currently still in development test phase.

This project is designed to function around the [PDB](http://www.wwpdb.org/download/downloads) default archive.
All scripts were written to work with the default PDB path structure. All files were unzipped before these scripts were put to work,
they will not unzip any files as they run through directories, as the files should already be unzipped.


## Files
- db_table_creater.plx
  - Drops all tables from database and replaces them. 
- pdb_parser.plx
  - Recursively accesses file directories, to parse and store PDB data in the database
- dssp_file_creator.plx
  - Recurively accesses file directories and converts pdb files (.ent) to dssp files (.dssp)
- dssp_parser.plx
  - Accesses a directory and parses dssp data to the database
- createtable.sql
  - The MySQL tables currently being used.

## Contributers
Just me
