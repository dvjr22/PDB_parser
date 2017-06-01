/*
Diego Valdes

create sample table for testing
*/

/*drop existing tables*/
DROP TABLE atom;
DROP TABLE experiment;
DROP TABLE phi_psi;

/*create new tables*/
CREATE TABLE atom(
_id integer NOT NULL auto_increment,
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
);

CREATE TABLE experiment(
_id integer NOT NULL auto_increment,
protein varchar(4),  /*  the protein */
experiment_method ENUM('X-RAY DIFFRACTION', 'FIBER DIFFRACTION', 'NEUTRON DIFFRACTION', 'ELECTRON CRYSTALLOGRAPHY', 'ELECTRON MICROSCOPY', 'SOLID-STATE NMR', 'SOLUTION NMR', 'SOLUTION SCATTERING'),  /*  the type of experiment to get protein data */
primary key (_id, protein)
);

CREATE TABLE phi_psi(
_id integer NOT NULL auto_increment,
protein varchar(4),  /*  the protein */
resName varchar(3), /*  residue name */
phi decimal(4,1), /*  phi value */
psi decimal(4,1), /*  psi value */
alpha decimal(4,1), /*  alpha value */
kappa decimal(4,1), /*  kappa value */
primary key (_id, protein, resName)
);



