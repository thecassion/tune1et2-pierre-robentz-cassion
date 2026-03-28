-- cr�er un utilisateur de travail appel� ORS1
-- lui donner les droits DBA
-- Modifier les param�tres de langue afin d'installer 
-- sans erreurs de date le script DEMOBLD
-- Ce script contient 4 tables dont 2 qui seront utlis�es
-- dans nos exercices : 
-- DEPT : TABLE des d�partements d'une entreprise
-- EMP  : Table des employ�s d'une entreprise.
-- Une FK existe dans EMP pour indiquer les d�partement des employ�s
-- Notes :

-- 1) s'il ya des chemins physiques, il faut les adapter � votre situation

-- *****Cas 1 : VOUS ETES SUR UNE BASE LOCALE *****************

-- cmd
-- Lancer sqlplus sans se logger
sqlplus /nolog

-- D�finir la variable qui indique l'emplacement des scripts
-- define SCRIPTPATH=D:\1agm05092005\1Cours\5ORS\2021_2022\0Auditeurs\ESTIA\TP_TUNE1_MODELE_2021_2022\script\0TP_BASE


-- MAC Docker 
define SCRIPTPATH=/opt/oracle/scripts/3Tuning_Oracle_Dossier_Etudiants/TP_TUNE1_MODELE_2025_2026/script/0TP_BASE

-- D�finir la vairiable qui va contenir le nom r�seau de votre base.
-- Le nom r�seau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIAS=PDBMBDS

-- D�finir la variable contenant le nom de l'utilisateur que vous allez cr�er
define MYUSER=ORS1

-- D�finir la variable contenant le password du compte SYSTEM
define SYSTEMPASSWORD=OracleSysdbaCours21c01

-- 
define MYINSTANCE=Cours21c

-- For MAC Docker 

define SCRIPTPATH=/opt/oracle/scripts/TP_TUNE1_MODELE_2025_2026/script/0TP_BASE

define DBALIAS=FREEPDB1
define MYUSER=ORS1
define SYSTEMPASSWORD=Oracle123
define MYINSTANCE=FREE

-- Se connecter avec votre compte System pour cr�er l'utilisateur 
connect system@&DBALIAS/&SYSTEMPASSWORD

-- suprimer l'utilisateur s'il existe d�j�
drop user &MYUSER cascade;

-- Cr�ation de l'utilisateur. 
create user &MYUSER identified by PassOrs1
default tablespace users
temporary tablespace temp;

-- for docker 
create user &MYUSER identified by PassOrs1 default tablespace users temporary tablespace temp;

-- affecter et enlever des droits
grant dba to &MYUSER;

revoke unlimited tablespace from &MYUSER;

-- connection avec le nouvel utilisateur. Il faut respecter la casse pour le password
connect &MYUSER@&DBALIAS/PassOrs1

alter user &MYUSER quota unlimited on users;

-- **** Cas 2 : vous vous connectez sur ma base DBCOURS **** 
-- connectez vous comme suit. L'alias DBCOURSH doit avoir �t� 
-- d�fini dans le fichier tnsnames.ora
connect ETxxxxx1M17@DBCOURSH/ETxxxxx1M1701
ou via sqldeveloper

-- A tous les co�ts ************************** 
-- Ex�cutez ce qui suit 

-- Le script demobld.sql est dans le dossier chemin\script
sql>@&SCRIPTPATH/demobld.sql
-- liste des tables cr�es
sql> select * from tab;

TNAME                          TABTYPE  CLUSTERID
------------------------------ ------- ----------
EMP                            TABLE
DEPT                           TABLE
BONUS                          TABLE
SALGRADE                       TABLE
DUMMY                          TABLE

select * from emp;
-- vous devez voir des lignes

/*
Exercice 3.1

Cr�er un index Btree non unique sur la colonne ENAME de la table EMP. L'index doit �tre localis� dans le tablespace USERS

CREATE INDEX IDX_emp_ename ON EMP(ENAME)

Cr�er un index concat�n� sur les colonnes Job et Sal de la table EMP. L'index doit �tre localiser dans le tablespace USERS. Faites aussi en sorte que 5 transactions puissent �tre inscrites en m�me temps

Cr�er un index Bitmap sur la colonne COMM (commission) de la table EMP. Le localiser dans le tablespace USERS.

Calculer la volum�trie des trois index sur la colonne COMM (commission) de la table EMP. 

Ecrire une requ�te qui renvoie des informations sur le job et le salaire pour tous les salaires sup�rieurs � 7000 et le job �gal � CLERK : d'abord en ramenant toutes les colonnes puis en ramenant uniquement le job et le salaire.
Avant de lancer les requ�tes faire :
Set AUTOTRACE ON pour visualiser les plans

Ecrire une requ�te qui permet de visualiser les informations sur les employ�s dont le num�ro est sup�rieur 7839 et dont la commission est sup�rieure � 0
Avant de lancer les requ�tes faire :
Set AUTOTRACE ON pour visualiser les plans

Supprimer tous les index et relancer les requ�tes pr�c�dentes
*/

-- Calculer la volum�trie des trois index de la table EMP. 

-- cr�er une proc�dure stock�e pour calculer la volum�trie
create or replace procedure createIndexSize(index_ddl IN varchar2,
taille_utilise OUT varchar2, taille_alloue OUT varchar2) IS
Begin
	dbms_space.create_index_cost(
		ddl=>index_ddl,
		used_bytes=>taille_utilise ,
		alloc_bytes=>taille_alloue
	);
End;
/

-- Utilisation de la proc�dure stock�e pour calculer la volum�trie
set serveroutput on
declare
	taille_utilise VARCHAR2(100);
	taille_alloue VARCHAR2(100);
begin

	createIndexSize('CREATE index idx_emp_ename on emp(ename)', taille_utilise, taille_alloue);
	dbms_output.put_line('taille_utilise pour idx_emp_ename='||taille_utilise);
	dbms_output.put_line('taille_alloue pour idx_emp_ename='||taille_alloue);

	
	createIndexSize('create index idx_emp_job_sal on emp (job, sal)', taille_utilise, taille_alloue);
	dbms_output.put_line('taille_utilise pour idx_emp_job_sal='||taille_utilise);
	dbms_output.put_line('taille_alloue pour idx_emp_job_sal='||taille_alloue);

	
	createIndexSize('create bitmap index idx_emp_comm on emp(comm)', taille_utilise, taille_alloue);
	dbms_output.put_line('taille_utilise pour idx_emp_comm='||taille_utilise);
	dbms_output.put_line('taille_alloue pour idx_emp_comm='||taille_alloue);

end;
/

?
------------------------------------
--- De mon execution

taille_utilise pour idx_emp_ename=70
taille_alloue pour idx_emp_ename=65536
taille_utilise pour idx_emp_job_sal=140
taille_alloue pour idx_emp_job_sal=65536
taille_utilise pour idx_emp_comm=28
taille_alloue pour idx_emp_comm=65536

------------------------------------------------


taille_utilise pour idx_emp_ename=84
taille_alloue pour idx_emp_ename=65536
taille_utilise pour idx_emp_job_sal=168
taille_alloue pour idx_emp_job_sal=65536
taille_utilise pour idx_emp_comm=28
taille_alloue pour idx_emp_comm=65536


-- Quel est l'int�r�t de conna�tre la volum�trie de vos objets ?
L'interet de la volumétrie est de pouvoir adapter la taille de vos segments et de vos indexes en fonction de la volumétrie de vos objets. 
En effet, si vous allouez une taille trop grande pour un objet qui n'en a pas besoin, vous allez gaspiller de l'espace disque et potentiellement ralentir les performances de votre base de données. 
A l'inverse, si vous allouez une taille trop petite pour un objet qui en a besoin, vous risquez d'avoir des erreurs d'espace insuffisant et des performances dégradées.
?
-- recalculer le TIS : taille initiale du segment  et recr�er les indexes avec la bonne taille

TIS=initial+(next *(minextents  -1))
Reponse : TIS=65536+(65536*(1-1))=65536

minextents:  est le nombre minimum d'extent que doit avoir un segment.
Un extent est une unité d'allocation de l'espace disque pour un objet de la base de données.
En général, on met minextents à 1 pour les objets qui n'ont pas besoin de beaucoup d'espace, 
et on peut mettre minextents à une valeur plus élevée pour les objets qui ont besoin de plus d'espace.

Extent : Un extent est une unité d'allocation de l'espace disque pour un objet de la base de données.

?
-- Cr�er un index Btree non unique sur la colonne ENAME de la table EMP. 
-- L'index doit �tre localis� dans le tablespace USERS
drop index idx_emp_ename;
create index idx_emp_ename on emp(ename)
tablespace users
storage(
initial 65536
minextents 1
next 65536
pctincrease 0
)
/

-- Cr�er un index concat�n� sur les colonnes Job et Sal de la table EMP. 
-- L'index doit �tre localiser dans le tablespace USERS. Faites aussi en 
-- sorte que 5 transactions puissent �tre inscrites en m�me temps
drop index idx_emp_job_sal;

create index idx_emp_job_sal on emp (job, sal)
initrans 5
tablespace users
storage(
initial 65536
minextents 1
next 65536
pctincrease 0
)
/

--Cr�er un index Bitmap sur la colonne COMM (commission) de la table EMP. 
-- Le localiser dans le tablespace USERS.

drop index idx_emp_comm;
create bitmap index idx_emp_comm on emp(comm)
tablespace users
storage(
initial 65536
minextents 1
next 65536
pctincrease 0
)
/

-- calcul des statistiques sur les objets (tables et indexes) de l'utilisateur &MYUSER
execute dbms_stats.gather_schema_stats('&MYUSER');


-- Reponse :
SQL> execute dbms_stats.gather_schema_stats('&MYUSER');

PL/SQL procedure successfully completed.

SQL> 





--Ecrire une requ�te qui renvoie des informations sur le job et 
--le salaire pour tous les salaires sup�rieurs � 7000 
--et le job �gal � CLERK : d'abord en ramenant toutes les colonnes 
-- puis en ramenant uniquement le job et le salaire.
-- Avant de lancer les requ�tes faire :
-- Set AUTOTRACE ON pour visualiser les plans
-- Copier et coller le r�sultat des requ�tes � la place de ?

Set AUTOTRACE ON
set linesize 300
select *
from emp
where sal>1000 and job='CLERK';

?
SQL> Set AUTOTRACE ON
set linesize 300
select *
from emp
where sal>1000 and job='CLERK';SQL> SQL>   2    3  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10


Execution Plan
----------------------------------------------------------
Plan hash value: 1919314207

-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |     3 |   114 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP             |     3 |   114 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_JOB_SAL |     3 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("JOB"='CLERK' AND "SAL">1000 AND "SAL" IS NOT NULL)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1358  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          2  rows processed

-------------------------------------------------------------------------------------

select/*+FULL (emp)*/ *
from emp
where sal>1000 and job='CLERK';

?
SQL> select/*+FULL (emp)*/ *
from emp
where sal>1000 and job='CLERK';  2    3  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10


Execution Plan
----------------------------------------------------------
Plan hash value: 3956160932

--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     3 |   114 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     3 |   114 |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("JOB"='CLERK' AND "SAL">1000)


Statistics
----------------------------------------------------------
          2  recursive calls
          0  db block gets
          9  consistent gets
          0  physical reads
          0  redo size
       1350  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          2  rows processed

SQL> 
-------------------------------------------------------------------
		  

select job, sal, ename
from emp
where sal>1000 and job='CLERK';

?
SQL> select job, sal, ename
from emp
where sal>1000 and job='CLERK';  2    3  

JOB              SAL ENAME
--------- ---------- ----------
CLERK           1100 ADAMS
CLERK           1300 MILLER


Execution Plan
----------------------------------------------------------
Plan hash value: 1919314207

-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |     3 |    54 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP             |     3 |    54 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_JOB_SAL |     3 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("JOB"='CLERK' AND "SAL">1000 AND "SAL" IS NOT NULL)


Statistics
----------------------------------------------------------
          2  recursive calls
          0  db block gets
          6  consistent gets
          0  physical reads
          0  redo size
        844  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          2  rows processed

SQL> 
------------------------------------------------------------------------------------

select *
from emp
where sal>1000 ;

?
SQL> select *
from emp
where sal>1000 ;  2    3  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7788 SCOTT      ANALYST         7566 09-DEC-82                3000                    20
      7902 FORD       ANALYST         7566 03-DEC-81                3000                    20
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10
      7782 CLARK      MANAGER         7839 09-JUN-81                2450                    10
      7698 BLAKE      MANAGER         7839 01-MAY-81                2850                    30
      7566 JONES      MANAGER         7839 02-APR-81                2975                    20
      7839 KING       PRESIDENT            17-NOV-81                5000                    10
      7521 WARD       SALESMAN        7698 22-FEB-81                1250        500         30
      7654 MARTIN     SALESMAN        7698 28-OCT-81                1250       1400         30
      7844 TURNER     SALESMAN        7698 08-SEP-81                1500          0         30

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7499 ALLEN      SALESMAN        7698 20-FEB-81                1600        300         30

12 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1463968650

-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |    13 |   494 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP             |    13 |   494 |     2   (0)| 00:00:01 |
|*  2 |   INDEX SKIP SCAN                   | IDX_EMP_JOB_SAL |    13 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SAL">1000)
       filter("SAL">1000)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1792  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
         12  rows processed

SQL> 
--------------------------------------------------------------------------------------
select *
from emp
where job='CLERK' ;

?

SQL> select *
from emp
where job='CLERK' ;  2    3  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7369 SMITH      CLERK           7902 17-DEC-80                 800                    20
      7900 JAMES      CLERK           7698 03-DEC-81                 950                    30
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10


Execution Plan
----------------------------------------------------------
Plan hash value: 1919314207

-------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name            | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                 |     3 |   114 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP             |     3 |   114 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_JOB_SAL |     3 |       |     1   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("JOB"='CLERK')


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1438  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          4  rows processed

SQL> 


-----------------------------------------------------------------------------------------------------------
-- Ecrire une requ�te qui permet de visualiser les informations 
-- sur les employ�s dont le num�ro est sup�rieur 7839 et dont la 
-- commission est sup�rieure � 0
-- Avant de lancer les requ�tes faire :
-- Set AUTOTRACE ON pour visualiser les plans

-- Supprimer tous les index et relancer les requ�tes pr�c�dentes

Set AUTOTRACE ON
set linesize 200
select * from emp
where comm >0;

?


SQL> Set AUTOTRACE ON
set linesize 200
select * from emp
where comm >0;SQL> SQL>   2  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7499 ALLEN      SALESMAN        7698 20-FEB-81                1600        300         30
      7521 WARD       SALESMAN        7698 22-FEB-81                1250        500         30
      7654 MARTIN     SALESMAN        7698 28-OCT-81                1250       1400         30


Execution Plan
----------------------------------------------------------
Plan hash value: 3956160932

--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     3 |   114 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     3 |   114 |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("COMM">0)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          7  consistent gets
          0  physical reads
          0  redo size
       1389  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          3  rows processed

SQL> 


------

SELECT * from emp where EMPNO > 7839 and comm >0;

SQL> SELECT * from emp where EMPNO > 7839 and comm >0;

no rows selected


Execution Plan
----------------------------------------------------------
Plan hash value: 2787773736

----------------------------------------------------------------------------------------------
| Id  | Operation                           | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |        |     1 |    38 |     2   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP    |     1 |    38 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | PK_EMP |     2 |       |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("COMM">0)
   2 - access("EMPNO">7839)


Statistics
----------------------------------------------------------
          2  recursive calls
          3  db block gets
          4  consistent gets
          0  physical reads
        564  redo size
       1024  bytes sent via SQL*Net to client
         83  bytes received via SQL*Net from client
          1  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          0  rows processed

SQL> 
-------------------------------------------------------------------------------------------------------------
select /*+INDEX(emp idx_emp_comm)*/ * from emp
where comm >0;

SQL> select /*+INDEX(emp idx_emp_comm)*/ * from emp
where comm >0;  2  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7499 ALLEN      SALESMAN        7698 20-FEB-81                1600        300         30
      7521 WARD       SALESMAN        7698 22-FEB-81                1250        500         30
      7654 MARTIN     SALESMAN        7698 28-OCT-81                1250       1400         30


Execution Plan
----------------------------------------------------------
Plan hash value: 3667944467

----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |              |     3 |   114 |     4   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP          |     3 |   114 |     4   (0)| 00:00:01 |
|   2 |   BITMAP CONVERSION TO ROWIDS       |              |       |       |            |          |
|*  3 |    BITMAP INDEX RANGE SCAN          | IDX_EMP_COMM |       |       |            |          |
----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - access("COMM">0)
       filter("COMM">0)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1414  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          3  rows processed

SQL> 

select count(*) from emp
where comm >0;

?

select * from emp
where comm >0 and empno=7839;

?

set autotrace off
/*
Exercice 4.1

Visualiser avec les diff�rentes m�thodes les plans d'ex�cution de la requ�te suivante :

	 select * from emp  where empno=7934;

-- a) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY() pour lire un plan g�n�r� dans PLAN_TABLE
-- Pas d'ex�cution de la requ�te. Seul le plan est g�n�r� dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase d�veloppement.

-- b) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY_CURSOR(sql_id) pour lire un plan g�n�r� 
-- dans la Zone des requ�tes partag�es (sqlarea). Ce plan est disponible dans les vues V$SQL_PLAN et 
-- V$SQL_PLAN_STATISTICS_ALL. La requ�te est en ex�cution normal. 
-- Cette approche est utile en phase d�veloppement ou en phase production (exploitation).

-- c) Utiliser le param�tre AUTOTRACE pour lire un plan g�n�r� dans la Zone des requ�tes partag�es (sqlarea). 
-- Ce plan est disponible dans les vues V$SQL_PLAN et V$SQL_PLAN_STATISTICS_ALL
-- Voici les effets d'AUTOTRACE : 
--   . set autotrace ON (idem: set autotrace ON EXPLAIN STATISTICS): Affiche le r�sultat+le plan + les statistiques
--   . set autotrace ON EXPLAIN : Affiche le r�sultat+le plan
--   . set autotrace ON STATISTICS : Affiche le r�sultat + les statistiques
--   . set autotrace TRACEONLY : Affiche le plan+les statistiques mais pas le r�sultat
--   . set autotrace TRACEONLY EXPLAIN : Affiche le plan mais pas le r�sultat et pas de statistiques
--   . set autotrace TRACEONLY STATISTICS : : Affiche le statistiques seules mais pas le r�sultat et pas de plan

-- Cette approche est utile en phase d�veloppement uniquement.

-- d) Ecrire sa propre requ�te pour lire un plan g�n�r� dans PLAN_TABLE
-- Pas d'ex�cution de la requ�te. Seul le plan est g�n�r� dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase d�veloppement.

-- e) Utiliser TKPROF pour calculer les temps d'ex�cution de plusieurs requ�tes.
-- G�n�rer le fichier de trace. Bien identifier votre fichier et g�n�rer avec TKPROF les temps mis
-- ansi que les plans d'ex�cution.



*/


-- Visualiser avec les diff�rentes m�thodes les plans d'ex�cution 
-- de la requ�te 
-- suivante :

set autotrace off

select * from emp  where empno=7934;


SQL> set autotrace off                                    

select * from emp  where empno=7934;SQL> SQL> 

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10

SQL> 

-- a) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY() pour lire un plan g�n�r� dans PLAN_TABLE
-- Pas d'ex�cution de la requ�te. Seul le plan est g�n�r� dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase d�veloppement.

Alter session set optimizer_mode=all_rows;
-- Reponse
SQL> Alter session set optimizer_mode=all_rows;

Session altered.

----
delete from plan_table;
--Reponse 
SQL> delete from plan_table;

6 rows deleted.

SQL> 

-----
EXPLAIN PLAN
for select * from emp  where empno=7934;
-- Reponse :
SQL> EXPLAIN PLAN
for select * from emp  where empno=7934;  2  

Explained.

SQL> 

----

set linesize 200

SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY());

?
-- Reponse
SQL> set linesize 200

SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY());SQL> SQL>   2  

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |     1 |    38 |     1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------

   2 - access("EMPNO"=7934)

14 rows selected.

SQL> 

----

