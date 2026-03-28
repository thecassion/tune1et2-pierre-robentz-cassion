/*

LIRE ATTENTIVEMENT LE CHAPITRE 2 � 10 DU COURS TUNE 2 
CONCERNANT LE REGLAGE AUTOMATIQUE DE REQUETES ET SURTOUT
SQL TUNING ADVISOR (voir aussi les annexes).

Ecrire un script qui permet d'analyser et produire des 
recommandations sur un pool de requ�tes sur l'application
APPLIBANK regroup� dans un  SQL Tuning Set. Le remplissage
du SQL TUNING SET set fait en r�cup�rant les requ�tes entre
deux clich�s AWR.

Travail � faire via l'API et en partie via OEM.

1. Charger l'application bancaire (AppliBank.sql)
dans le sch�ma de l'utilisateur ORS2

2. Provoquer de l'activit� (requ�tes sur l'application bancaire) 
dans la base entre deux clich�s AWR

3. G�n�rer les recommandations

Ecrire un script qui permet d'analyser et produire des 
recommandations r�cup�r�es les requ�tes entre
deux clich�s AWR.


4. Afficher les r�sultats d'analyses

5. G�rer le script SQL propos� pour le r�glage SQL

6. Activiter de r�glage � faire � l'issue de l'ex�cution de ce script


*/



set autotrace off
set termout on
set echo on
set serveroutput on


-- Activation du spool pour logger toutes vos actions
-- dans ce script. Adapter le chemin en fonction de votre
-- contexte.
spool &SCRIPTPATH/LOG/Ex91_TUNE2_STA_BANK_7RETUNE_QUERY.log 

-- 1. Charger l'application bancaire (AppliBank.sql)
-- dans le sch�ma de l'utilisateur ORS2

-- D�j� fait dans ...start.sql

-- Les index actuels sur l'application
-- Pour l'instant seul les 3 indexes primary doivent exister
select table_name, column_name, index_name 
from user_ind_columns
where table_name in ('CLIENT',  'COMPTE',  'TRANSACTION')
order by table_name, index_name, column_name;

 /*
TABLE_NAME                     COLUMN_NAME          INDEX_NAME
------------------------------ -------------------- ------------------------------
CLIENT                         CLIENTID             PK_CLIENT_CLIENTID
COMPTE                         COMPTEID             PK_COMPTE_COMPTEID
TRANSACTION                    TRANSACTIONID        PK_TRANSACTION_TRID
*/

-- Ne pas cr�er les indexes ci-dessous.
-- Ce sont les indexes qu'on aurait cr��s si on op�rait
-- un r�glage manuel. Lorsque SQLTUNING ADVISOR aura fait
-- des recommandations, comparez les indexes qu'ils recommandent
-- avec ceux ci. Ces indexes sont propos�es au vu des clauses
-- WHERE des requ�tes � optmiser automatiquement. 


  
-- v�rification du type d'optimiseur
 show parameter optimizer_mode;

-- optimizer_mode                       string      ALL_ROWS
 
-- passer en mode all_rows si utile
set autotrace off
alter session set optimizer_mode=all_rows ;

-- calculer les statistiques sur les objets de l'utilisateur
-- &MYPDBUSER
execute dbms_stats.gather_schema_stats('&MYPDBUSER');

-- Connexion avec au niveau CDB pour prendre un clich� AWR.
-- La gestion des statistiques se fait au niveau e ma CDB
connect &MYCDBUSER@&DBALIASCDB/&MYCDBUSERPASS

-- Prendre un premier clich� AWR pour d�limiter
-- l'espace de r�cup�ration des requ�tes.
set serveroutput on
variable snapid1 number;

begin
	:snapid1	:= dbms_workload_repository.create_snapshot;
	dbms_output.put_line('snap_id1='||:snapid1);
end;
/

-- ReConnexion � la  PDB pour utiliser STA
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS

-- reporter le num�ro de clich� rendu par le programme ici :
-- snap_id1=153  ? snap_id1=743

-- 2. Provoquer de l'activit� (requ�tes sur l'application bancaire) 
-- dans la base entre deux clich�s AWR

-- D�sactiver l'affichage � l'�cran des r�sultats des requ�tes.
 set autotrace &TRACEOPTION


 col compteid format a24
 col nom format a20
 col prenom format a20
 col ville format a20
 col adresse format a30

 
 -- Lancer plusieurs requ�tes
 
-- Requ�te 1:
-- listing des clients ayant des comptes 
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid;
 
 -- Requ�te 2:
 -- listing des clients ayant des comptes tri� selon l'identifiant et
 -- le nom du client
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 order by clientid , nom;
 
