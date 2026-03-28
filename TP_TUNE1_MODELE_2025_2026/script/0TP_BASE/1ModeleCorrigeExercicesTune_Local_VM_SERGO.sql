-- créer un utilisateur de travail appelé ORS1
-- lui donner les droits DBA
-- Modifier les paramètres de langue afin d'installer 
-- sans erreurs de date le script DEMOBLD
-- Ce script contient 4 tables dont 2 qui seront utlisées
-- dans nos exercices : 
-- DEPT : TABLE des départements d'une entreprise
-- EMP  : Table des employés d'une entreprise.
-- Une FK existe dans EMP pour indiquer les département des employés
-- Notes :

-- 1) s'il ya des chemins physiques, il faut les adapter à votre situation


-- *****Cas 1 : VOUS ETES SUR UNE BASE LOCALE *****************

cmd
-- Lancer sqlplus sans se logger
sqlplus /nolog

-- Définir la variable qui indique l'emplacement des scripts
define SCRIPTPATH=D:\1agm05092005\1Cours\5ORS\2021_2022\0Auditeurs\ESTIA\TP_TUNE1_MODELE_2021_2022\script\0TP_BASE

-- Définir la vairiable qui va contenir le nom réseau de votre base.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIAS=PDBMBDS

-- Définir la variable contenant le nom de l'utilisateur que vous allez créer
define MYUSER=ORS1

-- Définir la variable contenant le password du compte SYSTEM
define SYSTEMPASSWORD=OracleSysdbaCours21c01

-- 
define MYINSTANCE=Cours21c

-- Se connecter avec votre compte System pour créer l'utilisateur 
connect system@&DBALIAS/&SYSTEMPASSWORD

-- suprimer l'utilisateur s'il existe déjà
drop user &MYUSER cascade;

-- Création de l'utilisateur. 
create user &MYUSER identified by PassOrs1
default tablespace users
temporary tablespace temp;

-- affecter et enlever des droits
grant dba to &MYUSER;

revoke unlimited tablespace from &MYUSER;

-- connection avec le nouvel utilisateur. Il faut respecter la casse pour le password
connect &MYUSER@&DBALIAS/PassOrs1

alter user &MYUSER quota unlimited on users;

-- **** Cas 2 : vous vous connectez sur ma base DBCOURS **** 
-- connectez vous comme suit. L'alias DBCOURSH doit avoir été 
-- défini dans le fichier tnsnames.ora
connect ETxxxxx1M17@DBCOURSH/ETxxxxx1M1701
ou via sqldeveloper

-- A tous les coûts ************************** 
-- Exécutez ce qui suit 

-- Le script demobld.sql est dans le dossier chemin\script
sql>@&SCRIPTPATH\demobld.sql
-- liste des tables crées
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

Créer un index Btree non unique sur la colonne ENAME de la table EMP. L'index doit être localisé dans le tablespace USERS

Créer un index concaténé sur les colonnes Job et Sal de la table EMP. L'index doit être localiser dans le tablespace USERS. Faites aussi en sorte que 5 transactions puissent être inscrites en même temps

Créer un index Bitmap sur la colonne COMM (commission) de la table EMP. Le localiser dans le tablespace USERS.

Calculer la volumétrie des trois index sur la colonne COMM (commission) de la table EMP. 

Ecrire une requête qui renvoie des informations sur le job et le salaire pour tous les salaires supérieurs à 7000 et le job égal à CLERK : d'abord en ramenant toutes les colonnes puis en ramenant uniquement le job et le salaire.
Avant de lancer les requêtes faire :
Set AUTOTRACE ON pour visualiser les plans

Ecrire une requête qui permet de visualiser les informations sur les employés dont le numéro est supérieur 7839 et dont la commission est supérieure à 0
Avant de lancer les requêtes faire :
Set AUTOTRACE ON pour visualiser les plans

Supprimer tous les index et relancer les requêtes précédentes
*/

-- Calculer la volumétrie des trois index de la table EMP. 

-- créer une procédure stockée pour calculer la volumétrie
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

-- Utilisation de la procédure stockée pour calculer la volumétrie
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

taille_utilise pour idx_emp_ename=84
taille_alloue pour idx_emp_ename=65536
taille_utilise pour idx_emp_job_sal=168
taille_alloue pour idx_emp_job_sal=65536
taille_utilise pour idx_emp_comm=28
taille_alloue pour idx_emp_comm=65536


-- Quel est l'intérêt de connaître la volumétrie de vos objets ?
?
-- recalculer le TIS : taille initiale du segment  et recréer les indexes avec la bonne taille