-- b) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY_CURSOR(sql_id) pour lire un plan g�n�r� 
-- dans la Zone des requ�tes partag�es (sqlarea). Ce plan est disponible dans les vues V$SQL_PLAN et 
-- V$SQL_PLAN_STATISTICS_ALL. La requ�te est en ex�cution normal. 
-- Cette approche est utile en phase d�veloppement ou en phase production (exploitation).

set pagesize 100
delete from plan_table;

select * from emp  where empno=7934;


SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY_cursor);


-- Reponse

SQL> select * from emp  where empno=7934;

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10

SQL> SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY_cursor);  2  

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  2j2nvhsa4tcna, child number 0
-------------------------------------
select * from emp  where empno=7934

Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |       |       |     1 (100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)|          |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7934)


19 rows selected.


?

------------------

-- '2j2nvhsa4tcna' est le sql_id de votre requ�te
SELECT PLAN_TABLE_OUTPUT 
FROM TABLE
(DBMS_XPLAN.DISPLAY_cursor('2j2nvhsa4tcna'));

?


SQL> SELECT PLAN_TABLE_OUTPUT 
FROM TABLE
(DBMS_XPLAN.DISPLAY_cursor('2j2nvhsa4tcna'));  2    3  

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  2j2nvhsa4tcna, child number 0
-------------------------------------
select * from emp  where empno=7934

Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |       |       |     1 (100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)|          |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7934)


19 rows selected.

SQL> 

-- Si l'utilisation de la fonction display cursor �choue
-- Il s'agit peut �tre d'un probl�me de droit.
-- Ex�cutez alors la commande ci-dessous.
connect sys@&DBALIAS as sysdba;

SQL> connect sys@&DBALIAS as sysdba;
Enter password: 
Connected.
SQL> 
----------
grant execute on dbms_xplan to &MYUSER;
-- Reponse 
SQL> grant execute on dbms_xplan to &MYUSER;
old   1: grant execute on dbms_xplan to &MYUSER
new   1: grant execute on dbms_xplan to ORS1

Grant succeeded.

SQL> 

---
connect &MYUSER@&DBALIAS/PassOrs1;
-- Reponse: 
SQL> connect &MYUSER@&DBALIAS/PassOrs1;
Connected.
SQL> 

----
-- r�ex�cuter la requ�te
SELECT PLAN_TABLE_OUTPUT 
FROM TABLE
(DBMS_XPLAN.DISPLAY_cursor('2j2nvhsa4tcna'));

?
-- Reponse :
SQL> connect &MYUSER@&DBALIAS/PassOrs1;
Connected.
SQL> SELECT PLAN_TABLE_OUTPUT 
FROM TABLE
(DBMS_XPLAN.DISPLAY_cursor('2j2nvhsa4tcna'));  2    3  

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  2j2nvhsa4tcna, child number 0
-------------------------------------
select * from emp  where empno=7934

Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |       |       |     1 (100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)|          |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7934)


19 rows selected.

SQL> 


-- c) Utiliser le param�tre AUTOTRACE pour lire un plan g�n�r� dans la Zone des requ�tes partag�es (sqlarea). 
-- Ce plan est disponible dans les vues V$SQL_PLAN et V$SQL_PLAN_STATISTICS_ALL
-- Voici les effets d'AUTOTRACE : 
--   . set autotrace ON (idem: set autotrace ON EXPLAIN STATISTICS): Affiche le r�sultat+le plan + les statistiques
--   . set autotrace ON EXPLAIN : Affiche le r�sultat+le plan
--   . set autotrace ON STATISTICS : Affiche le r�sultat + les statistiques
--   . set autotrace TRACEONLY : Affiche le plan+les statistiques mais pas le r�sultat
--   . set autotrace TRACEONLY EXPLAIN : Affiche le plan mais pas le r�sultat et pas de statistiques
--   . set autotrace TRACEONLY STATISTICS : : Affiche le statistiques seules mais pas le r�sultat et pas de plan

-- Cette approche est utile en phase d�veloppement uniquement.


delete from plan_table;

-- Reponse :

SQL> delete from plan_table;

0 rows deleted.

SQL> 
-- Si autotrace vaut ON alors  il y aura : affichage du r�sultat, 
-- g�n�ration du plan d'ex�cution et des statistiques d'ex�cution
set autotrace on

set linesize 200
set pagesize 50

select * from emp  where empno=7934;

?

-- Reponse :

SQL> set autotrace on

set linesize 200
set pagesize 50

select * from emp  where empno=7934;SQL> SQL> SQL> SQL> SQL> 

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO
---------- ---------- --------- ---------- ------------------ ---------- ---------- ----------
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10


Execution Plan
----------------------------------------------------------
Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |     1 |    38 |     1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7934)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          2  consistent gets
          0  physical reads
          0  redo size
       1115  bytes sent via SQL*Net to client
         83  bytes received via SQL*Net from client
          1  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed

SQL> 

-- Si autotrace vaut traceonly alors  il y aura : d�sactivation l'affichage 
-- du r�sultat, g�n�ration du plan d'ex�cution et des statistiques d'ex�cution.
set autotrace traceonly
show autotrace
--autotrace TRACEONLY EXPLAIN STATISTICS
--Reponse :

SQL> set autotrace traceonly
show autotraceSQL> 
autotrace TRACEONLY EXPLAIN STATISTICS
SQL> 

------

select * from emp  where empno=7934;

-- Reponse :
SQL> select * from emp  where empno=7934;


Execution Plan
----------------------------------------------------------
Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |     1 |    38 |     1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7934)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          2  consistent gets
          0  physical reads
          0  redo size
       1115  bytes sent via SQL*Net to client
         83  bytes received via SQL*Net from client
          1  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed

SQL> 


-- Si autotrace vaut traceonly explain alors  il y aura : d�sactivation de 
-- l'affichage  du r�sultat, g�n�ration du plan d'ex�cution uniquement.
	  
set autotrace traceonly explain
set linesize 200
show autotrace
--autotrace TRACEONLY EXPLAIN

-- Reponse :
SQL> set autotrace traceonly explain
set linesize 200
show autotraceSQL> SQL> 
autotrace TRACEONLY EXPLAIN
SQL> 

---------------

select * from emp  where empno=7934;

-- Reponse :

SQL> select * from emp  where empno=7934;

Execution Plan
----------------------------------------------------------
Plan hash value: 2949544139

--------------------------------------------------------------------------------------
| Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |        |     1 |    38 |     1   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    38 |     1   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("EMPNO"=7934)

SQL> 

-- Si autotrace vaut traceonly statistics => d�sactivation de l'affichage 
-- du r�sultat, affichage des statistiques uniquement.
set autotrace traceonly statistics
set linesize 200
show autotrace
-- r�sultat de show autotrace 
-- autotrace TRACEONLY EXPLAIN


-- Resultat :

SQL> set autotrace traceonly statistics
set linesize 200
show autotraceSQL> SQL> 
autotrace TRACEONLY STATISTICS
SQL> 

select * from emp  where empno=7934;

--- Resultat :
SQL> select * from emp  where empno=7934;


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          2  consistent gets
          0  physical reads
          0  redo size
       1115  bytes sent via SQL*Net to client
         83  bytes received via SQL*Net from client
          1  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          1  rows processed

SQL> 

-- d) Ecrire sa propre requ�te pour lire un plan g�n�r� dans PLAN_TABLE
-- Pas d'ex�cution de la requ�te. Seul le plan est g�n�r� dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase d�veloppement.

set autotrace off
delete from plan_table;

-- Resultat :

SQL> set autotrace off
delete from plan_table;SQL> 

0 rows deleted.

SQL> 
---

EXPLAIN PLAN
set statement_id='PTEST'  
FOR select * from emp  where empno=7934;

-- Reponse :
SQL> EXPLAIN PLAN
set statement_id='PTEST'  
FOR select * from emp  where empno=7934;  2    3  

Explained.

SQL> 

---------


set linesize 200
col operation format a20
col options format a15
col object_name format a8
col id format 99
col pere format 99
col position format 99
col orig_pos format 99
col optimizer format a12
col card format 9999
col cost format 9999

-- Reponse :
SQL> set linesize 200
col operation format a20
col options format a15
col object_name format a8
col id format 99
col pere format 99
col position format 99
col orig_pos format 99
col optimizer format a12
col card format 9999
col cost format 9999SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> 
SQL> 

---

SELECT OPERATION, OPTIONS, OBJECT_NAME, ID, parent_id "PERE", position "pos", 
OBJECT_INSTANCE "ORIG_POS", optimizer, cost, cardinality "card"
FROM PLAN_TABLE
WHERE STATEMENT_ID='PTEST'
CONNECT BY PRIOR ID=PARENT_ID
AND STATEMENT_ID='PTEST'
START WITH ID=0
AND STATEMENT_ID='PTEST'
ORDER BY ID;

-- Reponse :

SQL> SELECT OPERATION, OPTIONS, OBJECT_NAME, ID, parent_id "PERE", position "pos", 
OBJECT_INSTANCE "ORIG_POS", optimizer, cost, cardinality "card"
FROM PLAN_TABLE
WHERE STATEMENT_ID='PTEST'
CONNECT BY PRIOR ID=PARENT_ID
AND STATEMENT_ID='PTEST'
START WITH ID=0
AND STATEMENT_ID='PTEST'
ORDER BY ID;  2    3    4    5    6    7    8    9  

OPERATION            OPTIONS         OBJECT_N  ID PERE        pos ORIG_POS OPTIMIZER     COST  card
-------------------- --------------- -------- --- ---- ---------- -------- ------------ ----- -----
SELECT STATEMENT                                0               1          ALL_ROWS         1     1
TABLE ACCESS         BY INDEX ROWID  EMP        1    0          1        1 ANALYZED         1     1
INDEX                UNIQUE SCAN     PK_EMP     2    1          1          ANALYZED         0     1

SQL> 


-- e) Utiliser TKPROF pour calculer les temps d'ex�cution de plusieurs requ�tes.
-- G�n�rer le fichier de trace. Bien identifier votre fichier et g�n�rer avec TKPROF les temps mis
-- ansi que les plans d'ex�cution.




--alter session set sql_trace=true;
set autotrace off

EXECUTE sys.dbms_session.set_sql_trace(true);
-- Reponse

SQL> set autotrace off
SQL> EXECUTE sys.dbms_session.set_sql_trace(true);

PL/SQL procedure successfully completed.

----

select ename 
from emp 
where ename='KING';

-- Resultat :

SQL> select ename 
from emp 
where ename='KING';  2    3  

ENAME
----------
KING

SQL> 

------

select dname, ename, sal
from emp e, dept d 
where d.deptno=e.deptno 
and job in ('PRESIDENT', 'CLERK');

--- Resultat :

SQL> select dname, ename, sal
from emp e, dept d 
where d.deptno=e.deptno 
and job in ('PRESIDENT', 'CLERK');  2    3    4  

DNAME          ENAME             SAL
-------------- ---------- ----------
ACCOUNTING     KING             5000
ACCOUNTING     MILLER           1300
RESEARCH       SMITH             800
RESEARCH       ADAMS            1100
SALES          JAMES             950

SQL> 

-------

select dname, ename, sal
from emp e, dept d 
where d.deptno=e.deptno 
and job in ('PRESIDENT', 'CLERK')
order by dname;

-- Resultat :

SQL> select dname, ename, sal
from emp e, dept d 
where d.deptno=e.deptno 
and job in ('PRESIDENT', 'CLERK')
order by dname;  2    3    4    5  

DNAME          ENAME             SAL
-------------- ---------- ----------
ACCOUNTING     KING             5000
ACCOUNTING     MILLER           1300
RESEARCH       SMITH             800
RESEARCH       ADAMS            1100
SALES          JAMES             950

SQL> 

------

--alter session set sql_trace=false;
EXECUTE sys.dbms_session.set_sql_trace(false);

-- Resultat :

SQL> EXECUTE sys.dbms_session.set_sql_trace(false);

PL/SQL procedure successfully completed.


-------

col username format A20
select vs.username, vp.spid 
from v$process vp , v$session vs
where vp.addr=vs.paddr 
and vs.username ='&MYUSER';
 
?
USERNAME             SPID
-------------------- ------------------------
ORS1                 10928

6184

--- resultat :

SQL> col username format A20
select vs.username, vp.spid 
from v$process vp , v$session vs
where vp.addr=vs.paddr 
and vs.username ='&MYUSER';SQL>   2    3    4  
old   4: and vs.username ='&MYUSER'
new   4: and vs.username ='ORS1'

USERNAME             SPID
-------------------- ------------------------
ORS1                 13107
ORS1                 11264

SQL> 
----------------------------------------------------------------------------------
-- Ex�cution de TKPROF pour visualiser les traces d'ex�cution des requ�tes
-- Pour cela vous devez lancer un nouveau CMD (Fen�tre DOS)
-- D�finissez les variable d'environnement DOS suivante :
-- MYSPID, MYINST, TRACEFILESPATH, MYTKPROFUSER
----------------------------------------------------------------------------------

-- D�finir la variable d'environnement DOS qui va contenir la valeur de vp.spid
-- Qui va permettre d'identifier le fichier qui contient la trace tkprof 
set MYSPID=10928

-- D�finir la variable d'environnement DOS qui va contenir le nom de l'instance
set MYINST=COURS21C

-- D�finir la variable d'environnement DOS qui contient le nom user � utiliser 
-- Lors du lancement de tkprof
set MYTKPROFUSER=ORS1

-- D�finir la variable d'environnement DOS qui contient le chemin vers les trace 
-- Oracle. 
set TRACEFILESPATH=%ORACLE_BASE%\diag\rdbms\%MYINST%\%MYINST%\trace

-- for docker 
set TRACEFILESPATH=%ORACLE_BASE%/diag/rdbms/%MYINST%/%MYINST%/trace

set MYTKPROFALIAS=PDBMBDS

--- CAS 1 : Vous avez une base Oracle Locale et vous travaillez avec Oracle 11g
-- ou 12c. Lancer tkprof sous DOS comme suit :

tkprof %TRACEFILESPATH%\%MYINST%_ora_%MYSPID%.trc Exo41_trc.trc EXPLAIN=%MYTKPROFUSER%@%MYTKPROFALIAS%/PassOrs1 SORT = execpu, fchcpu sys=n

-- For Mac
tkprof %TRACEFILESPATH%/%MYINST%_ora_%MYSPID%.trc Exo41_trc.trc EXPLAIN=%MYTKPROFUSER%@%MYTKPROFALIAS%/PassOrs1 SORT = execpu, fchcpu sys=n


-- Ouvrir ensuite le fichier Exo41_trc.trc avec un �diteur de texte ... on y les extraits suivants
notepad++ Exo41_trc.trc

-- Exemple d'extrait de de r�sultat 
?





-- CAS 2 : Vous n'avez pas de base Oracle Locale , et vous acc�dez � une base distante 
-- Par exemple ma base DBCOURS dans le r�seau de l'Universit� de appel�
-- 

-- R�cup�rer votre SPID en �x�cutant le code ci-dessous

set serveroutput on
declare
myUsernaName varchar2(30):='&MYUSER';
mySpid varchar2(30);
begin
mySpid:=pk_manageTrcFile.getMySpid(myUsernaName);

dbms_output.put_line(mySpid);
end;
/
old   2: myUsernaName varchar2(30):='&MYUSER';
new   2: myUsernaName varchar2(30):='PDBADMIN';
13117
5304
-- Affichage du contenu d'un fichier de trace g�n�r� avec TKPROF
--
set serveroutput on
declare
v_clob clob;
mySpid varchar2(10):='xxxx' ;--'5304'; -- remplacer le spid ici par celui obtenu plus haut
myInstanceName varchar2(10):='&MYINSTANCE';
begin
v_clob:=pk_manageTrcFile.displayMyTkprofTrace(mySpid, myInstanceName);
dbms_output.put_line(v_clob);
Exception 
		when others then
			dbms_output.put_line('Fichier de traces inexistant');
			dbms_output.put_line('sqlcode='||sqlcode);
			dbms_output.put_line('sqlerrm='||sqlerrm);

end;
/
		  
/*
HINTS ou Suggestions 

Exercice 5.1 

Ajouter dans la table des EMP une colonne SEXE de type CHAR(1) qui 
peut prendre l'une des valeurs suivantes :
F : pour F�minin
M : Masculin

Modifier les lignes existantes et faire en sorte que 50% des Employ�s soient de type F et l'autre moiti� de type M

Cr�er un index sur la colonne SEXE

Analyser la table avec la commande suivante
EXECUTE DBMS_STATS.Gather_table_stats('EMP')

Ecrire une requ�te qui renvoit les informations sur les employ�s de sexe masculin

En cas d'utilisation des index utiliser les HINTS pour d�sactiver l'index. En cas de non utilisation faire l'inverse.

Influencer le mode d'optimisation en choisissant le mode RULE

Refaire l'exercice avec les tables BIGEMP2 (environ 130000 lignes)
		  
*/
-- Exercice 5.1 

-- Ajouter dans la table des EMP une colonne 
-- SEXE de type CHAR(1) qui peut prendre 
-- l'une des valeurs suivantes :
-- F : pour F�minin
-- M : Masculin
ALTER TABLE EMP 
ADD (SEXE char(1) 
constraint chk_emp_sexe check(sexe in ('F','M')));

--resultat

SQL> ALTER TABLE EMP 
ADD (SEXE char(1) 
constraint chk_emp_sexe check(sexe in ('F','M')));  2    3  

Table altered.

SQL> 

-- Modifier les lignes existantes et faire en 
-- sorte que 50% des Employ�s soient 
-- de type F et l'autre moiti� de type M
update emp
set sexe='F'
where empno <7788;
update emp
set sexe='M'
where empno >=7788;
commit;

-- resultat

SQL> update emp
set sexe='F'
where empno <7788;
update emp
set sexe='M'
where empno >=7788;
commit;  2    3  
7 rows updated.

SQL>   2    3  
7 rows updated.

SQL> 
-- Cr�er un index sur la colonne SEXE
drop index IDX_EMP_SEXE;
CREATE INDEX IDX_EMP_SEXE ON EMP(SEXE);

-- resultat: 

SQL> drop index IDX_EMP_SEXE;
drop index IDX_EMP_SEXE
           *
ERROR at line 1:
ORA-01418: specified index does not exist
Help: https://docs.oracle.com/error-help/db/ora-01418/


SQL> CREATE INDEX IDX_EMP_SEXE ON EMP(SEXE);

Index created.

SQL> 



-- bAnalyser la table avec la commande suivante
EXECUTE DBMS_STATS.Gather_table_stats('&MYUSER', 'EMP');

-- resultat 

SQL> EXECUTE DBMS_STATS.Gather_table_stats('&MYUSER', 'EMP');


PL/SQL procedure successfully completed.

SQL> SQL> 


-- Ecrire une requ�te qui renvoit les informations sur 
--les employ�s de sexe masculin
set autotrace on
set linesize 200
alter session set optimizer_mode=all_rows;
select * from emp
where sexe='M';

--- Resultat :

SQL> set autotrace on
set linesize 200
alter session set optimizer_mode=all_rows;
select * from emp
where sexe='M';SQL> SQL> 
Session altered.

SQL>   2  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO S
---------- ---------- --------- ---------- ------------------ ---------- ---------- ---------- -
      7788 SCOTT      ANALYST         7566 09-DEC-82                3000                    20 M
      7839 KING       PRESIDENT            17-NOV-81                5000                    10 M
      7844 TURNER     SALESMAN        7698 08-SEP-81                1500          0         30 M
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20 M
      7900 JAMES      CLERK           7698 03-DEC-81                 950                    30 M
      7902 FORD       ANALYST         7566 03-DEC-81                3000                    20 M
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10 M

7 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1577150843

----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |              |     7 |   280 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP          |     7 |   280 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_SEXE |     7 |       |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SEXE"='M')


Statistics
----------------------------------------------------------
         24  recursive calls
          3  db block gets
         22  consistent gets
          0  physical reads
        612  redo size
       1672  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          7  rows processed

SQL> 

-- En cas d'utilisation des index utiliser 
-- les HINTS pour d�sactiver l'index. En cas 
-- de non utilisation faire l'inverse.
select  /*+ NO_INDEX(EMP IDX_EMP_SEXE) */ * from emp
where sexe='M';

