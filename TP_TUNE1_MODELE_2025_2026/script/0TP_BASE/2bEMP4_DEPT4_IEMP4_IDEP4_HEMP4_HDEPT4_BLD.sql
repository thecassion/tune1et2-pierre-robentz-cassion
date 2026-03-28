-----------------------------
-- Ce script permet de créer les tables DEPT4 et EMP4 (segment séparé)
-- Et les tables IDEPT4 et IEMP4  en cluster indexé.
-- Et les tables HDEPT4 et HEMP4  en cluster haché.
-- Des lignes sont insérés dans ces différentes tables.
-- Les tables DEPT4, IDEPT4, HDEPT4 ont le même volume (4 lignes chacunes).
-- Les tables EMP4, IEMP4, HEMP4 ont le même volume (1300000 lignes chacunes).
-- Plusieurs requêtes sont lancées par la suite pour comparer
-- les performances entre les trois approches de stockage :
--  - segments séparés : DEPT4 et EMP4
--  - cluster indexé   : IDEPT4 et IEMP4
--  - cluster haché    : HDEPT4 et HEMP4
-- ce script doit être exécuté dans le dossier ou il se trouve 
set autotrace off
set termout on
set echo on
set serveroutput on
set timing on

spool 2cbEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_LOG.LOG


alter session set nls_date_format='DD-MON-YYYY';
alter session set nls_language=american;

-- activation de la trace afin de pouvoir par la suite utiliser TKPROF
-- Voir les indications à la fin de ce fichier.
execute dbms_session.set_sql_trace(true);


-- Création d'un premier cliché AWR


set serveroutput on
declare
snapid number;
begin
snapid:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid_3='|| snapid);
end;
/
-- 1) via deux segments séparés EMP4 et DEPT4

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

-- insertion dans la table des départements
INSERT INTO dept4 VALUES
        (10,'ACCOUNTING','NEW YORK');
INSERT INTO dept4 VALUES (20,'RESEARCH','DALLAS');
INSERT INTO dept4 VALUES
        (30,'SALES','CHICAGO');
INSERT INTO dept4 VALUES
        (40,'OPERATIONS','BOSTON');


-- Insertion dans la table des employés
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


-- Insertion d'employés supplémentaires
DECLARE
	lesNoms	TabNoms4_t:= TabNoms4_t('Dupont', 'Durand', 'Foudil', 'Foudelle', 'Akim', 'Bleck', 'Zembla', 'Tintin', 'Milou', 'Mopolo', 'Malik', 'Amidou', 'Mamadou', 'Mariama', 'Marine', 'Mouloud', 'Chang', 'Li', 'Bruce', 'Balak');
	j		number:=1;
BEGIN
	For i In 1 .. 100000
	loop
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
	
	INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7902,'17-DEC-1980',800,NULL,20);
	j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'20-FEB-1981',1600,300,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'22-FEB-1981',1250,500,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'2-APR-1981',2975,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'28-SEP-1981',1250,1400,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'1-MAY-1981',2850,NULL,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'9-JUN-1981',2450,NULL,10);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'ANALYST',7566,'09-DEC-1982',3000,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'8-SEP-1981',1500,0,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7788,'12-JAN-1983',1100,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7698,'3-DEC-1981',950,NULL,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'ANALYST',7566,'3-DEC-1981',3000,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO emp4 VALUES
        (seq4_empno.nextval,lesNoms(j),'CLERK',7782,'23-JAN-1982',1300,NULL,10);

	j:=j+1;	-- incrémenter j
	End loop;
	COMMIT;
END;
/

Create index idx_emp4_deptno on emp4(deptno);

-- 2) via un cluster avec clé indexée (IEMP4 et IDEPT4)
DROP TABLE IEMP4 CASCADE CONSTRAINTS ;
DROP TABLE IDEPT4 CASCADE CONSTRAINTS ;
DROP CLUSTER CLU_IEMP4_IDEPT4;

CREATE CLUSTER CLU_IEMP4_IDEPT4 (
DEPTNO NUMBER(2)
);

-- Création de l'index sur la clé de cluster
CREATE INDEX  IDX_CLU_IEMP4_IDEPT4 
ON CLUSTER CLU_IEMP4_IDEPT4;

-- Création de la table DEPT4 dans le cluster
CREATE TABLE IDEPT4(
DEPTNO NUMBER(2) CONSTRAINT  pk_IDEPT4  PRIMARY KEY,
DNAME VARCHAR2(14),
LOC VARCHAR2(13)
 ) CLUSTER CLU_IEMP4_IDEPT4 (DEPTNO);

-- Création de la table IEMP4 dans le cluster
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

Create index idx_IEMP4_deptno on IEMP4(deptno);


-- Insertion de lignes à partir de la table DEPT
INSERT INTO IDEPT4 SELECT * FROM DEPT4;

-- Insertion de lignes à partir de la table EMP
INSERT INTO IEMP4 SELECT * FROM EMP4;

COMMIT;

alter system checkpoint;

-- 3) via un cluster avec clé hachée (HEMP4 et HDEPT4).

-- Création du cluster
DROP TABLE HEMP4 CASCADE CONSTRAINTS ;
DROP TABLE HDEPT4 CASCADE CONSTRAINTS ;
DROP CLUSTER HCLU_EMP4_DEPT4;

CREATE CLUSTER HCLU_EMP4_DEPT4 (
DEPTNO NUMBER(2)
) SIZE 500 HASHKEYS 100;

