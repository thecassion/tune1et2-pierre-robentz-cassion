
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
cmd
c:\>cd chemin\script\

sqlplus /nolog

connect ors1/Passors1

alter session set nls_language=american;

alter session set nls_territory=america;

sql>@2bEMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_BLD.SQL

--sqlplus ors1@ORCL/Passors1 @3EMP4_DEPT4_IEMP4_IDEP4_HEMP4_HDEPT4_BLD.SQL > Log_xemp4_xdept4.log

