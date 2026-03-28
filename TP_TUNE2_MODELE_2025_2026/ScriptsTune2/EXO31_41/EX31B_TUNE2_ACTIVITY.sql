/*
	LIRE ATTENTIVEMENT LE CHAPITRE 2 DU COURS TUNE 2 CONCERNANT PERFSTAT:
	 

	Ce script r�alise les activit�s suivantes :
		- 1. Cr�ation d'un clich�  AWR
		- 2. Provoquer l'activit� sur la base de donn�es
		- 3. R�cup�ration du SPID afin de pouvoir identifier le fichier de 
		- trace TKPROF
		- 4. Cr�ation d'un deuxmi�me clich� AWR

Attention :
	- Si des actions sont pr�c�d�s du commentaire --
	- Ne pas les ex�cuter

		
*/
-- Activation du spool
spool &SCRIPTPATH/LOG/EX31E_TUNE2_SPOOL_LOG.LOG

set autotrace off
set termout on
set echo on
set serveroutput on

set timing on


-- set arraysize 5000



-- 1. Capture en parral�le des statistiques pour AWR : 1er clich�

-- Connexion au niveau CDB pour prendre un clich� AWR
connect &MYCDBUSER@&DBALIASCDB/&MYCDBUSERPASS
-- set arraysize 5000
set serveroutput on
declare
snapid1 number;
begin
snapid1:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid1='|| snapid1);
end;
/

-- ReConnexion au niveau PDB. 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS
-- set arraysize 5000
-- activation de la trace afin de pouvoir par la suite utiliser TKPROF
-- Voir les indications � la fin de ce fichier.
execute dbms_session.set_sql_trace(true);


-- 2. Provoquer l'activit� sur la base de donn�es

-- Nous allons volontairement provoquer de l'activit� dans la base.
-- Cela permettra de capturer des clich�s de statistiques significatifs 
-- Une premi�re activit� va consister � cr�er un utilisateur appel� &MYPDBUSER
-- Des donn�es seront cr��es  dans son sch�ma et des requ�tes lanc�es sur
-- ces donn�es.
-- Cinq applications qui font la m�me chose seront install�es :
	-- la 1�re �crite en objet relationnel (table objet: BIGOEMP, BIGODEPT)
	-- La 2�me �crite en relationnel (table relationnelles: R_EMPLOYE, R_DEPT)
	-- La 3�me �crite en relationnel (EMP4, DEPT4) les tables sont organisees dans des segments s�par�s
	-- La 4�me �crite en relationnel mais les tables sont organis�es dans un cluster index� (IEMP4, IDEPT4)
	-- La 5�me �crite en relationnel mais les tables sont organis�es dans un cluster hach� (HEMP4, HDEPT4)
-- Plusieurs requ�tes sur ces applications sont ensuites lanc�es. 

-- On pourra ainsi profiter pour comparer les performances des diff�rentes 
-- approches.



-- Fixer le format de date et langue
alter session set nls_date_format='DD-MON-YYYY';
alter session set nls_language=american;


--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- la 1�re �crite en objet relationnel (table objet: BIGOEMP, BIGODEPT) --------------------------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

-- Suppression des tables et des types objets s'ils existent d�j�
DROP TABLE BIGOEMP CASCADE CONSTRAINT;
/
DROP TABLE BIGODEPT CASCADE CONSTRAINT;
/

DROP TYPE EMPLOYE_T FORCE
/

DROP TYPE DEPT_T FORCE
/

DROP TYPE tabPrenoms_t force
/

drop TYPE listEmployes_t force 
/

-- Cr�ation des types objets
CREATE OR REPLACE TYPE EMPLOYE_T 
/

CREATE OR REPLACE TYPE tabPrenoms_t AS VARRAY(4) OF varchar2(20)
/

create or replace type listEmployes_t as table of ref EMPLOYE_T
/

CREATE OR REPLACE TYPE DEPT_T AS OBJECT(		
DEPTNO		number,
DNAME		varchar2(30),
LOC		varchar2(30),
listEmployes	listEmployes_t,
static function getDept (deptno IN number) return DEPT_T,
MAP MEMBER FUNCTION compDept return VARCHAR2,
MEMBER PROCEDURE addLinkListeEmployes(RefEmp1 IN REF EMPLOYE_T),
MEMBER PROCEDURE deleteLinkListeEmployes (RefEmp1 IN REF EMPLOYE_T),
MEMBER PROCEDURE updateLinkListeEmployes (RefEmp1 IN REF EMPLOYE_T,
RefEmp2 REF EMPLOYE_T),
PRAGMA RESTRICT_REFERENCES (getDept, WNDS),
PRAGMA RESTRICT_REFERENCES (compDept, WNDS)
)
/