-- Resultat : 
SQL> select  /*+ NO_INDEX(EMP IDX_EMP_SEXE) */ * from emp
where sexe='M';  2  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO S
---------- ---------- --------- ---------- ------------------ ---------- ---------- ---------- -
      7788 SCOTT      ANALYST         7566 09-DEC-82                3000                    20 M
      7839 KING       PRESIDENT            17-NOV-81                5000                    10 M
      7844 TURNER     SALESMAN        7698 08-SEP-81                1500          0         30 M
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20 M
      7900 JAMES      CLERK           7698 03-DEC-81                 950                    30 M
      7902 FORD       ANALYST         7566 03-DEC-81                3000                    20 M
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10 M

7 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3956160932

--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |     7 |   280 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |     7 |   280 |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("SEXE"='M')


Statistics
----------------------------------------------------------
          8  recursive calls
          0  db block gets
          9  consistent gets
          0  physical reads
          0  redo size
       1642  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          7  rows processed

SQL> 

-- Influencer le mode d'optimisation en choisissant 
-- le mode RULE. Dans ce mode il est impossible de d�sactiver
-- l'index


select /*+RULE NO_INDEX(EMP IDX_EMP_SEXE) */ 
* from emp
where sexe='M';

SQL> select /*+RULE NO_INDEX(EMP IDX_EMP_SEXE) */ 
* from emp
where sexe='M';  2    3  

     EMPNO ENAME      JOB              MGR HIREDATE                  SAL       COMM     DEPTNO S
---------- ---------- --------- ---------- ------------------ ---------- ---------- ---------- -
      7788 SCOTT      ANALYST         7566 09-DEC-82                3000                    20 M
      7839 KING       PRESIDENT            17-NOV-81                5000                    10 M
      7844 TURNER     SALESMAN        7698 08-SEP-81                1500          0         30 M
      7876 ADAMS      CLERK           7788 12-JAN-83                1100                    20 M
      7900 JAMES      CLERK           7698 03-DEC-81                 950                    30 M
      7902 FORD       ANALYST         7566 03-DEC-81                3000                    20 M
      7934 MILLER     CLERK           7782 23-JAN-82                1300                    10 M

7 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 4264975279

----------------------------------------------------
| Id  | Operation                   | Name         |
----------------------------------------------------
|   0 | SELECT STATEMENT            |              |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP          |
|*  2 |   INDEX RANGE SCAN          | IDX_EMP_SEXE |
----------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SEXE"='M')

Note
-----
   - rule based optimizer used (consider using cbo)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1672  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          7  rows processed

SQL> 

-- Refaire l'exercice avec les tables BIGEMP2 (environ 130000 lignes)
set autotrace off

sql>@&SCRIPTPATH/BigEmp2.sql

ALTER TABLE BIGEMP2 
ADD (SEXE char(1) 
constraint chk_bigemp2_sexe check(sexe in ('F','M')));

-- Resultat: 

SQL> ALTER TABLE BIGEMP2 
ADD (SEXE char(1) 
constraint chk_bigemp2_sexe check(sexe in ('F','M')));  2    3  

Table altered.




-- Modifier les lignes existantes et faire en 
-- sorte que 50% des Employ�s soient 
-- de type F et l'autre moiti� de type M
update bigemp2
set sexe='F'
where rownum <65007;
update bigemp2
set sexe='M'
where sexe is null ;
commit;

-- Cr�er un index sur la colonne SEXE
CREATE INDEX IDX_bigemp2_SEXE ON bigemp2(SEXE);

-- bAnalyser la table avec la commande suivante
EXECUTE DBMS_STATS.Gather_table_stats('&MYUSER', 'bigemp2');

-- Ecrire une requ�te qui renvoit les informations sur 
--les employ�s de sexe masculin
set autotrace traceonly;
set linesize 200
alter session set optimizer_mode=all_rows;
select * from bigemp2
where sexe='M';


-- resultat : 

SQL> set autotrace traceonly;
set linesize 200
alter session set optimizer_mode=all_rows;
select * from bigemp2
where sexe='M';SQL> SQL> 
Session altered.

SQL>   2  

?

-- En cas d'utilisation des index utiliser 
-- les HINTS pour d�sactiver l'index. En cas 
-- de non utilisation faire l'inverse.
select  /*+INDEX(BIGEMP2 IDX_BIGEMP2_SEXE) */ * from bigemp2
where sexe='M';

-- resultat :
SQL> select  /*+INDEX(BIGEMP2 IDX_BIGEMP2_SEXE) */ * from bigemp2
where sexe='M';  2  

65008 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1895117924

--------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                  | 65007 |  2666K|   518   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| BIGEMP2          | 65007 |  2666K|   518   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_BIGEMP2_SEXE | 65007 |       |   118   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SEXE"='M')


Statistics
----------------------------------------------------------
         34  recursive calls
         45  db block gets
       9143  consistent gets
          0  physical reads
       8420  redo size
    3892927  bytes sent via SQL*Net to client
     108433  bytes received via SQL*Net from client
       4335  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
      65008  rows processed

SQL> 

-- Influencer le mode d'optimisation en choisissant 
-- le mode RULE

select /*+RULE NO_INDEX(BIGEMP2 IDX_BIGEMP2_SEXE) */ 
* from bigemp2
where sexe='M';

-- resultat :
SQL> select /*+RULE NO_INDEX(BIGEMP2 IDX_BIGEMP2_SEXE) */ 
* from bigemp2
where sexe='M';  2    3  

65008 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 4083080426

--------------------------------------------------------
| Id  | Operation                   | Name             |
--------------------------------------------------------
|   0 | SELECT STATEMENT            |                  |
|   1 |  TABLE ACCESS BY INDEX ROWID| BIGEMP2          |
|*  2 |   INDEX RANGE SCAN          | IDX_BIGEMP2_SEXE |
--------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("SEXE"='M')

Note
-----
   - rule based optimizer used (consider using cbo)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
       9131  consistent gets
          0  physical reads
          0  redo size
    3892927  bytes sent via SQL*Net to client
     108433  bytes received via SQL*Net from client
       4335  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
      65008  rows processed

SQL> 

select table_name, blocks 
from user_tables 
where table_name in ('EMP', 'BIGEMP2');

-- resultat :
SQL> select table_name, blocks 
from user_tables 
where table_name in ('EMP', 'BIGEMP2');  2    3  


Execution Plan
----------------------------------------------------------
Plan hash value: 741861194

--------------------------------------------------------------------------------------------------------------------
| Id  | Operation                                      | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                               |                   |     1 |   187 |    10   (0)| 00:00:01 |
|*  1 |  FILTER                                        |                   |       |       |            |          |
|   2 |   NESTED LOOPS OUTER                           |                   |     1 |   187 |    10   (0)| 00:00:01 |
|   3 |    NESTED LOOPS                                |                   |     1 |   183 |     9   (0)| 00:00:01 |
|   4 |     NESTED LOOPS OUTER                         |                   |     1 |   158 |     8   (0)| 00:00:01 |
|   5 |      NESTED LOOPS OUTER                        |                   |     1 |   150 |     7   (0)| 00:00:01 |
|   6 |       NESTED LOOPS                             |                   |     1 |   138 |     6   (0)| 00:00:01 |
|   7 |        NESTED LOOPS OUTER                      |                   |     1 |   135 |     5   (0)| 00:00:01 |
|   8 |         NESTED LOOPS                           |                   |     1 |   109 |     5   (0)| 00:00:01 |
|   9 |          MERGE JOIN CARTESIAN                  |                   |     1 |    81 |     4   (0)| 00:00:01 |
|  10 |           NESTED LOOPS                         |                   |     1 |    39 |     0   (0)| 00:00:01 |
|* 11 |            FIXED TABLE FIXED INDEX             | X$KSPPI (ind:1)   |     1 |    32 |     0   (0)| 00:00:01 |
|* 12 |            FIXED TABLE FIXED INDEX             | X$KSPPCV (ind:1)  |     1 |     7 |     0   (0)| 00:00:01 |
|  13 |           BUFFER SORT                          |                   |     1 |    42 |     4   (0)| 00:00:01 |
|  14 |            INLIST ITERATOR                     |                   |       |       |            |          |
|* 15 |             TABLE ACCESS BY INDEX ROWID BATCHED| OBJ$              |     1 |    42 |     4   (0)| 00:00:01 |
|* 16 |              INDEX RANGE SCAN                  | I_OBJ5            |     1 |       |     3   (0)| 00:00:01 |
|* 17 |          TABLE ACCESS CLUSTER                  | TAB$              |     1 |    28 |     1   (0)| 00:00:01 |
|* 18 |           INDEX UNIQUE SCAN                    | I_OBJ#            |     1 |       |     0   (0)| 00:00:01 |
|* 19 |         INDEX RANGE SCAN                       | I_IMSVC1          |     1 |    26 |     0   (0)| 00:00:01 |
|  20 |        TABLE ACCESS CLUSTER                    | TS$               |     1 |     3 |     1   (0)| 00:00:01 |
|* 21 |         INDEX UNIQUE SCAN                      | I_TS#             |     1 |       |     0   (0)| 00:00:01 |
|  22 |       TABLE ACCESS CLUSTER                     | SEG$              |     1 |    12 |     1   (0)| 00:00:01 |
|* 23 |        INDEX UNIQUE SCAN                       | I_FILE#_BLOCK#    |     1 |       |     0   (0)| 00:00:01 |
|* 24 |      INDEX RANGE SCAN                          | I_OBJ1            |     1 |     8 |     1   (0)| 00:00:01 |
|* 25 |     INDEX RANGE SCAN                           | I_USER2           |     1 |    25 |     1   (0)| 00:00:01 |
|* 26 |    INDEX RANGE SCAN                            | I_USER2           |     1 |     4 |     1   (0)| 00:00:01 |
|* 27 |   TABLE ACCESS BY INDEX ROWID BATCHED          | USER_EDITIONING$  |     1 |     6 |     2   (0)| 00:00:01 |
|* 28 |    INDEX RANGE SCAN                            | I_USER_EDITIONING |     2 |       |     1   (0)| 00:00:01 |
|* 29 |   TABLE ACCESS BY INDEX ROWID BATCHED          | USER_EDITIONING$  |     1 |     6 |     2   (0)| 00:00:01 |
|* 30 |    INDEX RANGE SCAN                            | I_USER_EDITIONING |     2 |       |     1   (0)| 00:00:01 |
|  31 |   NESTED LOOPS SEMI                            |                   |     1 |    29 |     2   (0)| 00:00:01 |
|* 32 |    INDEX SKIP SCAN                             | I_USER2           |     1 |    20 |     1   (0)| 00:00:01 |
|* 33 |    INDEX RANGE SCAN                            | I_OBJ4            |     1 |     9 |     1   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter(BITAND("U"."SPARE1",16)=0 OR BITAND("O"."FLAGS",1048576)=1048576 OR "O"."TYPE#"<>88 AND  NOT
              EXISTS (SELECT 0 FROM "SYS"."USER_EDITIONING$" "UE" WHERE "UE"."USER#"=:B1 AND "TYPE#"=:B2) OR  EXISTS
              (SELECT 0 FROM "SYS"."USER_EDITIONING$" "UE" WHERE "UE"."USER#"=:B3 AND "UE"."TYPE#"=:B4) AND
              (SYS_CONTEXT('userenv','current_edition_name')='ORA$BASE' AND "U"."TYPE#"<>2 OR "U"."TYPE#"=2 AND
              "U"."SPARE2"=TO_NUMBER(SYS_CONTEXT('userenv','current_edition_id')) OR  EXISTS (SELECT 0 FROM "SYS"."USER$"
              "U2","SYS"."OBJ$" "O2" WHERE "O2"."OWNER#"="U2"."USER#" AND "O2"."TYPE#"=88 AND "O2"."DATAOBJ#"=:B5 AND
              "U2"."TYPE#"=2 AND "U2"."SPARE2"=TO_NUMBER(SYS_CONTEXT('userenv','current_edition_id')))))
  11 - filter("KSPPINM"='_dml_monitoring_enabled' AND ("CON_ID"=0 OR "CON_ID"=3))
  12 - filter("INDX"="INDX" AND ("CON_ID"=0 OR "CON_ID"=3))
  15 - filter(BITAND("O"."FLAGS",128)=0)
  16 - access("O"."SPARE3"=USERENV('SCHEMAID') AND ("O"."NAME"='BIGEMP2' OR "O"."NAME"='EMP'))
  17 - filter(BITAND("T"."PROPERTY",1)=0 AND BITAND("T"."PROPERTY",36893488147419103232)=0)
  18 - access("O"."OBJ#"="T"."OBJ#")
  19 - access("T"."OBJ#"="SVC"."OBJ#"(+) AND "SVC"."SUBPART#"(+) IS NULL)
  21 - access("T"."TS#"="TS"."TS#")
  23 - access("T"."TS#"="S"."TS#"(+) AND "T"."FILE#"="S"."FILE#"(+) AND "T"."BLOCK#"="S"."BLOCK#"(+))
  24 - access("T"."BOBJ#"="CO"."OBJ#"(+))
  25 - access("O"."OWNER#"="U"."USER#")
  26 - access("CO"."OWNER#"="CU"."USER#"(+))
  27 - filter("TYPE#"=:B1)
  28 - access("UE"."USER#"=:B1)
  29 - filter("UE"."TYPE#"=:B1)
  30 - access("UE"."USER#"=:B1)
  32 - access("U2"."TYPE#"=2 AND "U2"."SPARE2"=TO_NUMBER(SYS_CONTEXT('userenv','current_edition_id')))
       filter("U2"."TYPE#"=2 AND "U2"."SPARE2"=TO_NUMBER(SYS_CONTEXT('userenv','current_edition_id')))
  33 - access("O2"."DATAOBJ#"=:B1 AND "O2"."TYPE#"=88 AND "O2"."OWNER#"="U2"."USER#")

Note
-----
   - this is an adaptive plan

SQL Analysis Report (identified by operation id/Query Block Name/Object Alias):
-------------------------------------------------------------------------------

   1 -  SEL$5E5254C2
           -  The query block has 1 cartesian product which may be
              expensive. Consider adding join conditions or removing the
              disconnected tables or views.


Statistics
----------------------------------------------------------
         74  recursive calls
          0  db block gets
         69  consistent gets
          1  physical reads
          0  redo size
        749  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          1  sorts (memory)
          0  sorts (disk)
          2  rows processed

SQL> 

/*
Exercice 5.2
5.2.1 Calcul de statistiques avec la commande ANALYZE
Calculer les statistiques sur les colonnes de les tables EMP et BIGEMP2
et ces index en utilisant la commande ANALYZE 

Afficher via des requ�tes SQL les informations concernant les statistiques

Sur les tables EMP et BIGEMP2
Sur les colonnes des tables EMP et BIGEMP2
Sur les Index des tables EMP et BIGEMP2

Nota : Bien identifier les tables ou trouver les statistiques

5.2.2 Mesurer l'effet des statistiques LOW_VALUE et HIGH_VALUE sur les tables
EMP et BIGEMP2 en consid�rant la colonne ENAME


*/

--5.2.1 Calcul de statistiques avec la commande ANALYZE

-- Calculer les statistiques sur les tables EMP et BIGEMP2,leurs colonnes  
-- et leurs index en utilisant la commande ANALYZE 
set autotrace off
ANALYZE TABLE EMP COMPUTE STATISTICS;

--resultat :
SQL> ANALYZE TABLE EMP COMPUTE STATISTICS;

Table analyzed.

SQL> 

---
ANALYZE TABLE BIGEMP2 COMPUTE STATISTICS;

-- resultat :
SQL> ANALYZE TABLE BIGEMP2 COMPUTE STATISTICS;


Table analyzed.

-- Afficher via une requ�te SQL les informations 
-- concernant les statistiques

-- Sur les tables EMP et BIGEMP2 � partir la vue user_tables
col table_name format a12
col num_rows format 9999999
set linesize 300
set pagesize 300
select
table_name,
num_rows,
Blocks,
empty_blocks,
avg_space,
chain_cnt,
avg_row_len 
FROM user_tables
WHERE table_name IN ('EMP', 'BIGEMP2');

-- resultat :


SQL> SQL> col table_name format a12
col num_rows format 9999999
set linesize 300
set pagesize 300
select
table_name,
num_rows,
Blocks,
empty_blocks,
avg_space,
chain_cnt,
avg_row_len 
FROM user_tables
WHERE table_name IN ('EMP', 'BIGEMP2');SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10  

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
BIGEMP2        130014        874           22        654          0          44
EMP                14          5            3       7949          0          42

SQL> 

-- sur les tables EMP et BIGEMP2 avec la vue user_tab_statistics
set linesize 300
set pagesize 300
col blocks format 9999
col EMPTY_BLOCKS format 9999
col table_name format a10
col num_rows format 9999999
col CHAIN_CNT format 9999
col AVG_SPACE  format 9999
col AVG_ROW_LEN   format 9999
col AVG_SPACE_FLST_BLKS  format 9999
col NUM_FLST_BLKS   format 9999
col AVG_CACHD_BLKS   format 9999
col AVG_CACHE_HIT_R  format 9999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS AVG_SPACE_FLST_BLKS,
NUM_FREELIST_BLOCKS NUM_FLST_BLKS,
AVG_CACHED_BLOCKS AVG_CACHD_BLKS, 
AVG_CACHE_HIT_RATIO AVG_CACHE_HIT_R
from user_tab_statistics
where table_name IN ('EMP','BIGEMP2');

-- resultat :


SQL> set linesize 300
set pagesize 300
col blocks format 9999
col EMPTY_BLOCKS format 9999
col table_name format a10
col num_rows format 9999999
col CHAIN_CNT format 9999
col AVG_SPACE  format 9999
col AVG_ROW_LEN   format 9999
col AVG_SPACE_FLST_BLKS  format 9999
col NUM_FLST_BLKS   format 9999
col AVG_CACHD_BLKS   format 9999
col AVG_CACHE_HIT_R  format 9999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS AVG_SPACE_FLST_BLKS,
NUM_FREELIST_BLOCKS NUM_FLST_BLKS,
AVG_CACHED_BLOCKS AVG_CACHD_BLKS, 
AVG_CACHE_HIT_RATIO AVG_CACHE_HIT_R
from user_tab_statistics
where table_name IN ('EMP','BIGEMP2');SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14  

TABLE_NAME NUM_ROWS BLOCKS EMPTY_BLOCKS AVG_SPACE CHAIN_CNT AVG_ROW_LEN AVG_SPACE_FLST_BLKS NUM_FLST_BLKS AVG_CACHD_BLKS AVG_CACHE_HIT_R
---------- -------- ------ ------------ --------- --------- ----------- ------------------- ------------- -------------- ---------------
BIGEMP2      130014    874           22       654         0          44                   0             0
EMP              14      5            3      7949         0          42                   0             0

SQL> 

-- Sur les colonnes des tables EMP et BIGEMP2 avec la vue user_tab_columns
set linesize 300
set pagesize 300
col table_name format a12
col COLUMN_NAME format a12
col LOW_VALUE format a20
col HIGH_VALUE format a20


select
table_name,
column_name,
num_distinct,
low_value,
High_value,
NUM_BUCKETS, 
DENSITY,        
NUM_NULLS
from user_tab_columns
where table_name IN ('EMP','BIGEMP2')
order by table_name, column_name;

-- resultat :

SQL> set linesize 300
set pagesize 300
col table_name format a12
col COLUMN_NAME format a12
col LOW_VALUE format a20
col HIGH_VALUE format a20


select
table_name,
column_name,
num_distinct,
low_value,
High_value,
NUM_BUCKETS, 
DENSITY,        
NUM_NULLS
from user_tab_columns
where table_name IN ('EMP','BIGEMP2')
order by table_name, column_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12  

TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE           NUM_BUCKETS    DENSITY  NUM_NULLS
------------ ------------ ------------ -------------------- -------------------- ----------- ---------- ----------
BIGEMP2      COMM                    4 80                   C20F                           1        .25      90010
BIGEMP2      DEPTNO                  3 C10B                 C11F                           1 .333333333          0
BIGEMP2      EMPNO              130014 C24A46               C30E5023                       1 7.6915E-06          0
BIGEMP2      ENAME                  34 4144414D53           5A656D626C61                   1 .029411765          0
BIGEMP2      HIREDATE               13 77B40C11010101       77B7010C010101                 1 .076923077          0
BIGEMP2      JOB                     5 414E414C595354       53414C45534D414E               1         .2          0
BIGEMP2      MGR                     6 C24C43               C25003                         1 .166666667          1
BIGEMP2      SAL                    12 C209                 C233                           1 .083333333          0
BIGEMP2      SEXE                    2 46                   4D                             1         .5          0
EMP          COMM                    4 80                   C20F                           1        .25         10
EMP          DEPTNO                  3 C10B                 C11F                           1 .333333333          0
EMP          EMPNO                  14 C24A46               C25023                         1 .071428571          0
EMP          ENAME                  14 4144414D53           57415244                       1 .071428571          0
EMP          HIREDATE               13 77B40C11010101       77B7010C010101                 1 .076923077          0
EMP          JOB                     5 414E414C595354       53414C45534D414E               1         .2          0
EMP          MGR                     6 C24C43               C25003                         1 .166666667          1
EMP          SAL                    12 C209                 C233                           1 .083333333          0
EMP          SEXE                    2 46                   4D                             1         .5          0

18 rows selected.

SQL> 

-- Sur les colonnes les tables EMP et BIGEMP2 avec la vue user_tab_col_statistics
set linesize 300
set pagesize 300
col table_name format a10
col column_name format a10
col NUM_DISTINCT format 999999
col HISTOGRAM format A4
col LOW_VALUE format A15
col HIGH_VALUE format A17


SELECT
TABLE_NAME ,
COLUMN_NAME, 
NUM_DISTINCT,
LOW_VALUE,
HIGH_VALUE ,
DENSITY,  
NUM_NULLS,
NUM_BUCKETS, 
SAMPLE_SIZE,
GLOBAL_STATS,
USER_STATS ,
AVG_COL_LEN,
HISTOGRAM
FROM user_tab_col_statistics
where table_name IN ('EMP','BIGEMP2')
order by table_name;

-- resultat :

SQL> set linesize 300
set pagesize 300
col table_name format a10
col column_name format a10
col NUM_DISTINCT format 999999
col HISTOGRAM format A4
col LOW_VALUE format A15
col HIGH_VALUE format A17


SELECT
TABLE_NAME ,
COLUMN_NAME, 
NUM_DISTINCT,
LOW_VALUE,
HIGH_VALUE ,
DENSITY,  
NUM_NULLS,
NUM_BUCKETS, 
SAMPLE_SIZE,
GLOBAL_STATS,
USER_STATS ,
AVG_COL_LEN,
HISTOGRAM
FROM user_tab_col_statistics
where table_name IN ('EMP','BIGEMP2')
order by table_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17  

TABLE_NAME COLUMN_NAM NUM_DISTINCT LOW_VALUE       HIGH_VALUE           DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE AVG_COL_LEN HIST
---------- ---------- ------------ --------------- ----------------- ---------- ---------- ----------- ----------- --- --- ----------- ----
BIGEMP2    EMPNO            130014 C24A46          C30E5023          7.6915E-06          0           1      130014 NO  NO            4 NONE
BIGEMP2    ENAME                34 4144414D53      5A656D626C61      .029411765          0           1      130014 NO  NO            6 NONE
BIGEMP2    SEXE                  2 46              4D                        .5          0           1      130014 NO  NO            1 NONE
BIGEMP2    DEPTNO                3 C10B            C11F              .333333333          0           1      130014 NO  NO            2 NONE
BIGEMP2    COMM                  4 80              C20F                     .25      90010           1      130014 NO  NO            2 NONE
BIGEMP2    SAL                  12 C209            C233              .083333333          0           1      130014 NO  NO            3 NONE
BIGEMP2    HIREDATE             13 77B40C11010101  77B7010C010101    .076923077          0           1      130014 NO  NO            7 NONE
BIGEMP2    MGR                   6 C24C43          C25003            .166666667          1           1      130014 NO  NO            3 NONE
BIGEMP2    JOB                   5 414E414C595354  53414C45534D414E          .2          0           1      130014 NO  NO            7 NONE
EMP        EMPNO                14 C24A46          C25023            .071428571          0           1          14 NO  NO            3 NONE
EMP        DEPTNO                3 C10B            C11F              .333333333          0           1          14 NO  NO            2 NONE
EMP        COMM                  4 80              C20F                     .25         10           1          14 NO  NO            2 NONE
EMP        SAL                  12 C209            C233              .083333333          0           1          14 NO  NO            3 NONE
EMP        SEXE                  2 46              4D                        .5          0           1          14 NO  NO            1 NONE
EMP        MGR                   6 C24C43          C25003            .166666667          1           1          14 NO  NO            3 NONE
EMP        JOB                   5 414E414C595354  53414C45534D414E          .2          0           1          14 NO  NO            7 NONE
EMP        ENAME                14 4144414D53      57415244          .071428571          0           1          14 NO  NO            5 NONE
EMP        HIREDATE             13 77B40C11010101  77B7010C010101    .076923077          0           1          14 NO  NO            7 NONE

18 rows selected.

SQL> 

-- Sur les Index des tables EMP et BIGEMP2 avec la vue user_indexes
set linesize 300
set pagesize 300
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999


select
table_name,
index_name,
BLEVEL,
LEAF_BLOCKS,
DISTINCT_KEYS,
AVG_LEAF_BLOCKS_PER_KEY,
AVG_DATA_BLOCKS_PER_KEY,
CLUSTERING_FACTOR	
from user_indexes
where table_name IN ('EMP', 'BIGEMP2')
order by table_name;


--resultat :

SQL> set linesize 300
set pagesize 300
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999


select
table_name,
index_name,
BLEVEL,
LEAF_BLOCKS,
DISTINCT_KEYS,
AVG_LEAF_BLOCKS_PER_KEY,
AVG_DATA_BLOCKS_PER_KEY,
CLUSTERING_FACTOR
from user_indexes
where table_name IN ('EMP', 'BIGEMP2')
order by table_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12  

TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR
------------ -------------------- ---------- ----------- ------------- ----------------------- ----------------------- -----------------
BIGEMP2      IDX_BIGEMP2_SEXE              1         236             2                     118                     398               797
BIGEMP2      PK_BIGEMP2                    1         244        130014                       1                       1              1003
EMP          IDX_EMP_JOB_SAL               0           1            12                       1                       1                 1
EMP          IDX_EMP_COMM                  0           1             5                       1                       1                 5
EMP          IDX_EMP_SEXE                  0           1             2                       1                       1                 1
EMP          PK_EMP                        0           1            14                       1                       1                 1
EMP          IDX_EMP_ENAME                 0           1            14                       1                       1                 1

7 rows selected.

SQL> 



-- Sur les Index les tables EMP et BIGEMP2 avec la vue user_ind_statistics
set linesize 300
set pagesize 300
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999



SELECT
 TABLE_NAME ,
 INDEX_NAME ,  
 BLEVEL   ,
 LEAF_BLOCKS,
 DISTINCT_KEYS , 
 AVG_LEAF_BLOCKS_PER_KEY ,
 AVG_DATA_BLOCKS_PER_KEY ,
 CLUSTERING_FACTOR   ,
 NUM_ROWS    
FROM user_ind_statistics
where table_name in ('EMP','BIGEMP2')
order by table_name;


-- resultat :
SQL> set linesize 300
set pagesize 300
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999


select
table_name,
index_name,
BLEVEL,
LEAF_BLOCKS,
DISTINCT_KEYS,
AVG_LEAF_BLOCKS_PER_KEY,
AVG_DATA_BLOCKS_PER_KEY,
CLUSTERING_FACTOR
from user_indexes
where table_name IN ('EMP', 'BIGEMP2')
order by table_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12  

TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR
------------ -------------------- ---------- ----------- ------------- ----------------------- ----------------------- -----------------
BIGEMP2      IDX_BIGEMP2_SEXE              1         236             2                     118                     398               797
BIGEMP2      PK_BIGEMP2                    1         244        130014                       1                       1              1003
EMP          IDX_EMP_JOB_SAL               0           1            12                       1                       1                 1
EMP          IDX_EMP_COMM                  0           1             5                       1                       1                 5
EMP          IDX_EMP_SEXE                  0           1             2                       1                       1                 1
EMP          PK_EMP                        0           1            14                       1                       1                 1
EMP          IDX_EMP_ENAME                 0           1            14                       1                       1                 1

7 rows selected.

SQL> set linesize 300
set pagesize 300
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999



SELECT
 TABLE_NAME ,
 INDEX_NAME ,  
 BLEVEL   ,
 LEAF_BLOCKS,
 DISTINCT_KEYS , 
 AVG_LEAF_BLOCKS_PER_KEY ,
 AVG_DATA_BLOCKS_PER_KEY ,
 CLUSTERING_FACTOR   ,
 NUM_ROWS    
FROM user_ind_statistics
where table_name in ('EMP','BIGEMP2')
order by table_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13  

TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR NUM_ROWS
------------ -------------------- ---------- ----------- ------------- ----------------------- ----------------------- ----------------- --------
BIGEMP2      PK_BIGEMP2                    1         244        130014                       1                       1              1003   130014
BIGEMP2      IDX_BIGEMP2_SEXE              1         236             2                     118                     398               797   130014
EMP          IDX_EMP_JOB_SAL               0           1            12                       1                       1                 1       14
EMP          IDX_EMP_SEXE                  0           1             2                       1                       1                 1       14
EMP          IDX_EMP_ENAME                 0           1            14                       1                       1                 1       14
EMP          PK_EMP                        0           1            14                       1                       1                 1       14
EMP          IDX_EMP_COMM                  0           1             5                       1                       1                 5        5

7 rows selected.

SQL> 

-- 5.2.2 Mesurer l'effet des statistiques LOW_VALUE et HIGH_VALUE sur les tables
-- EMP et BIGEMP2 en consid�rant la colonne ENAME

-- 5.2.2 Mesurer l'effet des statistiques LOW_VALUE et HIGH_VALUE sur les tables
-- EMP et BIGEMP2 en consid�rant la colonne ENAME

drop index idx_emp_ename;
-- resultat :
SQL> drop index idx_emp_ename;

Index dropped.
----
create index idx_emp_ename on emp(ename);
-- resultat :
SQL> create index idx_emp_ename on emp(ename);

Index created.

SQL> 
---
analyze table emp compute statistics;

-- resultat :
SQL> analyze table emp compute statistics;

Table analyzed.

SQL> 

-----

set autotrace traceonly
set linesize 200

alter session set OPTIMIZER_MODE=all_rows;
-- resultat :
SQL> alter session set OPTIMIZER_MODE=all_rows;

Session altered.

SQL> 

------
select * from emp	 Where ename >'A';

-- resultat :

SQL> select * from emp   Where ename >'A';

14 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3208032006

-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |    14 |   462 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP           |    14 |   462 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_ENAME |    14 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')


Statistics
----------------------------------------------------------
         12  recursive calls
          3  db block gets
          8  consistent gets
          0  physical reads
        564  redo size
       1992  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
         14  rows processed

SQL> 

-----

alter session set OPTIMIZER_MODE=first_rows_1;

-- resultat :
QL> alter session set OPTIMIZER_MODE=first_rows_1;

Session altered.

SQL> 
----
select * from emp	 Where ename >'A';

-- resultat :
SQL> select * from emp   Where ename >'A';

14 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3208032006

-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |     1 |    33 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP           |     1 |    33 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_ENAME |    14 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')


Statistics
----------------------------------------------------------
          8  recursive calls
          0  db block gets
          6  consistent gets
          0  physical reads
          0  redo size
       1992  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
         14  rows processed

SQL> 

-----
 


alter session set OPTIMIZER_MODE=first_rows_1000;

-- resultat :
SQL> alter session set OPTIMIZER_MODE=first_rows_1000;

Session altered.

SQL> 

----
select * from emp	 Where ename >'A';

-- resultat :
SQL> select * from emp   Where ename >'A';

14 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3208032006

-----------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name          | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |               |    14 |   462 |     2   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMP           |    14 |   462 |     2   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_EMP_ENAME |    14 |       |     1   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1992  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
         14  rows processed

SQL> 

----


-- En mode RULE l'index sera toujour utilis� m�me s'il n'apporte rien.
-- Mode � ne plus utiliser.
alter session set OPTIMIZER_MODE=rule;

-- resultat :
SQL> alter session set OPTIMIZER_MODE=rule;

Session altered.

SQL> 

---
select * from emp Where ename >'A';

-- resultat :
SQL> select * from emp Where ename >'A';

14 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3977601012

-----------------------------------------------------
| Id  | Operation                   | Name          |
-----------------------------------------------------
|   0 | SELECT STATEMENT            |               |
|   1 |  TABLE ACCESS BY INDEX ROWID| EMP           |
|*  2 |   INDEX RANGE SCAN          | IDX_EMP_ENAME |
-----------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')

Note
-----
   - rule based optimizer used (consider using cbo)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
          4  consistent gets
          0  physical reads
          0  redo size
       1992  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
         14  rows processed

SQL> 

----


-- Normalement l'usage de l'index n'apporte rien. On le d�sactive
-- Le co�t reste plus �l�v�. La taille de la table est
-- pour tirer une conclusion fiable.
alter session set OPTIMIZER_MODE=all_rows;

-- resultat :
SQL> alter session set OPTIMIZER_MODE=all_rows;

Session altered.

SQL> 

---
select /*+NO_INDEX(e idx_emp_ename)*/ * from emp e Where ename >'A';

-- resultat :
SQL> select /*+NO_INDEX(e idx_emp_ename)*/ * from emp e Where ename >'A';

14 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3956160932

--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |    14 |   462 |     3   (0)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| EMP  |    14 |   462 |     3   (0)| 00:00:01 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("ENAME">'A')


Statistics
----------------------------------------------------------
          8  recursive calls
          0  db block gets
          9  consistent gets
          0  physical reads
          0  redo size
       1929  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
         14  rows processed

SQL> 

----

 
 -- Reprendre la m�me chose avec la table BIGEMP2
 -- HIGH VALUE AND LOW VALUE

drop index idx_bidgemp2_ename;
create index idx_bidgemp2_ename on bigemp2(ename);

-- resultat :
SQL> drop index idx_bidgemp2_ename;
drop index idx_bidgemp2_ename
           *
ERROR at line 1:
ORA-01418: specified index does not exist
Help: https://docs.oracle.com/error-help/db/ora-01418/


SQL> create index idx_bidgemp2_ename on bigemp2(ename);

Index created.

SQL> 

----

analyze table bigemp2 compute statistics;

-- resultat :
SQL> analyze table bigemp2 compute statistics;

Table analyzed.

SQL> 

----

set autotrace traceonly
set linesize 200

-- resultat :
SQL> set autotrace traceonly
set linesize 200SQL> 
SQL> 

----

alter session set OPTIMIZER_MODE=all_rows;
-- resultat :
SQL> alter session set OPTIMIZER_MODE=all_rows;

Session altered.

SQL> 

----
select * from bigemp2 
Where ename >'A';

-- resultat :

SQL> select * from bigemp2 
Where ename >'A';  2  

130014 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 526821420

-----------------------------------------------------------------------------
| Id  | Operation         | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |         |   130K|  4443K|   239   (1)| 00:00:01 |
|*  1 |  TABLE ACCESS FULL| BIGEMP2 |   130K|  4443K|   239   (1)| 00:00:01 |
-----------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("ENAME">'A')


Statistics
----------------------------------------------------------
         12  recursive calls
          3  db block gets
       9437  consistent gets
          0  physical reads
        620  redo size
    7117758  bytes sent via SQL*Net to client
     217018  bytes received via SQL*Net from client
       8669  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
     130014  rows processed

SQL> 

----

-- Il y a de fortes chances que l'index soit utilis�. On vise la 1�re ligne
alter session set OPTIMIZER_MODE=first_rows_1;

-- resultat :
SQL> alter session set OPTIMIZER_MODE=first_rows_1;

Session altered.

SQL> 

----
select * from bigemp2 
Where ename >'A';

-- resultat :

SQL> select * from bigemp2 
Where ename >'A';  2  

130014 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1877594980

----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                    |     1 |    35 |     3   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| BIGEMP2            |     1 |    35 |     3   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_BIDGEMP2_ENAME |       |       |     2   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')


Statistics
----------------------------------------------------------
          8  recursive calls
          0  db block gets
      32526  consistent gets
          0  physical reads
          0  redo size
    7782515  bytes sent via SQL*Net to client
     217018  bytes received via SQL*Net from client
       8669  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
     130014  rows processed

SQL> 

-----
 


 alter session set OPTIMIZER_MODE=first_rows_1000;
 -- resultat :
 SQL>  alter session set OPTIMIZER_MODE=first_rows_1000;

Session altered.

SQL> 

----
 select * from bigemp2 
 Where ename >'A';

-- resultat :
SQL>  select * from bigemp2 
 Where ename >'A';  2  

130014 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1877594980

----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                    |  1000 | 35000 |   127   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| BIGEMP2            |  1000 | 35000 |   127   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_BIDGEMP2_ENAME |       |       |     4   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')


Statistics
----------------------------------------------------------
          8  recursive calls
          0  db block gets
      32526  consistent gets
          0  physical reads
          0  redo size
    7782515  bytes sent via SQL*Net to client
     217018  bytes received via SQL*Net from client
       8669  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
     130014  rows processed

SQL> 
----


 alter session set OPTIMIZER_MODE=rule;

 -- resultat :
 SQL>  alter session set OPTIMIZER_MODE=rule;

Session altered.

SQL> 

---
 select * from bigemp2 
 Where ename >'A';

-- resultat :

SQL>  select * from bigemp2 
 Where ename >'A';  2  

130014 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1375159952

----------------------------------------------------------
| Id  | Operation                   | Name               |
----------------------------------------------------------
|   0 | SELECT STATEMENT            |                    |
|   1 |  TABLE ACCESS BY INDEX ROWID| BIGEMP2            |
|*  2 |   INDEX RANGE SCAN          | IDX_BIDGEMP2_ENAME |
----------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')

Note
-----
   - rule based optimizer used (consider using cbo)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
      32524  consistent gets
          0  physical reads
          0  redo size
    7782515  bytes sent via SQL*Net to client
     217018  bytes received via SQL*Net from client
       8669  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
     130014  rows processed

SQL> 

-----
 
-- En mode all_rows l'usage l'index ne devrait pas �tre int�ressant	 
select/*+INDEX(a idx_bidgemp2_ename)*/ * from bigemp2 a	
Where ename >'A';

-- resultat :
SQL> select/*+INDEX(a idx_bidgemp2_ename)*/ * from bigemp2 a
Where ename >'A';  2  

130014 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1877594980

----------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name               | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                    |   130K|  4443K| 16261   (1)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| BIGEMP2            |   130K|  4443K| 16261   (1)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | IDX_BIDGEMP2_ENAME |   130K|       |   322   (0)| 00:00:01 |
----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ENAME">'A')


Statistics
----------------------------------------------------------
         10  recursive calls
          0  db block gets
      32526  consistent gets
          0  physical reads
          0  redo size
    7782515  bytes sent via SQL*Net to client
     217018  bytes received via SQL*Net from client
       8669  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
     130014  rows processed

SQL> 

---------

/*

Exercice 5.3 

	L'objectif de cet exercice est de provoquer et identifier 
	les cha�nages dans une table et d'y rem�dier. Pour cela 
	Le script ci-dessous cr�� une table Etudiant. Des lignes
	Y sont ins�r�es.


-- Ex�cuter le script ci-dessous pour cr�er la table �tudiant et y ins�rer des ligne 
@&SCRIPTPATH\ETUDIANTBLD.SQL
	
Exercice 5.3  suite

Calculer les statistiques sur la table et les index avec la commande ANALYZE

V�rifier s'il ya des cha�nages

Provoquer les cha�nages et assurer vous de leur pr�sence

S'il y'a des cha�nages, faire en sorte de les supprimer




*/


-- Exercice 5.3 

-- L'objectif de cet exercice est de provoquer et 
-- identifier les cha�nages dans une table et 
-- d'y rem�dier.

-- Ex�cuter le script ci-dessous pour cr�er la table �tudiant et y ins�rer des ligne
 set autotrace off
sql>@&SCRIPTPATH/ETUDIANTBLD.SQL

-- resultat :

SQL>  set autotrace off
SQL> @&SCRIPTPATH/ETUDIANTBLD.SQL
        DROP TABLE ETUDIANT
                   *
