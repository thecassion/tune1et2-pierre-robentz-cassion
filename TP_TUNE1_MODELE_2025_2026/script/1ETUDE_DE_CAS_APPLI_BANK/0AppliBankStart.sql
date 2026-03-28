/*
Installation et optimisation des requêtes d'une application bancaire AppliBank
-- 1. Lancer ce script pour créer les tables et insérer des lignes 
-- de l'application bancaire AppliBank
-- 2. Exécuter les requêtes de l'application bancaire avant leur optimisation
-- 3. Proposer dans le fichier ci-dessous, requête par requête des index
-- afin de pouvoir les optimiser.
-- Exécuter ensuite ce script
-- 4. Exécuter les requêtes de l'application bancaire après optimisation
-- Comparer les plans d'exécution obtenus en étape 2 avec ceux obtenus en étape4


*/

define DBALIAS=PDBORCL
define SCRIPTPATH=D:\1agm05092005\1Cours\5ORS\2018_2019\0TP_TUNE_MODELE\TP_TUNE1_MODELE\script\1ETUDE_DE_CAS_APPLI_BANK
define MYUSER=ORS1

-- connection avec le nouvel utilisateur. Il faut respecter la casse pour le password
connect &MYUSER@&DBALIAS/PassOrs1

-- 1. Lancer ce script pour créer les tables et insérer des lignes 
-- de l'application bancaire AppliBank
@&SCRIPTPATH\1AppliBankBld.sql

-- 2. Exécuter les requêtes de l'application bancaire avant leur optimisation
@&SCRIPTPATH\4AppliBankQuery.sql

-- 3. Proposer dans le fichier ci-dessous, requête par requête des index
-- afin de pouvoir les optimiser.
-- Exécuter ensuite ce script
-- @&SCRIPTPATH\test\Ex91_TUNE2_STA_BANK_9SCRIPT.sql
@&SCRIPTPATH\5AppliBankCreateIndexes.sql

-- 4. Exécuter les requêtes de l'application bancaire après optimisation
-- Comparer les plans d'exécution obtenus en étape 2 avec ceux obtenus en étape4
@&SCRIPTPATH\6AppliBankQueryAfterIndexCreation.sql


undefine SCRIPTPATH
undefine MYUSER
