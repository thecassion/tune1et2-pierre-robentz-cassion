/*
	LIRE ATTENTIVEMENT LE CHAPITRE 2 DU COURS TUNE 2 CONCERNANT PERFSTAT:
	 

	Ce script réalise les activités suivantes :
		- 1. Déinstallation de STATSPACK si ce repository est déjà créé
		- 2. Installation du repository de STATSPACK
		- 3. Création d'un premier cliché STATSPACK et en parallèle un ^premier cliché AWR
		- 4. Provoquer l'activité sur la base de données
		- 5. Création d'un dexième cliché STATSPACK et en parallèle un deuxmième cliché AWR
		- 6. Génération du rapport STATSPACK. Le rapport AWR sera généré dans l'exercice ex31_Tune2_AWR.sql


Attention :
	- Si des actions sont précédés du commentaire --
	- Ne pas les exécuter

		
*/


-- Afin d'exécuter ce script vous devez commencer 
-- par exécuter le contenu du scrpt Ex21_Tune2_STATSPACK_Start

-- 3. Création d'un premier cliché STATSPACK et en parallèle un cliché AWR

-- Capture des statistiques pour STATSPACK : 1er cliché
EXECUTE statspack.snap(6);

-- Capture en parralèle des statistiques pour AWR : 1er cliché

set serveroutput on
declare
snapid number;
begin
snapid:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid 1='|| snapid);
end;
/
-- Snapid 1=3 Snapid 1=28 12/12/11 Snapid 1=84


-- 4. Provoquer l'activité sur la base de données

-- Nous allons volontairement provoquer de l'activité dans la base.
-- Cela permettra de capturer des clichés de statistiques significatifs 
-- Une première activité va consister à créer un utilisateur appelé TESTBIG
-- Des données seront créées  dans son schéma et des requêtes lancées sur
-- ces données.
-- Cinq applications qui font la même chose seront installées :
	-- la 1ère écrite en objet relationnel (table objet: BIGOEMP, BIGODEPT)
	-- La 2ème écrite en relationnel (table relationnelles: R_EMPLOYE, R_DEPT)
	-- La 3ème écrite en relationnelle (EMP4, DEPT4)
	-- La 4ème écrite en relationnelle mais les tables sont organisées dans un cluster indexé (IEMP4, IDEPT4)
	-- La 5ème écrite en relationnelle mais les tables sont organisées dans un cluster haché (HEMP4, HDEPT4)

-- On pourra ainsi profiter pour comparer les performances des différentes approches.

-- suppression de l'utilisateur TESTBIG S'IL EXISTE DEJA
DROP USER testbig cascade;

-- Création de l'utilisateur testbig
create user testbig identified by testbig
default tablespace users
temporary tablespace temp
quota unlimited on users;
grant dba to testbig;
revoke unlimited tablespace from testbig;

alter user testbig quota unlimited on users;

-- Fixer le format de date et langue
alter session set nls_date_format='DD-MON-YYYY';
alter session set nls_language=american;

-- Suppression des tables et des types objets s'ils existent déjà
DROP TABLE TESTBIG.BIGOEMP CASCADE CONSTRAINT;
/
DROP TABLE TESTBIG.BIGODEPT CASCADE CONSTRAINT;
/

DROP TYPE TESTBIG.EMPLOYE_T FORCE
/

DROP TYPE TESTBIG.DEPT_T FORCE
/

DROP TYPE TESTBIG.tabPrenoms_t force
/

drop TYPE TESTBIG.listEmployes_t force 
/

-- Création des types objets
CREATE OR REPLACE TYPE TESTBIG.EMPLOYE_T 
/

CREATE OR REPLACE TYPE TESTBIG.tabPrenoms_t AS VARRAY(4) OF varchar2(20)
/

create or replace type TESTBIG.listEmployes_t as table of ref TESTBIG.EMPLOYE_T
/