TIS=initial+(next *(minextents  -1))

?
-- Créer un index Btree non unique sur la colonne ENAME de la table EMP. 
-- L'index doit être localisé dans le tablespace USERS
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

-- Créer un index concaténé sur les colonnes Job et Sal de la table EMP. 
-- L'index doit être localiser dans le tablespace USERS. Faites aussi en 
-- sorte que 5 transactions puissent être inscrites en même temps
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

--Créer un index Bitmap sur la colonne COMM (commission) de la table EMP. 
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








--Ecrire une requête qui renvoie des informations sur le job et 
--le salaire pour tous les salaires supérieurs à 7000 
--et le job égal à CLERK : d'abord en ramenant toutes les colonnes 
-- puis en ramenant uniquement le job et le salaire.
-- Avant de lancer les requêtes faire :
-- Set AUTOTRACE ON pour visualiser les plans
-- Copier et coller le résultat des requêtes à la place de ?

Set AUTOTRACE ON
set linesize 300
select *
from emp
where sal>1000 and job='CLERK';

?



select/*+FULL (emp)*/ *
from emp
where sal>1000 and job='CLERK';

?

		  

select job, sal, ename
from emp
where sal>1000 and job='CLERK';

?



select *
from emp
where sal>1000 ;

?

select *
from emp
where job='CLERK' ;

?

-- Ecrire une requête qui permet de visualiser les informations 
-- sur les employés dont le numéro est supérieur 7839 et dont la 
-- commission est supérieure à 0
-- Avant de lancer les requêtes faire :
-- Set AUTOTRACE ON pour visualiser les plans

-- Supprimer tous les index et relancer les requêtes précédentes

Set AUTOTRACE ON
set linesize 200
select * from emp
where comm >0;

?
select /*+INDEX(emp idx_emp_comm)*/ * from emp
where comm >0;


select count(*) from emp
where comm >0;

?

select * from emp
where comm >0 and empno=7839;

?

set autotrace off
/*
Exercice 4.1

Visualiser avec les différentes méthodes les plans d'exécution de la requête suivante :

	 select * from emp  where empno=7934;

-- a) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY() pour lire un plan généré dans PLAN_TABLE
-- Pas d'exécution de la requête. Seul le plan est généré dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase développement.

-- b) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY_CURSOR(sql_id) pour lire un plan généré 
-- dans la Zone des requêtes partagées (sqlarea). Ce plan est disponible dans les vues V$SQL_PLAN et 
-- V$SQL_PLAN_STATISTICS_ALL. La requête est en exécution normal. 
-- Cette approche est utile en phase développement ou en phase production (exploitation).

-- c) Utiliser le paramètre AUTOTRACE pour lire un plan généré dans la Zone des requêtes partagées (sqlarea). 
-- Ce plan est disponible dans les vues V$SQL_PLAN et V$SQL_PLAN_STATISTICS_ALL
-- Voici les effets d'AUTOTRACE : 
--   . set autotrace ON (idem: set autotrace ON EXPLAIN STATISTICS): Affiche le résultat+le plan + les statistiques
--   . set autotrace ON EXPLAIN : Affiche le résultat+le plan
--   . set autotrace ON STATISTICS : Affiche le résultat + les statistiques
--   . set autotrace TRACEONLY : Affiche le plan+les statistiques mais pas le résultat
--   . set autotrace TRACEONLY EXPLAIN : Affiche le plan mais pas le résultat et pas de statistiques
--   . set autotrace TRACEONLY STATISTICS : : Affiche le statistiques seules mais pas le résultat et pas de plan

-- Cette approche est utile en phase développement uniquement.

-- d) Ecrire sa propre requête pour lire un plan généré dans PLAN_TABLE
-- Pas d'exécution de la requête. Seul le plan est généré dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase développement.

-- e) Utiliser TKPROF pour calculer les temps d'exécution de plusieurs requêtes.
-- Générer le fichier de trace. Bien identifier votre fichier et générer avec TKPROF les temps mis
-- ansi que les plans d'exécution.



*/


-- Visualiser avec les différentes méthodes les plans d'exécution 
-- de la requête 
-- suivante :

set autotrace off

select * from emp  where empno=7934;

-- a) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY() pour lire un plan généré dans PLAN_TABLE
-- Pas d'exécution de la requête. Seul le plan est généré dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase développement.

Alter session set optimizer_mode=all_rows;
delete from plan_table;
EXPLAIN PLAN
for select * from emp  where empno=7934;

set linesize 200

SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY());

?

