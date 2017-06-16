
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

select * from atom where protein = '1D3Z' and serial = 1 and model = 1;
select * from atom where protein = '1D3Z' and resSeq = 1 and model = 1;

select * from atom where protein = '1D3Z' and resSeq = 1 and model = 1
union
select * from atom where protein = '1D3Z' and resSeq = 1 and model = 2;

select * from atom where protein = '1D3Z' and resName = 'gly' and model = 1;

select distinct resSeq from atom where protein = '1D3Z' and resName = 'gly' and model = 1;



select * from atom 
where 
protein = '1D3Z' and resName = 'gly' and model = 1 and
resSeq in (select distinct resSeq from atom where protein = '1D3Z' and resName = 'gly' and model = 1);




select * from atom 
where 
protein = '1D3Z'and model = 1 and
resSeq in (select distinct resSeq - 1 from atom where protein = '1D3Z' and resName = 'gly' and model = 1)
union 
select * from atom 
where 
protein = '1D3Z'and model = 1 and
resSeq in (select distinct resSeq + 1 from atom where protein = '1D3Z' and resName = 'gly' and model = 1);




select * from phi_psi where resName = 'gly';


select * from phi_psi 
where 
resSeq in (select distinct resSeq - 1 from phi_psi where resName = 'gly')
union 
select * from phi_psi 
where 
resSeq in (select distinct resSeq + 1 from phi_psi where resName = 'gly');


+--------+
| resSeq |
+--------+no
|     10 |
|     35 |
|     47 |
|     53 |
|     75 |
|     76 |
+--------+



/*

		model
MODEL        	1   

record	serial  name	resName	chainId	resSeq	x_coord	y_coord	z_coord	occupancy	tempFactor	element          
ATOM      1  	N   	MET 	A   	1      	52.923 	-90.016 8.509  	1.00  		9.67		N  

ATOM      2  CA  MET A   1      51.653 -89.304   8.833  1.00 10.38           C  
ATOM      3  C   MET A   1      50.851 -89.086   7.556  1.00  9.62           C  
ATOM      4  O   MET A   1      51.414 -89.033   6.462  1.00  9.62           O  
ATOM      5  CB  MET A   1      51.976 -87.958   9.485  1.00 13.77           C  
ATOM      6  CG  MET A   1      52.864 -87.131   8.557  1.00 16.29           C  


*/



CREATE TABLE phi_psi(
_id integer primary key NOT NULL auto_increment,
protein varchar(4),  /*  the protein */
resName varchar(3), /*  residue name */
phi decimal(4,1), /*  phi value */
psi decimal(4,1), /*  psi value */
alpha decimal(4,1), /*  alpha value */
kappa decimal(4,1), /*  kappa value */
);