-- Requ�te 3:
-- listing des comptes d'un client connaissant son nom 
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 and nom ='Petit'
 order by co.clientid, nom, prenom;
 
 
 -- Requ�te 4:
 -- listing des informations sur les comptes et clients 
 -- dont le solde est n�gatif
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 and solde <0;
 

-- Requ�te 5:
-- listing des transactions par compte et client
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid;
 
 
 -- Requ�te 6:
 -- listing des transactions par compte et client pour lesquels le solde du compte n�gatif
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and co.solde <0;

-- Requ�te 7:
-- liste des transactions par compte et client connaissant le nom du client
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom='Petit';
 
 -- Requ�te 8:
 -- liste des transactions par compte et client connaissant le nom du client et op�r�es � une date donn�e
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom='Petit' and date_operation=to_date('27-01-2010', 'DD-MM-YYYY');

 
 -- Requ�te 9:
 -- liste des op�ration d'un client donn�es de type DEBIT
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom='Petit' and operation='DEBIT';
 
 
 -- Requ�te 10:
 -- total des transaction par client, par compte, par operation
 
  select cl.clientid,  co.compteid, operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 group by cl.clientid,  co.compteid, operation;

 
-- Requ�te 11:
 -- total des transaction par client, par compte, par operation 
 -- dont le total est sup�rieur � 10000
 
 select cl.clientid,  tr.compteid, operation, sum(montant)  
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 group by cl.clientid,  tr.compteid, operation
 having sum(montant) >10000;

 
 -- Requ�te 12:
-- balance des transactions par type et par date
 select  operation, date_operation, sum(montant)
 from transaction tr
 group by operation, date_operation;

-- Requ�te 13:
-- balance des transactions par type
 select  operation, sum(montant)
 from transaction tr
 group by operation;
 
 -- Requ�te 14:
 -- Balance des transactions par type pour des compte �pargne 
 -- entre deux dates
 select co.typecompte,  operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and tr.date_operation 
 between to_date('25-01-2010', 'DD-MM-YYYY') and to_date('27-01-2010', 'DD-MM-YYYY')
 group by co.typecompte,  operation ;

 -- Requ�te 15:
 -- un connexion de jointure manque
 select co.typecompte,  operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid 
 and tr.date_operation 
 between to_date('25-01-2010', 'DD-MM-YYYY') and to_date('27-01-2010', 'DD-MM-YYYY')
 group by co.typecompte,  operation ;

 set autotrace off

-- Connexion avec lau niveau CDB pour prendre un clich� AWR
-- La gestion des statistiques se fait au niveau e ma CDB
connect &MYCDBUSER@&DBALIASCDB/&MYCDBUSERPASS


-- Prendre un deuxi�me clich� AWR pour d�limiter
-- la fin de l'espace de r�cup�ration des requ�tes.
variable snapid2 number;
set serveroutput on

begin
	:snapid2	:= dbms_workload_repository.create_snapshot;
	dbms_output.put_line('snap_id2='||:snapid2);
end;
/

-- ReConnexion � la  PDB pour utiliser STA
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS

-- reporter le num�ro de clich� rendu par le programme ici :
-- snap_id2= 154 ? snap_id2=744

-- Supprimer la tache  
-- Supprimer 1 tache BANK_SQL_TUNING_TASK si elle existe d�j�
execute DBMS_SQLTUNE.DROP_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER');
execute DBMS_SQLTUNE.DROP_SQLSET('bank_sql_tuning_set'||'&MYPDBUSER');
-- Si vous avez d�j� ex�cut� ce script, il se peut qu'un
-- qu'un profile de requ�te ai d�j� �t� cr��. Dans ce cas:
-- Rechercher puis supprimer le profie s'il existe d�j� 
---
set linesize 200
col sql_text format A40
select name 
from dba_sql_profiles
order by name;

-- Supprimer le(s) profile(s) s'ils ont �t� trouv�s avec la requ�te 
-- pr�c�dente. NomProfile est le r�sultat de la requ�te
-- ci-dessus. R�p�ter l'action si utile.
execute DBMS_SQLTUNE.DROP_SQL_PROFILE('NomProfile');

-- 3. G�n�rer les recommandations
-- Ex�cuter le script ci-dessous pour optimiser automatiquement
-- les requ�tes lanc�es entre snap_id1 et snap_id2.
-- Le conseiller qui sera utilis� ici est SQL TUNNING ADVISOR.
set serveroutput on
DECLARE
my_task_name VARCHAR2(30);
nom_sqlset varchar2(50):='bank_sql_tuning_set'||'&MYPDBUSER';
l_cursor  DBMS_SQLTUNE.sqlset_cursor;
BEGIN
DBMS_SQLTUNE.CREATE_SQLSET(
sqlset_name => nom_sqlset,
description => 'I/O intensive workload');

