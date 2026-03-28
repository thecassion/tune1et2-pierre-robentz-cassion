/*

Exercice 1

Travail à faire via l'API

Ecrire un script qui permet d'analyser et produire des recommandations sur des requêtes SQL stockées dans une table utilisateur. Vous devez pour cela :
0. Connexion
1. Définir une tâche avec un template OLTP ou DWH ou mixte
2. Définir un workload à partir d'une table Utilisateur (voir Annexe 11.1) 
à créer à remplir avec au moins deux requêtes
3. Attacher la tâche aux workload
4. Fixer certains paramètres de la tâche tel que 
EXECUTION_TYPE = INDEX_ONLY puis FULL
MODE = COMPREHENSIVE
5. Exécuter la tâche


Visualiser les recommandations

Et si possible accepter les recommandations

Travail à faire via OEM

Refaire le travail fait avec l'API via OEM

	
*/

-----------------------------------------------------------------------------------
-- 1. Définition de variables, création d'un user si utile, 
-- Connexion à la base de données 
-----------------------------------------------------------------------------------

-- Connexion à la base de données 
-- Télécharger instant client pour votre OS site Oracle
-- ou récupérer le dans l'espace partagé que vous a communiqué l'enseignant
-- Créer un dossier "logiciels" sur votre disque C ou D
-- Prendre instant client sur le drive ici : 
-- ..\3ETU_M2MBDS_ESATIC\1COURS\Mopolo\5Tuning\OutilInstantClientet placer le zip -- dans le dossier : logiciel dezippé.
-----------------------------------------------------------------------------------

cmd
cd C:\Logiciels\..\instantclient_21_3_WindowsESATIC
cd C:\Logiciels\7_INSTANT_CLIENT\instantclient_21_3_WindowsESATIC\instantclient_21_3_WindowsESATIC
-- Lancer sqlplus sans se logger
sqlplus /nolog

-- Définir la variable qui indique l'emplacement des scripts
-- Attention le chemin vers le dossier du cours Tuning doit être sans espace
-- Créer un par exemple un dossier c:\tporacle et y déposer le dossier
-- du cours. 
define SCRIPTPATH=C:\TRAVAUX_PRATIQUES\tpTuning\ESATIC\5Tuning\TP_TUNE2_2021_2022\ScriptsTune2\EXO31_41

-- Définir la variable contenant le nom de l'instance

define MYINSTANCE=bdcours19c

-- Définir la vairiable qui va contenir le nom réseau de votre base PDB.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
-- Lancer netmgr pour Ajouter l'alias PDBM2ESA
-- 
define DBALIASPDB=PDBM2ESA

-- Définir la vairiable qui va contenir le nom réseau de votre base CDB.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIASCDB=bdcours19c

-- Définir la variable contenant le nom de l'utilisateur que vous allez 
-- utiliser au niveau CDB. 
define MYCDBUSER=c##adminawr
 
-- Définir la variable contenant le pass de l'utilisateur que vous allez 
-- utiliser au niveau CDB.
define MYCDBUSERPASS=TempPassword01

-- Définir la variable contenant le nom de l'utilisateur que vous allez 
-- créer au niveau PDB ou utiliser s'il existe déjà. 

define MYPDBNUM=?
define MYPDBUSER=ORS2&MYPDBNUM
 
-- Définir la variable contenant le pass de l'utilisateur que vous allez 
-- créer au niveau PDB ou utiliser s'il existe déjà.
define MYPDBUSERPASS=PassOrs2

-- Définir la variable contenant la trace que vous souhaitez :
-- ON : si affiche résultat+plan
-- TRACEONLY : si affichage plan uniquement
define TRACEOPTION=TRACEONLY

-- pour voir les variables définies tapez
define


-- Connexion avec le nouvel utilisateur ou un utilisateur existant au niveau
-- PDB. 
connect &MYPDBUSER@&DBALIASPDB/&MYPDBUSERPASS

---------------------------------------------------------------------------------------
-- 2. activation du script pour exécuter le conseiller SAA
-- Le résultat de cette exécution sera la génération dans le dossier :
-- %ORACLE_BASE%\admin\dpdump\nomBase\nomPdb
-- d'un fichier nommé : SAA_Generate_script_on_bank_app_'||mydate||'.sql
@&SCRIPTPATH\Ex101_Tune2_SAA_BANK_2ACTIVITY.SQL

-- 3 Implémentation des recommandations
-- Copier le contenu du fichier généré en 2 dans le dossier fichier :
-- Ex101_Tune2_SAA_BANK_3Recommandations.sql
-- Ce fichier se trouve dans le dossier :&SCRIPTPATH\EXO101
-- Nettoyer les doublons puis exécutez ce script pour implémenter les recommandations
@&SCRIPTPATH\Ex101_Tune2_SAA_BANK_3Recommandations.sql


-- 4. activation du script pour réexécuter le conseiller SAA
-- Le résultat de cette réexécution sera la génération dans le dossier :
-- %ORACLE_BASE%\admin\dpdump\nomBase\nomPdb
-- d'un fichier nommé : SAA_Generate_script_on_bank_app_'||mydate||'.sql
-- Si l'étape 3 est faite il ne doit pas avoir de recommandationn d'index
@&SCRIPTPATH\Ex101_Tune2_SAA_BANK_4ACTIVITYRetune.SQL

