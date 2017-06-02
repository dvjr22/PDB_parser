# PDB Parser
Perl scripts used to create a RDBMS of the PDB.  Currently still in development test phase.

## Files
- db_table_creater.plx
 - Drops all tables from database and replaces them. 
- dive_parse_4.plx
 - Recursively accesses file directories, to parse and store PDB data in the database
- dssp_file_creator.plx
 - Recurively accesses file directories and converts pdb files (.ent) to dssp files (.dssp)
- dssp_parse.plx
 - Accesses a directory and parses dssp data to the database
- createtable.sql
 - The MySQL tables currently being used.

## Contributers
Just me