CREATE OR REPLACE TYPE EMPLOYE_T AS OBJECT(	
EMPNO		NUMBER,	
ENAME		varchar2(15), 
PRENOMS		tabPrenoms_t,		
JOB		Varchar2(20),	
SAL		number(7,2),		
CV		CLOB,		
DATE_NAISS	date,		
DATE_EMB	date,
refDept		REF DEPT_T,
ORDER MEMBER FUNCTION compEmp(emp IN EMPLOYE_T)
return NUMBER,
PRAGMA RESTRICT_REFERENCES (compEmp, WNDS)	
)
/	

create or replace type setEmployes_t as table of EMPLOYE_T
/

ALTER TYPE DEPT_T
ADD
Static function getInfoEmp(deptno IN number)
 return setEmployes_t CASCADE
/

-- cr�ation des tables objets
CREATE TABLE BIGODEPT of DEPT_T(
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
 
CREATE TABLE BIGOEMP of EMPLOYE_T(
	constraint pk_employe_empno primary key(empno) 
	USING INDEX TABLESPACE users,
	constraint chk_employe_ename check (ename =upper(ename)),
	constraint chk_employe_job check 
		(job IN ('Ingenieur','Secr�taire', 'Directeur', 'PDG', 'Planton')),
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

-- Cr�ation d'indexes

CREATE UNIQUE INDEX IDX_DEPT_DNAME ON BIGODEPT(dname)
TABLESPACE users
/


ALTER TABLE storeListEmployes
	ADD (SCOPE FOR (column_value) IS BIGOEMP);

ALTER TABLE BIGOEMP
	ADD (SCOPE FOR (refDept) IS BIGODEPT);

CREATE UNIQUE INDEX idx_SLE_nested_table_id_column_value ON storeListEmployes(nested_table_id, column_value)
TABLESPACE users
/

CREATE INDEX IDX_BIGOEMP_REFDEPT ON BIGOEMP(refdept)
TABLESPACE users
/

-- Afin d'acc�ler le d�r�f�rencement implicite ou explicite.
ALTER TABLE storeListEmployes
	ADD (REF (column_value) WITH ROWID);

ALTER TABLE BIGOEMP
ADD (REF (refDept) WITH ROWID);


-- Suppression puis cr�ation d'une s�quence
drop sequence seq_empno;
create sequence seq_empno start with 12;




-- Suppression puis cr�ation d'une s�quence
drop sequence seq_empno;
create sequence seq_empno start with 12;





-- Insertion massive de lignes dans la table des employ�s
declare
	refDept1 ref DEPT_T;
	refDept2 ref DEPT_T;
	refDept3 ref DEPT_T;
	refDept4 ref DEPT_T;
	i number(8):=0;

begin
	-- Cr�ation des d�partements
	insert into BIGODEPT d 
	values(1000, 'Recherche', 'rabat',listEmployes_t() ) 
	returning ref(d) into refDept1;


 	insert into BIGODEPT d 
	values(1001,'Marketing', 'Casa',listEmployes_t() ) 
	returning ref(d) into refDept2;

	insert into BIGODEPT d 
	values(1002,'RH', 'Casa',listEmployes_t() ) 
	returning ref(d) into refDept3;


	insert into BIGODEPT d 
	values(1003,'Ventes', 'Casa',listEmployes_t() ) 
	returning ref(d) into refDept4;

	-- Cr�ation des employ�s
	insert into BIGOEMP e 
	values(1, 'MILOUD', tabPrenoms_t('Mohamed'),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into BIGOEMP e 
	values(2, 'BOUMLID', tabPrenoms_t('Foudelle'),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into BIGOEMP e 
	values(3, 'MILOU', tabPrenoms_t('Tintin'),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into BIGOEMP e 
	values(4, 'FOUDIL', tabPrenoms_t('Foudelle'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into BIGOEMP e 
	values(5, 'FOUDELLE', tabPrenoms_t('Amina', 'traor�'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into BIGOEMP e 
	values(6, 'ERZULIE', tabPrenoms_t('Maria'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into BIGOEMP e 
	values(7, 'IBOLELE', tabPrenoms_t('La Terre'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into BIGOEMP e 
	values(8, 'JACQUOUD', tabPrenoms_t('Le croquant'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into BIGOEMP e 
	values(9, 'MARX', tabPrenoms_t('Karl'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into BIGOEMP e 
	values(10, 'RACKHAM', tabPrenoms_t('Le rouge'),'Secr�taire', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;

	loop

	-- Cr�ation des employ�s
	insert into BIGOEMP e 
	values(seq_empno.nextval, 'MILOUD', tabPrenoms_t('Mohamed'||i),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into BIGOEMP e 
	values(seq_empno.nextval, 'BOUMLID', tabPrenoms_t('Foudelle'||i),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into BIGOEMP e 
	values(seq_empno.nextval, 'MILOU', tabPrenoms_t('Tintin'||i),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into BIGOEMP e 
	values(seq_empno.nextval, 'FOUDIL', tabPrenoms_t('Foudelle'||i),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into BIGOEMP e 
	values(seq_empno.nextval, 'FOUDELLE', tabPrenoms_t('Amina'||i, 'traor�'),'Planton', 
	13600, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into BIGOEMP e 
	values(seq_empno.nextval, 'ERZULIE', tabPrenoms_t('Maria'||i),'Ingenieur', 
	13500, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into BIGOEMP e 
	values(seq_empno.nextval, 'IBOLELE', tabPrenoms_t('La Terre'||i),'Ingenieur', 
	13800, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into BIGOEMP e 
	values(seq_empno.nextval, 'JACQUOUD', tabPrenoms_t('Le croquant'||i),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into BIGOEMP e 
	values(seq_empno.nextval, 'MARX', tabPrenoms_t('Karl'||i),'Ingenieur', 
	13100, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into BIGOEMP e 
	values(seq_empno.nextval, 'RACKHAM', tabPrenoms_t('Le rouge'||i),'Secr�taire', 
	13400, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;




	-- mise � jour de la liste des r�f�rences vers les employes
	commit;
	i:=i+1;
	EXIT WHEN i>30000;
	end loop;

end;
/




-- Mise � jour de la liste des r�f�rences vers les employ�s
Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT d
where d.deptno=1000
)lemp
select ref(e) from BIGOEMP e
where e.refdept.deptno=1000;


Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT d
where d.deptno=1001
)lemp
select ref(e) from BIGOEMP e
where e.refdept.deptno=1001;


Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT d
where d.deptno=1002
)lemp
select ref(e) from BIGOEMP e
where  e.refdept.deptno=1002;


Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT d
where d.deptno=1003
)lemp
select ref(e) from BIGOEMP e
where  e.refdept.deptno=1003;

commit;





--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- Deuxi�me application �crite en objet relationnel (table objet: BIGOEMP2, BIGODEPT2) -----------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------
-------------------------------------------------------------
-- Suppression des tables et des types objets s'ils existent d�j�
DROP TABLE BIGOEMP2 CASCADE CONSTRAINT;
/
DROP TABLE BIGODEPT2 CASCADE CONSTRAINT;
/
-- cr�ation des tables objets
CREATE TABLE BIGODEPT2 of DEPT_T(
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
 
CREATE TABLE BIGOEMP2 of EMPLOYE_T(
	constraint pk_BIGOEMP2_empno primary key(empno) 
	USING INDEX TABLESPACE users,
	constraint chk_BIGOEMP2_ename check (ename =upper(ename)),
	constraint chk_BIGOEMP2_job check 
		(job IN ('Ingenieur','Secr�taire', 'Directeur', 'PDG', 'Planton')),
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

-- Cr�ation d'indexes
drop index IDX_BIGDEPT2_DNAME;
drop INDEX idx_storeListEmps2_nested_id;

CREATE UNIQUE INDEX IDX_BIGDEPT2_DNAME ON BIGODEPT2(dname)
TABLESPACE users
/

ALTER TABLE storeListEmployes2
	ADD (SCOPE FOR (column_value) IS BIGOEMP2);

ALTER TABLE BIGOEMP2
	ADD (SCOPE FOR (refDept) IS BIGODEPT2);

CREATE UNIQUE INDEX idx_SLE2_nested_table_id_column_value ON storeListEmployes2(nested_table_id, column_value)
TABLESPACE users
/

-- Laisser la cr�ation de cet index en commentaire. On vera l'effet de son absence avec les conseillers tuning
-- et les requ�tes qui l'impliquent.

--CREATE INDEX IDX_BIGOEMP2_REFDEPT ON BIGOEMP2(refdept)
--TABLESPACE users
--/

-- Afin d'acc�ler le d�r�f�rencement implicite ou explicite.
ALTER TABLE storeListEmployes2
	ADD (REF (column_value) WITH ROWID);

ALTER TABLE BIGOEMP2
ADD (REF (refDept) WITH ROWID);

-- Suppression puis cr�ation d'une s�quence
drop sequence seq_empno2;
create sequence seq_empno2 start with 12;

-- Insertion massive de lignes dans la table des employ�s
declare
	refDept1 ref DEPT_T;
	refDept2 ref DEPT_T;
	refDept3 ref DEPT_T;
	refDept4 ref DEPT_T;
	i number(8):=0;

begin
	-- Cr�ation des d�partements
	insert into BIGODEPT2 d 
	values(1000, 'Recherche', 'rabat',listEmployes_t() ) 
	returning ref(d) into refDept1;


 	insert into BIGODEPT2 d 
	values(1001,'Marketing', 'Casa',listEmployes_t() ) 
	returning ref(d) into refDept2;

	insert into BIGODEPT2 d 
	values(1002,'RH', 'Casa',listEmployes_t() ) 
	returning ref(d) into refDept3;


	insert into BIGODEPT2 d 
	values(1003,'Ventes', 'Casa',listEmployes_t() ) 
	returning ref(d) into refDept4;

	-- Cr�ation des employ�s
	insert into BIGOEMP2 e 
	values(1, 'MILOUD', tabPrenoms_t('Mohamed'),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into BIGOEMP2 e 
	values(2, 'BOUMLID', tabPrenoms_t('Foudelle'),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into BIGOEMP2 e 
	values(3, 'MILOU', tabPrenoms_t('Tintin'),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into BIGOEMP2 e 
	values(4, 'FOUDIL', tabPrenoms_t('Foudelle'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into BIGOEMP2 e 
	values(5, 'FOUDELLE', tabPrenoms_t('Amina', 'traor�'),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into BIGOEMP2 e 
	values(6, 'ERZULIE', tabPrenoms_t('Maria'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into BIGOEMP2 e 
	values(7, 'IBOLELE', tabPrenoms_t('La Terre'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into BIGOEMP2 e 
	values(8, 'JACQUOUD', tabPrenoms_t('Le croquant'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into BIGOEMP2 e 
	values(9, 'MARX', tabPrenoms_t('Karl'),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into BIGOEMP2 e 
	values(10, 'RACKHAM', tabPrenoms_t('Le rouge'),'Secr�taire', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;

	loop

	-- Cr�ation des employ�s
	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'MILOUD', tabPrenoms_t('Mohamed'||i),'Ingenieur', 
	10000, empty_clob(),to_date('10-10-1980', 'DD-MM-YYYY')+5,
	to_date('10-10-2000', 'DD-MM-YYYY')+5,refDept1) ;


	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'BOUMLID', tabPrenoms_t('Foudelle'||i),'Planton', 
	2000, empty_clob(),to_date('10-10-1982', 'DD-MM-YYYY')+10,
	to_date('10-10-2001', 'DD-MM-YYYY')+10,refDept1);


	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'MILOU', tabPrenoms_t('Tintin'||i),'Directeur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+1,
	to_date('10-10-2002', 'DD-MM-YYYY')+1,refDept2) ;


	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'FOUDIL', tabPrenoms_t('Foudelle'||i),'Planton', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+3,
	to_date('10-10-2002', 'DD-MM-YYYY')+3,refDept2) ;

	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'FOUDELLE', tabPrenoms_t('Amina'||i, 'traor�'),'Planton', 
	13600, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+4,
	to_date('10-10-2002', 'DD-MM-YYYY')+4,refDept3) ;


	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'ERZULIE', tabPrenoms_t('Maria'||i),'Ingenieur', 
	13500, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+6,
	to_date('10-10-2002', 'DD-MM-YYYY')+6,refDept4) ;


	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'IBOLELE', tabPrenoms_t('La Terre'||i),'Ingenieur', 
	13800, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+11,
	to_date('10-10-2002', 'DD-MM-YYYY')+11,refDept4) ;


	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'JACQUOUD', tabPrenoms_t('Le croquant'||i),'Ingenieur', 
	13000, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+20,
	to_date('10-10-2002', 'DD-MM-YYYY')+20,refDept4) ;

	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'MARX', tabPrenoms_t('Karl'||i),'Ingenieur', 
	13100, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+25,
	to_date('10-10-2002', 'DD-MM-YYYY')+25,refDept1) ;

	insert into BIGOEMP2 e 
	values(seq_empno2.nextval, 'RACKHAM', tabPrenoms_t('Le rouge'||i),'Secr�taire', 
	13400, empty_clob(),to_date('10-10-1978', 'DD-MM-YYYY')+30,
	to_date('10-10-2002', 'DD-MM-YYYY')+30,refDept1) ;




	-- mise � jour de la liste des r�f�rences vers les employes
	commit;
	i:=i+1;
	EXIT WHEN i>30000;
	end loop;

end;
/




-- Mise � jour de la liste des r�f�rences vers les employ�s
Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT2 d
where d.deptno=1000
)lemp
select ref(e) from BIGOEMP2 e
where e.refdept.deptno=1000;


Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT2 d
where d.deptno=1001
)lemp
select ref(e) from BIGOEMP2 e
where e.refdept.deptno=1001;


Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT2 d
where d.deptno=1002
)lemp
select ref(e) from BIGOEMP2 e
where  e.refdept.deptno=1002;


Insert into
table(
select d.LISTEMPLOYES   from BIGODEPT2 d
where d.deptno=1003
)lemp
select ref(e) from BIGOEMP2 e
where  e.refdept.deptno=1003;

commit;



--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- Troisi�me application �crite en relationnel (table relationnelles: R_EMPLOYE, R_DEPT) ---------------------
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

-- Cr�ation des tables relationnelles
drop table r_dept cascade constraints
/
drop table r_employe
/

CREATE TABLE R_DEPT(		
DEPTNO	number constraint pk_r_dept_deptno primary key,
DNAME	varchar2(30)constraint chk_r_dept_dname check(dname in 
		('Recherche','RH', 'Marketing','Ventes', 'Finance')),
LOC	varchar2(30),
constraint chk_r_dept_deptno check(deptno between 1000 and 9999)
)
/

CREATE TABLE R_EMPLOYE(	
EMPNO		NUMBER constraint pk_r_employe_empno primary key,	
ENAME		varchar2(15)constraint chk_r_employe_ename check (ename =upper(ename)), 
JOB		Varchar2(20) constraint chk_r_employe_job check 
		(job IN ('Ingenieur','Secr�taire', 'Directeur', 'PDG', 'Planton')),	
SAL		number(7,2),		
CV		CLOB,		
DATE_NAISS	date,		
DATE_EMB	date,
deptno		number constraint fk_r_emp_r_dept references r_dept(deptno),
constraint chk_r_emp_date_e_date_n check (date_emb>date_naiss)
)
/

-- cr�ation d'indexes	
create index idx_r_employe_deptno on r_employe(deptno)
tablespace users
/

create unique index idx_r_dept_dname on r_dept(dname)
tablespace users
/

create  index idx_r_employe_ename on r_employe(ename)
tablespace users
/
-- insertion des lignes dans les tables relationnelles � partir des tables objets
INSERT INTO r_dept
select deptno, dname, loc  from BIGODEPT;

INSERT INTO r_EMPLOYE
SELECT EMPNO, ENAME, JOB,SAL, CV,  DATE_NAISS, DATE_EMB, e.refdept.deptno
from BIGOEMP e;

commit;


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- 4�me application �crite en relationnelle (EMP4, DEPT4) les tables sont organisees dans des segments s�par�s -----
-- 4�me application �crite en relationnelle mais les tables sont organis�es dans un cluster index� (IEMP4, IDEPT4)--
-- 5�me application �crite en relationnelle mais les tables sont organis�es dans un cluster hach� (HEMP4, HDEPT4)---
-- Ces applications sont dans le scripts ci-dessous. ---------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

-- Installation des tables EMP4 et DEPT4 � partir du script
/*
Ce script permet de cr�er :
- des tables EMP4 et DEPT4 segment s�par�.
- des tables IEMP4 et IDEPT4 en cluster index�.
- des tables HEMP4 et HDEPT4 en cluster hach�.
- Ces tables contiennent un m�me nombre de lignes

*/

alter session set nls_date_format='DD-MON-YYYY';
alter session set nls_language=american;

drop table dept4 cascade constraint;
drop table emp4 cascade constraint;

DROP TYPE TabNoms4_T;
CREATE OR REPLACE TYPE TabNoms4_T 
as Varray(20) of varchar2(20)
/


CREATE TABLE dept4
       (DEPTNO NUMBER(2),
        DNAME VARCHAR2(14),
        LOC VARCHAR2(13) );

CREATE TABLE emp4
       (EMPNO NUMBER(8) NOT NULL,
        ENAME VARCHAR2(50),
        JOB VARCHAR2(9),
        MGR NUMBER(4),
        HIREDATE DATE,
        SAL NUMBER(7,2),
        COMM NUMBER(7,2),
        DEPTNO NUMBER(2));

alter table dept4 add constraint pk_dept4
primary key (deptno);
alter table emp4 add constraint pk_emp4
primary key (empno);
alter table emp4 add constraint fk_emp4_deptno
foreign key (deptno) references dept4(deptno);

drop sequence seq4_empno;
drop sequence seq_ename;
create sequence seq4_empno start with 7935;
create sequence seq_ename start with 1;

-- insertion dans la table des d�partements
INSERT INTO dept4 VALUES
        (10,'ACCOUNTING','NEW YORK');
INSERT INTO dept4 VALUES (20,'RESEARCH','DALLAS');
INSERT INTO dept4 VALUES
        (30,'SALES','CHICAGO');
INSERT INTO dept4 VALUES
        (40,'OPERATIONS','BOSTON');


-- Insertion dans la table des employ�s
INSERT INTO emp4 VALUES
        (7369,'SMITH','CLERK',7902,'17-DEC-1980',800,NULL,20);
INSERT INTO emp4 VALUES
        (7499,'ALLEN','SALESMAN',7698,'20-FEB-1981',1600,300,30);
INSERT INTO emp4 VALUES
        (7521,'WARD','SALESMAN',7698,'22-FEB-1981',1250,500,30);
INSERT INTO emp4 VALUES
        (7566,'JONES','MANAGER',7839,'2-APR-1981',2975,NULL,20);
INSERT INTO emp4 VALUES
        (7654,'MARTIN','SALESMAN',7698,'28-SEP-1981',1250,1400,30);
INSERT INTO emp4 VALUES
        (7698,'BLAKE','MANAGER',7839,'1-MAY-1981',2850,NULL,30);
INSERT INTO emp4 VALUES
        (7782,'CLARK','MANAGER',7839,'9-JUN-1981',2450,NULL,10);
INSERT INTO emp4 VALUES
        (7788,'SCOTT','ANALYST',7566,'09-DEC-1982',3000,NULL,20);
INSERT INTO emp4 VALUES
        (7839,'KING','PRESIDENT',NULL,'17-NOV-1981',5000,NULL,10);
INSERT INTO emp4 VALUES
        (7844,'TURNER','SALESMAN',7698,'8-SEP-1981',1500,0,30);
INSERT INTO emp4 VALUES
        (7876,'ADAMS','CLERK',7788,'12-JAN-1983',1100,NULL,20);
INSERT INTO emp4 VALUES
        (7900,'JAMES','CLERK',7698,'3-DEC-1981',950,NULL,30);
INSERT INTO emp4 VALUES
        (7902,'FORD','ANALYST',7566,'3-DEC-1981',3000,NULL,20);
INSERT INTO emp4 VALUES
        (7934,'MILLER','CLERK',7782,'23-JAN-1982',1300,NULL,10);


-- Insertion d'employ�s suppl�mentaires
DECLARE
	lesNoms	TabNoms4_t:= TabNoms4_t('Dupont', 'Durand', 'Foudil', 'Foudelle', 'Akim', 'Bleck', 'Zembla', 'Tintin', 'Milou', 'Mopolo', 'Malik', 'Amidou', 'Mamadou', 'Mariama', 'Marine', 'Mouloud', 'Chang', 'Li', 'Bruce', 'Balak');
	j		number:=1;
BEGIN
	For i In 1 .. 100000
	loop
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;
	
	INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7902,'17-DEC-1980',800,NULL,20);
	j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'20-FEB-1981',1600,300,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'22-FEB-1981',1250,500,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'2-APR-1981',2975,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'28-SEP-1981',1250,1400,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'1-MAY-1981',2850,NULL,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'9-JUN-1981',2450,NULL,10);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'ANALYST',7566,'09-DEC-1982',3000,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'8-SEP-1981',1500,0,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7788,'12-JAN-1983',1100,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7698,'3-DEC-1981',950,NULL,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'ANALYST',7566,'3-DEC-1981',3000,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas d�passer la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7782,'23-JAN-1982',1300,NULL,10);

	j:=j+1;	-- incr�menter j
	End loop;
	COMMIT;
END;
/


---

-- Cr�ation des table IEMP4 et IDEPT4 dans  un cluster index�
DROP TABLE IEMP4 CASCADE CONSTRAINTS ;
DROP TABLE IDEPT4 CASCADE CONSTRAINTS ;
DROP CLUSTER CLU_IEMP4_IDEPT4;

CREATE CLUSTER CLU_IEMP4_IDEPT4 (
DEPTNO NUMBER(2)
);

-- Cr�ation de l'index sur la cl� de cluster
DROP INDEX IDX_CLU_IEMP4_IDEPT4 ;
CREATE INDEX  IDX_CLU_IEMP4_IDEPT4 
ON CLUSTER CLU_IEMP4_IDEPT4;

-- Cr�ation de la table DEPT4 dans le cluster
CREATE TABLE IDEPT4(
DEPTNO NUMBER(2) CONSTRAINT  pk_IDEPT4  PRIMARY KEY,
DNAME VARCHAR2(14),
LOC VARCHAR2(13)
 ) CLUSTER CLU_IEMP4_IDEPT4 (DEPTNO);

-- Cr�ation de la table IEMP4 dans le cluster
CREATE TABLE IEMP4(
EMPNO NUMBER(8) constraint pk_IEMP4 primary key,
ENAME VARCHAR2(50),
JOB VARCHAR2(9),
MGR NUMBER(4),
HIREDATE DATE,
SAL NUMBER(7,2),
COMM NUMBER(7,2),
DEPTNO NUMBER(2) CONSTRAINT fk_IEMP4_deptno REFERENCES IDEPT4 (DEPTNO)
)CLUSTER CLU_IEMP4_IDEPT4 (DEPTNO) ;

-- cr�ation d'un index sur la cl� �trang�re
Create index idx_IEMP4_deptno on IEMP4(deptno);


-- Insertion de lignes � partir de la table DEPT4
INSERT INTO IDEPT4 SELECT * FROM DEPT4;

-- Insertion de lignes � partir de la table EMP4
INSERT INTO IEMP4 SELECT * FROM EMP4;

COMMIT;


-- Cr�ation des table HEMP4 et HDEPT4 dans  un cluster hach�

-- Cr�ation du cluster
DROP TABLE HEMP4 CASCADE CONSTRAINTS ;
DROP TABLE HDEPT4 CASCADE CONSTRAINTS ;
DROP CLUSTER HCLU_EMP4_DEPT4;

CREATE CLUSTER HCLU_EMP4_DEPT4 (
DEPTNO NUMBER(2)
) SIZE 2K HASH IS DEPTNO HASHKEYS 100;

-- Cr�ation de la table HDEPT4 dans le cluster
CREATE TABLE HDEPT4(
DEPTNO NUMBER(2) CONSTRAINT  pk_hdept4  PRIMARY KEY,
DNAME VARCHAR2(14),
LOC VARCHAR2(13) ) 
CLUSTER HCLU_EMP4_DEPT4 (DEPTNO);

-- Cr�ation de la table HEMP4 dans le cluster
CREATE TABLE HEMP4(
EMPNO NUMBER(8) constraint pk_hemp4 primary key,
ENAME VARCHAR2(50),
JOB VARCHAR2(9),
MGR NUMBER(4),
HIREDATE DATE,
SAL NUMBER(7,2),
COMM NUMBER(7,2),
DEPTNO NUMBER(2) CONSTRAINT fk_hemp4_deptno REFERENCES HDEPT4 (DEPTNO)
)CLUSTER HCLU_EMP4_DEPT4 (DEPTNO) ;

-- pas n�cessaire de cr�er cet index.
-- Create index idx_hemp4_deptno on HEMP4(deptno);

-- Insertion de lignes � partir de la table DEPT4
INSERT INTO HDEPT4 SELECT * FROM DEPT4;

-- Insertion de lignes � partir de la table EMP4
INSERT INTO HEMP4 SELECT * FROM EMP4;

COMMIT;

alter system checkpoint;



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Diverses requ�tes sur les diff�rentes applications cr��s ----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

-- Calcul des statitisques sur les objets de &MYPDBUSER
Execute Dbms_stats.gather_schema_stats('&MYPDBUSER');


-- L'activation de la trace en traceonly �vite l'affiche du 
-- r�sultat des r�qu�tes � l'�cran.
Set autotrace &TRACEOPTION
set linesize 200
-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Jointure avec des tables non clust�ris�es (CBO)
SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno;

-- Jointure avec tables relationnelles en cluster index� (CBO)
SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno;

-- Jointure avec tables en cluster hach� (CBO)
SELECT /*+USE_HASH(e d) */ dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno;

--SELECT dname, loc, ename, job, hiredate
--FROM HEMP4 e, HDEPT4 d
--WHERE e.deptno=d.deptno;



-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Jointure avec des tables non clust�ris�es (CBO)
SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno;



-- Jointure avec tables en cluster index� (CBO)
SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno;



-- Jointure avec tables en cluster hach� (CBO)
SELECT  /*+USE_HASH(e d) */ dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno;


-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Comptage de lignes dans les tables EMP4, IEMP4 et HEMP4
select count(*) from emp4;



select count(*) from IEMP4;



select count(*) from HEMP4;



-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Comptage de lignes dans les tables EMP4, IEMP4 et HEMP4
select count(*) from emp4;



select count(*) from IEMP4;



select count(*) from HEMP4;



-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Jointures connaissant un d�partement donn�.
set autotrace &TRACEOPTION
SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;


-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Jointures connaissant un d�partement donn�.
SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



SELECT dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;



-- Fixer l'optimizer de statistiques en mode first_rows_1
Alter session set optimizer_mode=first_rows_1;

-- Recherche des employ�s d'un d�partement connu.
SELECT  ename, job, hiredate
FROM EMP4 e
WHERE e.deptno=10;



SELECT  ename, job, hiredate
FROM IEMP4 e
WHERE e.deptno=10;



SELECT  ename, job, hiredate
FROM HEMP4 e
WHERE e.deptno=10;


-- Fixer l'optimizer de statistiques en mode all_rows
Alter session set optimizer_mode=all_rows;

-- Recherche des employ�s d'un d�partement connu.
SELECT  ename, job, hiredate
FROM EMP4 e
WHERE e.deptno=10;

SELECT  ename, job, hiredate
FROM IEMP4 e
WHERE e.deptno=10;



SELECT  ename, job, hiredate
FROM HEMP4 e
WHERE e.deptno=10;


-- Consultations compar�es sur les tables objets et les tables relationnelles

set autotrace &TRACEOPTION
set linesize 300
-- Consultation en mode FIRST_ROWS_1
alter session set optimizer_mode=FIRST_ROWS_1;

-- Recherche des informations sur les employ�s (+info dept) d'un d�partement connaissant son num�ro
-- Via la table des employ�s. Tables objets
select  e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP e
where e.refdept.deptno=1000;

-- en for�ant l'usage de l'index sur REFDEPT
select /*+INDEX (e IDX_EMPLOYE_REFDEPT)*/ e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP e
where e.refdept.deptno=1000;

-- Recherche des informations sur les employ�s d'un d�partement connaissant son num�ro
-- Via la table des employ�s. Tables objets
select  e.ename, e.job, e.sal
from BIGOEMP2 e
where e.refdept.deptno=1000;



-- Recherche des informations sur les employ�s d'un d�partement connaissant son num�ro
-- Via la liste des r�f�rences vers les employ�s dudit d�partement: tables objets
select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from BIGODEPT d
where d.deptno=1000
)lemp;

select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from BIGODEPT2 d
where d.deptno=1000
)lemp;

select e.ename, e.sal, d.dname,  d.loc 
from r_employe e, r_dept d
where e.deptno=d.deptno and d.deptno=1000;


-- Recherche des informations sur un d�partement connaissant un employ� de ce
-- Via la liste des r�f�rences vers les employ�s dudit d�partement: tables objets

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP e
where e.empno=1;

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP2 e
where e.empno=1;

select e.ename, e.sal, d.dname,  d.loc 
from r_employe e, r_dept d
where e.deptno=d.deptno and e.empno=1;



-- Consultation en mode all_rows
alter session set optimizer_mode=all_rows;

-- Recherche des informations sur les employ�s d'un d�partement connaissant son num�ro
-- Via la table des employ�s. Tables objets
select  e.empno, e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP e
where e.refdept.deptno=1000;

-- en for�ant l'usage de l'index sur REFDEPT
select /*+INDEX (e IDX_EMPLOYE_REFDEPT)*/e.empno,  e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP e
where e.refdept.deptno=1000;

-- Recherche des informations sur les employ�s d'un d�partement connaissant son num�ro
-- Via la table des employ�s. Tables objets
select  e.empno, e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP2 e
where e.refdept.deptno=1000;


-- Recherche des informations sur les employ�s d'un d�partement connaissant son num�ro
-- Via la liste des r�f�rences vers les employ�s dudit d�partement: tables objets
select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from BIGODEPT d
where d.deptno=1000
)lemp;

select lemp.column_value.empno,lemp.column_value.ename
from  
table(
select d.LISTEMPLOYES   from BIGODEPT2 d
where d.deptno=1000
)lemp;

select e.ename, e.sal, d.dname,  d.loc 
from r_employe e, r_dept d
where e.deptno=d.deptno and d.deptno=1000;


-- Recherche des informations sur un d�partement connaissant un employ� de ce
-- Via la liste des r�f�rences vers les employ�s dudit d�partement: tables objets

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP e
where e.empno=1;

select e.ename, e.sal, e.refdept.dname,  e.refdept.loc 
from BIGOEMP2 e
where e.empno=1;


select e.ename, e.sal, d.dname,  d.loc 
from r_employe e, r_dept d
where e.deptno=d.deptno and e.empno=1;

set autotrace off;


-- D�sactivation de la trace afin de pouvoir par la suite utiliser TKPROF
-- Voir les indications � la fin de ce fichier.
execute dbms_session.set_sql_trace(false);




set autotrace off

---?

-- 3. R�cup�ration du SPID afin de pouvoir identifier le fichier de 
-- trace TKPROF

select vs.username, vp.spid 
from v$process vp , v$session vs
where vp.addr=vs.paddr 
and vs.username ='&MYPDBUSER';

-- D�sactivation de la trace
-- Voir la fin du fichier pour voir comment lancer TKPROF
execute dbms_session.set_sql_trace(false);

-- La valeur de user_dump_dest indique l'emplacement 
-- du fichier de trace g�n�r�.
show parameter user_dump_dest

set termout off
set echo off
set serveroutput off

set timing off

-- 4. Cr�ation d'un deuxmi�me clich� AWR

-- Connexion au niveau CDB pour prendre un clich� AWR
connect &MYCDBUSER@&DBALIASCDB/&MYCDBUSERPASS
-- set arraysize 5000
set serveroutput on
declare
snapid2 number;
begin
snapid2:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid2='|| snapid2);
end;
/
-- ReConnexion au niveau PDB. 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS
-- set arraysize 5000
-- UTILISATION DE TKPROF
-- Voir l'exercice 4 de TUNE 1 en se servant du spid 


spool off
 