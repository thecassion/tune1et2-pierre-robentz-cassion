
-- chargement des clients avec sqlldr
create table CLIENTS (
ClIENTID 	number(8) constraoprimary key, 
NOM 		varchar2(50), 
PRENOM 		varchar2(50), 
CODEPOSTAL 	varchar2(7),
VILLE 		varchar2(100), 
ADRESSE  	varchar2(100), 
TELEPHONE 	varchar2(12), 
ANNEENAISS 	varchar2(6)
);

-- fichier de controle client.ctl
LOAD DATA
INFILE 'clientData_txt.txt'
INTO TABLE CLIENTS
FIELDS TERMINATED BY ';'
(ClIENTID, NOM, PRENOM, CODEPOSTAL, VILLE, ADRESSE, TELEPHONE, ANNEENAISS)


-- la commande
sqlldr xxx2b20/pass CONTROL=client.ctl LOG=client.log BAD=client.bad 


-- chargement des appréacitions avec sqlldr
CREATE TABLE APPRECIATIONS(
VOLID number(8), 
CRITEREID number(8), 
CLIENTID number(8),  
DATEVOL  varchar2(12), 
NOTE varchar2(12),
constraint pk_APPRECIATIONS primary key (VOLID, CRITEREID, CLIENTID, DATEVOL)
);


-- fichier de controle appreciation.ctl
LOAD DATA
INFILE 'appreciationData_txt.txt'
INTO TABLE APPRECIATIONS
FIELDS TERMINATED BY ';'
(VOLID, CRITEREID, CLIENTID, DATEVOL, NOTE)


-- la commande
sqlldr xxx2b20/pass CONTROL=appreciation.ctl LOG=appreciation.log BAD=appreciation.bad 


-- chargement des recommandations avec sqlldr
CREATE TABLE  recommandations(
VOLID number(8), 
CLIENTID number(8),  
DATEVOL varchar2(12), 
Recommand  varchar2(3),
constraint pk_recommandations primary key (VOLID, CLIENTID, DATEVOL)
);

alter table recommandations
modify (Recommand varchar2(4));

-- fichier de controle recommandation.ctl
LOAD DATA
INFILE 'recommandationData_txt.txt'
INTO TABLE recommandations
FIELDS TERMINATED BY ';'
(VOLID, CLIENTID, DATEVOL, Recommand)



-- la commande
sqlldr xxx2b20/pass CONTROL=recommandation.ctl LOG=recommandation.log BAD=recommandation.bad 

select ''''||recommand||'''' from recommandations;
-- chargement ou recopie des critères

-- solution 1
CREATE TABLE  CRITERES(
CRITEREID number(8) constraint pk_criteres_critereid primary key, 
TITRE varchar2(50),
DESCRIPTION varchar2(100)
);

insert into CRITERES select * from CRITERES_MIAGE_votreLogin_H_O_EXT;

-- solution 2

CREATE TABLE  CRITERES as select * from CRITERES_MIAGE_votreLogin_H_O_EXT;
alter table CRITERES
add (constraints pk_criteres_critereid primary key (CRITEREID));

-- chargement des pilotes, avions et vols

sql> @$MYTPHOME/tpnosql/airbase/airbase.sql




-- requetes

-- requête 1 : appreciations faites par les clients Martin et Bernard

select nom, critereid, dateVol, note 
from client c, appreciations a
where c.clientid=a.clientid and c.nom in ('Martin', 'Bernard');

-- voir un plan d'exécution
set autotrace on
set linesize 200
select nom, critereid, dateVol, note 
from client c, appreciations a
where c.clientid=a.clientid and c.nom in ('Martin', 'Bernard');
