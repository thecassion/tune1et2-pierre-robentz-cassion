/*
	LIRE ATTENTIVEMENT LE CHAPITRE 2 DU COURS TUNE 2 CONCERNANT PERFSTAT:
	 

	Ce script réalise les activités suivantes :
		- 1. Déinstallation de STATSPACK si ce repository est déjà créé
		- 2. Installation du repository de STATSPACK
		- 3. Création d'un premier cliché STATSPACK et en parallèle un ^premier cliché AWR
		- 4. Provoquer l'activité sur la base de données
		- 5. Création d'un dexième cliché STATSPACK et en parallèle un deuxmième cliché AWR
		- 6. Génération du rapport STATSPACK. Le rapport AWR sera généré dans l'exercice ex31_Tune2_AWR.sql


Attention :
	- Si des actions sont précédés du commentaire --
	- Ne pas les exécuter

		
*/

-- 1. Déinstallation de STATSPACK si ce repository est déjà créé

-- Désinstallation de statspack s'il existe sous dos
-- Si vous avez une autre instance remplacé ORCL par la votre.
-- Si votre mot de passe de SYS est différent de dbamanager, 
-- remplacé le par le votre.
-- Vous devez être connecté SYS AS SYSDBA pour effectuer les tâches
-- de suppression et de création du répository statspack.

-- Sur la ligne Execution de Windows aller sous DOS en éxécutant cmd
-- sous dos
set ORACLE_SID=ORCL
sqlplus /nolog

-- Définition de variables
define ORADATAPATH=C:\oracle\product\10.2.0\oradata
define SYSTEMPASSWORD=oraclesysdba
define MYSID=ORCL

-- Sous SQL
connect system/&SYSTEMPASSWORD as sysdba
-- connect sys as sysdba

-- à exécuter uniquement si statspack est déjà installé
@%ORACLE_HOME%\rdbms\admin\spdrop.sql

-- 2. Installation du repository de STATSPACK
-- Installation de statspack (il s'agit de créé le dictionnaire statspack)

-- création du TS pour le dictionnaire de statspack si ce tablespace n'existe pas déjà
create tablespace tsstatspack
datafile '&ORADATAPATH\&MYSID\ts_statspack_1.dbf' size 100M autoextend on ;

-- Installation du repository de statspack s'il n'existe pas
-- Un utilisateur appelé perfstat va être créé. Il aura le password,
-- le tablespace par défaut le tablespace temporaire cité ci-dessous.

@%ORACLE_HOME%\rdbms\admin\spcreate 
--password : dbamanager
--default tablespace:tsstatspack
--tablespace temp: temp

-- A partir de maintenant le reste de l'activité va se dérouler sous 
-- le compte SYSTEM. Connectez vous comme étant SYSTEM.
-- Il faut adapter le mot de passe et l'instance à votre environnement.

define SYSTEMPASSWORD=oraclesysdba

connect system/&SYSTEMPASSWORD


-- Déifinition du chemin du Script et du Spool
define SSPATH=C:\1agm05092005\1Cours\ORS\2012_2013\TP_TUNE2_MBDS_MODELE_2013\ScriptsTune2

-- activation du spool
SPOOL &SSPATH\Ex21_Tune2_STATSPACK.log


-- 3. Création d'un premier cliché STATSPACK et en parallèle un ^premier cliché AWR
-- 4. Provoquer l'activité sur la base de données
-- 5. Création d'un dexième cliché STATSPACK et en parallèle un deuxmième cliché AWR
@&SSPATH\Ex21_Tune2_STATSPACK_Activity.sql

-- désactivation du spool
spool off

-- Suppression de la variable SSPATH
undefine SSPATH
undefine ORADATAPATH
undefine SYSTEMPASSWORD
undefine MYSID



-- 6. Générer le rapport STATSPACK. Le rapport AWR sera généré dans l'exercice ex31_Tune2_AWR.sql

-- générer le rapport STATSPACK
@%ORACLE_HOME%\rdbms\admin\spreport

-- Le rapport AWR sera généré dans l'exercice suivant : ex31_awr.sql
-- Notez bien les valeurs de SNAPID_1 et SNAPID_2

-- Pour analyser le script rapidement il est possible de se servir
-- d'outils pour aller vite.
-- L'analyse est en réalité basé sur une somme d'expériences
-- de dba Oracle
-- http://www.statspackanalyzer.com/analyze090630.asp
-- Il faut s'inscrire par exemple dans ce site pour pouvoir analyser
-- votre script statspack. 