ERROR at line 1:
ORA-00942: table or view "ORS1"."ETUDIANT" does not exist
Help: https://docs.oracle.com/error-help/db/ora-00942/



Table created.

        DROP SEQUENCE Seq_ETU_NUMERO
                      *
ERROR at line 1:
ORA-02289: sequence does not exist
Help: https://docs.oracle.com/error-help/db/ora-02289/



Sequence created.

        DROP TYPE TabENoms_T
*
ERROR at line 1:
ORA-04043: Object TABENOMS_T does not exist.
Help: https://docs.oracle.com/error-help/db/ora-04043/



Type created.


PL/SQL procedure successfully completed.

SQL> 

------

-- Calculer les statistiques sur la table et les index avec la commande ANALYZE
ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;

-- resultat :

SQL> ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;


Table analyzed.

SQL> SQL> 

------
-- V�rifier s'il ya des cha�nages
select chain_cnt from user_tables 
where table_name='ETUDIANT';

 -- resultat :

 SQL> SQL> select chain_cnt from user_tables 
where table_name='ETUDIANT';  2  

CHAIN_CNT
---------
        0

--------
		
-- Provoquer les cha�nages et assurer vous de leur pr�sence


Update etudiant
set CV=cv||cv
where etu# IN (1,2);
commit;

-- resultat :


SQL> Update etudiant
set CV=cv||cv
where etu# IN (1,2);
commit;  2    3  
2 rows updated.

SQL> 

----

ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;

-- resultat :
SQL> ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;

Table analyzed.

SQL> 

-----
select chain_cnt from user_tables 
where table_name='ETUDIANT';

-- resultat :

SQL> select chain_cnt from user_tables 
where table_name='ETUDIANT';  2  

CHAIN_CNT
---------
        1

SQL> 

----

-- S'il y'a des cha�nages, faire en sorte de les supprimer

-- identifiant des lignes chain�es
select rowid, etu#
from etudiant where etu# in (1,2);

-- resultat :

SQL> select rowid, etu#
from etudiant where etu# in (1,2);  2  

ROWID                    ETU#
------------------ ----------
AAAR4lAAYAAAAb3AAB          2
AAAR4lAAYAAAAb3AAA          1

SQL> 

-----

-- v�fier et sinon cr�er la table chained_rows
-- vers seront envoy�e les identifiant des lignes
-- apr�s analyse.
 
desc chained_rows

-- resultat :
SQL> desc chained_rows
ERROR:
ORA-04043: Object chained_rows does not exist.
Help: https://docs.oracle.com/error-help/db/ora-04043/


SQL> 

------

-- cr�er la table si elle n'existe pas
@$ORACLE_HOME/rdbms/admin/utlchain.sql

--resultat :
SQL> @$ORACLE_HOME/rdbms/admin/utlchain.sql

Table created.

SQL> 

------

desc chained_rows
-- resultat :
SQL> desc chained_rows
 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 OWNER_NAME                                         VARCHAR2(128)
 TABLE_NAME                                         VARCHAR2(128)
 CLUSTER_NAME                                       VARCHAR2(128)
 PARTITION_NAME                                     VARCHAR2(128)
 SUBPARTITION_NAME                                  VARCHAR2(128)
 HEAD_ROWID                                         ROWID
 ANALYZE_TIMESTAMP                                  DATE

SQL> 


--------

ANALYZE TABLE etudiant 
LIST CHAINED ROWS INTO chained_rows;

--resultat

SQL> 
ANALYZE TABLE etudiant 
LIST CHAINED ROWS INTO chained_rows;SQL>   2  

Table analyzed.

SQL> 

set line size 200
col OWNER_NAME   format A20          
col TABLE_NAME     format A20           
col HEAD_ROWID       format A20         
col ANALYZE_TIMESTAMP   format A20      

select OWNER_NAME,TABLE_NAME, HEAD_ROWID, ANALYZE_TIMESTAMP 
from chained_rows;

-- resultat 


SQL> set line size 200
col OWNER_NAME   format A20          
col TABLE_NAME     format A20           
col HEAD_ROWID       format A20         
col ANALYZE_TIMESTAMP   format A20      

select OWNER_NAME,TABLE_NAME, HEAD_ROWID, ANALYZE_TIMESTAMP 
from chained_rows;
SP2-0268: linesize option not a valid number
Help: https://docs.oracle.com/error-help/db/sp2-0268/
SQL> SQL> SQL> SQL> SQL> SQL>   2  
OWNER_NAME           TABLE_NAME           HEAD_ROWID
-------------------- -------------------- --------------------
ANALYZE_TIMESTAMP
--------------------
ORS1                 ETUDIANT             AAAR5tAAYAAAABGAAA
27-MAR-26


SQL> 

-- sauvegarde des lignes cha�n�es dans etudiant2
CREATE TABLE etudiant2 as SELECT etudiant.* 
FROM etudiant, chained_rows
WHERE etudiant.rowid=head_rowid;

-- resultat :

SQL> CREATE TABLE etudiant2 as SELECT etudiant.* 
FROM etudiant, chained_rows
WHERE etudiant.rowid=head_rowid;  2    3  

Table created.

SQL> 

-- V�rification

select rowid from etudiant2;

-- resultat :
SQL> select rowid from etudiant2;

ROWID
------------------
AAAR5xAAYAAAATLAAA

SQL> 



-- suppression des lignes cha�n�es dans etudiant
DELETE FROM etudiant WHERE rowid in
(SELECT head_rowid FROM chained_rows);
-- resultat :

SQL> DELETE FROM etudiant WHERE rowid in
(SELECT head_rowid FROM chained_rows);  2  

1 row deleted.

SQL> 

-- r�insertion des lignes dans etudiant depuis etudiant2
INSERT INTO etudiant
SELECT * FROM etudiant2;
-- resultat :

SQL> INSERT INTO etudiant
SELECT * FROM etudiant2;  2  

1 row created.

SQL> 

-- Reanalyse et v�rification si les chainages sont partis
ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;
select chain_cnt from user_tables 
where table_name='ETUDIANT';
 
-- resultat :

SQL> ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;
select chain_cnt from user_tables 
where table_name='ETUDIANT';
Table analyzed.

SQL>   2  

 CHAIN_CNT
----------
         0

SQL> 
 

/*
Exercice 5.4 : Utilisation du package dbms_stats et recolte automatique

Calculer manuellement les statistiques en utilisant le package DBMS_STATS
Sur un utilisateur (exemple : &MYUSER)
Sur la base enti�re

V�rifier la pr�sence des statistiques dans le dictionnaire de donn�es Oracle

Supprimer les statistiques de l'utilisateur &MYUSER et mettre en �vidence leur absence. Puis recalculer les et mettre en �vidence leur pr�sence
 
Exporter les statistiques de l'utilisateur &MYUSER

V�rifier que Oracle collecte automatiquement les statistiques sur votre base
Comment activer ou d�sactiver la collecte des statistiques
Quels sont les param�tres de configuration actuels de la collecte


*/


-- Exercice 5.4 : Utilisation du package dbms_stats et recolte automatique

-- Calculer manuellement les statistiques en utilisant le package DBMS_STATS
-- Sur un utilisateur (exemple : &MYUSER)
-- Sur la base enti�re


-- Sur un utilisateur (exemple : &MYUSER)

PROCEDURE GATHER_SCHEMA_STATS
-- Nom d'argument                  Type                    E/S par d�faut ?
 ------------------------------ ----------------------- ------ --------
 OWNNAME                        VARCHAR2                IN
 ESTIMATE_PERCENT               NUMBER                  IN     DEFAULT
 BLOCK_SAMPLE                   BOOLEAN                 IN     DEFAULT
 METHOD_OPT                     VARCHAR2                IN     DEFAULT
 DEGREE                         NUMBER                  IN     DEFAULT
 GRANULARITY                    VARCHAR2                IN     DEFAULT
 CASCADE                        BOOLEAN                 IN     DEFAULT
 STATTAB                        VARCHAR2                IN     DEFAULT
 STATID                         VARCHAR2                IN     DEFAULT
 OPTIONS                        VARCHAR2                IN     DEFAULT
 STATOWN                        VARCHAR2                IN     DEFAULT
 NO_INVALIDATE                  BOOLEAN                 IN     DEFAULT
 GATHER_TEMP                    BOOLEAN                 IN     DEFAULT
 GATHER_FIXED                   BOOLEAN                 IN     DEFAULT
 STATTYPE                       VARCHAR2                IN     DEFAULT
 FORCE                          BOOLEAN                 IN     DEFAULT
set autotrace off

-- Laisser Oracle d�terminer le pourcentage de l'�chantillon,
-- Le d�gr� de parall�lisme et le calcul des histogram.
begin
DBMS_STATS.GATHER_SCHEMA_STATS (
OWNNAME           =>'&MYUSER',
ESTIMATE_PERCENT  =>DBMS_STATS.AUTO_SAMPLE_SIZE,
DEGREE            =>DBMS_STATS.AUTO_DEGREE,
CASCADE           =>DBMS_STATS.AUTO_CASCADE,
METHOD_OPT        => 'for all columns size auto'
);
end;
/

-- resultat :

SQL> 
PROCEDURE GATHER_SCHEMA_STATS
-- Nom d'argument                  Type                    E/S par d�faut ?
 ------------------------------ ----------------------- ------ --------
 OWNNAME                        VARCHAR2                IN
 ESTIMATE_PERCENT               NUMBER                  IN     DEFAULT
 BLOCK_SAMPLE                   BOOLEAN                 IN     DEFAULT
 METHOD_OPT                     VARCHAR2                IN     DEFAULT
 DEGREE                         NUMBER                  IN     DEFAULT
 GRANULARITY                    VARCHAR2                IN     DEFAULT
 CASCADE                        BOOLEAN                 IN     DEFAULT
 STATTAB                        VARCHAR2                IN     DEFAULT
 STATID                         VARCHAR2                IN     DEFAULT
 OPTIONS                        VARCHAR2                IN     DEFAULT
 STATOWN                        VARCHAR2                IN     DEFAULT
 NO_INVALIDATE                  BOOLEAN                 IN     DEFAULT
 GATHER_TEMP                    BOOLEAN                 IN     DEFAULT
 GATHER_FIXED                   BOOLEAN                 IN     DEFAULT
 STATTYPE                       VARCHAR2                IN     DEFAULT
 FORCE                          BOOLEAN                 IN     DEFAULT
set autotrace off

-- Laisser Oracle d�terminer le pourcentage de l'�chantillon,
-- Le d�gr� de parall�lisme et le calcul des histogram.
begin
DBMS_STATS.GATHER_SCHEMA_STATS (
OWNNAME           =>'&MYUSER',
ESTIMATE_PERCENT  =>DBMS_STATS.AUTO_SAMPLE_SIZE,
DEGREE            =>DBMS_STATS.AUTO_DEGREE,
CASCADE           =>DBMS_STATS.AUTO_CASCADE,
METHOD_OPT        => 'for all columns size auto'
);
end;
/
SQL> SP2-0734: unknown command beginning "PROCEDURE ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SQL> SQL> SP2-0734: unknown command beginning "OWNNAME   ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "ESTIMATE_P..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "BLOCK_SAMP..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "METHOD_OPT..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SP2-0044: For a list of known commands enter HELP
and to leave enter EXIT.
Help: https://docs.oracle.com/error-help/db/sp2-0044/
SQL> SP2-0734: unknown command beginning "DEGREE    ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "GRANULARIT..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "CASCADE   ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "STATTAB   ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SP2-0044: For a list of known commands enter HELP
and to leave enter EXIT.
Help: https://docs.oracle.com/error-help/db/sp2-0044/
SQL> SP2-0734: unknown command beginning "STATID    ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "OPTIONS   ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "STATOWN   ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "NO_INVALID..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SP2-0044: For a list of known commands enter HELP
and to leave enter EXIT.
Help: https://docs.oracle.com/error-help/db/sp2-0044/
SQL> SP2-0734: unknown command beginning "GATHER_TEM..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "GATHER_FIX..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "STATTYPE  ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "FORCE     ..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SP2-0044: For a list of known commands enter HELP
and to leave enter EXIT.
Help: https://docs.oracle.com/error-help/db/sp2-0044/
SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10  old   3: OWNNAME     =>'&MYUSER',
new   3: OWNNAME           =>'ORS1',


PL/SQL procedure successfully completed.

SQL> SQL> 

-- Afficher via une requ�te SQL les informations 
-- concernant les statistiques

-- Sur les tables de &MYUSER � partir la vue user_tables
col table_name format a12
col num_rows format 9999999
select
table_name,
num_rows,
Blocks,
empty_blocks,
avg_space,
chain_cnt,
avg_row_len 
FROM dba_tables
WHERE owner='&MYUSER'
order by table_name;

-- resultat :

SQL> 
SQL> col table_name format a12
col num_rows format 9999999
select
table_name,
num_rows,
Blocks,
empty_blocks,
avg_space,
chain_cnt,
avg_row_len 
FROM dba_tables
WHERE owner='&MYUSER'
order by table_name;SQL> SQL>   2    3    4    5    6    7    8    9   10   11  
old  10: WHERE owner='&MYUSER'
new  10: WHERE owner='ORS1'

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
BONUS               0          0            0          0          0           0
CHAINED_ROWS        1          5            0          0          0          36
DEPT                4          5            0          0          0          20
DUMMY               1          5            0          0          0           2
EMP                14          5            0          0          0          38
ETUDIANT       100000       3772           68        278          0         287
ETUDIANT2           1          4            0          0          0         559
SALGRADE            5          5            0          0          0          10

8 rows selected.

SQL> 



-- sur les tables de &MYUSER avec la vue user_tab_statistics
col table_name format a12
col num_rows format 9999999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS  AVG_S_F_BLKS,
NUM_FREELIST_BLOCKS NUM_F_BLKS,
AVG_CACHED_BLOCKS  AVG_C_BLKS, 
AVG_CACHE_HIT_RATIO
from dba_tab_statistics
where owner='&MYUSER'
order by table_name;

-- resultat :

SQL> col table_name format a12
col num_rows format 9999999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS  AVG_S_F_BLKS,
NUM_FREELIST_BLOCKS NUM_F_BLKS,
AVG_CACHED_BLOCKS  AVG_C_BLKS, 
AVG_CACHE_HIT_RATIO
from dba_tab_statistics
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15  
old  14: where owner='&MYUSER'
new  14: where owner='ORS1'

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_S_F_BLKS NUM_F_BLKS AVG_C_BLKS AVG_CACHE_HIT_RATIO
------------ ---------- ---------- -------------------
BONUS               0          0            0          0          0           0
           0          0

CHAINED_ROWS        1          5            0          0          0          36
           0          0

DEPT                4          5            0          0          0          20
           0          0


TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_S_F_BLKS NUM_F_BLKS AVG_C_BLKS AVG_CACHE_HIT_RATIO
------------ ---------- ---------- -------------------
DUMMY               1          5            0          0          0           2
           0          0

EMP                14          5            0          0          0          38
           0          0

ETUDIANT       100000       3772           68        278          0         287
           0          0


TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_S_F_BLKS NUM_F_BLKS AVG_C_BLKS AVG_CACHE_HIT_RATIO
------------ ---------- ---------- -------------------
ETUDIANT2           1          4            0          0          0         559
           0          0

SALGRADE            5          5            0          0          0          10
           0          0


8 rows selected.

SQL> 



-- Sur les colonnes des tables de &MYUSER avec la vue user_tab_columns
col table_name format a12
col COLUMN_NAME format a12
col LOW_VALUE format a20
col HIGH_VALUE format a20
select
table_name,
column_name,
num_distinct,
low_value,
High_value,
NUM_BUCKETS, 
DENSITY,        
NUM_NULLS
from dba_tab_columns
where owner='&MYUSER'
order by table_name;

-- resultat :

SQL> col table_name format a12
col COLUMN_NAME format a12
col LOW_VALUE format a20
col HIGH_VALUE format a20
select
table_name,
column_name,
num_distinct,
low_value,
High_value,
NUM_BUCKETS, 
DENSITY,        
NUM_NULLS
from dba_tab_columns
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12  
old  11: where owner='&MYUSER'
new  11: where owner='ORS1'

TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
BONUS        SAL                     0
          0          0          0

BONUS        JOB                     0
          0          0          0

BONUS        ENAME                   0
          0          0          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
BONUS        COMM                    0
          0          0          0

CHAINED_ROWS CLUSTER_NAME            0
          0          0          1

CHAINED_ROWS TABLE_NAME              1 4554554449414E54     4554554449414E54
          1          1          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
CHAINED_ROWS OWNER_NAME              1 4F525331             4F525331
          1          1          0

CHAINED_ROWS PARTITION_NA            0
             ME
          0          0          1

CHAINED_ROWS ANALYZE_TIME            1 787E031B172403       787E031B172403
             STAMP

TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
          1          1          0

CHAINED_ROWS HEAD_ROWID              1 00011E6D060000460000 00011E6D060000460000
          1          1          0

CHAINED_ROWS SUBPARTITION            1 4E2F41               4E2F41
             _NAME
          1          1          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
DEPT         LOC                     4 424F53544F4E         4E455720594F524B
          1        .25          0

DEPT         DNAME                   4 4143434F554E54494E47 53414C4553
          1        .25          0

DEPT         DEPTNO                  4 C10B                 C129
          1        .25          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
DUMMY        DUMMY                   1 80                   80
          1          1          0

EMP          EMPNO                  14 C24A46               C25023
          1 .071428571          0

EMP          DEPTNO                  3 C10B                 C11F
          3 .035714286          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
EMP          COMM                    4 80                   C20F
          1        .25         10

EMP          SAL                    12 C209                 C233
          1 .083333333          0

EMP          HIREDATE               13 77B40C11010101       77B7010C010101
          1 .076923077          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
EMP          MGR                     6 C24C43               C25003
          1 .166666667          1

EMP          JOB                     5 414E414C595354       53414C45534D414E
          1         .2          0

EMP          ENAME                  14 4144414D53           57415244
          1 .071428571          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
ETUDIANT     ETU#               100000 C102                 C30B
          1     .00001          0

ETUDIANT     NOM                   129 416B696D             5A656D626C61
          1 .007751938          0

ETUDIANT     CV                      2 554E20435620504C4549 554E20435620504C4549
                                       4E2C20554E2043562050 4E2C20554E2043562050
                                       4C45494E2C20554E2043 4C45494E2C20554E2043

TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
                                       5620504C45494E2C2055 5620504C45494E2C2055
                                       4E20435620504C45494E 4E20435620504C45494E
                                       2C20554E20435620504C 2C20554E20435620504C
                                       45494E2C             45494E2C
          1         .5          0

ETUDIANT2    CV                      1 554E20435620504C4549 554E20435620504C4549
                                       4E2C20554E2043562050 4E2C20554E2043562050
                                       4C45494E2C20554E2043 4C45494E2C20554E2043

TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
                                       5620504C45494E2C2055 5620504C45494E2C2055
                                       4E20435620504C45494E 4E20435620504C45494E
                                       2C20554E20435620504C 2C20554E20435620504C
                                       45494E2C             45494E2C
          1          1          0

ETUDIANT2    NOM                     1 4475706F6E74         4475706F6E74
          1          1          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
ETUDIANT2    ETU#                    1 C102                 C102
          1          1          0

SALGRADE     GRADE                   5 C102                 C106
          1         .2          0

SALGRADE     LOSAL                   5 C208                 C21F02
          1         .2          0


TABLE_NAME   COLUMN_NAME  NUM_DISTINCT LOW_VALUE            HIGH_VALUE
------------ ------------ ------------ -------------------- --------------------
NUM_BUCKETS    DENSITY  NUM_NULLS
----------- ---------- ----------
SALGRADE     HISAL                   5 C20D                 C26464
          1         .2          0


32 rows selected.

SQL> 


-- Sur les colonnes les tables de &MYUSER avec la vue user_tab_col_statistics
col table_name format a15
col column_name format a17
col  NUM_DIS format 999999
SELECT
TABLE_NAME ,
COLUMN_NAME, 
NUM_DISTINCT NUM_DIS,
LOW_VALUE,
HIGH_VALUE ,
DENSITY,  
NUM_NULLS,
NUM_BUCKETS, 
SAMPLE_SIZE,
GLOBAL_STATS,
USER_STATS ,
AVG_COL_LEN,
HISTOGRAM
FROM dba_tab_col_statistics
where owner='&MYUSER'
order by table_name;