-- Appel de la fonction DBMS_SQLTUNE.select_workload_repository 
-- pour recolter les requ�tes � r�gler automatiquement entre
-- snap_id1 et snap_id2.
-- remplacer snap_id1 et snap_id2 par les valeurs captur�es 
-- plus haut apr�s les appels de:dbms_workload_repository.create_snapshot;.
--1059 et 1174
  OPEN l_cursor FOR
    SELECT VALUE(p)
    FROM   TABLE (DBMS_SQLTUNE.select_workload_repository (
                    :snapid1, --snap_id1,  -- begin_snap : 
                    :snapid2, --snap_id2,  -- end_snap
                    'parsing_schema_name =''&MYPDBUSER''  and parsing_schema_name <> ''SYS''', -- basic_filter
                    NULL, -- object_filter
                    NULL, -- ranking_measure1
                    NULL, -- ranking_measure2
                    NULL, -- ranking_measure3
                    NULL, -- result_percentage
					NULL, -- result_limit
					'ALL' -- attribute_list
					)
                --    10)   -- result_limit
                  ) p;

-- charger les requ�tes recolt�es entre snap_id1 et snap_id2
-- actuellement pr�sente dans l_cursor dans le sql tuning 
-- set cr�� pr�c�demment.
  DBMS_SQLTUNE.load_sqlset (
    sqlset_name     => nom_sqlset,
    populate_cursor => l_cursor);

-- cr�er une t�che de tuning pour le sql tuning set
-- aliment� en requ�te dans l'action ci-dessus.	
my_task_name := DBMS_SQLTUNE.CREATE_TUNING_TASK(
sqlset_name => nom_sqlset,
basic_filter => 'parsing_schema_name =''&MYPDBUSER''', -- basic_filter
scope => 'COMPREHENSIVE',
time_limit => 60,
task_name => 'BANK_SQL_TUNING_TASK'||'&MYPDBUSER',
description => 'Task to tune a query on a specified bank queries'
);

-- Ex�cuter le t�che de tuning 
-- le conseiller utilis� ici est STA.
DBMS_SQLTUNE.EXECUTE_TUNING_TASK( task_name => my_task_name );

END;
/

-- profile des fonctions utilis�es dans le programme ci-dessus.
-- A ne pas ex�cuter. Voir le manuel Oracle Oracle� Database
-- PL/SQL Packages and Types Reference pour la description
-- d�taill�e.
/*
DBMS_SQLTUNE.SELECT_WORKLAOD_REPOSITORY (
begin_snap IN NUMBER,
end_snap IN NUMBER,
basic_filter IN VARCHAR2 := NULL,
object_filter IN VARCHAR2 := NULL,
ranking_measure1 IN VARCHAR2 := NULL,
ranking_measure2 IN VARCHAR2 := NULL,
ranking_measure3 IN VARCHAR2 := NULL,
result_percentage IN NUMBER := 1,
result_limit IN NUMBER := NULL
attribute_list IN VARCHAR2 := NULL)
RETURN sys.sqlset PIPELINED;


DBMS_SQLTUNE.CREATE_TUNING_TASK(
sqlset_name IN VARCHAR2,
basic_filter IN VARCHAR2 := NULL,
object_filter IN VARCHAR2 := NULL,
rank1 IN VARCHAR2 := NULL,
rank2 IN VARCHAR2 := NULL,
rank3 IN VARCHAR2 := NULL,
result_percentage IN NUMBER := NULL,
result_limit IN NUMBER := NULL,
scope IN VARCHAR2 := SCOPE_COMPREHENSIVE,
time_limit IN NUMBER := TIME_LIMIT_DEFAULT,
task_name IN VARCHAR2 := NULL,
description IN VARCHAR2 := NULL
plan_filter IN VARCHAR2 := 'MAX_ELAPSED_TIME',
sqlset_owner IN VARCHAR2 := NULL)
RETURN VARCHAR2;

*/



-- 4. Afficher les r�sultats d'analyses

-- Consultation des informations sur la tache

-- V�rification de la t�che cr��e
col task_name format a20
SELECT task_name 
FROM DBA_ADVISOR_LOG 
WHERE owner ='ORS2' and task_name='BANK_SQL_TUNING_TASK'||'&MYPDBUSER';

--?

-- La vue Advisor_tasks contient des informations 
-- sur les t�ches

