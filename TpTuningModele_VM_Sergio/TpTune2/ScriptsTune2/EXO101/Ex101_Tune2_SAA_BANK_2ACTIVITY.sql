/*

Exercice 101

Travail à faire via l'API

Ecrire un script qui permet d'analyser et produire des recommandations d'indexes 
et/ou de vues matérialisées sur des requêtes SQL stockées dans une table utilisateur. 
Vous devez pour cela :
 - Définir une tâche avec un template OLTP ou DWH ou mixte
 - Définir un workload à partir d'une table Utilisateur (voir Annexe 11.1) à créer 
   à remplir avec au moins deux requêtes
 - Attacher la tâche aux workload
 - Fixer certains paramètres de la tâche tel que 
EXECUTION_TYPE = INDEX_ONLY puis FULL
MODE = COMPREHENSIVE
- Exécuter la tâche

Visualiser les recommandations Et si possible accepter les recommandations

Les principales étapes du script sont:

1. Supprimer les indexes recommandés dans EXO91 et posés dans EXO91_TUNED
2. Charger les requêtes dans la table utilisateur user_workload
3. Analyser les requêtes et produire les recommandations
4. Consulter les recommandations

*/


set autotrace off
set termout on
set echo on
set serveroutput on


spool &SCRIPTPATH\LOG\Ex101_Tune2_SAA_BANK_3SPOOL.LOG

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- 1. Supprimer les indexes recommandés dans EXO91 et posés dans EXO91_TUNED
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- liste des indexes actuels

select table_name, column_name, index_name 
from user_ind_columns
where table_name in ('CLIENT',  'COMPTE',  'TRANSACTION')
order by table_name, index_name, column_name;

-- suppression des indexes posés dans le EXO91

declare 

sql_stmt 	varchar2(200);
cursor c1 is
	select index_name 
	from user_indexes
	where table_name in ('CLIENT',  'COMPTE',  'TRANSACTION')
	and 
	(UNIQUENESS = 'NONUNIQUE'
		OR 
		(UNIQUENESS='UNIQUE' 
			and index_name not in (
			select constraint_name 
			from user_constraints 
			where constraint_type 
			IN ('P', 'U') 
			)
		)
	);
begin
	for C1_elem in c1 
	loop
		sql_stmt:= 'drop index ' || c1_elem.index_name;
		EXECUTE IMMEDIATE sql_stmt;
	end loop;

end;
/

-- liste des indexes après
select table_name, column_name, index_name 
from user_ind_columns
where table_name in ('CLIENT',  'COMPTE',  'TRANSACTION')
order by table_name, index_name, column_name;


--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- 2. Charger les requêtes dans la table utilisateur user_workload
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

-- Si utile Suppession puis création de la table utilisateur
drop table user_workload;


create table user_workload(
MODULE VARCHAR2(64) , 	--Nom du module applicatif.
ACTION VARCHAR2(64),	-- Action sur l'application.
BUFFER_GETS NUMBER default 0, --nbre total de buffer-gets pour la requête.
CPU_TIME NUMBER default 0, -- Total CPU time in seconds for the statement.
ELAPSED_TIME NUMBER default 0, -- Total elapsed time in seconds for the statement.
DISK_READS NUMBER default 0 , --Total number of disk-read operations used 
				-- by the statement.
ROWS_PROCESSED NUMBER default 0, --  Total number of rows process by this 
				-- SQL statement.
EXECUTIONS NUMBER default 1, -- Total number of times the statement is executed.
OPTIMIZER_COST NUMBER default  0, -- Optimizer's calculated cost value for 
				          -- executing the query.
LAST_EXECUTION_DATE DATE  default SYSDATE , -- Last time the query is 
				-- used. Defaults to not available.
PRIORITY NUMBER default 2, 	--  Must be one of the following values:
				-- 1- HIGH, 2- MEDIUM, or 3- LOW
SQL_TEXT CLOB,		--  or LONG or VARCHAR2
				-- None The SQL statement. This is a required 			-- column.
STAT_PERIOD NUMBER default 1 ,
-- Period of time that corresponds to the execution statistics in seconds.
USERNAME VARCHAR(30) default user
--Current user User submitting the query. This is a required column.
);



-- chargement des requêtes dans cette table
-- aggregation with selection

INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example1', 'Action', 2,
' select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 order by clientid , nom')
/
 
 -- liste des comptes et clients dont le solde est négatif
 INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example2', 'Action', 2,
 'select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 and solde <0');
 
 
-- liste des transactions par compte 

-- liste des transactions par compte et client
INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example3', 'Action', 2,
 'select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid');
 
 
 -- liste des transactions par compte et client pour lesquels le solde du compte négatif
 INSERT INTO user_workload (username, module, action, priority, sql_text)
 VALUES ('&MYPDBUSER', 'Example4', 'Action', 2,
 'select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and co.solde <0');