CREATE OR REPLACE TYPE TESTBIG.DEPT_T AS OBJECT(		
DEPTNO		number,
DNAME		varchar2(30),
LOC		varchar2(30),
listEmployes	listEmployes_t,
static function getDept (deptno IN number) return TESTBIG.DEPT_T,
MAP MEMBER FUNCTION compDept return VARCHAR2,
MEMBER PROCEDURE addLinkListeEmployes(RefEmp1 IN REF TESTBIG.EMPLOYE_T),
MEMBER PROCEDURE deleteLinkListeEmployes (RefEmp1 IN REF TESTBIG.EMPLOYE_T),
MEMBER PROCEDURE updateLinkListeEmployes (RefEmp1 IN REF TESTBIG.EMPLOYE_T,
RefEmp2 REF TESTBIG.EMPLOYE_T),
PRAGMA RESTRICT_REFERENCES (getDept, WNDS),
PRAGMA RESTRICT_REFERENCES (compDept, WNDS)
)
/

CREATE OR REPLACE TYPE TESTBIG.EMPLOYE_T AS OBJECT(	
EMPNO		NUMBER,	
ENAME		varchar2(15), 
PRENOMS		tabPrenoms_t,		
JOB		Varchar2(20),	
SAL		number(7,2),		
CV		CLOB,		
DATE_NAISS	date,		
DATE_EMB	date,
refDept		REF TESTBIG.DEPT_T,
ORDER MEMBER FUNCTION compEmp(emp IN TESTBIG.EMPLOYE_T)
return NUMBER,
PRAGMA RESTRICT_REFERENCES (compEmp, WNDS)	
)
/	

create or replace type TESTBIG.setEmployes_t as table of TESTBIG.EMPLOYE_T
/

ALTER TYPE TESTBIG.DEPT_T
ADD
Static function getInfoEmp(deptno IN number)
 return setEmployes_t CASCADE
/

-- création des tables objets
CREATE TABLE TESTBIG.BIGODEPT of TESTBIG.DEPT_T(
	constraint pk_dept_deptno primary key(deptno) 
	USING INDEX TABLESPACE users,
	constraint chk_dept_dname check(dname in 
	('Recherche','RH', 'Marketing','Ventes', 'Finance')),
	constraint chk_dept_deptno check(deptno between 1000 and 9999),
	constraint nl_dept_name dname not null,
	constraint nl_dept_loc loc not null
)
TABLESPACE users
NESTED TABLE listEmployes STORE AS storeListEmployes 
/
 
CREATE TABLE TESTBIG.BIGOEMP of TESTBIG.EMPLOYE_T(
	constraint pk_employe_empno primary key(empno) 
	USING INDEX TABLESPACE users,
	constraint chk_employe_ename check (ename =upper(ename)),
	constraint chk_employe_job check 
		(job IN ('Ingenieur','Secrétaire', 'Directeur', 'PDG', 'Planton')),
	constraint chk_employe_sal check (sal between 1500 AND 15000),
	constraint chk_employe_date_e_date_n check (date_emb>date_naiss),
	constraint nl_employe_ename ename not null,
	constraint nl_employe_job job not null,
	constraint nl_employe_sal sal not null,
	constraint nl_employe_date_naiss date_naiss not null,
	constraint nl_employe_date_emb date_emb not null
)
TABLESPACE users
LOB (CV) STORE AS (TABLESPACE users pctversion 30)
/

-- Création d'indexes

CREATE UNIQUE INDEX TESTBIG.IDX_DEPT_DNAME ON TESTBIG.BIGODEPT(dname)
TABLESPACE users
/

CREATE INDEX TESTBIG.idx_storeListEmps_nested_id ON TESTBIG.storeListEmployes(nested_table_id)
TABLESPACE users
/


ALTER TABLE TESTBIG.storeListEmployes
	ADD (SCOPE FOR (column_value) IS TESTBIG.BIGOEMP);

ALTER TABLE TESTBIG.BIGOEMP
	ADD (SCOPE FOR (refDept) IS TESTBIG.BIGODEPT);

CREATE INDEX TESTBIG.IDX_EMPLOYE_REFDEPT ON TESTBIG.BIGOEMP(refdept)
TABLESPACE users
/




-- Suppression puis création d'une séquence
drop sequence TESTBIG.seq_empno;
create sequence TESTBIG.seq_empno start with 12;





-- Insertion massive de lignes dans la table des employés
declare
	refDept1 ref TESTBIG.DEPT_T;
	refDept2 ref TESTBIG.DEPT_T;
	refDept3 ref TESTBIG.DEPT_T;
	refDept4 ref TESTBIG.DEPT_T;
	i number(8):=0;