SELECT TASK_NAME, ADVISOR_NAME, status , RECOMMENDATION_COUNT, SOURCE         
FROM USER_ADVISOR_TASKS 
WHERE task_name = 'BANK_SQL_TUNING_TASK'||'&MYPDBUSER';

--?

-- La vue V$ADVISOR_PROGRESS contient des informations 
-- sur la progression des t�ches

-- Exemple de consultation de la progression

SELECT sofar, totalwork FROM
V$ADVISOR_PROGRESS  vp, 
DBA_ADVISOR_LOG da
WHERE vp.username = '&MYPDBUSER'  
AND vp.task_id=da.task_id
AND da.task_name = 'BANK_SQL_TUNING_TASK'||'&MYPDBUSER';

--?

--La fonction DBMS_SQLTUNE.REPORT_TUNING_TASK permet d'afficher 
--le r�sultat d'une analyse


SET LONG 4000
SET LONGCHUNKSIZE 4000
SET LINESIZE 200
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK( 'BANK_SQL_TUNING_TASK'||'&MYPDBUSER')
FROM DUAL;


--?

-- r�sultat du report il est conseill�e de restructurer la
-- requ�te.

--?

-- la ligne ci-dessous dans le rapport indique qu'il y'a une 
-- restructuration de la requete � faire.
-- Number of SQL Restructure Findings: 1

--
-- Type de recommandation
-- Consulter le type de recommandation dans la vue
-- DBA_ADVISOR_RECOMMENDATIONS
--

col task_name format A20
col PARENT_REC_IDS format A40
col vs.SQL_TEXT format a60
col reco_type format A20
set linesize 200
set pagesize 400


select distinct dar.task_name,  vs.sql_id, vs.SQL_TEXT, dar.type reco_type  , BENEFIT
from v$sqlarea vs, 
DBA_ADVISOR_SQLPLANS da,
DBA_ADVISOR_RECOMMENDATIONS dar
where vs.sql_id=da.sql_id
and da.task_id=dar.task_id
and dar.task_name='BANK_SQL_TUNING_TASK'||'&MYPDBUSER'
and sql_text not like '%EXPLAIN%'
and sql_text not like '%opt_param%'
and sql_text not like '%insert%'
and sql_text not like '%V_$SESSTAT%'
and sql_text not like '%PLAN_TABLE%'
order by dar.task_name,  vs.sql_id, reco_type;


--?

--
-- Consultation la description du probl�me trouv� par STA
-- Dans la vue DBA_ADVISOR_FINDINGS
-- R�sultation de la recherche
---

col task_name format A10
col message format A40
col more_info format A40
col impact_type format A40
col vs.SQL_TEXT format a40
set linesize 300
set pagesize 400

select distinct dar.task_name,  da.object_id, vs.sql_id, vs.SQL_TEXT, MESSAGE, impact_type, more_info 
from v$sqlarea vs, 
DBA_ADVISOR_SQLPLANS da,
DBA_ADVISOR_FINDINGS dar
where vs.sql_id=da.sql_id
and da.task_id=dar.task_id
and da.object_id=dar.object_id
and dar.task_name='BANK_SQL_TUNING_TASK'||'&MYPDBUSER'
and sql_text not like '%EXPLAIN%'
and sql_text not like '%opt_param%'
and sql_text not like '%insert%'
and sql_text not like '%V_$SESSTAT%'
and sql_text not like '%PLAN_TABLE%'
order by dar.task_name,  da.object_id, vs.sql_id;



--?

---
--- recommandation
--- consulter les actions (diagnostic) recommand�es par STA
--- dans la vue DBA_ADVISOR_ACTIONS
---
-- voir 
col task_name format A20
col message format A40
col more_info format A40
col impact_type format A40
col SQL_TEXT format a40

set linesize 200
set pagesize 400


select distinct dar.task_name,  da.object_id, vs.sql_id, vs.SQL_TEXT, message 
from v$sqlarea vs, 
DBA_ADVISOR_SQLPLANS da,
DBA_ADVISOR_ACTIONS dar
where vs.sql_id=da.sql_id
and da.task_id=dar.task_id
and da.object_id=dar.object_id
and dar.task_name='BANK_SQL_TUNING_TASK'||'&MYPDBUSER'
and sql_text not like '%EXPLAIN%'
and sql_text not like '%opt_param%'
and sql_text not like '%insert%'
and sql_text not like '%V_$SESSTAT%'
and sql_text not like '%PLAN_TABLE%'
order by dar.task_name, da.object_id, vs.sql_id;

--?

