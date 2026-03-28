/*

	LIRE ATTENTIVEMENT LE CHAPITRE 3 DU COURS TUNE 2 CONCERNANT AWR:
	
	Ce script r�alise les activit�s suivantes :
		- Ce script g�n�re le rapport AWR en servant des clich�s AWR captur�s
		- dans l'exercices Ex21_Tune2_Statspack.sql grace au lancement
		- de la proc�dure :dbms_workload_repository.create_snapshot
		- analyser le rapport.
		
*/


-- G�n�ration de rapports manuels avec AWR
@$ORACLE_HOME/rdbms/admin/awrrpt.sql

-- Le rapport doit �tre d�pos� dans le dossier &SCRIPTPATH\REPORTS
-- 
-- Pour analyser le script rapidement il est possible de se servir
-- d'outils pour aller vite.
-- L'analyse est en r�alit� bas� sur une somme d'exp�riences
-- de dba Oracle
