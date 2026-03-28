/*
	LIRE ATTENTIVEMENT LE CHAPITRE 3 DU COURS TUNE 2 CONCERNANT AWR:

	1. Ex�cuter le script ci-dessous pour g�n�rer le rapport ADDM
	Lire les recommandations.
	Utiliser les nr de clich�s AWR g�n�r�s dans l'exercices 
	Ex21_Tune2_Statspack.sql
	
	2. G�n�rer aussi ce m�me rapport depuis le database contr�le
	(Enterprise Manager : environnement graphique)
	
*/


-- Utilisation de ADDM (Automatic Database Diagonstic Monitor)
-- via le script addmrpt.sql
-- G�n�ration d'un rapport de diagnostic automatique.
-- Il faut se servir des clich�s AWR g�n�r�s dans l'exercice 
-- Ex21_Tune2_Statspack.sql
@$ORACLE_HOME/rdbms/admin/addmrpt.sql

--G�n�rer aussi ce m�me rapport depuis le database contr�le
--(Enterprise Manager : environnement graphique)