-- b) Utiliser le package DBMS_XPLAN et sa fonction DISPLAY_CURSOR(sql_id) pour lire un plan généré 
-- dans la Zone des requêtes partagées (sqlarea). Ce plan est disponible dans les vues V$SQL_PLAN et 
-- V$SQL_PLAN_STATISTICS_ALL. La requête est en exécution normal. 
-- Cette approche est utile en phase développement ou en phase production (exploitation).

set pagesize 100
delete from plan_table;

select * from emp  where empno=7934;


SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(DBMS_XPLAN.DISPLAY_cursor);


?

-- rechercher l'id de la requête
select sql_id, sql_text from v$sql where sql_text like '%emp%empno%';


-- '2j2nvhsa4tcna' est le sql_id de votre requête
SELECT PLAN_TABLE_OUTPUT 
FROM TABLE
(DBMS_XPLAN.DISPLAY_cursor('2j2nvhsa4tcna'));

?

-- Si l'utilisation de la fonction display cursor échoue
-- Il s'agit peut être d'un problème de droit.
-- Exécutez alors la commande ci-dessous.
connect sys@&DBALIAS as sysdba;
grant execute on dbms_xplan to &MYUSER;

connect &MYUSER@&DBALIAS/PassOrs1;

-- réexécuter la requête
SELECT PLAN_TABLE_OUTPUT 
FROM TABLE
(DBMS_XPLAN.DISPLAY_cursor('2j2nvhsa4tcna'));


?


-- c) Utiliser le paramètre AUTOTRACE pour lire un plan généré dans la Zone des requêtes partagées (sqlarea). 
-- Ce plan est disponible dans les vues V$SQL_PLAN et V$SQL_PLAN_STATISTICS_ALL
-- Voici les effets d'AUTOTRACE : 
--   . set autotrace ON (idem: set autotrace ON EXPLAIN STATISTICS): Affiche le résultat+le plan + les statistiques
--   . set autotrace ON EXPLAIN : Affiche le résultat+le plan
--   . set autotrace ON STATISTICS : Affiche le résultat + les statistiques
--   . set autotrace TRACEONLY : Affiche le plan+les statistiques mais pas le résultat
--   . set autotrace TRACEONLY EXPLAIN : Affiche le plan mais pas le résultat et pas de statistiques
--   . set autotrace TRACEONLY STATISTICS : : Affiche le statistiques seules mais pas le résultat et pas de plan

-- Cette approche est utile en phase développement uniquement.


delete from plan_table;

-- Si autotrace vaut ON alors  il y aura : affichage du résultat, 
-- génèration du plan d'exécution et des statistiques d'exécution
set autotrace on

set linesize 200
set pagesize 50

select * from emp  where empno=7934;

?

-- Si autotrace vaut traceonly alors  il y aura : désactivation l'affichage 
-- du résultat, génération du plan d'exécution et des statistiques d'exécution.
set autotrace traceonly
show autotrace
--autotrace TRACEONLY EXPLAIN STATISTICS

select * from emp  where empno=7934;

?


-- Si autotrace vaut traceonly explain alors  il y aura : désactivation de 
-- l'affichage  du résultat, génération du plan d'exécution uniquement.
	  
set autotrace traceonly explain
set linesize 200
show autotrace
--autotrace TRACEONLY EXPLAIN

select * from emp  where empno=7934;

?

-- Si autotrace vaut traceonly statistics => désactivation de l'affichage 
-- du résultat, affichage des statistiques uniquement.
set autotrace traceonly statistics
set linesize 200
show autotrace
-- résultat de show autotrace 
-- autotrace TRACEONLY EXPLAIN

select * from emp  where empno=7934;

?

-- d) Ecrire sa propre requête pour lire un plan généré dans PLAN_TABLE
-- Pas d'exécution de la requête. Seul le plan est généré dans plan_table avec la commande EXPLAIN PLAN
-- Cette approche est utile uniquement en phase développement.

set autotrace off
delete from plan_table;

EXPLAIN PLAN
set statement_id='PTEST'  
FOR select * from emp  where empno=7934;




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

SELECT OPERATION, OPTIONS, OBJECT_NAME, ID, parent_id "PERE", position "pos", 
OBJECT_INSTANCE "ORIG_POS", optimizer, cost, cardinality "card"
FROM PLAN_TABLE
WHERE STATEMENT_ID='PTEST'
CONNECT BY PRIOR ID=PARENT_ID
AND STATEMENT_ID='PTEST'
START WITH ID=0
AND STATEMENT_ID='PTEST'
ORDER BY ID;

?


