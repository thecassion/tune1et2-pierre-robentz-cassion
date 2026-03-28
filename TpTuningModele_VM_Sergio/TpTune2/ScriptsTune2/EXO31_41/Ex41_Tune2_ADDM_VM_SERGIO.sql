/*
	LIRE ATTENTIVEMENT LE CHAPITRE 3 DU COURS TUNE 2 CONCERNANT AWR:

	1. Exécuter le script ci-dessous pour générer le rapport ADDM
	Lire les recommandations.
	Utiliser les nr de clichés AWR générés dans l'exercices 
	Ex21_Tune2_Statspack.sql
	
	2. Générer aussi ce même rapport depuis le database contrôle
	(Enterprise Manager : environnement graphique)
	
*/


-- Utilisation de ADDM (Automatic Database Diagonstic Monitor)
-- via le script addmrpt.sql
-- Génération d'un rapport de diagnostic automatique.
-- Il faut se servir des clichés AWR générés dans l'exercice 
-- Ex21_Tune2_Statspack.sql
@$ORACLE_HOME/rdbms/admin/addmrpt.sql

--Générer aussi ce même rapport depuis le database contrôle
--(Enterprise Manager : environnement graphique)