-- Liste des actions possibles
set linesize 200
col ATTR1 format a30
col ATTR2 format a10
col attr3 format a20
col ATTR4 format a10
col attr5 format a30

select
object_id, 
ATTR1,
ATTR2,
ATTR3,
ATTR4,
ATTR5
from DBA_ADVISOR_ACTIONS
where attr1!='SYS'
and attr1 not like '%SYSMAN%'
order by object_id;


---
--- Raisonnement
--- Raisonnement avec des explications compl�mentaires sur 
--- le probl�me.
--- Consult� pour cela la vue DBA_ADVISOR_RATIONALE
---





col task_name format A20
col message format A40
col more_info format A40
col impact_type format A40
col SQL_TEXT format a40
set linesize 200
set pagesize 400


select distinct dar.task_name,  da.object_id, vs.sql_id, vs.SQL_TEXT, message 
from v$sqlarea vs, 
DBA_ADVISOR_SQLPLANS da,
DBA_ADVISOR_RATIONALE dar
where vs.sql_id=da.sql_id
and da.task_id=dar.task_id
and da.object_id=dar.object_id
and dar.task_name='BANK_SQL_TUNING_TASK'||'&MYPDBUSER'
and sql_text not like '%EXPLAIN%'
and sql_text not like '%opt_param%'
and sql_text not like '%insert%'
and sql_text not like '%V_$SESSTAT%'
and sql_text not like '%PLAN_TABLE%'
order by dar.task_name,  da.object_id, vs.sql_id;
--?






--
-- Rechercher s'il y'a des scripts g�n�r�s
-- Identifier s'il ya un profile pour cette requ�te choisie plus
-- haut.
-- afficher le script complet ou partiel
col myscript format a1000
set long 4000
select dbms_sqltune.SCRIPT_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER', 'ALL') MYSCRIPT from dual;

select dbms_sqltune.SCRIPT_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER', 'INDEXES') MYSCRIPT from dual;
select dbms_sqltune.SCRIPT_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER', 'PROFILES') MYSCRIPT from dual;
select dbms_sqltune.SCRIPT_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER', 'STATISTICS') MYSCRIPT from dual;

-- une autre fa�on d'afficher le script complet
set serveroutput on
begin
dbms_output.put_line(dbms_sqltune.SCRIPT_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER', 'ALL'));
end;
/
--?

-- 5. G�rer le script SQL propos� pour le r�glage SQL
-- G�rer le script SQL propos� pour le r�glage SQL : Attention ce script est disponible dans le dossier %ORACLE_BASE%\admin\dpdump
-- r�cup�rer le script et le mettre dans votre dossier : EXO91
-- Editer ce script de fa�on appropri�
declare 
mydate varchar2(20):=to_char(sysdate, 'DD_MM_YYYY_HH24_MI_SS');
fname varchar2(300):='STA2_Generate_action_script_on_bank_app_'
||'&MYPDBUSER'|| '_'||mydate||'After_Tune.sql';
begin

DBMS_ADVISOR.CREATE_FILE(
DBMS_SQLTUNE.SCRIPT_TUNING_TASK('BANK_SQL_TUNING_TASK'||'&MYPDBUSER'),
'DATA_PUMP_DIR', 
fname
);
end;
/

-- ex�cuter le script pour accepter le profile de la requ�te choisie

-- execute dbms_sqltune.accept_sql_profile(task_name => 'BANK_SQL_TUNING_TASK'||'&MYPDBUSER', replace => TRUE);

---
--- V�rifier la pr�sence d'un profie dans la vue 
---
set linesize 200

col sql_text format A40
select name ,CATEGORY,  SQL_TEXT , STATUS,FORCE_MATCHING
from dba_sql_profiles
order by name;


SPOOL OFF

-- 6. Activiter de r�glage � faire � l'issue de l'ex�cution de ce script
-- 6.1 dupliquer le Dossier EXO91 en EXO91_TUNED
-- 6.2 Adapt� les scripts dans EXO91_TUNED pour prendre en compte ce nouveau nom
-- 6.3 Analyer le r�sultat de l'activit� de STA en lisant le fichier Ex91_Tune2_STA_BANK_8SPOOL.LOG dans EXO91_TUNED
-- 6.4 R�cup�rer et adapter le script g�n�r� en 5
-- 6.5 Corriger dans EXO91_TUNED\Ex91_TUNE2_STA_BANK_2ACTIVITY.SQL la requ�te ou le produit cart�sien est �voqu�
-- 6.6 R�ex�cuter les scripts � partir de EXO91_TUNED\Ex91_TUNE2_STA_BANK_1START.SQL