-- Création de la table HDEPT4 dans le cluster
CREATE TABLE HDEPT4(
DEPTNO NUMBER(2) CONSTRAINT  pk_hdept4  PRIMARY KEY,
DNAME VARCHAR2(14),
LOC VARCHAR2(13) ) 
CLUSTER HCLU_EMP4_DEPT4 (DEPTNO);

-- Création de la table HEMP4 dans le cluster
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

Create index idx_hemp4_deptno on hemp4(deptno);

-- Insertion de lignes à partir de la table DEPT
INSERT INTO HDEPT4 SELECT * FROM DEPT4;

-- Insertion de lignes à partir de la table EMP
INSERT INTO HEMP4 SELECT * FROM EMP4;

COMMIT;
-- spool off
-- spool JOIN_WITH_AND_NO_CLUSTER2sur16.LOG

Execute Dbms_stats.gather_schema_stats('ORS1');


-----------------------------------------------------------------------------
--------------------------RULE-----------------------------------------------
-----------------------------------------------------------------------------

Set autotrace traceonly;
set linesize 200

Alter session set optimizer_mode=rule;

SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno;
---?

-- Jointure avec tables en cluster indexé (RBO)
SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno;

-- Jointure avec tables en cluster haché (RBO)
SELECT dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno;

SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

SELECT dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

SELECT  ename, job, hiredate
FROM EMP4 e
WHERE e.deptno=10;

SELECT  ename, job, hiredate
FROM IEMP4 e
WHERE e.deptno=10;

SELECT  ename, job, hiredate
FROM HEMP4 e
WHERE e.deptno=10;


--- ?
select count(*) from emp4;

---?

select count(*) from iemp4;

---?

select count(*) from hemp4;

---?
-- pour voir les temps en mode règle il faut utiliser TKPROF


-----------------------------------------------------------------------------
--------------------------FIRST_ROWS-----------------------------------------
-----------------------------------------------------------------------------

-- CBO : optimizer_mode=first_rows;
Alter session set optimizer_mode=first_rows_1;

SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno;

---?

-- Jointure avec tables en cluster indexé (CBO)
SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno;


-- Jointure avec tables en cluster haché (CBO)
SELECT /*+USE_HASH(e d) */ dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno;

SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

---?
--spool off
--spool JOIN_WITH_AND_NO_CLUSTER9sur16.LOG

SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

---?

SELECT dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

--spool off
--spool JOIN_WITH_AND_NO_CLUSTER10sur16.LOG

SELECT  ename, job, hiredate
FROM EMP4 e
WHERE e.deptno=10;

----?

SELECT  ename, job, hiredate
FROM IEMP4 e
WHERE e.deptno=10;

----?
--spool off
--spool JOIN_WITH_AND_NO_CLUSTER11sur16.LOG

SELECT  ename, job, hiredate
FROM HEMP4 e
WHERE e.deptno=10;


select count(*) from emp4;

---?

select count(*) from iemp4;

---?

select count(*) from hemp4;


-----------------------------------------------------------------------------
-----------------------------ALL_RORWS---------------------------------------
-----------------------------------------------------------------------------
-- CBO : optimizer_mode=all_rows;
Alter session set optimizer_mode=all_rows;

SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno;

---?

-- Jointure avec tables en cluster indexé (CBO)
SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno;

-- Jointure avec tables en cluster haché (CBO)
SELECT /*+USE_HASH(e d) */dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno;



SELECT dname, loc, ename, job, hiredate
FROM EMP4 e, DEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

SELECT dname, loc, ename, job, hiredate
FROM IEMP4 e, IDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;

---?

SELECT dname, loc, ename, job, hiredate
FROM HEMP4 e, HDEPT4 d
WHERE e.deptno=d.deptno and d.deptno=10;


SELECT  ename, job, hiredate
FROM EMP4 e
WHERE e.deptno=10;

----?

SELECT  ename, job, hiredate
FROM IEMP4 e
WHERE e.deptno=10;

SELECT  ename, job, hiredate
FROM HEMP4 e
WHERE e.deptno=10;


select count(*) from emp4;

---?

select count(*) from iemp4;

---?

select count(*) from hemp4;

---?

set autotrace off

select vs.username, vp.spid 
from v$process vp , v$session vs
where vp.addr=vs.paddr 
and vs.username ='ORS1';

-- Désactivation de la trace
-- Voir la fin du fichier pour voir comment lancer TKPROF
execute dbms_session.set_sql_trace(false);

--?
-- 3. Création d'un deuxmième cliché AWR


set serveroutput on
declare
snapid number;
begin
snapid:=dbms_workload_repository.create_snapshot;
dbms_output.put_line('Snapid_3='|| snapid);
end;
/

-- La valeur de user_dump_dest indique l'emplacement 
-- du fichier de trace généré.
show parameter user_dump_dest

--?

spool off
set timing off

-- UTILISATION DE TKPROF
-- remplacer le chemin par la valeur donnée par show parameter user_dump_dest
-- et instanceName par le nom de votre instance
-- et spid par la valeur de spid recueillie via la requête ci-dessus
-- TKPROF doit être lancé sous DOS dans le dossier ...\script
--tkprof C:\app\Gabriel\diag\rdbms\orcl\orcl\trace\instanceName_ora_spid.trc 2dEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_TRC.TRC EXPLAIN=ors1/Passors1 
-- SORT = execpu, fchcpu sys=n
-- exemple
--tkprof C:\app\Gabriel\diag\rdbms\orcl\orcl\trace\orcl_ora_8900.trc 2dEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_TRC.TRC EXPLAIN=ors1/Passors1 
-- SORT = execpu, fchcpu sys=n
-- instanceName=orcl spid=3604
-- Ouvrir ensuite le fichier trc1.prf par notepad++ ou autre
-- debut trc2.prf