-- resultat :


SQL> col table_name format a15
col column_name format a17
col  NUM_DIS format 999999
SELECT
TABLE_NAME ,
COLUMN_NAME, 
NUM_DISTINCT NUM_DIS,
LOW_VALUE,
HIGH_VALUE ,
DENSITY,  
NUM_NULLS,
NUM_BUCKETS, 
SAMPLE_SIZE,
GLOBAL_STATS,
USER_STATS ,
AVG_COL_LEN,
HISTOGRAM
FROM dba_tab_col_statistics
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17  
old  16: where owner='&MYUSER'
new  16: where owner='ORS1'

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
BONUS           COMM                    0
                              0          0           0             YES NO
          0 NONE

BONUS           SAL                     0
                              0          0           0             YES NO
          0 NONE

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------

BONUS           JOB                     0
                              0          0           0             YES NO
          0 NONE

BONUS           ENAME                   0
                              0          0           0             YES NO

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
          0 NONE

CHAINED_ROWS    HEAD_ROWID              1 00011E6D060000460000
00011E6D060000460000          1          0           1           1 YES NO
         10 NONE

CHAINED_ROWS    ANALYZE_TIMESTAMP       1 787E031B172403

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
787E031B172403                1          0           1           1 YES NO
          8 NONE

CHAINED_ROWS    SUBPARTITION_NAME       1 4E2F41
4E2F41                        1          0           1           1 YES NO
          4 NONE


TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
CHAINED_ROWS    PARTITION_NAME          0
                              0          1           0             YES NO
          0 NONE

CHAINED_ROWS    CLUSTER_NAME            0
                              0          1           0             YES NO
          0 NONE

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------

CHAINED_ROWS    TABLE_NAME              1 4554554449414E54
4554554449414E54              1          0           1           1 YES NO
          9 NONE

CHAINED_ROWS    OWNER_NAME              1 4F525331
4F525331                      1          0           1           1 YES NO

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
          5 NONE

DEPT            LOC                     4 424F53544F4E
4E455720594F524B            .25          0           1           4 YES NO
          8 NONE

DEPT            DNAME                   4 4143434F554E54494E47

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
53414C4553                  .25          0           1           4 YES NO
         10 NONE

DEPT            DEPTNO                  4 C10B
C129                        .25          0           1           4 YES NO
          3 NONE


TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
DUMMY           DUMMY                   1 80
80                            1          0           1           1 YES NO
          2 NONE

EMP             EMPNO                  14 C24A46
C25023               .071428571          0           1          14 YES NO
          4 NONE

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------

EMP             ENAME                  14 4144414D53
57415244             .071428571          0           1          14 YES NO
          6 NONE

EMP             HIREDATE               13 77B40C11010101
77B7010C010101       .076923077          0           1          14 YES NO

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
          8 NONE

EMP             MGR                     6 C24C43
C25003               .166666667          1           1          13 YES NO
          4 NONE

EMP             JOB                     5 414E414C595354

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
53414C45534D414E             .2          0           1          14 YES NO
          8 NONE

EMP             SAL                    12 C209
C233                 .083333333          0           1          14 YES NO
          4 NONE


TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
EMP             COMM                    4 80
C20F                        .25         10           1           4 YES NO
          2 NONE

EMP             DEPTNO                  3 C10B
C11F                 .035714286          0           3          14 YES NO
          3 FREQUENCY

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------

ETUDIANT        CV                      2 554E20435620504C4549
                                          4E2C20554E2043562050
                                          4C45494E2C20554E2043
                                          5620504C45494E2C2055
                                          4E20435620504C45494E
                                          2C20554E20435620504C

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
                                          45494E2C
554E20435620504C4549         .5          0           1      100000 YES NO
4E2C20554E2043562050
4C45494E2C20554E2043
5620504C45494E2C2055
4E20435620504C45494E
2C20554E20435620504C

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
45494E2C
        276 NONE

ETUDIANT        NOM                   129 416B696D
5A656D626C61         .007751938          0           1      100000 YES NO
          8 NONE


TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
ETUDIANT        ETU#               100000 C102
C30B                     .00001          0           1      100000 YES NO
          5 NONE

ETUDIANT2       NOM                     1 4475706F6E74
4475706F6E74                  1          0           1           1 YES NO
          7 NONE

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------

ETUDIANT2       CV                      1 554E20435620504C4549
                                          4E2C20554E2043562050
                                          4C45494E2C20554E2043
                                          5620504C45494E2C2055
                                          4E20435620504C45494E
                                          2C20554E20435620504C

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
                                          45494E2C
554E20435620504C4549          1          0           1           1 YES NO
4E2C20554E2043562050
4C45494E2C20554E2043
5620504C45494E2C2055
4E20435620504C45494E
2C20554E20435620504C

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
45494E2C
        549 NONE

ETUDIANT2       ETU#                    1 C102
C102                          1          0           1           1 YES NO
          3 NONE


TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------
SALGRADE        GRADE                   5 C102
C106                         .2          0           1           5 YES NO
          3 NONE

SALGRADE        LOSAL                   5 C208
C21F02                       .2          0           1           5 YES NO
          4 NONE

TABLE_NAME      COLUMN_NAME       NUM_DIS LOW_VALUE
--------------- ----------------- ------- --------------------
HIGH_VALUE              DENSITY  NUM_NULLS NUM_BUCKETS SAMPLE_SIZE GLO USE
-------------------- ---------- ---------- ----------- ----------- --- ---
AVG_COL_LEN HISTOGRAM
----------- ---------------

SALGRADE        HISAL                   5 C20D
C26464                       .2          0           1           5 YES NO
          4 NONE


32 rows selected.

SQL> 



-- Sur les Index des tables de &MYUSER  avec la vue user_indexes
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999
select
table_name,
index_name,
BLEVEL,
LEAF_BLOCKS,
DISTINCT_KEYS,
AVG_LEAF_BLOCKS_PER_KEY,
AVG_DATA_BLOCKS_PER_KEY,
CLUSTERING_FACTOR	
from dba_indexes
where owner='&MYUSER'
order by table_name;

-- resultat :
SQL> col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999
select
table_name,
index_name,
BLEVEL,
LEAF_BLOCKS,
DISTINCT_KEYS,
AVG_LEAF_BLOCKS_PER_KEY,
AVG_DATA_BLOCKS_PER_KEY,
CLUSTERING_FACTOR
from dba_indexes
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12  
old  11: where owner='&MYUSER'
new  11: where owner='ORS1'

TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS
------------ -------------------- ---------- ----------- -------------
AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR
----------------------- ----------------------- -----------------
DEPT         PK_DEPT                       0           1             4
                      1                       1                 1

EMP          PK_EMP                        0           1            14
                      1                       1                 1

ETUDIANT     PK_ETU                        1         187        100000
                      1                       1              3705


TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS
------------ -------------------- ---------- ----------- -------------
AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR
----------------------- ----------------------- -----------------
SALGRADE     PK_SALGRADE                   0           1             5
                      1                       1                 1


SQL> 





-- Sur les Index les tables de &MYUSER  avec la vue user_ind_statistics
col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999

SELECT
 TABLE_NAME ,
 INDEX_NAME ,  
 BLEVEL   ,
 LEAF_BLOCKS,
 DISTINCT_KEYS , 
 AVG_LEAF_BLOCKS_PER_KEY ,
 AVG_DATA_BLOCKS_PER_KEY ,
 CLUSTERING_FACTOR   ,
 NUM_ROWS    
FROM dba_ind_statistics
where owner='&MYUSER'
order by table_name;

-- resultat :

SQL> col index_name format a20
col table_name format a12
col LEAF_BLOCKS format 999999
col DISTINCT_KEYS format 999999
col AVG_LEAF_BLOCKS_PER_KEY format 999999
col AVG_DATA_BLOCKS_PER_KEY format 999999
col CLUSTERING_FACTOR format 999999

SELECT
 TABLE_NAME ,
 INDEX_NAME ,  
 BLEVEL   ,
 LEAF_BLOCKS,
 DISTINCT_KEYS , 
 AVG_LEAF_BLOCKS_PER_KEY ,
 AVG_DATA_BLOCKS_PER_KEY ,
 CLUSTERING_FACTOR   ,
 NUM_ROWS    
FROM dba_ind_statistics
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13  
old  12: where owner='&MYUSER'
new  12: where owner='ORS1'

TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS
------------ -------------------- ---------- ----------- -------------
AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR NUM_ROWS
----------------------- ----------------------- ----------------- --------
DEPT         PK_DEPT                       0           1             4
                      1                       1                 1        4

EMP          PK_EMP                        0           1            14
                      1                       1                 1       14

ETUDIANT     PK_ETU                        1         187        100000
                      1                       1              3705   100000


TABLE_NAME   INDEX_NAME               BLEVEL LEAF_BLOCKS DISTINCT_KEYS
------------ -------------------- ---------- ----------- -------------
AVG_LEAF_BLOCKS_PER_KEY AVG_DATA_BLOCKS_PER_KEY CLUSTERING_FACTOR NUM_ROWS
----------------------- ----------------------- ----------------- --------
SALGRADE     PK_SALGRADE                   0           1             5
                      1                       1                 1        5


SQL> 

-- Sur la base enti�re

-- PROCEDURE GATHER_DATABASE_STATS
-- Nom d'argument                  Type                    E/S par d�faut ?
 ------------------------------ ----------------------- ------ --------
 ESTIMATE_PERCENT               NUMBER                  IN     DEFAULT
 BLOCK_SAMPLE                   BOOLEAN                 IN     DEFAULT
 METHOD_OPT                     VARCHAR2                IN     DEFAULT
 DEGREE                         NUMBER                  IN     DEFAULT
 GRANULARITY                    VARCHAR2                IN     DEFAULT
 CASCADE                        BOOLEAN                 IN     DEFAULT
 STATTAB                        VARCHAR2                IN     DEFAULT
 STATID                         VARCHAR2                IN     DEFAULT
 OPTIONS                        VARCHAR2                IN     DEFAULT
 STATOWN                        VARCHAR2                IN     DEFAULT
 GATHER_SYS                     BOOLEAN                 IN     DEFAULT
 NO_INVALIDATE                  BOOLEAN                 IN     DEFAULT
 GATHER_TEMP                    BOOLEAN                 IN     DEFAULT
 GATHER_FIXED                   BOOLEAN                 IN     DEFAULT
 STATTYPE                       VARCHAR2                IN     DEFAULT



-- ne pas ex�cuter : trop long 
execute dbms_stats.gather_database_stats;
-- resultat :

SQL> execute dbms_stats.gather_database_stats;

PL/SQL procedure successfully completed.

SQL> 

-- Supprimer les statistiques de l'utilisateur &MYUSER et mettre en �vidence 
-- leur absence. Puis recalculer les et mettre en �vidence leur pr�sence
 execute dbms_stats.delete_schema_stats('&MYUSER');

-- resultat :

SQL>  execute dbms_stats.delete_schema_stats('&MYUSER');

PL/SQL procedure successfully completed.

SQL>  

-- Sur les tables de &MYUSER
col table_name format a12
col num_rows format 9999999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS  ,
NUM_FREELIST_BLOCKS ,
AVG_CACHED_BLOCKS , 
AVG_CACHE_HIT_RATIO
from dba_tab_statistics
where owner='&MYUSER'
order by table_name;

-- resultat :
SQL> col table_name format a12
col num_rows format 9999999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS  ,
NUM_FREELIST_BLOCKS ,
AVG_CACHED_BLOCKS , 
AVG_CACHE_HIT_RATIO
from dba_tab_statistics
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15  
old  14: where owner='&MYUSER'
new  14: where owner='ORS1'

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------
BONUS



CHAINED_ROWS



TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------

DEPT



DUMMY


TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------


EMP



ETUDIANT

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------



ETUDIANT2




TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------
SALGRADE




8 rows selected.

SQL> 

-- recalculer les statistiques
begin
DBMS_STATS.GATHER_SCHEMA_STATS (
OWNNAME           =>'&MYUSER',
ESTIMATE_PERCENT  =>DBMS_STATS.AUTO_SAMPLE_SIZE,
DEGREE            =>DBMS_STATS.AUTO_DEGREE,
CASCADE           =>DBMS_STATS.AUTO_CASCADE,
METHOD_OPT        => 'for all columns size auto'
);
end;
/

-- resultat :
SQL> begin
DBMS_STATS.GATHER_SCHEMA_STATS (
OWNNAME           =>'&MYUSER',
ESTIMATE_PERCENT  =>DBMS_STATS.AUTO_SAMPLE_SIZE,
DEGREE            =>DBMS_STATS.AUTO_DEGREE,
CASCADE           =>DBMS_STATS.AUTO_CASCADE,
METHOD_OPT        => 'for all columns size auto'
);
end;
/  2    3    4    5    6    7    8    9   10  
old   3: OWNNAME           =>'&MYUSER',
new   3: OWNNAME           =>'ORS1',

PL/SQL procedure successfully completed.

SQL> 


 -- Sur les tables de &MYUSER
col table_name format a12
col num_rows format 9999999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS  ,
NUM_FREELIST_BLOCKS ,
AVG_CACHED_BLOCKS , 
AVG_CACHE_HIT_RATIO
from dba_tab_statistics
where owner='&MYUSER'
order by table_name;

-- resultat :
SQL> col table_name format a12
col num_rows format 9999999

SELECT
TABLE_NAME,
NUM_ROWS ,
BLOCKS,
EMPTY_BLOCKS,
AVG_SPACE ,
CHAIN_CNT,
AVG_ROW_LEN, 
AVG_SPACE_FREELIST_BLOCKS  ,
NUM_FREELIST_BLOCKS ,
AVG_CACHED_BLOCKS , 
AVG_CACHE_HIT_RATIO
from dba_tab_statistics
where owner='&MYUSER'
order by table_name;SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15  
old  14: where owner='&MYUSER'
new  14: where owner='ORS1'

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------
BONUS               0          0            0          0          0           0
                        0                   0


CHAINED_ROWS        1          5            0          0          0          36
                        0                   0


TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------

DEPT                4          5            0          0          0          20
                        0                   0


DUMMY               1          5            0          0          0           2
                        0                   0

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------


EMP                14          5            0          0          0          38
                        0                   0


ETUDIANT       100000       3772            0          0          0         287

TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------
                        0                   0


ETUDIANT2           1          4            0          0          0         559
                        0                   0



TABLE_NAME   NUM_ROWS     BLOCKS EMPTY_BLOCKS  AVG_SPACE  CHAIN_CNT AVG_ROW_LEN
------------ -------- ---------- ------------ ---------- ---------- -----------
AVG_SPACE_FREELIST_BLOCKS NUM_FREELIST_BLOCKS AVG_CACHED_BLOCKS
------------------------- ------------------- -----------------
AVG_CACHE_HIT_RATIO
-------------------
SALGRADE            5          5            0          0          0          10
                        0                   0



8 rows selected.

SQL> 

-- Exporter les statitistiques de l'utilisateur ors
PROCEDURE EXPORT_SCHEMA_STATS
-- Nom d'argument                  Type                    E/S par d�faut ?
 ------------------------------ ----------------------- ------ --------
 OWNNAME                        VARCHAR2                IN
 STATTAB                        VARCHAR2                IN
 STATID                         VARCHAR2                IN     DEFAULT
 STATOWN                        VARCHAR2                IN     DEFAULT

-- Avant d'exporter les statistiques il faut cr�er la table
-- devant contenir les statistiques
DBMS_STATS.CREATE_STAT_TABLE (
ownname VARCHAR2,
stattab VARCHAR2,
tblspace VARCHAR2 DEFAULT NULL);

-- cr�ation de la table devant contenir les stats
select * from tab where tname='STATORS' order by tname ;

-- resultat :

SQL> select * from tab where tname='STATORS' order by tname ;

no rows selected

SQL> 
------

execute DBMS_STATS.CREATE_STAT_TABLE('&MYUSER','STATors','USERS');
desc STATors

-- resultat :
SQL> execute DBMS_STATS.CREATE_STAT_TABLE('&MYUSER','STATors','USERS');
desc STATors
PL/SQL procedure successfully completed.

SQL> 

--------
select * from tab where tname='STATORS' order by tname ;

-- resultat :
SQL> select * from tab where tname='STATORS' order by tname ;
Usage: DESCRIBE [schema.]object[@db_link]
SQL> 

----
execute dbms_stats.export_schema_stats('&MYUSER', 'STATors');

-- resultat :
SQL> execute dbms_stats.export_schema_stats('&MYUSER', 'STATors');

PL/SQL procedure successfully completed.

SQL> 

-------

-- v�rifier la g�n�ration de statistiques
set linesize 500
set pagesize 500
col statid format a6
col version format 9999999
col flags format 99999
col c1 format a15
col c2 format a2
col c3 format a2
col c4 format a17
col c5 format a4
col ch1 format a15
col r1 format a15
col r2 format a15
select * from STATors;

-- resultat :
SQL> set linesize 500
set pagesize 500
col statid format a6
col version format 9999999
col flags format 99999
col c1 format a15
col c2 format a2
col c3 format a2
col c4 format a17
col c5 format a4
col ch1 format a15
col r1 format a15
col r2 format a15
select * from STATors;SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> 

STATID T  VERSION  FLAGS C1              C2 C3 C4                C5   C6                                                                                                                                       N1         N2         N3         N4         N5         N6         N7         N8         N9        N10        N11        N12      N13 D1          T1                                                                          R1              R2
------ - -------- ------ --------------- -- -- ----------------- ---- -------------------------------------------------------------------------------------------------------------------------------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ---------- ------------------ --------------------------------------------------------------------------- --------------- ---------------
R3                                                                                                                                                                                                                                                              CH1             CL1
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------- --------------------------------------------------------------------------------
BL1
----------------------------------------------------------------------------------------------------------------------------------------------------------------
       T        8      2 BONUS                                   ORS1                                                                                                                                           0          0          0          0                                                      0                                           27-MAR-26



       C        8      2 BONUS                 COMM              ORS1                                                                                                                                           0          0          0                     0                                0                                                      27-MAR-26



       C        8      2 BONUS                 ENAME             ORS1                                                                                                                                           0          0          0                     0                                0                                                      27-MAR-26



       C        8      2 BONUS                 JOB               ORS1                                                                                                                                           0          0          0                     0                                0                                                      27-MAR-26



       C        8      2 BONUS                 SAL               ORS1                                                                                                                                           0          0          0                     0                                0                                                      27-MAR-26



       T        8      2 CHAINED_ROWS                            ORS1                                                                                                                                           1          5         36          1                                                      0                                           27-MAR-26



       C        8      2 CHAINED_ROWS          ANALYZE_TIMESTAMP ORS1                                                                                                                                           1          1          1          1          0 2461127.94 2461127.94          8                                                      27-MAR-26                                                                               787E031B172403  787E031B172403



       C        8      2 CHAINED_ROWS          CLUSTER_NAME      ORS1                                                                                                                                           0          0          0                     1                                0                                                      27-MAR-26



       C        8   1026 CHAINED_ROWS          HEAD_ROWID        ORS1                                                                                                                                           1          1          1          1          0 2.2693E+31 2.2693E+31         10                                                      27-MAR-26                                                                               00011E6D0600004 00011E6D0600004
                                                                                                                                                                                                                                                                                                                                                   60000            60000



       C        8      2 CHAINED_ROWS          OWNER_NAME        ORS1                                                                                                                                           1          1          1          1          0 4.1186E+35 4.1186E+35          5                                                      27-MAR-26                                                                               4F525331        4F525331



       C        8      2 CHAINED_ROWS          PARTITION_NAME    ORS1                                                                                                                                           0          0          0                     1                                0                                                      27-MAR-26



       C        8      2 CHAINED_ROWS          SUBPARTITION_NAME ORS1                                                                                                                                           1          1          1          1          0 4.0596E+35 4.0596E+35          4                                                      27-MAR-26                                                                               4E2F41          4E2F41



       C        8      2 CHAINED_ROWS          TABLE_NAME        ORS1                                                                                                                                           1          1          1          1          0 3.5998E+35 3.5998E+35          9                                                      27-MAR-26                                                                               4554554449414E5 4554554449414E5
                                                                                                                                                                                                                                                                                                                                                   4                4



       T        8      2 DEPT                                    ORS1                                                                                                                                           4          5         20          4                                                      0                                           27-MAR-26



       I        8      2 PK_DEPT               DEPT              ORS1 ORS1                                                                                                                                      4          1          4          1          1          1          0          4                                                      27-MAR-26
                                                                                                                                                                                                                                                                                6.DEPTNO


       C        8   1026 DEPT                  DEPTNO            ORS1                                                                                                                                           4        .25          4          4          0         10         40          3                                                      27-MAR-26                                                                               C10B            C129



       C        8      2 DEPT                  DNAME             ORS1                                                                                                                                           4        .25          4          4          0 3.3886E+35 4.3229E+35         10                                                      27-MAR-26                                                                               4143434F554E544 53414C4553
                                                                                                                                                                                                                                                                                                                                                   94E47



       C        8      2 DEPT                  LOC               ORS1                                                                                                                                           4        .25          4          4          0 3.4430E+35 4.0641E+35          8                                                      27-MAR-26                                                                               424F53544F4E    4E455720594F524
                                                                                                                                                                                                                                                                                                                                                   B



       T        8      2 DUMMY                                   ORS1                                                                                                                                           1          5          2          1                                                      0                                           27-MAR-26



       C        8      2 DUMMY                 DUMMY             ORS1                                                                                                                                           1          1          1          1          0          0          0          2                                                      27-MAR-26                                                                               80              80



       T        8      2 EMP                                     ORS1                                                                                                                                          14          5         38         14                                                      0                                           27-MAR-26



       I        8      2 PK_EMP                EMP               ORS1 ORS1                                                                                                                                     14          1         14          1          1          1          0         14                                                      27-MAR-26
                                                                                                                                                                                                                                                                                5.EMPNO


       C        8      2 EMP                   COMM              ORS1                                                                                                                                           4        .25          4          4         10          0       1400          2                                                      27-MAR-26                                                                               80              C20F



       C        8   4102 EMP                   DEPTNO            ORS1                                                                                                                                           3 .035714286          3         14          0         10         30          3          1          3         10          0          27-MAR-26                                                                               C10B            C11F