-- e) Utiliser TKPROF pour calculer les temps d'exécution de plusieurs requêtes.
-- Générer le fichier de trace. Bien identifier votre fichier et générer avec TKPROF les temps mis
-- ansi que les plans d'exécution.




--alter session set sql_trace=true;
set autotrace off

EXECUTE sys.dbms_session.set_sql_trace(true);

select ename 
from emp 
where ename='KING';

select dname, ename, sal
from emp e, dept d 
where d.deptno=e.deptno 
and job in ('PRESIDENT', 'CLERK');

select dname, ename, sal
from emp e, dept d 
where d.deptno=e.deptno 
and job in ('PRESIDENT', 'CLERK')
order by dname;

--alter session set sql_trace=false;
EXECUTE sys.dbms_session.set_sql_trace(false);

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
----------------------------------------------------------------------------------
-- Exécution de TKPROF pour visualiser les traces d'exécution des requêtes
-- Pour cela vous devez lancer un nouveau CMD (Fenêtre DOS)
-- Définissez les variable d'environnement DOS suivante :
-- MYSPID, MYINST, TRACEFILESPATH, MYTKPROFUSER
----------------------------------------------------------------------------------

-- Définir la variable d'environnement DOS qui va contenir la valeur de vp.spid
-- Qui va permettre d'identifier le fichier qui contient la trace tkprof 
set MYSPID=10928

-- Définir la variable d'environnement DOS qui va contenir le nom de l'instance
set MYINST=COURS21C

-- Définir la variable d'environnement DOS qui contient le nom user à utiliser 
-- Lors du lancement de tkprof
set MYTKPROFUSER=ORS1

-- Définir la variable d'environnement DOS qui contient le chemin vers les trace 
-- Oracle. 
set TRACEFILESPATH=%ORACLE_BASE%\diag\rdbms\%MYINST%\%MYINST%\trace

set MYTKPROFALIAS=PDBMBDS

--- CAS 1 : Vous avez une base Oracle Locale et vous travaillez avec Oracle 11g
-- ou 12c. Lancer tkprof sous DOS comme suit :

tkprof %TRACEFILESPATH%\%MYINST%_ora_%MYSPID%.trc Exo41_trc.trc EXPLAIN=%MYTKPROFUSER%@%MYTKPROFALIAS%/PassOrs1 SORT = execpu, fchcpu sys=n


-- Ouvrir ensuite le fichier Exo41_trc.trc avec un éditeur de texte ... on y les extraits suivants
notepad++ Exo41_trc.trc

-- Exemple d'extrait de de résultat 
?





-- CAS 2 : Vous n'avez pas de base Oracle Locale , et vous accédez à une base distante 
-- Par exemple ma base DBCOURS dans le réseau de l'Université de appelé
-- 

-- Récupérer votre SPID en éxécutant le code ci-dessous

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
-- Affichage du contenu d'un fichier de trace généré avec TKPROF
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
F : pour Féminin
M : Masculin

Modifier les lignes existantes et faire en sorte que 50% des Employés soient de type F et l'autre moitié de type M

Créer un index sur la colonne SEXE

Analyser la table avec la commande suivante
EXECUTE DBMS_STATS.Gather_table_stats('EMP')

Ecrire une requête qui renvoit les informations sur les employés de sexe masculin

En cas d'utilisation des index utiliser les HINTS pour désactiver l'index. En cas de non utilisation faire l'inverse.

Influencer le mode d'optimisation en choisissant le mode RULE

Refaire l'exercice avec les tables BIGEMP2 (environ 130000 lignes)
		  
*/
-- Exercice 5.1 

-- Ajouter dans la table des EMP une colonne 
-- SEXE de type CHAR(1) qui peut prendre 
-- l'une des valeurs suivantes :
-- F : pour Féminin
-- M : Masculin
ALTER TABLE EMP 
ADD (SEXE char(1) 
constraint chk_emp_sexe check(sexe in ('F','M')));

-- Modifier les lignes existantes et faire en 
-- sorte que 50% des Employés soient 
-- de type F et l'autre moitié de type M
update emp
set sexe='F'
where empno <7788;
update emp
set sexe='M'
where empno >=7788;
commit;

-- Créer un index sur la colonne SEXE
drop index IDX_EMP_SEXE;
CREATE INDEX IDX_EMP_SEXE ON EMP(SEXE);

-- bAnalyser la table avec la commande suivante
EXECUTE DBMS_STATS.Gather_table_stats('&MYUSER', 'EMP');

-- Ecrire une requête qui renvoit les informations sur 
--les employés de sexe masculin
set autotrace on
set linesize 200
alter session set optimizer_mode=all_rows;
select * from emp
where sexe='M';

