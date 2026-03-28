/*


Cr�er une proc�dure d'analyse des objets

Cette proc�dure permet d'analyser un segment
une table ou un tablespace avec Segment Advisor.
Il faut lui passer en param�tre :
- Le nom de la tache
- Si utile sa description
- Le type d'objet � analyser :TABLE, TABLESPACE 
- Le nom de l'objet
- Le propri�taire de l'objet si c'est une table


*/


-- se connecter � la base
-- Se connecter en tant ORS1 sur votre instance Oracle
-- Se d�placer dans le dossier 
-- Changer de r�pertoire sous en se d�placant dans le dossier ou se trouve :..\ScriptsTune2
-- exemple
-- cd  1agm05092005\1Cours\5ORS\2014_2015\TP_TUNE2_MODELE_2015\ScriptsTune2
-- Lancer sqlplus dans ce dossier ScriptsTune2

-----------------------------------------------------------------------------------
-- 1. D�finition de variables, cr�ation d'un user si utile, 
-- Connexion � la base de donn�es 
-----------------------------------------------------------------------------------

-- Connexion � la base de donn�es 
-- T�l�charger instant client pour votre OS site Oracle
-- ou r�cup�rer le dans l'espace partag� que vous a communiqu� l'enseignant
-- Cr�er un dossier "logiciels" sur votre disque C ou D
-- Prendre instant client sur le drive ici : 
-- ..\3ETU_M2MBDS_ESATIC\1COURS\Mopolo\5Tuning\OutilInstantClientet placer le zip -- dans le dossier : logiciel dezipp�.
-----------------------------------------------------------------------------------

cmd
cd C:\Logiciels\..\instantclient_21_3_WindowsESATIC
cd C:\Logiciels\7_INSTANT_CLIENT\instantclient_21_3_WindowsESATIC\instantclient_21_3_WindowsESATIC
-- Lancer sqlplus sans se logger
sqlplus /nolog

-- D�finir la variable qui indique l'emplacement des scripts
-- Attention le chemin vers le dossier du cours Tuning doit �tre sans espace
-- Cr�er un par exemple un dossier c:\tporacle et y d�poser le dossier
-- du cours. 
-- define SCRIPTPATH=C:\TRAVAUX_PRATIQUES\tpTuning\ESATIC\5Tuning\TP_TUNE2_2021_2022\ScriptsTune2\EXO31_41

-- Pour Docker
define SCRIPTPATH=/opt/oracle/scripts/TP_TUNE2_MODELE_2025_2026/ScriptsTune2/EXO111

-- D�finir la variable contenant le nom de l'instance

define MYINSTANCE=FREE

-- D�finir la vairiable qui va contenir le nom r�seau de votre base PDB.
-- Le nom r�seau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
-- Lancer netmgr pour Ajouter l'alias PDBM2ESA
-- 
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

define MYPDBNUM=1
define MYPDBUSER=ORS2
 
-- D�finir la variable contenant le pass de l'utilisateur que vous allez 
-- cr�er au niveau PDB ou utiliser s'il existe d�j�.
define MYPDBUSERPASS=PassOrs2

-- D�finir la variable contenant la trace que vous souhaitez :
-- ON : si affiche r�sultat+plan
-- TRACEONLY : si affichage plan uniquement
define TRACEOPTION=TRACEONLY

-- pour voir les variables d�finies tapez
define


-- Connexion avec le nouvel utilisateur ou un utilisateur existant au niveau
-- PDB. 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS


---------------------------------------------------------------------------------------
-- 2. activation du script pour ex�cuter le conseiller SAA
-- Le r�sultat de cette ex�cution sera la g�n�ration dans le dossier :
-- %ORACLE_BASE%\admin\dpdump\nomBase\nomPdb
-- d'un fichier nomm� : SAA_Generate_script_on_bank_app_'||mydate||'.sql
@&SCRIPTPATH/Ex111_Tune2_SA_2ACTIVITY.SQL