-- liste des transactions par compte et client connaissant le nom du client
 INSERT INTO user_workload (username, module, action, priority, sql_text)
 VALUES ('&MYPDBUSER', 'Example5', 'Action', 2,
 'select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom=''Petit''');
 
 -- liste des transactions par compte et client connaissant le nom du client et opérées à une date donnée
 INSERT INTO user_workload (username, module, action, priority, sql_text)
 VALUES ('&MYPDBUSER', 'Example6', 'Action', 2,
 'select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom=''Petit'' and date_operation=to_date(''27-01-2010'', ''DD-MM-YYYY'')');

 -- 7ème requête
 -- liste des opération d'un client données de type DEBIT
INSERT INTO user_workload (username, module, action, priority, sql_text)
 VALUES ('&MYPDBUSER', 'Example7', 'Action', 2,
 'select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom=''Petit'' and operation=''DEBIT''');
 
 -- Erreur 1 : total des transaction par client, par compte, par operation
INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example8', 'Action', 2,
 'select cl.clientid,  tr.compteid, operation, sum(montant)
 from client cl, transaction tr, compte co
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 group by cl.clientid,  tr.compteid, operation');

 -- Erreur 2 : total des transaction par client, par compte, par operation 
 -- dont le total est supérieur à 10000
 INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example9', 'Action', 2,
 'select cl.clientid,  tr.compteid, operation, sum(montant)
 from client cl, transaction tr, compte co
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 group by cl.clientid,  tr.compteid, operation
 having sum(montant) >10000');

 
-- 10ème balance des transactions par type et par date
INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example10', 'Action', 2,
 'select  operation, date_operation, sum(montant)
 from transaction tr
 group by operation, date_operation');

-- balance des transactions par type
INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example11', 'Action', 2,
 'select  operation, sum(montant)
 from transaction tr
 group by operation');
 
 -- balance des transactions par type pour des compte épargne entre deux dates
  INSERT INTO user_workload (username, module, action, priority, sql_text)
