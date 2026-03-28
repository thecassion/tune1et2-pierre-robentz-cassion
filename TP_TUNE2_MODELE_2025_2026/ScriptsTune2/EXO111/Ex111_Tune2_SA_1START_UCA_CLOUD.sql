/*


Créer une procédure d'analyse des objets

Cette procédure permet d'analyser un segment
une table ou un tablespace avec Segment Advisor.
Il faut lui passer en paramètre :
- Le nom de la tache
- Si utile sa description
- Le type d'objet à analyser :TABLE, TABLESPACE 
- Le nom de l'objet
- Le propriétaire de l'objet si c'est une table


*/


-- se connecter à la base
-- Se connecter en tant ORS1 sur votre instance Oracle
-- Se déplacer dans le dossier 
-- Changer de répertoire sous en se déplacant dans le dossier ou se trouve :..\ScriptsTune2
-- exemple
-- cd  1agm05092005\1Cours\5ORS\2014_2015\TP_TUNE2_MODELE_2015\ScriptsTune2
-- Lancer sqlplus dans ce dossier ScriptsTune2

-----------------------------------------------------------------------------------
-- 1. Définition de variables, création d'un user si utile, 
-- Connexion à la base de données 
-----------------------------------------------------------------------------------

cmd
-- Lancer sqlplus sans se logger
sqlplus /nolog

-- Définir la variable qui indique l'emplacement des scripts
define SCRIPTPATH=D:\1agm05092005\1Cours\5ORS\2019_2020\2TPTUNE2\TP_TUNE2_ESATIC_07_01_2020\ScriptsTune2\EXO111


-- Définir la variable contenant le nom de l'instance
define MYINSTANCE=DBTEST12

-- Définir la vairiable qui va contenir le nom réseau de votre base PDB.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIASPDB=PDBORCL

-- Définir la vairiable qui va contenir le nom réseau de votre base CDB.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIASCDB=DBTEST12

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

-- Connexion avec le nouvel utilisateur ou un utilisateur existant au niveau
-- PDB. 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS


---------------------------------------------------------------------------------------
-- 2. activation du script pour exécuter le conseiller SAA
-- Le résultat de cette exécution sera la génération dans le dossier :
-- %ORACLE_BASE%\admin\dpdump\nomBase\nomPdb
-- d'un fichier nommé : SAA_Generate_script_on_bank_app_'||mydate||'.sql
@&SCRIPTPATH\Ex111_Tune2_SA_2ACTIVITY.SQL

