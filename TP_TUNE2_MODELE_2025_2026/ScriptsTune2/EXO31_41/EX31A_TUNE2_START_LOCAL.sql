/*
LIRE ATTENTIVEMENT LE CHAPITRE 2 et 3 DU COURS TUNE 2 :
	 

Ce script r�alise les activit�s suivantes :
-- 1. D�finition de variables, cr�ation d'un user si utile, 
--    Connexion � la base de donn�es 
-- 2. Lancement du script Ex31b_Tune2_Activity.sql pour provoquer une forte 
-- activit� qui pourra nous permettre avec AWR et ADDM d'identifier si possible 
-- des � r�soudre.
Attention :
	- Si des actions sont pr�c�d�s du commentaire --
	- Ne pas les ex�cuter
	- ***CE SCRIPT EST EXECUTER IDEALEMENT UNIQUEMENT SOUS SQLPLUS***

-- 3. Lancement du script Ex31D_TUNE2_AWR_REPORT.sql pour g�n�rer un 
--    rapport AWR (Automatic Workload Repository)

-- 4. Lancement du script Ex41_Tune2_ADDM.sql pour g�n�rer un 
--    rapport ADDM (Automatic Database Diagnostic Monitor)
		
*/

-----------------------------------------------------------------------------------
-- 1. D�finition de variables, cr�ation d'un user si utile, 
-- Connexion � la base de donn�es 
-----------------------------------------------------------------------------------

cmd
-- Lancer sqlplus sans se logger
sqlplus /nolog

-- D�finir la variable qui indique l'emplacement des scripts
-- Attention le chemin vers le dossier du cours Tuning doit �tre sans espace
-- Cr�er un par exemple un dossier c:\tporacle et y d�poser le dossier
-- du cours. 
-- define SCRIPTPATH=D:\1agm05092005\1Cours\5ORS\2019_2020\TP_TUNE2_ESATIC\ScriptsTune2\EXO31_41
define SCRIPTPATH=/opt/oracle/scripts/TP_TUNE2_MODELE_2025_2026/ScriptsTune2/EXO31_41

-- D�finir la variable contenant le nom de l'instance
-- define MYINSTANCE=DBTEST12
define MYINSTANCE=FREE

-- D�finir la vairiable qui va contenir le nom r�seau de votre base PDB.
-- Le nom r�seau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
-- define DBALIASPDB=PDBORCL

define DBALIASPDB=FREEPDB1


-- D�finir la vairiable qui va contenir le nom r�seau de votre base CDB.
-- Le nom r�seau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIASCDB=FREE

-- D�finir la variable contenant le nom de l'utilisateur que vous allez 
-- utiliser au niveau CDB. 
define MYCDBUSER=SYSTEM
 
-- D�finir la variable contenant le pass de l'utilisateur que vous allez 
-- utiliser au niveau CDB.
define MYCDBUSERPASS=Oracle123

-- D�finir la variable contenant le nom de l'utilisateur que vous allez 
-- cr�er au niveau PDB ou utiliser s'il existe d�j�. 
define MYPDBUSER=ORS2
 
-- D�finir la variable contenant le pass de l'utilisateur que vous allez 
-- cr�er au niveau PDB ou utiliser s'il existe d�j�.
define MYPDBUSERPASS=PassOrs2

-- D�finir la variable contenant la trace que vous souhaitez :
-- ON : si affiche r�sultat+plan
-- TRACEONLY : si affichage plan uniquement
define TRACEOPTION=TRACEONLY

-- Se connecter avec votre compte CDB dans la PDB pour cr�er l'utilisateur 
-- &MYPDBUSER
-- 
connect &MYCDBUSER@&DBALIASPDB/&MYCDBUSERPASS

-- suprimer l'utilisateur s'il existe d�j�
drop user &MYPDBUSER cascade;

-- Cr�ation de l'utilisateur. 
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
-- activit� qui pourra nous permettre avec AWR et ADDM d'identifier si possible 
-- des � r�soudre.
-- Un fichier contenant les logs d'ex�cution appel� :EX31E_TUNE2_SPOOL_LOG.LOG
-- sera g�n�r� dans le dossier : &SCRIPTPATH\LOG
-----------------------------------------------------------------------------------
@&SCRIPTPATH/EX31b_TUNE2_ACTIVITY.SQL

-----------------------------------------------------------------------------------
-- 3. Lancement du script Ex31C_TUNE2_AWR_REPORT.sql pour g�n�rer un 
--    rapport AWR (Automatic Workload Repository)
-- Vous devez indiquer le clich� de d�part snapid1 et de fin snapid2
-- Voir le fichier : EX31E_TUNE2_SPOOL_LOG.LOG g�n�r� en 2.
-- Vous devez d�posez ce rapport dans le dossier :
-- Substituer &SCRIPTPATH par la veleur concr�te fix�e plus haut
-- R�ponses interactives :
-- Specify the Report Type : text
-- Specify the location of AWR Data : AWR_ROOT
-- Entrez une valeur pour num_days : 1
-- Entrez une valeur pour begin_snap :snapid1
-- Entrez une valeur pour begin_snap :snapid2
-- Entrez une valeur pour report_name :/opt/oracle/scripts/TP_TUNE2_MODELE_2025_2026/ScriptsTune2/EXO31_41/REPORTS/awrrpt_1_snapid1_snapid2.txt
-----------------------------------------------------------------------------------
@&SCRIPTPATH/Ex31C_TUNE2_AWR_REPORT.sql

-----------------------------------------------------------------------------------
-- 4. Lancement du script Ex41_Tune2_ADDM.sql pour g�n�rer un 
-- rapport ADDM (Automatic Database Diagnostic Monitor)
-- Vous devez indiquer le clich� de d�part snapid1 et de fin snapid2
-- Voir le fichier : EX31E_TUNE2_SPOOL_LOG.LOG g�n�r� en 2.
-- Vous devez d�posez ce rapport dans le dossier :
-- &SCRIPTPATH\REPORTS
-- Substituer &SCRIPTPATH par la veleur concr�te fix�e plus haut*
-- R�ponses interactives :
-- Entrez une valeur pour num_days : 1
-- Entrez une valeur pour begin_snap :snapid1
-- Entrez une valeur pour begin_snap :snapid2
-- Entrez une valeur pour report_name :/opt/oracle/scripts/TP_TUNE2_MODELE_2025_2026/ScriptsTune2/EXO31_41/REPORTS/addmrpt_1_snapid1_snapid2.txt
-----------------------------------------------------------------------------------
-- Ce rapport ne peut �tre g�n�r� qu'au niveau CDB 
connect &MYCDBUSER@&DBALIASCDB/&MYCDBUSERPASS

connect &MYCDBUSER@&MYCDBUSERPASS/&DBALIASPDB

@&SCRIPTPATH/Ex41_Tune2_ADDM.sql

-- Reconnexion au niveau PDB 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS

-- ACTION DE VOTRE PART :
-- Analyser le rapport ADDM et proposer des correctifs
