/*
LIRE ATTENTIVEMENT LE CHAPITRE 2 et 3 DU COURS TUNE 2 :
	 

Ce script réalise les activités suivantes :
-- 1. Définition de variables, création d'un user si utile, 
--    Connexion à la base de données 
-- 2. Lancement du script Ex31b_Tune2_Activity.sql pour provoquer une forte 
-- activité qui pourra nous permettre avec AWR et ADDM d'identifier si possible 
-- des à résoudre.
Attention :
	- Si des actions sont précédés du commentaire --
	- Ne pas les exécuter
	- ***CE SCRIPT EST EXECUTER IDEALEMENT UNIQUEMENT SOUS SQLPLUS***

-- 3. Lancement du script Ex31D_TUNE2_AWR_REPORT.sql pour générer un 
--    rapport AWR (Automatic Workload Repository)

-- 4. Lancement du script Ex41_Tune2_ADDM.sql pour générer un 
--    rapport ADDM (Automatic Database Diagnostic Monitor)
		
*/

-----------------------------------------------------------------------------------
-- 1. Définition de variables, création d'un user si utile, 
-- Connexion à la base de données 
-----------------------------------------------------------------------------------
cmd

cd C:\Logiciels\19VM_SERGIO\vagrant-projects\OracleDatabase\21.3.0

vagrant ssh

-- Lancer sqlplus sans se logger
sudo -su oracle

-- Lancer sqlplus sans se logger
sqlplus /nolog

-- Définir la variable qui indique l'emplacement des scripts
-- Attention le chemin vers le dossier du cours Tuning doit être sans espace
-- Créer un par exemple un dossier c:\tporacle et y déposer le dossier
-- du cours. 
define SCRIPTPATH=/vagrant/TpTuning/TpTune2/ScriptsTune2/EXO31_41

-- Définir la variable contenant le nom de l'instance
define MYINSTANCE=ORCLCDB

-- Définir la vairiable qui va contenir le nom réseau de votre base PDB.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIASPDB=ORCLPDB1

-- Définir la vairiable qui va contenir le nom réseau de votre base CDB.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIASCDB=ORCLCDB

-- Définir la variable contenant le nom de l'utilisateur que vous allez 
-- utiliser au niveau CDB. 
define MYCDBUSER=SYSTEM
 
-- Définir la variable contenant le pass de l'utilisateur que vous allez 
-- utiliser au niveau CDB.
define MYCDBUSERPASS=Welcome1

-- Définir la variable contenant le nom de l'utilisateur que vous allez 
-- créer au niveau PDB ou utiliser s'il existe déjà. 
define MYPDBUSER=ORS2
 
-- Définir la variable contenant le pass de l'utilisateur que vous allez 
-- créer au niveau PDB ou utiliser s'il existe déjà.
define MYPDBUSERPASS=PassOrs2

-- Définir la variable contenant la trace que vous souhaitez :
-- ON : si affiche résultat+plan
-- TRACEONLY : si affichage plan uniquement
define TRACEOPTION=TRACEONLY

-- Se connecter avec votre compte CDB dans la PDB pour créer l'utilisateur 
-- &MYPDBUSER
-- 
connect &MYCDBUSER@&DBALIASPDB/&MYCDBUSERPASS

-- suprimer l'utilisateur s'il existe déjà
drop user &MYPDBUSER cascade;

-- Création de l'utilisateur. 
create user &MYPDBUSER identified by &MYPDBUSERPASS
default tablespace users
temporary tablespace temp;

-- affecter et enlever des droits
grant dba to &MYPDBUSER;

revoke unlimited tablespace from &MYPDBUSER;

alter user &MYPDBUSER quota unlimited on users;

-- Connexion avec le nouvel utilisateur ou un utilisateur existant au niveau
-- PDB. 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS

-----------------------------------------------------------------------------------
-- 2. Lancement du script Ex31b_Tune2_Activity.sql pour provoquer une forte 
-- activité qui pourra nous permettre avec AWR et ADDM d'identifier si possible 
-- des à résoudre.
-- Un fichier contenant les logs d'exécution appelé :EX31E_TUNE2_SPOOL_LOG.LOG
-- sera généré dans le dossier : &SCRIPTPATH\LOG
-----------------------------------------------------------------------------------
@&SCRIPTPATH/EX31b_TUNE2_ACTIVITY_VM_SERGIO.SQL

-----------------------------------------------------------------------------------
-- 3. Lancement du script Ex31C_TUNE2_AWR_REPORT.sql pour générer un 
--    rapport AWR (Automatic Workload Repository)
-- Vous devez indiquer le cliché de départ snapid1 et de fin snapid2
-- Voir le fichier : EX31E_TUNE2_SPOOL_LOG.LOG généré en 2.
-- Vous devez déposez ce rapport dans le dossier :
-- Substituer &SCRIPTPATH par la veleur concrète fixée plus haut
-- Réponses interactives :
-- Specify the Report Type : text
-- Specify the location of AWR Data : AWR_ROOT
-- Entrez une valeur pour num_days : 1
-- Entrez une valeur pour begin_snap :snapid1
-- Entrez une valeur pour begin_snap :snapid2
-- Entrez une valeur pour report_name :&SCRIPTPATH\REPORTS\awrrpt_1_snapid1_snapid2.txt
-----------------------------------------------------------------------------------
@&SCRIPTPATH/Ex31C_TUNE2_AWR_REPORT_VM_SERGIO.sql

-----------------------------------------------------------------------------------
-- 4. Lancement du script Ex41_Tune2_ADDM.sql pour générer un 
-- rapport ADDM (Automatic Database Diagnostic Monitor)
-- Vous devez indiquer le cliché de départ snapid1 et de fin snapid2
-- Voir le fichier : EX31E_TUNE2_SPOOL_LOG.LOG généré en 2.
-- Vous devez déposez ce rapport dans le dossier :
-- &SCRIPTPATH\REPORTS
-- Substituer &SCRIPTPATH par la veleur concrète fixée plus haut*
-- Réponses interactives :
-- Entrez une valeur pour num_days : 1
-- Entrez une valeur pour begin_snap :snapid1
-- Entrez une valeur pour begin_snap :snapid2
-- Entrez une valeur pour report_name :&SCRIPTPATH\REPORTS\addmrpt_1_snapid1_snapid2.txt
-----------------------------------------------------------------------------------
-- Ce rapport ne peut être généré qu'au niveau CDB 
connect &MYCDBUSER@&DBALIASCDB/&MYCDBUSERPASS

@&SCRIPTPATH/Ex41_Tune2_ADDM_VM_SERGIO.sql

-- Reconnexion au niveau PDB 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS

-- ACTION DE VOTRE PART :
-- Analyser le rapport ADDM et proposer des correctifs