C10B


       C        8   4102 EMP                   DEPTNO            ORS1                                                                                                                                           3 .035714286          3         14          0         10         30          3          1          8         20          0          27-MAR-26                                                                               C10B            C11F
C115


       C        8   4102 EMP                   DEPTNO            ORS1                                                                                                                                           3 .035714286          3         14          0         10         30          3          1         14         30          0          27-MAR-26                                                                               C10B            C11F
C11F


       C        8      2 EMP                   EMPNO             ORS1                                                                                                                                          14 .071428571         14         14          0       7369       7934          4                                                      27-MAR-26                                                                               C24A46          C25023



       C        8      2 EMP                   ENAME             ORS1                                                                                                                                          14 .071428571         14         14          0 3.3888E+35 4.5305E+35          6                                                      27-MAR-26                                                                               4144414D53      57415244



       C        8      2 EMP                   HIREDATE          ORS1                                                                                                                                          13 .076923077         13         14          0    2444591    2445347          8                                                      27-MAR-26                                                                               77B40C11010101  77B7010C010101



       C        8      2 EMP                   JOB               ORS1                                                                                                                                           5         .2          5         14          0 3.3909E+35 4.3229E+35          8                                                      27-MAR-26                                                                               414E414C595354  53414C45534D414
                                                                                                                                                                                                                                                                                                                                                   E



       C        8      2 EMP                   MGR               ORS1                                                                                                                                           6 .166666667          6         13          1       7566       7902          4                                                      27-MAR-26                                                                               C24C43          C25003



       C        8      2 EMP                   SAL               ORS1                                                                                                                                          12 .083333333         12         14          0        800       5000          4                                                      27-MAR-26                                                                               C209            C233



       T        8      2 ETUDIANT                                ORS1                                                                                                                                      100000       3772        287     100000                                                      0                                           27-MAR-26



       I        8      2 PK_ETU                ETUDIANT          ORS1 ORS1                                                                                                                                 100000        187     100000          1          1       3705          1     100000                                                      27-MAR-26
                                                                                                                                                                                                                                                                                4.ETU#


       C        8      2 ETUDIANT              CV                ORS1                                                                                                                                           2         .5          2     100000          0 4.4293E+35 4.4293E+35        276                                                      27-MAR-26                                                                               554E20435620504 554E20435620504
                                                                                                                                                                                                                                                                                                                                                   C45494E2C20554E C45494E2C20554E
                                                                                                                                                                                                                                                                                                                                                   20435620504C454 20435620504C454
                                                                                                                                                                                                                                                                                                                                                   94E2C20554E2043 94E2C20554E2043
                                                                                                                                                                                                                                                                                                                                                   5620504C45494E2 5620504C45494E2
                                                                                                                                                                                                                                                                                                                                                   C20554E20435620 C20554E20435620
                                                                                                                                                                                                                                                                                                                                                   504C45494E2C205 504C45494E2C205
                                                                                                                                                                                                                                                                                                                                                   54E20435620504C 54E20435620504C
                                                                                                                                                                                                                                                                                                                                                   45494E2C         45494E2C



       C        8   1026 ETUDIANT              ETU#              ORS1                                                                                                                                      100000     .00001     100000     100000          0          1     100000          5                                                      27-MAR-26                                                                               C102            C30B



       C        8      2 ETUDIANT              NOM               ORS1                                                                                                                                         129 .007751938        129     100000          0 3.3968E+35 4.6936E+35          8                                                      27-MAR-26                                                                               416B696D        5A656D626C61



       T        8      2 ETUDIANT2                               ORS1                                                                                                                                           1          4        559          1                                                      0                                           27-MAR-26



       C        8      2 ETUDIANT2             CV                ORS1                                                                                                                                           1          1          1          1          0 4.4293E+35 4.4293E+35        549                                                      27-MAR-26                                                                               554E20435620504 554E20435620504
                                                                                                                                                                                                                                                                                                                                                   C45494E2C20554E C45494E2C20554E
                                                                                                                                                                                                                                                                                                                                                   20435620504C454 20435620504C454
                                                                                                                                                                                                                                                                                                                                                   94E2C20554E2043 94E2C20554E2043
                                                                                                                                                                                                                                                                                                                                                   5620504C45494E2 5620504C45494E2
                                                                                                                                                                                                                                                                                                                                                   C20554E20435620 C20554E20435620
                                                                                                                                                                                                                                                                                                                                                   504C45494E2C205 504C45494E2C205
                                                                                                                                                                                                                                                                                                                                                   54E20435620504C 54E20435620504C
                                                                                                                                                                                                                                                                                                                                                   45494E2C         45494E2C



       C        8      2 ETUDIANT2             ETU#              ORS1                                                                                                                                           1          1          1          1          0          1          1          3                                                      27-MAR-26                                                                               C102            C102



       C        8      2 ETUDIANT2             NOM               ORS1                                                                                                                                           1          1          1          1          0 3.5546E+35 3.5546E+35          7                                                      27-MAR-26                                                                               4475706F6E74    4475706F6E74



       T        8      2 SALGRADE                                ORS1                                                                                                                                           5          5         10          5                                                      0                                           27-MAR-26



       I        8      2 PK_SALGRADE           SALGRADE          ORS1 ORS1                                                                                                                                      5          1          5          1          1          1          0          5                                                      27-MAR-26
                                                                                                                                                                                                                                                                                5.GRADE


       C        8      2 SALGRADE              GRADE             ORS1                                                                                                                                           5         .2          5          5          0          1          5          3                                                      27-MAR-26                                                                               C102            C106



       C        8      2 SALGRADE              HISAL             ORS1                                                                                                                                           5         .2          5          5          0       1200       9999          4                                                      27-MAR-26                                                                               C20D            C26464



       C        8      2 SALGRADE              LOSAL             ORS1                                                                                                                                           5         .2          5          5          0        700       3001          4                                                      27-MAR-26                                                                               C208            C21F02



       I        8      2 STATORS               STATORS           ORS1 ORS1                                                                                                                                      0          0          0          0          0          0          0          0                                                      27-MAR-26
                                                                                                                                                                                                                                                                                6.STATID,4.TYPE,2.C5,2.C1,2.C2,2.C3,2.C4,7.VERSION




47 rows selected.

SQL> 




-- vous pouvez ensuite exporter via EXPDP le contenu des statistiques
-- pour un d�placement vers une autre base
set DPUSER=ORS1
set DPDBALIAS=PDBMBDS
expdp %DPUSER%/PassOrs1@%DPDBALIAS% dumpfile=stators.dump tables=STATors


-- Export: Release 10.2.0.3.0 - Production on Jeudi, 11 F�vrier, 2010 10:46:10

-- Copyright (c) 2003, 2005, Oracle.  All rights reserved.


-- resultat :
sh-4.4$ DPUSER=ORS1
sh-4.4$ DPDBALIAS=PDBMBDS
sh-4.4$ expdp ${DPUSER}/PassOrs1@${DPDBALIAS} dumpfile=stators.dump tables=STATors

Export: Release 23.26.1.0.0 - Production on Fri Mar 27 23:31:57 2026
Version 23.26.1.0.0

Copyright (c) 1982, 2026, Oracle and/or its affiliates.  All rights reserved.

Connected to: Oracle AI Database 26ai Free Release 23.26.1.0.0 - Develop, Learn, and Run for Free
Starting "ORS1"."SYS_EXPORT_TABLE_01":  ORS1/********@PDBMBDS dumpfile=stators.dump tables=STATors 
Processing object type TABLE_EXPORT/TABLE/TABLE_DATA
Processing object type TABLE_EXPORT/TABLE/INDEX/STATISTICS/INDEX_STATISTICS
Processing object type TABLE_EXPORT/TABLE/STATISTICS/TABLE_STATISTICS
Processing object type TABLE_EXPORT/TABLE/TABLE
Processing object type TABLE_EXPORT/TABLE/INDEX/INDEX
. . exported "ORS1"."STATORS"                             22.6 KB      47 rows
Master table "ORS1"."SYS_EXPORT_TABLE_01" successfully loaded/unloaded
******************************************************************************
Dump file set for ORS1.SYS_EXPORT_TABLE_01 is:
  /opt/oracle/admin/FREE/dpdump/4A91C0ECC3691091E0636402000AAA96/stators.dump
Job "ORS1"."SYS_EXPORT_TABLE_01" successfully completed at Fri Mar 27 23:32:24 2026 elapsed 0 00:00:25

sh-4.4$ 


--------

**/


-- V�rifier qu'Oracle collecte automatiquement les statistiques sur votre base
-- Comment activer ou d�sactiver la collecte des statitistiques
-- Quels sont les param�tres de configuration actuels de la collecte

-- V�rifier que Oracle collecte automatiquement les statistiques sur votre base

--- en 11g

select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;



-- resultat :
SQL> select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;

CLIENT_NAME                                                      OPERATION_NAME                                                   STATUS
---------------------------------------------------------------- ---------------------------------------------------------------- --------
auto optimizer stats collection                                  auto optimizer stats job                                         ENABLED
auto space advisor                                               auto space advisor job                                           ENABLED
sql tuning advisor                                               automatic sql tuning task                                        ENABLED

SQL> 

----


select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_TASK;

-- resultat :

SQL> select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_TASK;

CLIENT_NAME                                                      OPERATION_NAME                                                   STATUS
---------------------------------------------------------------- ---------------------------------------------------------------- --------
sql tuning advisor                                               automatic sql tuning task                                        ENABLED
auto optimizer stats collection                                  auto optimizer stats job                                         ENABLED
auto space advisor                                               auto space advisor job                                           ENABLED

SQL> 

-----

col client_name format a40
col OPERATION_NAME format a30
set linesize 90
select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;


-- resultat :

SQL> col client_name format a40
col OPERATION_NAME format a30
set linesize 90
select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;SQL> SQL> SQL> 

CLIENT_NAME                              OPERATION_NAME                 STATUS
---------------------------------------- ------------------------------ --------
auto optimizer stats collection          auto optimizer stats job       ENABLED
auto space advisor                       auto space advisor job         ENABLED
sql tuning advisor                       automatic sql tuning task      ENABLED

SQL> 

----

BEGIN
  DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'auto optimizer stats collection', 
    operation => NULL,  window_name => NULL);
END;
/

-- resultat :
SQL> BEGIN
  DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'auto optimizer stats collection', 
    operation => NULL,  window_name => NULL);
END;
/  2    3    4    5    6  

PL/SQL procedure successfully completed.

SQL> 
---
select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;

-- resultat :

SQL> select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;

CLIENT_NAME                              OPERATION_NAME                 STATUS
---------------------------------------- ------------------------------ --------
auto optimizer stats collection          auto optimizer stats job       DISABLED
auto space advisor                       auto space advisor job         ENABLED
sql tuning advisor                       automatic sql tuning task      ENABLED

SQL> 

----

BEGIN
  DBMS_AUTO_TASK_ADMIN.ENABLE(
    client_name => 'auto optimizer stats collection', 
    operation => NULL,  window_name => NULL);
END;
/

-- resultat :

SQL> BEGIN
  DBMS_AUTO_TASK_ADMIN.ENABLE(
    client_name => 'auto optimizer stats collection', 
    operation => NULL,  window_name => NULL);
END;
/  2    3    4    5    6  

PL/SQL procedure successfully completed.

SQL> 

----
select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;


-- resultat :
SQL> select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;

CLIENT_NAME                              OPERATION_NAME                 STATUS
---------------------------------------- ------------------------------ --------
auto optimizer stats collection          auto optimizer stats job       ENABLED
auto space advisor                       auto space advisor job         ENABLED
sql tuning advisor                       automatic sql tuning task      ENABLED

SQL> 

----


-- Quels sont les param�tres de configuration actuels de la collecte
DBMS_STATS.GET_PARAM (
pname IN VARCHAR2)
RETURN VARCHAR2;

set serveroutput on

-- modification des param�tres
--dbms_stats.set_param('CASCADE','DBMS_STATS.AUTO_CASCADE');
--dbms_stats.set_param('ESTIMATE_PERCENT','5'); 
--dbms_stats.set_param('DEGREE','NULL');

declare
param varchar2(1000);
begin
param:=DBMS_STATS.GET_PARAM ('ESTIMATE_PERCENT');
dbms_output.put_line('ESTIMATE_PERCENT='||param);
param:=DBMS_STATS.GET_PARAM ('CASCADE');
dbms_output.put_line('CASCADE='||param);
param:=DBMS_STATS.GET_PARAM ('DEGREE');
dbms_output.put_line('DEGREE='||param);
end;
/

-- resultat :

SQL> DBMS_STATS.GET_PARAM (
pname IN VARCHAR2)
RETURN VARCHAR2;

set serveroutput on

-- modification des param�tres
--dbms_stats.set_param('CASCADE','DBMS_STATS.AUTO_CASCADE');
--dbms_stats.set_param('ESTIMATE_PERCENT','5'); 
--dbms_stats.set_param('DEGREE','NULL');

declare
param varchar2(1000);
begin
param:=DBMS_STATS.GET_PARAM ('ESTIMATE_PERCENT');
dbms_output.put_line('ESTIMATE_PERCENT='||param);
param:=DBMS_STATS.GET_PARAM ('CASCADE');
dbms_output.put_line('CASCADE='||param);
param:=DBMS_STATS.GET_PARAM ('DEGREE');
dbms_output.put_line('DEGREE='||param);
end;
/SP2-0734: unknown command beginning "RETURN VAR..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SP2-0734: unknown command beginning "pname IN V..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SP2-0044: For a list of known commands enter HELP
and to leave enter EXIT.
Help: https://docs.oracle.com/error-help/db/sp2-0044/
SQL> SP2-0734: unknown command beginning "RETURN VAR..." - rest of line ignored.
Help: https://docs.oracle.com/error-help/db/sp2-0734/
SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11  
ESTIMATE_PERCENT=DBMS_STATS.AUTO_SAMPLE_SIZE
CASCADE=DBMS_STATS.AUTO_CASCADE
DEGREE=NULL

PL/SQL procedure successfully completed.

SQL> 

-- modification d'un param�tre
execute dbms_stats.set_param('ESTIMATE_PERCENT','5'); 
--resultat :
SQL> execute dbms_stats.set_param('ESTIMATE_PERCENT','5'); 

PL/SQL procedure successfully completed.

SQL> 
--
execute dbms_stats.set_param('DEGREE','NULL');

-- resultat :
SQL> execute dbms_stats.set_param('DEGREE','NULL');

PL/SQL procedure successfully completed.

SQL> 

--

declare
param varchar2(1000);
begin
param:=DBMS_STATS.GET_PARAM ('ESTIMATE_PERCENT');
dbms_output.put_line('ESTIMATE_PERCENT='||param);
param:=DBMS_STATS.GET_PARAM ('CASCADE');
dbms_output.put_line('CASCADE='||param);
param:=DBMS_STATS.GET_PARAM ('DEGREE');
dbms_output.put_line('DEGREE='||param);
end;
/

-- resultat :

SQL> declare
param varchar2(1000);
begin
param:=DBMS_STATS.GET_PARAM ('ESTIMATE_PERCENT');
dbms_output.put_line('ESTIMATE_PERCENT='||param);
param:=DBMS_STATS.GET_PARAM ('CASCADE');
dbms_output.put_line('CASCADE='||param);
param:=DBMS_STATS.GET_PARAM ('DEGREE');
dbms_output.put_line('DEGREE='||param);
end;
/  2    3    4    5    6    7    8    9   10   11  
ESTIMATE_PERCENT=5
CASCADE=DBMS_STATS.AUTO_CASCADE
DEGREE=NULL

PL/SQL procedure successfully completed.

SQL> 

-- modification des param�tres
execute dbms_stats.set_param('ESTIMATE_PERCENT','DBMS_STATS.AUTO_SAMPLE_SIZE');
-- resultat :
SQL> execute dbms_stats.set_param('ESTIMATE_PERCENT','DBMS_STATS.AUTO_SAMPLE_SIZE'); 

PL/SQL procedure successfully completed.

SQL> 
----
execute dbms_stats.set_param('DEGREE','DBMS_STATS.AUTO_DEGREE');

-- resultat: 
SQL> execute dbms_stats.set_param('DEGREE','DBMS_STATS.AUTO_DEGREE'); 

PL/SQL procedure successfully completed.

SQL> 

execute dbms_stats.set_param('CASCADE','DBMS_STATS.AUTO_CASCADE');

-- resultat :


SQL> execute dbms_stats.set_param('CASCADE','DBMS_STATS.AUTO_CASCADE'); 

PL/SQL procedure successfully completed.

SQL> 

---

declare
param varchar2(1000);
begin
param:=DBMS_STATS.GET_PARAM ('ESTIMATE_PERCENT');
dbms_output.put_line('ESTIMATE_PERCENT='||param);
param:=DBMS_STATS.GET_PARAM ('CASCADE');
dbms_output.put_line('CASCADE='||param);
param:=DBMS_STATS.GET_PARAM ('DEGREE');
dbms_output.put_line('DEGREE='||param);
end;
/

-- resultat :


SQL> declare
param varchar2(1000);
begin
param:=DBMS_STATS.GET_PARAM ('ESTIMATE_PERCENT');
dbms_output.put_line('ESTIMATE_PERCENT='||param);
param:=DBMS_STATS.GET_PARAM ('CASCADE');
dbms_output.put_line('CASCADE='||param);
param:=DBMS_STATS.GET_PARAM ('DEGREE');
dbms_output.put_line('DEGREE='||param);
end;
/  2    3    4    5    6    7    8    9   10   11  
ESTIMATE_PERCENT=DBMS_STATS.AUTO_SAMPLE_SIZE
CASCADE=DBMS_STATS.AUTO_CASCADE
DEGREE=DBMS_STATS.AUTO_DEGREE

PL/SQL procedure successfully completed.

SQL> 

----