?

-- En cas d'utilisation des index utiliser 
-- les HINTS pour désactiver l'index. En cas 
-- de non utilisation faire l'inverse.
select  /*+ NO_INDEX(EMP IDX_EMP_SEXE) */ * from emp
where sexe='M';

?

-- Influencer le mode d'optimisation en choisissant 
-- le mode RULE. Dans ce mode il est impossible de désactiver
-- l'index


select /*+RULE NO_INDEX(EMP IDX_EMP_SEXE) */ 
* from emp
where sexe='M';

?

-- Refaire l'exercice avec les tables BIGEMP2 (environ 130000 lignes)
set autotrace off

sql>@&SCRIPTPATH\BigEmp2.sql

ALTER TABLE BIGEMP2 
ADD (SEXE char(1) 
constraint chk_bigemp2_sexe check(sexe in ('F','M')));



-- Modifier les lignes existantes et faire en 
-- sorte que 50% des Employés soient 
-- de type F et l'autre moitié de type M
update bigemp2
set sexe='F'
where rownum <65007;
update bigemp2
set sexe='M'
where sexe is null ;
commit;

-- Créer un index sur la colonne SEXE
CREATE INDEX IDX_bigemp2_SEXE ON bigemp2(SEXE);

-- bAnalyser la table avec la commande suivante
EXECUTE DBMS_STATS.Gather_table_stats('&MYUSER', 'bigemp2');

-- Ecrire une requête qui renvoit les informations sur 
--les employés de sexe masculin
set autotrace traceonly;
set linesize 200
alter session set optimizer_mode=all_rows;
select * from bigemp2
where sexe='M';

?

-- En cas d'utilisation des index utiliser 
-- les HINTS pour désactiver l'index. En cas 
-- de non utilisation faire l'inverse.
select  /*+INDEX(BIGEMP2 IDX_BIGEMP2_SEXE) */ * from bigemp2
where sexe='M';

?

-- Influencer le mode d'optimisation en choisissant 
-- le mode RULE

select /*+RULE NO_INDEX(BIGEMP2 IDX_BIGEMP2_SEXE) */ 
* from bigemp2
where sexe='M';

?

select table_name, blocks 
from user_tables 
where table_name in ('EMP', 'BIGEMP2');



/*
Exercice 5.2
5.2.1 Calcul de statistiques avec la commande ANALYZE
Calculer les statistiques sur les colonnes de les tables EMP et BIGEMP2
et ces index en utilisant la commande ANALYZE 

Afficher via des requêtes SQL les informations concernant les statistiques

Sur les tables EMP et BIGEMP2
Sur les colonnes des tables EMP et BIGEMP2
Sur les Index des tables EMP et BIGEMP2

Nota : Bien identifier les tables ou trouver les statistiques

5.2.2 Mesurer l'effet des statistiques LOW_VALUE et HIGH_VALUE sur les tables
EMP et BIGEMP2 en considérant la colonne ENAME


*/

--5.2.1 Calcul de statistiques avec la commande ANALYZE

-- Calculer les statistiques sur les tables EMP et BIGEMP2,leurs colonnes  
-- et leurs index en utilisant la commande ANALYZE 
set autotrace off
ANALYZE TABLE EMP COMPUTE STATISTICS;
ANALYZE TABLE BIGEMP2 COMPUTE STATISTICS;

-- Afficher via une requête SQL les informations 
-- concernant les statistiques

-- Sur les tables EMP et BIGEMP2 à partir la vue user_tables
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

?

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

?

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

?
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

?

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


?



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


?

-- 5.2.2 Mesurer l'effet des statistiques LOW_VALUE et HIGH_VALUE sur les tables
-- EMP et BIGEMP2 en considérant la colonne ENAME

-- 5.2.2 Mesurer l'effet des statistiques LOW_VALUE et HIGH_VALUE sur les tables
-- EMP et BIGEMP2 en considérant la colonne ENAME

drop index idx_emp_ename;
create index idx_emp_ename on emp(ename);
analyze table emp compute statistics;

set autotrace traceonly
set linesize 200

alter session set OPTIMIZER_MODE=all_rows;
select * from emp	 Where ename >'A';

?

alter session set OPTIMIZER_MODE=first_rows_1;
select * from emp	 Where ename >'A';

?
 


alter session set OPTIMIZER_MODE=first_rows_1000;
select * from emp	 Where ename >'A';
 
?


-- En mode RULE l'index sera toujour utilisé même s'il n'apporte rien.
-- Mode à ne plus utiliser.
alter session set OPTIMIZER_MODE=rule;
select * from emp Where ename >'A';
?


