set TERMOUT OFF
spool &SCRIPTPATH\appliBankQuery.log
set linesize 500
set pagesize 5000
-- vérification du type d'optimiseur
 show parameter optimizer_mode;

-- optimizer_mode                       string      ALL_ROWS
 
-- passer en mode all_rows si utile

alter session set optimizer_mode=all_rows ;

-- calculer les statistiques sur les objets de l'utilisateur
-- ORS2
execute dbms_stats.gather_schema_stats('&MYUSER');


 col compteid format a24
 col nom format a20
 col prenom format a20
 col ville format a20
 col adresse format a30
 set linesize 150

 -- Lancer plusieurs requêtes
 
-- listing des clients ayant des comptes 
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid;
 
 
 -- listing des clients ayant des comptes trié selon l'identifiant et
 -- le nom du client
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 order by clientid , nom;
 