/*
Exercice 5.5 

Mettre en �vidence que l'optimiseur de statistique et l'optimiseur 
de r�gles ne prennent pas souvent les m�mes d�cisions

Soient les tables Emp et Dept et les index sur ename, deptno dans emp 
et deptno dans dept. G�n�rer les plans des deux requ�tes ci-dessous et comparer. 
Il est � savoir que l'optimiseur de r�gles en cas d'index sur les deux colonnes
 de jointures, il choisit la table la plus � droite de la clause FROM comme
 premi�re table (elle est lue s�quentiellement)

Alter session set OPTIMIZER_MODE=rule;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME  FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

-- resultat :

SQL> Alter session set OPTIMIZER_MODE=rule;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME  FROM dept, emp
WHERE emp.deptno=dept.deptno ; 
Session altered.

SQL>   2  

     EMPNO ENAME          DEPTNO DNAME
---------- ---------- ---------- --------------
      7369 SMITH              20 RESEARCH
      7499 ALLEN              30 SALES
      7521 WARD               30 SALES
      7566 JONES              20 RESEARCH
      7654 MARTIN             30 SALES
      7698 BLAKE              30 SALES
      7782 CLARK              10 ACCOUNTING
      7788 SCOTT              20 RESEARCH
      7839 KING               10 ACCOUNTING
      7844 TURNER             30 SALES
      7876 ADAMS              20 RESEARCH
      7900 JAMES              30 SALES
      7902 FORD               20 RESEARCH
      7934 MILLER             10 ACCOUNTING

14 rows selected.

SQL> 


Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

-- resultat :

SQL> Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 
Session altered.

SQL>   2    3  

     EMPNO ENAME          DEPTNO DNAME
---------- ---------- ---------- --------------
      7369 SMITH              20 RESEARCH
      7499 ALLEN              30 SALES
      7521 WARD               30 SALES
      7566 JONES              20 RESEARCH
      7654 MARTIN             30 SALES
      7698 BLAKE              30 SALES
      7782 CLARK              10 ACCOUNTING
      7788 SCOTT              20 RESEARCH
      7839 KING               10 ACCOUNTING
      7844 TURNER             30 SALES
      7876 ADAMS              20 RESEARCH
      7900 JAMES              30 SALES
      7902 FORD               20 RESEARCH
      7934 MILLER             10 ACCOUNTING

14 rows selected.

SQL> 




*/


-- 5.5 Mettre en �vidence que l'optimiseur de statistique et 
-- l'optimiseur de r�gles ne prennent pas souvent les 
-- m�mes d�cisions

-- Soient les tables Emp et Dept et les index sur ename, 
-- deptno dans emp et deptno dans dept. G�n�rer les plans 
-- des deux requ�tes ci-dessous et comparer. Il est � 
-- savoir que l'optimiseur de r�gles en cas d'index sur les
--  deux colonnes de jointures, il choisit la table la plus 
--  � gauche de la clause FROM comme premi�re table 
--  (elle est lue s�quentiellement)

 col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('EMP', 'DEPT');
 
 -- resultat :

SQL>  col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('EMP', 'DEPT');SQL>   2    3  

TABLE_NAME   COLUMN_NAME          INDEX_NAME
------------ -------------------- --------------------
DEPT         DEPTNO               PK_DEPT
EMP          EMPNO                PK_EMP

SQL> 

-----

SQL> set autotrace on
SQL>  col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('EMP', 'DEPT');SQL>   2    3  

TABLE_NAME   COLUMN_NAME          INDEX_NAME
------------ -------------------- --------------------
DEPT         DEPTNO               PK_DEPT
EMP          EMPNO                PK_EMP
EMP          JOB                  IDX_EMP_JOB_SAL
EMP          SAL                  IDX_EMP_JOB_SAL
EMP          COMM                 IDX_EMP_COMM
EMP          SEXE                 IDX_EMP_SEXE
EMP          ENAME                IDX_EMP_ENAME

7 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1401642928

-------------------------------------------------------------------
| Id  | Operation                           | Name                |
-------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                     |
|   1 |  VIEW                               | USER_IND_COLUMNS_V$ |
|   2 |   UNION-ALL                         |                     |
|   3 |    NESTED LOOPS OUTER               |                     |
|   4 |     TABLE ACCESS BY INDEX ROWID     | COL$                |
|*  5 |      INDEX UNIQUE SCAN              | I_COL3              |
|*  6 |     TABLE ACCESS CLUSTER            | ATTRCOL$            |
|*  7 |    FILTER                           |                     |
|   8 |     NESTED LOOPS                    |                     |
|   9 |      NESTED LOOPS                   |                     |
|  10 |       NESTED LOOPS                  |                     |
|  11 |        NESTED LOOPS OUTER           |                     |
|  12 |         NESTED LOOPS                |                     |
|  13 |          NESTED LOOPS               |                     |
|* 14 |           INDEX RANGE SCAN          | I_OBJ2              |
|  15 |           TABLE ACCESS CLUSTER      | ICOL$               |
|* 16 |            INDEX UNIQUE SCAN        | I_OBJ#              |
|  17 |          TABLE ACCESS CLUSTER       | COL$                |
|* 18 |           INDEX UNIQUE SCAN         | I_OBJ#              |
|* 19 |         TABLE ACCESS CLUSTER        | ATTRCOL$            |
|  20 |        TABLE ACCESS BY INDEX ROWID  | OBJ$                |
|* 21 |         INDEX RANGE SCAN            | I_OBJ1              |
|* 22 |       INDEX UNIQUE SCAN             | I_IND1              |
|* 23 |      TABLE ACCESS BY INDEX ROWID    | IND$                |
|* 24 |     TABLE ACCESS CLUSTER            | TAB$                |
|* 25 |      INDEX UNIQUE SCAN              | I_OBJ#              |
|  26 |    NESTED LOOPS OUTER               |                     |
|  27 |     TABLE ACCESS BY INDEX ROWID     | COL$                |
|* 28 |      INDEX UNIQUE SCAN              | I_COL3              |
|* 29 |     TABLE ACCESS CLUSTER            | ATTRCOL$            |
|* 30 |    FILTER                           |                     |
|  31 |     NESTED LOOPS OUTER              |                     |
|  32 |      NESTED LOOPS                   |                     |
|  33 |       NESTED LOOPS                  |                     |
|  34 |        NESTED LOOPS                 |                     |
|  35 |         NESTED LOOPS                |                     |
|* 36 |          INDEX RANGE SCAN           | I_OBJ2              |
|* 37 |          TABLE ACCESS BY INDEX ROWID| IND$                |
|* 38 |           INDEX UNIQUE SCAN         | I_IND1              |
|  39 |         TABLE ACCESS BY INDEX ROWID | ICOL$               |
|* 40 |          INDEX RANGE SCAN           | I_ICOL1             |
|* 41 |        TABLE ACCESS BY INDEX ROWID  | OBJ$                |
|* 42 |         INDEX RANGE SCAN            | I_OBJ1              |
|  43 |       TABLE ACCESS BY INDEX ROWID   | COL$                |
|* 44 |        INDEX UNIQUE SCAN            | I_COL3              |
|* 45 |      TABLE ACCESS CLUSTER           | ATTRCOL$            |
|* 46 |     TABLE ACCESS CLUSTER            | TAB$                |
|* 47 |      INDEX UNIQUE SCAN              | I_OBJ#              |
-------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   5 - access("TC"."OBJ#"=:B1 AND "TC"."INTCOL#"=:B2-1)
   6 - filter("TC"."INTCOL#"="AC"."INTCOL#"(+))
   7 - filter("BASE"."TYPE#"<>2 OR  (SELECT 1 FROM "SYS"."TAB$" "T"
              WHERE "T"."OBJ#"=:B1 AND BITAND("T"."PROPERTY",36893488147419103232)=0)=
              1)
  14 - access("BASE"."OWNER#"=USERENV('SCHEMAID'))
       filter(("BASE"."NAME"='EMP' OR "BASE"."NAME"='DEPT') AND
              ("BASE"."NAMESPACE"=1 OR "BASE"."NAMESPACE"=5))
  16 - access("IC"."BO#"="BASE"."OBJ#")
  18 - access("C"."OBJ#"="BASE"."OBJ#")
  19 - filter("C"."INTCOL#"="AC"."INTCOL#"(+))
  21 - access("IC"."OBJ#"="IDX"."OBJ#")
  22 - access("IDX"."OBJ#"="I"."OBJ#")
  23 - filter(("I"."TYPE#"=1 OR "I"."TYPE#"=2 OR "I"."TYPE#"=3 OR
              "I"."TYPE#"=4 OR "I"."TYPE#"=6 OR "I"."TYPE#"=7 OR "I"."TYPE#"=9 OR
              "I"."TYPE#"=10) AND "C"."INTCOL#"=DECODE(BITAND("I"."PROPERTY",1024),0,"
              IC"."INTCOL#","IC"."SPARE2"))
  24 - filter(BITAND("T"."PROPERTY",36893488147419103232)=0)
  25 - access("T"."OBJ#"=:B1)
  28 - access("TC"."OBJ#"=:B1 AND "TC"."INTCOL#"=:B2-1)
  29 - filter("TC"."INTCOL#"="AC"."INTCOL#"(+))
  30 - filter("BASE"."TYPE#"<>2 OR  (SELECT 1 FROM "SYS"."TAB$" "T"
              WHERE "T"."OBJ#"=:B1 AND BITAND("T"."PROPERTY",36893488147419103232)=0)=
              1)
  36 - access("IDX"."OWNER#"=USERENV('SCHEMAID') AND
              "IDX"."NAMESPACE"=4)
       filter("IDX"."NAMESPACE"=4)
  37 - filter("I"."TYPE#"=1 OR "I"."TYPE#"=2 OR "I"."TYPE#"=3 OR
              "I"."TYPE#"=4 OR "I"."TYPE#"=6 OR "I"."TYPE#"=7 OR "I"."TYPE#"=9 OR
              "I"."TYPE#"=10)
  38 - access("IDX"."OBJ#"="I"."OBJ#")
  40 - access("IC"."OBJ#"="IDX"."OBJ#")
  41 - filter("BASE"."NAME"='EMP' OR "BASE"."NAME"='DEPT')
  42 - access("I"."BO#"="BASE"."OBJ#")
       filter("BASE"."OWNER#"<>USERENV('SCHEMAID'))
  44 - access("C"."OBJ#"="BASE"."OBJ#" AND
              "C"."INTCOL#"=DECODE(BITAND("I"."PROPERTY",1024),0,"IC"."INTCOL#","IC"."
              SPARE2"))
  45 - filter("C"."INTCOL#"="AC"."INTCOL#"(+))
  46 - filter(BITAND("T"."PROPERTY",36893488147419103232)=0)
  47 - access("T"."OBJ#"=:B1)

Note
-----
   - rule based optimizer used (consider using cbo)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
        234  consistent gets
          0  physical reads
          0  redo size
        975  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
          7  rows processed

SQL> 

--- 

create index idx_emp_deptno on emp(deptno);
-- resultat :
SQL> create index idx_emp_deptno on emp(deptno);

Index created.

SQL> 

--------
execute dbms_stats.gather_table_stats('&MYUSER', 'EMP');
-- resultat :

SQL> execute dbms_stats.gather_table_stats('&MYUSER', 'EMP');

PL/SQL procedure successfully completed.

SQL> 

-----
Alter session set OPTIMIZER_MODE=rule;
-- resultat :
SQL> Alter session set OPTIMIZER_MODE=rule;

Session altered.

SQL> 

---
set autotrace on
set linesize 200
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME  FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

-- resultat :

SQL> set autotrace on
set linesize 200SQL> 
SQL> SELECT EMPNO, ENAME, dept.DEPTNO, DNAME  FROM dept, emp
WHERE emp.deptno=dept.deptno ;   2  

     EMPNO ENAME          DEPTNO DNAME
---------- ---------- ---------- --------------
      7369 SMITH              20 RESEARCH
      7499 ALLEN              30 SALES
      7521 WARD               30 SALES
      7566 JONES              20 RESEARCH
      7654 MARTIN             30 SALES
      7698 BLAKE              30 SALES
      7782 CLARK              10 ACCOUNTING
      7788 SCOTT              20 RESEARCH
      7839 KING               10 ACCOUNTING
      7844 TURNER             30 SALES
      7876 ADAMS              20 RESEARCH
      7900 JAMES              30 SALES
      7902 FORD               20 RESEARCH
      7934 MILLER             10 ACCOUNTING

14 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3625962092

------------------------------------------------
| Id  | Operation                    | Name    |
------------------------------------------------
|   0 | SELECT STATEMENT             |         |
|   1 |  NESTED LOOPS                |         |
|   2 |   NESTED LOOPS               |         |
|   3 |    TABLE ACCESS FULL         | EMP     |
|*  4 |    INDEX UNIQUE SCAN         | PK_DEPT |
|   5 |   TABLE ACCESS BY INDEX ROWID| DEPT    |
------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("EMP"."DEPTNO"="DEPT"."DEPTNO")

Note
-----
   - rule based optimizer used (consider using cbo)


Statistics
----------------------------------------------------------
         92  recursive calls
          6  db block gets
        103  consistent gets
          2  physical reads
        948  redo size
       1254  bytes sent via SQL*Net to client
        108  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          7  sorts (memory)
          0  sorts (disk)
         14  rows processed

SQL> 

----


set autotrace traceonly explain

Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

-- resultat :
SQL> set autotrace traceonly explain
SQL> Alter session set OPTIMIZER_MODE=first_rows_1;

Session altered.

SQL> SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 
  2    3  
Execution Plan
----------------------------------------------------------
Plan hash value: 3625962092

----------------------------------------------------------------------------------------
| Id  | Operation                    | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |         |     1 |    26 |     3   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                |         |     1 |    26 |     3   (0)| 00:00:01 |
|   2 |   NESTED LOOPS               |         |     1 |    26 |     3   (0)| 00:00:01 |
|   3 |    TABLE ACCESS FULL         | EMP     |     1 |    13 |     2   (0)| 00:00:01 |
|*  4 |    INDEX UNIQUE SCAN         | PK_DEPT |     1 |       |     0   (0)| 00:00:01 |
|   5 |   TABLE ACCESS BY INDEX ROWID| DEPT    |     1 |    13 |     1   (0)| 00:00:01 |
----------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("EMP"."DEPTNO"="DEPT"."DEPTNO")

SQL> 

-------

Alter session set OPTIMIZER_MODE=all_rows;
-- resultat :
SQL> Alter session set OPTIMIZER_MODE=all_rows;

Session altered.

SQL> 

-----
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

-- resultat :
SQL> SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ;   2    3  

Execution Plan
----------------------------------------------------------
Plan hash value: 844388907

----------------------------------------------------------------------------------------
| Id  | Operation                    | Name    | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |         |    14 |   364 |     6  (17)| 00:00:01 |
|   1 |  MERGE JOIN                  |         |    14 |   364 |     6  (17)| 00:00:01 |
|   2 |   TABLE ACCESS BY INDEX ROWID| DEPT    |     4 |    52 |     2   (0)| 00:00:01 |
|   3 |    INDEX FULL SCAN           | PK_DEPT |     4 |       |     1   (0)| 00:00:01 |
|*  4 |   SORT JOIN                  |         |    14 |   182 |     4  (25)| 00:00:01 |
|   5 |    TABLE ACCESS FULL         | EMP     |    14 |   182 |     3   (0)| 00:00:01 |
----------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("EMP"."DEPTNO"="DEPT"."DEPTNO")
       filter("EMP"."DEPTNO"="DEPT"."DEPTNO")

SQL> 

-------

-- Refaire la m�me requ�te sur les tables BIGEMP2 et BIGDEPT2
set autotrace off
col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('BIGEMP2', 'BIGDEPT2');
 
-- resultat :


SQL> set autotrace off
col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('BIGEMP2', 'BIGDEPT2');SQL> SQL>   2    3  

TABLE_NAME   COLUMN_NAME          INDEX_NAME
------------ -------------------- --------------------
BIGDEPT2     DEPTNO               PK_BIGDEPT2
BIGEMP2      EMPNO                PK_BIGEMP2
BIGEMP2      SEXE                 IDX_BIGEMP2_SEXE
BIGEMP2      ENAME                IDX_BIDGEMP2_ENAME

SQL> 

------

create index idx_bigemp2_deptno on bigemp2(deptno);
--- resultat 
SQL> create index idx_bigemp2_deptno on bigemp2(deptno);

Index created.

SQL> 
-------
execute dbms_stats.gather_table_stats('&MYUSER', 'BIGEMP2');
-- resultat :
SQL> execute dbms_stats.gather_table_stats('&MYUSER', 'BIGEMP2');

PL/SQL procedure successfully completed.

SQL> 

-----
Alter session set OPTIMIZER_MODE=rule;
-- resultat :
SQL> Alter session set OPTIMIZER_MODE=rule;

Session altered.

SQL> 

-----
set autotrace traceonly explain
SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME  FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 

--- resultat :


SQL> set autotrace traceonly explain
SQL> SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME  FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ;   2  

Execution Plan
----------------------------------------------------------
Plan hash value: 2035656552

----------------------------------------------------
| Id  | Operation                    | Name        |
----------------------------------------------------
|   0 | SELECT STATEMENT             |             |
|   1 |  NESTED LOOPS                |             |
|   2 |   NESTED LOOPS               |             |
|   3 |    TABLE ACCESS FULL         | BIGEMP2     |
|*  4 |    INDEX UNIQUE SCAN         | PK_BIGDEPT2 |
|   5 |   TABLE ACCESS BY INDEX ROWID| BIGDEPT2    |
----------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("BIGEMP2"."DEPTNO"="BIGDEPT2"."DEPTNO")

Note
-----
   - rule based optimizer used (consider using cbo)

SQL> 

-------

set autotrace traceonly explain

Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME
FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 

-- resultat :

SQL> set autotrace traceonly explain

Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME
FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; SQL> SQL> 
Session altered.

SQL>   2    3  

Execution Plan
----------------------------------------------------------
Plan hash value: 2035656552

--------------------------------------------------------------------------------------------
| Id  | Operation                    | Name        | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |             |     1 |    37 |     2   (0)| 00:00:01 |
|   1 |  NESTED LOOPS                |             |     1 |    37 |     2   (0)| 00:00:01 |
|   2 |   NESTED LOOPS               |             |     1 |    37 |     2   (0)| 00:00:01 |
|   3 |    TABLE ACCESS FULL         | BIGEMP2     |     1 |    15 |     2   (0)| 00:00:01 |
|*  4 |    INDEX UNIQUE SCAN         | PK_BIGDEPT2 |     1 |       |     0   (0)| 00:00:01 |
|   5 |   TABLE ACCESS BY INDEX ROWID| BIGDEPT2    |     1 |    22 |     0   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("BIGEMP2"."DEPTNO"="BIGDEPT2"."DEPTNO")

Note
-----
   - dynamic statistics used: dynamic sampling (level=2)

SQL> 

----


Alter session set OPTIMIZER_MODE=all_rows;
SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME
FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 

?

SELECT /*+ INDEX(bigemp2 idx_bigemp2_deptno)*/EMPNO, ENAME, bigdept2.DEPTNO, DNAME
FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 

?

SELECT /*+USE_NL(bigdept2,  bigemp2)*/ EMPNO, ENAME, bigdept2.DEPTNO, DNAME
FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 


/*
6. Etude de cas

Mesurer les temps acc�s aux enregistrements de deux tables (emp3 et dept3), 
colonne de jointure deptno et produire les plans d'acc�s :

1) via une jointure
2) via un cluster avec cl� index�e
3) via un cluster avec cl� hach�e.

Pour 2) et 3) il est n�cessaire de :
a)cr�er un cluster,
b)cr�er deux tables emp3 et dept3 copies conformes de emp et dept.

Note : pour les mesures, utiliser TKPROF ou AUTOTRACE
*/

-- 6. Etude de cas

-- Mesurer les temps acc�s aux enregistrements de deux tables (emp3 et dept3), 
-- colonne de jointure deptno et produire les plans d'acc�s :

-- 1) via une jointure
-- Jointure sans tables en cluster (RBO, CBO)
-- Jointure avec tables en cluster index (RBO, CBO)
-- Jointure avec tables en cluster hach� (RBO, CBO)
-- cr�ation et insertion de lignes dans les tables EMP4 et DEPT4
-- cr�ation et insertion de lignes dans les tables IEMP4 et IDEPT4 (
-- cluster index�)
-- cr�ation et insertion de lignes dans les tables HEMP4 et HDEPT4 (
-- cluster hach�)

-- EMP4 � 100000 lignes
-- changer de r�pertoire et se d�placer jusqu'au script
-- du cours Tuning.

-- Veuillez �diter et adapter le script ci-dessous pour poursuivre l'activit�.
2aEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_START.sql