-- Normalement l'usage de l'index n'apporte rien. On le désactive
-- Le coût reste plus élévé. La taille de la table est
-- pour tirer une conclusion fiable.
alter session set OPTIMIZER_MODE=all_rows;
select /*+NO_INDEX(e idx_emp_ename)*/ * from emp e Where ename >'A';
?

 
 -- Reprendre la même chose avec la table BIGEMP2
 -- HIGH VALUE AND LOW VALUE

drop index idx_bidgemp2_ename;
create index idx_bidgemp2_ename on bigemp2(ename);

analyze table bigemp2 compute statistics;

set autotrace traceonly
set linesize 200

alter session set OPTIMIZER_MODE=all_rows;
select * from bigemp2 
Where ename >'A';

?

-- Il y a de fortes chances que l'index soit utilisé. On vise la 1ère ligne
alter session set OPTIMIZER_MODE=first_rows_1;
select * from bigemp2 
Where ename >'A';

?
 


 alter session set OPTIMIZER_MODE=first_rows_1000;
 select * from bigemp2 
 Where ename >'A';

? 


 alter session set OPTIMIZER_MODE=rule;
 select * from bigemp2 
 Where ename >'A';

?
 
-- En mode all_rows l'usage l'index ne devrait pas être intéressant	 
select/*+INDEX(a idx_bidgemp2_ename)*/ * from bigemp2 a	
Where ename >'A';

?

/*

Exercice 5.3 

	L'objectif de cet exercice est de provoquer et identifier 
	les chaînages dans une table et d'y remédier. Pour cela 
	Le script ci-dessous créé une table Etudiant. Des lignes
	Y sont insérées.


-- Exécuter le script ci-dessous pour créer la table étudiant et y insérer des ligne 
@&SCRIPTPATH\ETUDIANTBLD.SQL
	
Exercice 5.3  suite

Calculer les statistiques sur la table et les index avec la commande ANALYZE

Vérifier s'il ya des chaînages

Provoquer les chaînages et assurer vous de leur présence

S'il y'a des chaînages, faire en sorte de les supprimer




*/


-- Exercice 5.3 

-- L'objectif de cet exercice est de provoquer et 
-- identifier les chaînages dans une table et 
-- d'y remédier.

-- Exécuter le script ci-dessous pour créer la table étudiant et y insérer des ligne
 set autotrace off
sql>@&SCRIPTPATH\ETUDIANTBLD.SQL

	

-- Calculer les statistiques sur la table et les index avec la commande ANALYZE
ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;
-- Vérifier s'il ya des chaînages
select chain_cnt from user_tables 
where table_name='ETUDIANT';

 ?
		
-- Provoquer les chaînages et assurer vous de leur présence


Update etudiant
set CV=cv||cv
where etu# IN (1,2);
commit;

ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;
select chain_cnt from user_tables 
where table_name='ETUDIANT';

?

-- S'il y'a des chaînages, faire en sorte de les supprimer

-- identifiant des lignes chainées
select rowid, etu#
from etudiant where etu# in (1,2);
?

-- véfier et sinon créer la table chained_rows
-- vers seront envoyée les identifiant des lignes
-- après analyse.
 
desc chained_rows
?

-- créer la table si elle n'existe pas
@%ORACLE_HOME%\rdbms\admin\utlchain.sql

desc chained_rows
?

ANALYZE TABLE etudiant 
LIST CHAINED ROWS INTO chained_rows;

set line size 200
col OWNER_NAME   format A20          
col TABLE_NAME     format A20           
col HEAD_ROWID       format A20         
col ANALYZE_TIMESTAMP   format A20      

select OWNER_NAME,TABLE_NAME, HEAD_ROWID, ANALYZE_TIMESTAMP 
from chained_rows;

?

-- sauvegarde des lignes chaînées dans etudiant2
CREATE TABLE etudiant2 as SELECT etudiant.* 
FROM etudiant, chained_rows
WHERE etudiant.rowid=head_rowid;
?

-- Vérification

select rowid from etudiant2;
?

-- suppression des lignes chaînées dans etudiant
DELETE FROM etudiant WHERE rowid in
(SELECT head_rowid FROM chained_rows);
?
-- réinsertion des lignes dans etudiant depuis etudiant2
INSERT INTO etudiant
SELECT * FROM etudiant2;
?

-- Reanalyse et vérification si les chainages sont partis
ANALYZE TABLE ETUDIANT COMPUTE STATISTICS;
select chain_cnt from user_tables 
where table_name='ETUDIANT';
 
?
 

