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
resSeq integer, /*  residue sequence number */
x_coord decimal(5,3), /*  x coordinate */
y_coord decimal(5,3), /*  y coordinate */
z_coord decimal(5,3), /*  z coordinate */
occupancy float, /*  occupancy */
tempFactor float, /*  temperature factor */
element varchar(2), /*  element symbol */
model integer, /*  model number */
primary key (_id),
unique (protein, record, serial, name, resName, chainId, model)
);

CREATE TABLE phi_psi(
_id integer primary key NOT NULL auto_increment,
protein varchar(4),  /*  the protein */
resSeq integer, /*  residue sequence number */
resName varchar(3), /*  residue name */
phi decimal(4,1), /*  phi value */
psi decimal(4,1), /*  psi value */
alpha decimal(4,1), /*  alpha value */
kappa decimal(4,1) /*  kappa value */
);

CREATE TABLE experiment(
_id integer primary key NOT NULL auto_increment,
protein varchar(4) unique,  /*  the protein */
experiment_method ENUM(
'X-RAY DIFFRACTION', 
'FIBER DIFFRACTION', 
'NEUTRON DIFFRACTION', 
'ELECTRON CRYSTALLOGRAPHY', 
'ELECTRON MICROSCOPY', 
'SOLID-STATE NMR', 
'SOLUTION NMR', 
'SOLUTION SCATTERING'
)  /*  the type of experiment to get protein data */
);