VALUES ('&MYPDBUSER', 'Example12', 'Action', 2,
 'select co.typecompte,  operation, sum(montant)
 from client cl, compte co, transaction tr
 where co.compteid=tr.compteid
 and tr.date_operation 
 between to_date(''25-01-2010'', ''DD-MM-YYYY'') and to_date(''27-01-2010'', ''DD-MM-YYYY'')
 group by co.typecompte,  operation') ;


 INSERT INTO user_workload (username, module, action, priority, sql_text)
 VALUES ('&MYPDBUSER', 'Example13', 'Action', 2,
 'select co.typecompte,  operation, sum(montant)
 from client cl, compte co, transaction tr
 where co.compteid=tr.compteid
 and tr.date_operation 
 between to_date(''25-01-2010'', ''DD-MM-YYYY'') and to_date(''27-01-2010'', ''DD-MM-YYYY'')
 group by co.typecompte,  operation ');
 
 INSERT INTO user_workload (username, module, action, priority, sql_text)
 VALUES ('&MYPDBUSER', 'Example14', 'Action', 2,
 'select co.typecompte,  operation, sum(montant)
 from compte co, transaction tr
 where co.compteid=tr.compteid
 and tr.date_operation 
 between to_date(''25-01-2010'', ''DD-MM-YYYY'') and to_date(''27-01-2010'', ''DD-MM-YYYY'')
 group by co.typecompte,  operation') ;


commit;


--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- 3. Analyser les requêtes et produire les recommandations
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


-- programmation de tache Sql access advisor
set serveroutput on

-- fixer les spérateurs de nombre en Anglais. "," pour les décimaux et "." pour les groupes

-- Anglais
alter session set NLS_NUMERIC_CHARACTERS = '.,' ; 

-- Francais
-- alter session set NLS_NUMERIC_CHARACTERS = ',.'  ; 
declare
saved_stmts NUMBER;
failed_stmts NUMBER;
wkld_name VARCHAR2(30) :='WKLD_BANK';
taskname VARCHAR2(30) := 'TASK_BANK'; 
task_id NUMBER;
num_found NUMBER:=0;
Begin
-- détacher la tache et le workload
select count(*) into num_found 
from user_advisor_sqla_wk_map 
where task_name = taskname and workload_name = wkld_name;
IF num_found > 0 THEN
DBMS_ADVISOR.RESET_TASK (taskname);
DBMS_ADVISOR.DELETE_SQLWKLD_REF(taskname, wkld_name);
END IF;

-- suppression puis création de la t
select count(*) into num_found 
from dba_advisor_tasks 
where owner='&MYPDBUSER' and task_name=taskname;

IF num_found > 0 THEN
DBMS_ADVISOR.DELETE_TASK (taskname);
END IF;
DBMS_ADVISOR.CREATE_TASK ('SQL Access Advisor', task_id, taskname);

-- suppression et puis création du workload
select count(*) into num_found 
from user_advisor_sqlw_sum 
where workload_name = wkld_name;
IF num_found > 0 THEN
DBMS_ADVISOR.DELETE_SQLWKLD(workload_name=> wkld_name);
END IF;
DBMS_ADVISOR.CREATE_SQLWKLD (wkld_name);

-- chargement du workload
DBMS_ADVISOR.IMPORT_SQLWKLD_USER( 
workload_name=> wkld_name,import_mode=>'NEW', owner_name=>'&MYPDBUSER', 
table_name=>'USER_WORKLOAD', Saved_rows=>saved_stmts, 
Failed_rows=>failed_stmts);
dbms_output.put_line(' saved_stmts='||saved_stmts);
dbms_output.put_line(' failed_stmts='||failed_stmts);
-- Attacher le workload à une tâche
/* Link Workload to Task */
dbms_advisor.add_sqlwkld_ref(taskname,wkld_name);

--Mise à jour de paramètres de la tâche
dbms_advisor.set_task_parameter(taskname,'EXECUTION_TYPE','INDEX_ONLY');--'FULL');--'INDEX_ONLY');
dbms_advisor.set_task_parameter(taskname,'MODE','COMPREHENSIVE');

-- exécuter la tâche
DBMS_ADVISOR.EXECUTE_TASK(taskname);
Exception 
When others then
dbms_output.put_line(' SQLcode='||sqlcode);
dbms_output.put_line(' SQLerrm='||sqlerrm);
End;
/
/*
*
ERREUR à la ligne 1 :
ORA-13600: erreur survenue dans Advisor
ORA-13635: La valeur indiquée pour le paramètre ADJUSTED_SCALEUP_GREEN_THRESH
ne peut pas être convertie en nombre.
ORA-06512: à "SYS.PRVT_ADVISOR", ligne 3902
ORA-06512: à "SYS.DBMS_ADVISOR", ligne 102
ORA-06512: à ligne 26
*/

-- ALTER SYSTEM SET NLS_TERRITORY=FRANCE scope=spfile;

-- si cette apparait faire les 	actions suivantes 
-- Ne pas lancer les deux programmes qui suivent 
-- si pas d'erreur

/*
-- ne pas exécuter ce script si pas d'erreur plus haut
declare
template_id NUMBER;
template_name VARCHAR2(255):= 'MY_TEMPLATE';
Begin
DBMS_ADVISOR.SET_DEFAULT_TASK_PARAMETER (
'SQL Access Advisor', 
'ADJUSTED_SCALEUP_GREEN_THRESH'  ,
'1,25' -- au lieu de 1.25
);
end;
/

-- ne pas exécuter ce script si pas d'erreur plus haut
declare
template_id NUMBER;
template_name VARCHAR2(255):= 'MY_TEMPLATE';
Begin
DBMS_ADVISOR.SET_DEFAULT_TASK_PARAMETER (
'SQL Access Advisor', 
'OVERALL_SCALEUP_GREEN_THRESH'  ,
'1,5' -- au lieu de 1.5
);
end;
/

*/

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- 4. Consulter les recommandations
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

-- Consulter les requêtes de référence que va régler SAA
col WORKLOAD_NAME format a20
col SQL_TEXT format a70
set linesize 200
set pagesize 400
select WORKLOAD_NAME, sql_id, SQL_TEXT from DBA_ADVISOR_SQLW_STMTS
Where workload_name= 'WKLD_BANK'
order by sql_id;


-- Visualisation des recommandations
-- Affiche du nr de recommandation, le rang et le bénéfice de 
-- la recommandation

SELECT REC_ID, RANK, BENEFIT, type
FROM USER_ADVISOR_RECOMMENDATIONS WHERE TASK_NAME = 'TASK_BANK';

-- Visualisation des recommandations
-- Afficher des recommandations et des bénéfices 
-- par requêtes

SELECT sql_id, rec_id, precost, postcost,
(precost-postcost)*100/precost AS percent_benefit
FROM USER_ADVISOR_SQLA_WK_STMTS
WHERE TASK_NAME = 'TASK_BANK'
AND workload_name = 'WKLD_BANK';

-- Visualisation des recommandations
-- Affichage des actions recommandés :
-- Comptage des actions recommandées


SELECT 'Action Count', COUNT(DISTINCT action_id) cnt
FROM user_advisor_actions 
WHERE task_name = 'TASK_BANK';



-- Visualisation des recommandations
-- Affichage des actions recommandés :
-- Liste des actions recommandées


Col command format A30
Col attr1 format A40
Set long 500
SELECT rec_id, action_id, command, attr1
FROM user_advisor_actions 
WHERE task_name = 'TASK_BANK'
ORDER BY rec_id, action_id;


-- Visualisation des recommandations
-- Génération des scripts SQL
-- Afin d'implémenter les recommandations il est possible de 
-- générer des scripts

-- La fonction GET_TASK_SCRIPT construire le script
set serveroutput on
begin
dbms_output.put_line(DBMS_ADVISOR.GET_TASK_SCRIPT('TASK_BANK'));
end;
/

-- La fonction CREATE_FILE permet de créer le fichier 
-- contenant le script
declare 
mydate varchar2(20):=to_char(sysdate, 'DD_MM_YYYY_HH24_MI_SS');
fname varchar2(300):='SAA_Generate_script_on_bank_app_'||mydate||'.sql';
begin
dbms_output.put_line(fname);
DBMS_ADVISOR.CREATE_FILE(
buffer=>DBMS_ADVISOR.GET_TASK_SCRIPT('TASK_BANK'),
location =>'DATA_PUMP_DIR', 
 filename=>fname
);
end;
/

spool off