/*
Exercice 5.4 : Utilisation du package dbms_stats et recolte automatique

Calculer manuellement les statistiques en utilisant le package DBMS_STATS
Sur un utilisateur (exemple : &MYUSER)
Sur la base entière

Vérifier la présence des statistiques dans le dictionnaire de données Oracle

Supprimer les statistiques de l'utilisateur &MYUSER et mettre en évidence leur absence. Puis recalculer les et mettre en évidence leur présence
 
Exporter les statistiques de l'utilisateur &MYUSER

Vérifier que Oracle collecte automatiquement les statistiques sur votre base
Comment activer ou désactiver la collecte des statistiques
Quels sont les paramètres de configuration actuels de la collecte


*/


-- Exercice 5.4 : Utilisation du package dbms_stats et recolte automatique

-- Calculer manuellement les statistiques en utilisant le package DBMS_STATS
-- Sur un utilisateur (exemple : &MYUSER)
-- Sur la base entière


-- Sur un utilisateur (exemple : &MYUSER)

PROCEDURE GATHER_SCHEMA_STATS
-- Nom d'argument                  Type                    E/S par défaut ?
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

-- Laisser Oracle déterminer le pourcentage de l'échantillon,
-- Le dégré de parallélisme et le calcul des histogram.
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


-- Afficher via une requête SQL les informations 
-- concernant les statistiques

-- Sur les tables de &MYUSER à partir la vue user_tables
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

?

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

?

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
?
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
?

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

?



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

?

-- Sur la base entière

-- PROCEDURE GATHER_DATABASE_STATS
-- Nom d'argument                  Type                    E/S par défaut ?
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



-- ne pas exécuter : trop long 
execute dbms_stats.gather_database_stats;


-- Supprimer les statistiques de l'utilisateur &MYUSER et mettre en évidence 
-- leur absence. Puis recalculer les et mettre en évidence leur présence
 execute dbms_stats.delete_schema_stats('&MYUSER');
 
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
?

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

?

-- Exporter les statitistiques de l'utilisateur ors
PROCEDURE EXPORT_SCHEMA_STATS
-- Nom d'argument                  Type                    E/S par défaut ?
 ------------------------------ ----------------------- ------ --------
 OWNNAME                        VARCHAR2                IN
 STATTAB                        VARCHAR2                IN
 STATID                         VARCHAR2                IN     DEFAULT
 STATOWN                        VARCHAR2                IN     DEFAULT

-- Avant d'exporter les statistiques il faut créer la table
-- devant contenir les statistiques
DBMS_STATS.CREATE_STAT_TABLE (
ownname VARCHAR2,
stattab VARCHAR2,
tblspace VARCHAR2 DEFAULT NULL);

-- création de la table devant contenir les stats
select * from tab where tname='STATORS' order by tname ;

?

execute DBMS_STATS.CREATE_STAT_TABLE('&MYUSER','STATors','USERS');
desc STATors

?

select * from tab where tname='STATORS' order by tname ;

?

 
execute dbms_stats.export_schema_stats('&MYUSER', 'STATors');

-- vérifier la génération de statistiques
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

?




-- vous pouvez ensuite exporter via EXPDP le contenu des statistiques
-- pour un déplacement vers une autre base
set DPUSER=ORS1
set DPDBALIAS=PDBORCL
expdp %DPUSER%/PassOrs1@%DPDBALIAS% dumpfile=stators.dump tables=STATors


-- Export: Release 10.2.0.3.0 - Production on Jeudi, 11 FÚvrier, 2010 10:46:10

-- Copyright (c) 2003, 2005, Oracle.  All rights reserved.


?


-- Vérifier qu'Oracle collecte automatiquement les statistiques sur votre base
-- Comment activer ou désactiver la collecte des statitistiques
-- Quels sont les paramètres de configuration actuels de la collecte

-- Vérifier que Oracle collecte automatiquement les statistiques sur votre base

--- en 11g

select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;



?


select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_TASK;

?

col client_name format a40
col OPERATION_NAME format a30
set linesize 90
select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;


?

BEGIN
  DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'auto optimizer stats collection', 
    operation => NULL,  window_name => NULL);
END;
/

select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;

?

BEGIN
  DBMS_AUTO_TASK_ADMIN.ENABLE(
    client_name => 'auto optimizer stats collection', 
    operation => NULL,  window_name => NULL);
END;
/

select CLIENT_NAME, OPERATION_NAME, STATUS from DBA_AUTOTASK_OPERATION;


?


-- Quels sont les paramètres de configuration actuels de la collecte
DBMS_STATS.GET_PARAM (
pname IN VARCHAR2)
RETURN VARCHAR2;

