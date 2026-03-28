/*

	LIRE ATTENTIVEMENT LE CHAPITRE 3 DU COURS TUNE 2 CONCERNANT AWR:
	
	Ce script réalise les activités suivantes :
		- Ce script génère le rapport AWR en servant des clichés AWR capturés
		- dans l'exercices Ex21_Tune2_Statspack.sql grace au lancement
		- de la procédure :dbms_workload_repository.create_snapshot
		- analyser le rapport.
		
*/


-- Génération de rapports manuels avec AWR
@$ORACLE_HOME/rdbms/admin/awrrpt.sql

-- Le rapport doit être déposé dans le dossier &SCRIPTPATH\REPORTS
-- 
-- Pour analyser le script rapidement il est possible de se servir
-- d'outils pour aller vite.
-- L'analyse est en réalité basé sur une somme d'expériences
-- de dba Oracle
