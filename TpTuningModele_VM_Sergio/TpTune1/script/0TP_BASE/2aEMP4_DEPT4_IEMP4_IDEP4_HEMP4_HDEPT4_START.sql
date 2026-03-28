
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

-- se connect avec le compte system
-- *****Cas 1 : VOUS ETES SUR UNE BASE LOCALE DANS LA VM LINUX DE SRGIO *****************

cmd

cd C:\Logiciels\19VM_SERGIO\vagrant-projects\OracleDatabase\21.3.0

vagrant ssh

-- Lancer sqlplus sans se logger
sudo -su oracle

sqlplus /nolog

-- Définir la variable qui indique l'emplacement des scripts
define SCRIPTPATH=/vagrant/TpTuning/TpTune1/script/0TP_BASE

-- Définir la vairiable qui va contenir le nom réseau de votre base.
-- Le nom réseau se dans le fichier tnsnames.ora
-- Il est disponible dans le dossier : %ORACLE_HOME%\network\admin
define DBALIAS=ORCLPDB1

-- Définir la variable contenant le nom de l'utilisateur que vous allez créer
define MYUSER=ORS1

-- Définir la variable contenant le password du compte SYSTEM
define SYSTEMPASSWORD=Welcome1

-- 
define MYINSTANCE=ORCLCDB

-- connection avec le nouvel utilisateur. Il faut respecter la casse pour le password
connect &MYUSER/PassOrs1@&DBALIAS

alter session set nls_language=american;

alter session set nls_territory=america;

sql>@&SCRIPTPATH/2bEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_BLD.SQL


