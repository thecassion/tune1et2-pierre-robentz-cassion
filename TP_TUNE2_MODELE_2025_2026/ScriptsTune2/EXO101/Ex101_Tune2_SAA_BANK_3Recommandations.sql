--Rem  SQL Access Advisor : Version 12.2.0.1.0 - Production
--Rem  
--Rem  Nom utilisateur :    ORS2
--Rem  T�che :             TASK_BANK
--Rem  Date d'ex�cution :   

-- 3 Impl�mentation des recommandations
-- Copier le contenu du fichier g�n�r�
-- nomm� : SAA_Generate_script_on_bank_app_'||mydate||'.sql 
-- dans le dossier : -- %ORACLE_BASE%\admin\dpdump\nomBase\nomPdb
-- dans ce fichier :
-- Ex101_Tune2_SAA_BANK_3Recommandations.sql
-- Ce fichier se trouve dans le dossier :&SCRIPTPATH\EXO101
-- Nettoyer les doublons puis ex�cutez ce script pour impl�menter 
-- les recommandations

/*
< Mettre les actions ci-apr�s ce commentaire>
*/

Rem  SQL Access Advisor: Version 23.0.0.0.0 - Production
Rem  
Rem  Username:        ORS2
Rem  Task:            TASK_BANK
Rem  Execution date:  28/03/2026 05:33
Rem  

/* RETAIN INDEX "ORS2"."PK_CLIENT_CLIENTID" */

/* RETAIN INDEX "ORS2"."PK_COMPTE_COMPTEID" */

CREATE BITMAP INDEX "ORS2"."TRANSACTION_IDX$$_00A10000"
    ON "ORS2"."TRANSACTION"
    ("DATE_OPERATION")
    COMPUTE STATISTICS;

CREATE INDEX "ORS2"."CLIENT_IDX$$_00A10001"
    ON "ORS2"."CLIENT"
    ("NOM")
    COMPUTE STATISTICS;

CREATE INDEX "ORS2"."COMPTE_IDX$$_00A10002"
    ON "ORS2"."COMPTE"
    ("CLIENTID")
    COMPUTE STATISTICS;

CREATE INDEX "ORS2"."TRANSACTION_IDX$$_00A10003"
    ON "ORS2"."TRANSACTION"
    ("COMPTEID")
    COMPUTE STATISTICS;

CREATE INDEX "ORS2"."COMPTE_IDX$$_00A10004"
    ON "ORS2"."COMPTE"
    ("SOLDE")
    COMPUTE STATISTICS;