begin
	-- Création des départements
	insert into TESTBIG.BIGODEPT d 
	values(1000, 'Recherche', 'rabat',testbig.listEmployes_t() ) 
	returning ref(d) into refDept1;


 	insert into TESTBIG.BIGODEPT d 
	values(1001,'Marketing', 'Casa',testbig.listEmployes_t() ) 
	returning ref(d) into refDept2;

	insert into TESTBIG.BIGODEPT d 
	values(1002,'RH', 'Casa',testbig.listEmployes_t() ) 
	returning ref(d) into refDept3;


	insert into TESTBIG.BIGODEPT d 
	values(1003,'Ventes', 'Casa',testbig.listEmployes_t() ) 
	returning ref(d) into refDept4;

	-- Création des employés
	insert into TESTBIG.BIGOEMP e 
	values(1, 'MILOUD', testbig.tabPrenoms_t('Mohamed'),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into TESTBIG.BIGOEMP e 
	values(2, 'BOUMLID', testbig.tabPrenoms_t('Foudelle'),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into TESTBIG.BIGOEMP e 
	values(3, 'MILOU', testbig.tabPrenoms_t('Tintin'),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into TESTBIG.BIGOEMP e 
	values(4, 'FOUDIL', testbig.tabPrenoms_t('Foudelle'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into TESTBIG.BIGOEMP e 
	values(5, 'FOUDELLE', testbig.tabPrenoms_t('Amina', 'traoré'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into TESTBIG.BIGOEMP e 
	values(6, 'ERZULIE', testbig.tabPrenoms_t('Maria'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into TESTBIG.BIGOEMP e 
	values(7, 'IBOLELE', testbig.tabPrenoms_t('La Terre'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into TESTBIG.BIGOEMP e 
	values(8, 'JACQUOUD', testbig.tabPrenoms_t('Le croquant'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into TESTBIG.BIGOEMP e 
	values(9, 'MARX', testbig.tabPrenoms_t('Karl'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into TESTBIG.BIGOEMP e 
	values(10, 'RACKHAM', testbig.tabPrenoms_t('Le rouge'),'Secrétaire', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;

	loop

	-- Création des employés
	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'MILOUD', testbig.tabPrenoms_t('Mohamed'||i),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'BOUMLID', testbig.tabPrenoms_t('Foudelle'||i),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'MILOU', testbig.tabPrenoms_t('Tintin'||i),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'FOUDIL', testbig.tabPrenoms_t('Foudelle'||i),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'FOUDELLE', testbig.tabPrenoms_t('Amina'||i, 'traoré'),'Planton', 
	13600, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'ERZULIE', testbig.tabPrenoms_t('Maria'||i),'Ingenieur', 
	13500, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'IBOLELE', testbig.tabPrenoms_t('La Terre'||i),'Ingenieur', 
	13800, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'JACQUOUD', testbig.tabPrenoms_t('Le croquant'||i),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'MARX', testbig.tabPrenoms_t('Karl'||i),'Ingenieur', 
	13100, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into TESTBIG.BIGOEMP e 
	values(testbig.seq_empno.nextval, 'RACKHAM', testbig.tabPrenoms_t('Le rouge'||i),'Secrétaire', 
	13400, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;




	-- mise à jour de la liste des références vers les employes
	commit;
	i:=i+1;
	EXIT WHEN i>30000;
	end loop;

end;
/




-- Mise à jour de la liste des références vers les employés
Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT d
where d.deptno=1000
)lemp
select ref(e) from TESTBIG.BIGOEMP e
where e.refdept.deptno=1000;


Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT d
where d.deptno=1001
)lemp
select ref(e) from TESTBIG.BIGOEMP e
where e.refdept.deptno=1001;


Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT d
where d.deptno=1002
)lemp
select ref(e) from TESTBIG.BIGOEMP e
where  e.refdept.deptno=1002;


Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT d
where d.deptno=1003
)lemp
select ref(e) from TESTBIG.BIGOEMP e
where  e.refdept.deptno=1003;

commit;






-------------------------------------------------------------
-------------------------------------------------------------
-- Suppression des tables et des types objets s'ils existent déjà
DROP TABLE TESTBIG.BIGOEMP2 CASCADE CONSTRAINT;
/
DROP TABLE TESTBIG.BIGODEPT2 CASCADE CONSTRAINT;
/
-- création des tables objets
CREATE TABLE TESTBIG.BIGODEPT2 of TESTBIG.DEPT_T(
	constraint pk_BIGODEPT2_deptno primary key(deptno) 
	USING INDEX TABLESPACE users,
	constraint chk_BIGODEPT2_dname check(dname in 
	('Recherche','RH', 'Marketing','Ventes', 'Finance')),
	constraint chk_BIGODEPT2_deptno check(deptno between 1000 and 9999),
	constraint nl_BIGODEPT2_name dname not null,
	constraint nl_BIGODEPT2_loc loc not null
)
TABLESPACE users
NESTED TABLE listEmployes STORE AS storeListEmployes2 
/
 
CREATE TABLE TESTBIG.BIGOEMP2 of TESTBIG.EMPLOYE_T(
	constraint pk_BIGOEMP2_empno primary key(empno) 
	USING INDEX TABLESPACE users,
	constraint chk_BIGOEMP2_ename check (ename =upper(ename)),
	constraint chk_BIGOEMP2_job check 
		(job IN ('Ingenieur','Secrétaire', 'Directeur', 'PDG', 'Planton')),
	constraint chk_BIGOEMP2_sal check (sal between 1500 AND 15000),
	constraint chk_BIGOEMP2_date_e_date_n check (date_emb>date_naiss),
	constraint nl_BIGOEMP2_ename ename not null,
	constraint nl_BIGOEMP2_job job not null,
	constraint nl_BIGOEMP2_sal sal not null,
	constraint nl_BIGOEMP2_date_naiss date_naiss not null,
	constraint nl_BIGOEMP2_date_emb date_emb not null
)
TABLESPACE users
LOB (CV) STORE AS (TABLESPACE users pctversion 30)
/

-- Création d'indexes
drop index TESTBIG.IDX_BIGDEPT2_DNAME;
drop INDEX TESTBIG.idx_storeListEmps2_nested_id;

CREATE UNIQUE INDEX TESTBIG.IDX_BIGDEPT2_DNAME ON TESTBIG.BIGODEPT2(dname)
TABLESPACE users
/

CREATE INDEX TESTBIG.idx_storeListEmps2_nested_id ON TESTBIG.storeListEmployes2(nested_table_id)
TABLESPACE users
/

-- ne pas exécuter les lignes en commentaires (lignes précédées de --)
--ALTER TABLE TESTBIG.storeListEmployes
--	ADD (SCOPE FOR (column_value) IS TESTBIG.BIGOEMP);

--ALTER TABLE TESTBIG.BIGOEMP
--	ADD (SCOPE FOR (refDept) IS TESTBIG.BIGODEPT);

--CREATE INDEX TESTBIG.IDX_EMPLOYE_REFDEPT ON TESTBIG.BIGOEMP(refdept)
--TABLESPACE users
--/


-- Afin d'accéler le déréférencement implicite ou explicite.
ALTER TABLE TESTBIG.storeListEmployes2
	ADD (REF (column_value) WITH ROWID);

ALTER TABLE TESTBIG.BIGOEMP2
ADD (REF (refDept) WITH ROWID);



-- Suppression puis création d'une séquence
drop sequence TESTBIG.seq_empno2;
create sequence TESTBIG.seq_empno2 start with 12;





-- Insertion massive de lignes dans la table des employés
declare
	refDept1 ref TESTBIG.DEPT_T;
	refDept2 ref TESTBIG.DEPT_T;
	refDept3 ref TESTBIG.DEPT_T;
	refDept4 ref TESTBIG.DEPT_T;
	i number(8):=0;

begin
	-- Création des départements
	insert into TESTBIG.BIGODEPT2 d 
	values(1000, 'Recherche', 'rabat',testbig.listEmployes_t() ) 
	returning ref(d) into refDept1;


 	insert into TESTBIG.BIGODEPT2 d 
	values(1001,'Marketing', 'Casa',testbig.listEmployes_t() ) 
	returning ref(d) into refDept2;

	insert into TESTBIG.BIGODEPT2 d 
	values(1002,'RH', 'Casa',testbig.listEmployes_t() ) 
	returning ref(d) into refDept3;


	insert into TESTBIG.BIGODEPT2 d 
	values(1003,'Ventes', 'Casa',testbig.listEmployes_t() ) 
	returning ref(d) into refDept4;

	-- Création des employés
	insert into TESTBIG.BIGOEMP2 e 
	values(1, 'MILOUD', testbig.tabPrenoms_t('Mohamed'),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(2, 'BOUMLID', testbig.tabPrenoms_t('Foudelle'),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into TESTBIG.BIGOEMP2 e 
	values(3, 'MILOU', testbig.tabPrenoms_t('Tintin'),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(4, 'FOUDIL', testbig.tabPrenoms_t('Foudelle'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into TESTBIG.BIGOEMP2 e 
	values(5, 'FOUDELLE', testbig.tabPrenoms_t('Amina', 'traoré'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(6, 'ERZULIE', testbig.tabPrenoms_t('Maria'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(7, 'IBOLELE', testbig.tabPrenoms_t('La Terre'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(8, 'JACQUOUD', testbig.tabPrenoms_t('Le croquant'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into TESTBIG.BIGOEMP2 e 
	values(9, 'MARX', testbig.tabPrenoms_t('Karl'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into TESTBIG.BIGOEMP2 e 
	values(10, 'RACKHAM', testbig.tabPrenoms_t('Le rouge'),'Secrétaire', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;

	loop

	-- Création des employés
	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'MILOUD', testbig.tabPrenoms_t('Mohamed'||i),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'BOUMLID', testbig.tabPrenoms_t('Foudelle'||i),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'MILOU', testbig.tabPrenoms_t('Tintin'||i),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'FOUDIL', testbig.tabPrenoms_t('Foudelle'||i),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'FOUDELLE', testbig.tabPrenoms_t('Amina'||i, 'traoré'),'Planton', 
	13600, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'ERZULIE', testbig.tabPrenoms_t('Maria'||i),'Ingenieur', 
	13500, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'IBOLELE', testbig.tabPrenoms_t('La Terre'||i),'Ingenieur', 
	13800, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'JACQUOUD', testbig.tabPrenoms_t('Le croquant'||i),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'MARX', testbig.tabPrenoms_t('Karl'||i),'Ingenieur', 
	13100, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into TESTBIG.BIGOEMP2 e 
	values(testbig.seq_empno2.nextval, 'RACKHAM', testbig.tabPrenoms_t('Le rouge'||i),'Secrétaire', 
	13400, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;




	-- mise à jour de la liste des références vers les employes
	commit;
	i:=i+1;
	EXIT WHEN i>30000;
	end loop;

end;
/




-- Mise à jour de la liste des références vers les employés
Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT2 d
where d.deptno=1000
)lemp
select ref(e) from TESTBIG.BIGOEMP2 e
where e.refdept.deptno=1000;


Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT2 d
where d.deptno=1001
)lemp
select ref(e) from TESTBIG.BIGOEMP2 e
where e.refdept.deptno=1001;


Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT2 d
where d.deptno=1002
)lemp
select ref(e) from TESTBIG.BIGOEMP2 e
where  e.refdept.deptno=1002;


Insert into
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT2 d
where d.deptno=1003
)lemp
select ref(e) from TESTBIG.BIGOEMP2 e
where  e.refdept.deptno=1003;

commit;



--------------------------------------------------------------
--------------------------------------------------------------


-- Création des tables relationnelles
drop table TESTBIG.r_dept cascade constraints
/
drop table TESTBIG.r_employe
/

CREATE TABLE TESTBIG.R_DEPT(		
DEPTNO	number constraint pk_r_dept_deptno primary key,
DNAME	varchar2(30)constraint chk_r_dept_dname check(dname in 
		('Recherche','RH', 'Marketing','Ventes', 'Finance')),
LOC	varchar2(30),
constraint chk_r_dept_deptno check(deptno between 1000 and 9999)
)
/

CREATE TABLE TESTBIG.R_EMPLOYE(	
EMPNO		NUMBER constraint pk_r_employe_empno primary key,	
ENAME		varchar2(15)constraint chk_r_employe_ename check (ename =upper(ename)), 
JOB		Varchar2(20) constraint chk_r_employe_job check 
		(job IN ('Ingenieur','Secrétaire', 'Directeur', 'PDG', 'Planton')),	
SAL		number(7,2),		
CV		CLOB,		
DATE_NAISS	date,		
DATE_EMB	date,
deptno		number constraint fk_r_emp_r_dept references testbig.r_dept(deptno),
constraint chk_r_emp_date_e_date_n check (date_emb>date_naiss)
)
/

-- création d'indexes	
create index TESTBIG.idx_r_employe_deptno on TESTBIG.r_employe(deptno)
tablespace users
/

create unique index TESTBIG.idx_r_dept_dname on TESTBIG.r_dept(dname)
tablespace users
/

create  index TESTBIG.idx_r_employe_ename on TESTBIG.r_employe(ename)
tablespace users
/
-- insertion des lignes dans les tables relationnelles à partir des tables objets
INSERT INTO TESTBIG.r_dept
select deptno, dname, loc  from TESTBIG.BIGODEPT;

INSERT INTO TESTBIG.r_EMPLOYE
SELECT EMPNO, ENAME, JOB,SAL, CV,  DATE_NAISS, DATE_EMB, e.refdept.deptno
from TESTBIG.BIGOEMP e;

commit;

-- Installation des tables EMP4 et DEPT4 à partir du script
-- @chemin\DEPT4EMP4.SQL
-- Ce script se trouve dans le répertoire script2 du tp TUNE 2.
-- C:\gm05092005\Cours\ORS\2011_2012\TP_TUNE2_MBDS_MODELE_2012\ScriptsTune2
@@DEPT4EMP4_TESTBIG.sql


-- Création des table testbig.IEMP4 et testbig.IDEPT4 dans  un cluster indexé
DROP TABLE testbig.IEMP4 CASCADE CONSTRAINTS ;
DROP TABLE testbig.IDEPT4 CASCADE CONSTRAINTS ;
DROP CLUSTER testbig.CLU_IEMP4_IDEPT4;

CREATE CLUSTER testbig.CLU_IEMP4_IDEPT4 (
DEPTNO NUMBER(2)
);

-- Création de l'index sur la clé de cluster
DROP INDEX testbig.IDX_CLU_IEMP4_IDEPT4 ;
CREATE INDEX  testbig.IDX_CLU_IEMP4_IDEPT4 
ON CLUSTER testbig.CLU_IEMP4_IDEPT4;

-- Création de la table DEPT4 dans le cluster
CREATE TABLE testbig.IDEPT4(
DEPTNO NUMBER(2) CONSTRAINT  pk_IDEPT4  PRIMARY KEY,
DNAME VARCHAR2(14),
LOC VARCHAR2(13)
 ) CLUSTER testbig.CLU_IEMP4_IDEPT4 (DEPTNO);

-- Création de la table testbig.IEMP4 dans le cluster
CREATE TABLE testbig.IEMP4(
EMPNO NUMBER(8) constraint pk_IEMP4 primary key,
ENAME VARCHAR2(50),
JOB VARCHAR2(9),
MGR NUMBER(4),
HIREDATE DATE,
SAL NUMBER(7,2),
COMM NUMBER(7,2),
DEPTNO NUMBER(2) CONSTRAINT fk_IEMP4_deptno REFERENCES testbig.IDEPT4 (DEPTNO)
)CLUSTER testbig.CLU_IEMP4_IDEPT4 (DEPTNO) ;

-- création d'un index sur la clé étrangère
Create index idx_IEMP4_deptno on testbig.IEMP4(deptno);


-- Insertion de lignes à partir de la table DEPT4
INSERT INTO testbig.IDEPT4 SELECT * FROM testbig.DEPT4;

-- Insertion de lignes à partir de la table EMP4
INSERT INTO testbig.IEMP4 SELECT * FROM testbig.EMP4;

COMMIT;


-- Création des table testbig.HEMP4 et testbig.HDEPT4 dans  un cluster haché

-- Création du cluster
DROP TABLE testbig.HEMP4 CASCADE CONSTRAINTS ;
DROP TABLE testbig.HDEPT4 CASCADE CONSTRAINTS ;
DROP CLUSTER testbig.HCLU_EMP4_DEPT4;

CREATE CLUSTER testbig.HCLU_EMP4_DEPT4 (
DEPTNO NUMBER(2)
) SIZE 2K HASH IS DEPTNO HASHKEYS 100;

-- Création de la table testbig.HDEPT4 dans le cluster
CREATE TABLE testbig.HDEPT4(
DEPTNO NUMBER(2) CONSTRAINT  pk_hdept4  PRIMARY KEY,
DNAME VARCHAR2(14),
LOC VARCHAR2(13) ) 
CLUSTER testbig.HCLU_EMP4_DEPT4 (DEPTNO);

-- Création de la table testbig.HEMP4 dans le cluster
CREATE TABLE testbig.HEMP4(
EMPNO NUMBER(8) constraint pk_hemp4 primary key,
ENAME VARCHAR2(50),
JOB VARCHAR2(9),
MGR NUMBER(4),
HIREDATE DATE,
SAL NUMBER(7,2),
COMM NUMBER(7,2),
DEPTNO NUMBER(2) CONSTRAINT fk_hemp4_deptno REFERENCES testbig.HDEPT4 (DEPTNO)
)CLUSTER testbig.HCLU_EMP4_DEPT4 (DEPTNO) ;

-- pas nécessaire de créer cet index.
-- Create index idx_hemp4_deptno on testbig.HEMP4(deptno);

-- Insertion de lignes à partir de la table DEPT4
INSERT INTO testbig.HDEPT4 SELECT * FROM testbig.DEPT4;

-- Insertion de lignes à partir de la table EMP4
INSERT INTO testbig.HEMP4 SELECT * FROM testbig.EMP4;

COMMIT;

alter system checkpoint;

-- Calcul des statitisques sur les objets de TESTBIG
Execute Dbms_stats.gather_schema_stats('TESTBIG');

-- Prise d'un 2ème cliché STATSPACK
EXECUTE statspack.snap(6);

-- prise en parallèle d'un 2ème cliché AWR
set serveroutput on
declare
snapid number;
begin
snapid:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid_2='|| snapid);
end;
/
-- Snapid_2=85


-- L'activation de la trace en traceonly évite l'affiche du 
-- résultat des réquêtes à l'écran.
Set autotrace traceonly
set linesize 200
-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Jointure avec des tables non clustérisées (CBO)
SELECT dname, loc, ename, job, hiredate
FROM testbig.EMP4 e, testbig.DEPT4 d
WHERE e.deptno=d.deptno;

-- Jointure avec tables relationnelles en cluster indexé (CBO)
SELECT dname, loc, ename, job, hiredate
FROM testbig.IEMP4 e, testbig.IDEPT4 d
WHERE e.deptno=d.deptno;

-- Jointure avec tables en cluster haché (CBO)
SELECT /*+USE_HASH(e d) */dname, loc, ename, job, hiredate
FROM testbig.HEMP4 e, testbig.HDEPT4 d
WHERE e.deptno=d.deptno;

--SELECT dname, loc, ename, job, hiredate
--FROM testbig.HEMP4 e, testbig.HDEPT4 d
--WHERE e.deptno=d.deptno;



-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Jointure avec des tables non clustérisées (CBO)
SELECT dname, loc, ename, job, hiredate
FROM testbig.EMP4 e, testbig.DEPT4 d
WHERE e.deptno=d.deptno;



-- Jointure avec tables en cluster indexé (CBO)
SELECT dname, loc, ename, job, hiredate
FROM testbig.IEMP4 e, testbig.IDEPT4 d
WHERE e.deptno=d.deptno;



-- Jointure avec tables en cluster haché (CBO)
SELECT /*+USE_HASH(e d) */ dname, loc, ename, job, hiredate
FROM testbig.HEMP4 e, testbig.HDEPT4 d
WHERE e.deptno=d.deptno;


-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Comptage de lignes dans les tables testbig.testbig.EMP4, testbig.Itestbig.testbig.EMP4 et HEMP4
select count(*) from testbig.emp4;



select count(*) from testbig.IEMP4;



select count(*) from testbig.HEMP4;



-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Comptage de lignes dans les tables EMP4, testbig.IEMP4 et HEMP4
select count(*) from testbig.emp4;



select count(*) from testbig.IEMP4;



select count(*) from testbig.HEMP4;



-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Jointures connaissant un département donné.
set autotrace traceonly
SELECT dname, loc, ename, job, hiredate
FROM testbig.EMP4 e, testbig.DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM testbig.IEMP4 e, testbig.IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM testbig.HEMP4 e, testbig.HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;


-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Jointures connaissant un département donné.
SELECT dname, loc, ename, job, hiredate
FROM testbig.EMP4 e, testbig.DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM testbig.IEMP4 e, testbig.IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM testbig.HEMP4 e, testbig.HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Recherche des employés d'un département connu.
SELECT  ename, job, hiredate
FROM testbig.EMP4 e
WHERE e.deptno=10;



SELECT  ename, job, hiredate
FROM testbig.IEMP4 e
WHERE e.deptno=10;



SELECT  ename, job, hiredate
FROM testbig.HEMP4 e
WHERE e.deptno=10;


-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Recherche des employés d'un département connu.
SELECT  ename, job, hiredate
FROM testbig.EMP4 e
WHERE e.deptno=10;

SELECT  ename, job, hiredate
FROM testbig.IEMP4 e
WHERE e.deptno=10;



SELECT  ename, job, hiredate
FROM testbig.HEMP4 e
WHERE e.deptno=10;


-- Consultations comparées sur les tables objets et les tables relationnelles

set autotrace traceonly
set linesize 300
-- Consultation en mode FIRST_ROWS_1
alter session set optimizer_mode=FIRST_ROWS_1;

-- Recherche des informations sur les employés (+info dept) d'un département connaissant son numéro
-- Via la table des employés. Tables objets
select  e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP e
where e.refdept.deptno=1000;

-- en forçant l'usage de l'index sur REFDEPT
select /*+INDEX (e IDX_EMPLOYE_REFDEPT)*/ e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP e
where e.refdept.deptno=1000;

-- Recherche des informations sur les employés d'un département connaissant son numéro
-- Via la table des employés. Tables objets
select  e.ename, e.job, e.sal
from TESTBIG.BIGOEMP2 e
where e.refdept.deptno=1000;



-- Recherche des informations sur les employés d'un département connaissant son numéro
-- Via la liste des références vers les employés dudit département: tables objets
select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT d
where d.deptno=1000
)lemp;

select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT2 d
where d.deptno=1000
)lemp;

select e.ename, e.sal, d.dname,  d.loc 
from TESTBIG.r_employe e, TESTBIG.r_dept d
where e.deptno=d.deptno and d.deptno=1000;


-- Recherche des informations sur un département connaissant un employé de ce
-- Via la liste des références vers les employés dudit département: tables objets

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP e
where e.empno=1;

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP2 e
where e.empno=1;

select e.ename, e.sal, d.dname,  d.loc 
from TESTBIG.r_employe e, TESTBIG.r_dept d
where e.deptno=d.deptno and e.empno=1;



-- Consultation en mode all_rows
alter session set optimizer_mode=all_rows;

-- Recherche des informations sur les employés d'un département connaissant son numéro
-- Via la table des employés. Tables objets
select  e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP e
where e.refdept.deptno=1000;

-- en forçant l'usage de l'index sur REFDEPT
select /*+INDEX (e IDX_EMPLOYE_REFDEPT)*/ e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP e
where e.refdept.deptno=1000;

-- Recherche des informations sur les employés d'un département connaissant son numéro
-- Via la table des employés. Tables objets
select  e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP2 e
where e.refdept.deptno=1000;


-- Recherche des informations sur les employés d'un département connaissant son numéro
-- Via la liste des références vers les employés dudit département: tables objets
select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT d
where d.deptno=1000
)lemp;

select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from TESTBIG.BIGODEPT2 d
where d.deptno=1000
)lemp;

select e.ename, e.sal, d.dname,  d.loc 
from TESTBIG.r_employe e, TESTBIG.r_dept d
where e.deptno=d.deptno and d.deptno=1000;


-- Recherche des informations sur un département connaissant un employé de ce
-- Via la liste des références vers les employés dudit département: tables objets

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP e
where e.empno=1;

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from TESTBIG.BIGOEMP2 e
where e.empno=1;


select e.ename, e.sal, d.dname,  d.loc 
from TESTBIG.r_employe e, TESTBIG.r_dept d
where e.deptno=d.deptno and e.empno=1;

set autotrace off;


-- 5. Créer un deuxième cliché STATSPACK et en parallèle un deuxmième cliché AWR

-- Prise d'un 3ème cliché STATSPACK
EXECUTE statspack.snap(6);

-- prise en parallèle d'un 3ème cliché AWR
set serveroutput on
declare
snapid number;
begin
snapid:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid_3='|| snapid);
end;
/
-- Snapid_3=12   Snapid_3=10 Snapid 3=19 Snapid_3=29 Snapid_3=86
-- désactivation du spool