set serveroutput on

-- modification des paramètres
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

?

-- modification d'un paramètre
execute dbms_stats.set_param('ESTIMATE_PERCENT','5'); 
execute dbms_stats.set_param('DEGREE','NULL');

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

?

-- modification des paramètres
execute dbms_stats.set_param('ESTIMATE_PERCENT','DBMS_STATS.AUTO_SAMPLE_SIZE'); 
execute dbms_stats.set_param('DEGREE','DBMS_STATS.AUTO_DEGREE'); 
execute dbms_stats.set_param('CASCADE','DBMS_STATS.AUTO_CASCADE'); 

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

?

/*
Exercice 5.5 

Mettre en évidence que l'optimiseur de statistique et l'optimiseur 
de règles ne prennent pas souvent les mêmes décisions

Soient les tables Emp et Dept et les index sur ename, deptno dans emp 
et deptno dans dept. Générer les plans des deux requêtes ci-dessous et comparer. 
Il est à savoir que l'optimiseur de règles en cas d'index sur les deux colonnes
 de jointures, il choisit la table la plus à droite de la clause FROM comme
 première table (elle est lue séquentiellement)

Alter session set OPTIMIZER_MODE=rule;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME  FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 




*/


-- 5.5 Mettre en évidence que l'optimiseur de statistique et 
-- l'optimiseur de règles ne prennent pas souvent les 
-- mêmes décisions

-- Soient les tables Emp et Dept et les index sur ename, 
-- deptno dans emp et deptno dans dept. Générer les plans 
-- des deux requêtes ci-dessous et comparer. Il est à 
-- savoir que l'optimiseur de règles en cas d'index sur les
--  deux colonnes de jointures, il choisit la table la plus 
--  à gauche de la clause FROM comme première table 
--  (elle est lue séquentiellement)

 col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('EMP', 'DEPT');
 
 ?

create index idx_emp_deptno on emp(deptno);
execute dbms_stats.gather_table_stats('&MYUSER', 'EMP');
Alter session set OPTIMIZER_MODE=rule;
set autotrace on
set linesize 200
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME  FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

?


set autotrace traceonly explain

Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

?

Alter session set OPTIMIZER_MODE=all_rows;
SELECT EMPNO, ENAME, dept.DEPTNO, DNAME
FROM dept, emp
WHERE emp.deptno=dept.deptno ; 

?

-- Refaire la même requête sur les tables BIGEMP2 et BIGDEPT2
set autotrace off
col column_name format a20
 select table_name, column_name, index_name 
 from user_ind_columns
 where table_name in ('BIGEMP2', 'BIGDEPT2');
 
?

create index idx_bigemp2_deptno on bigemp2(deptno);
execute dbms_stats.gather_table_stats('&MYUSER', 'BIGEMP2');
Alter session set OPTIMIZER_MODE=rule;
set autotrace traceonly explain
SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME  FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 

?

set autotrace traceonly explain

Alter session set OPTIMIZER_MODE=first_rows_1;
SELECT EMPNO, ENAME, bigdept2.DEPTNO, DNAME
FROM bigdept2,  bigemp2
WHERE  bigemp2.deptno=bigdept2.deptno ; 

?


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

Mesurer les temps accès aux enregistrements de deux tables (emp3 et dept3), 
colonne de jointure deptno et produire les plans d'accès :

1) via une jointure
2) via un cluster avec clé indexée
3) via un cluster avec clé hachée.

Pour 2) et 3) il est nécessaire de :
a)créer un cluster,
b)créer deux tables emp3 et dept3 copies conformes de emp et dept.

Note : pour les mesures, utiliser TKPROF ou AUTOTRACE
*/

-- 6. Etude de cas

-- Mesurer les temps accès aux enregistrements de deux tables (emp3 et dept3), 
-- colonne de jointure deptno et produire les plans d'accès :

-- 1) via une jointure
-- Jointure sans tables en cluster (RBO, CBO)
-- Jointure avec tables en cluster index (RBO, CBO)
-- Jointure avec tables en cluster haché (RBO, CBO)
-- création et insertion de lignes dans les tables EMP4 et DEPT4
-- création et insertion de lignes dans les tables IEMP4 et IDEPT4 (
-- cluster indexé)
-- création et insertion de lignes dans les tables HEMP4 et HDEPT4 (
-- cluster haché)

-- EMP4 à 100000 lignes
-- changer de répertoire et se déplacer jusqu'au script
-- du cours Tuning.

-- Veuillez éditer et adapter le script ci-dessous pour poursuivre l'activité.
2aEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_START.sql




