
spool &SCRIPTPATH\LOG\appliBankQueryAfterIndexCreation.log
set echo on
set serveroutput on
SET TERMOUT ON
PROMPT Executing AppliBank Queries After Index Creation.  Please wait.
-- Empêche l'affichage à l'écran
--SET TERMOUT OFF

set linesize 500
set pagesize 5000


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

 set autotrace traceonly

 -- Lancer plusieurs requêtes

-- Requête 1:
-- listing des clients ayant des comptes 
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid;
 
 -- Requête 2:
 -- listing des clients ayant des comptes trié selon l'identifiant et
 -- le nom du client
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 order by clientid , nom;
 
-- Requête 3:
-- listing des comptes d'un client connaissant son nom 
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 and nom ='Petit'
 order by co.clientid, nom, prenom;
 
 
 -- Requête 4:
 -- listing des informations sur les comptes et clients 
 -- dont le solde est négatif
 select cl.clientid, nom, prenom, compteid, typecompte, solde
 from client cl, compte co
 where cl.clientid=co.clientid
 and solde <0;
 

-- Requête 5:
-- listing des transactions par compte et client
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid;
 
 
 -- Requête 6:
 -- listing des transactions par compte et client pour lesquels le solde du compte négatif
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and co.solde <0;

-- Requête 7:
-- liste des transactions par compte et client connaissant le nom du client
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom='Petit';
 
 -- Requête 8:
 -- liste des transactions par compte et client connaissant le nom du client et opérées à une date donnée
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom='Petit' and date_operation=to_date('27-01-2010', 'DD-MM-YYYY');

 
 -- Requête 9:
 -- liste des opération d'un client données de type DEBIT
 select cl.clientid, nom, prenom, co.compteid, co.typecompte, tr.date_operation,  operation, 
 optionoperation, montant
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and cl.nom='Petit' and operation='DEBIT';
 
 
 -- Requête 10:
 -- total des transaction par client, par compte, par operation
 
  select cl.clientid,  co.compteid, operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 group by cl.clientid,  co.compteid, operation;

 
-- Requête 11:
 -- total des transaction par client, par compte, par operation 
 -- dont le total est supérieur à 10000
 
 select cl.clientid,  tr.compteid, operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 group by cl.clientid,  tr.compteid, operation
 having sum(montant) >10000;

 
 -- Requête 12:
-- balance des transactions par type et par date
 select  operation, date_operation, sum(montant)
 from transaction tr
 group by operation, date_operation;

-- Requête 13:
-- balance des transactions par type
 select  operation, sum(montant)
 from transaction tr
 group by operation;
 
 -- Requête 14:
 -- Balance des transactions par type pour des compte épargne 
 -- entre deux dates
 select co.typecompte,  operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid and co.compteid=tr.compteid
 and tr.date_operation 
 between to_date('25-01-2010', 'DD-MM-YYYY') and to_date('27-01-2010', 'DD-MM-YYYY')
 group by co.typecompte,  operation ;

 -- Requête 15:
 -- un connexion de jointure manque
 select co.typecompte,  operation, sum(montant)
 from client cl, compte co, transaction tr
 where cl.clientid=co.clientid 
 and tr.date_operation 
 between to_date('25-01-2010', 'DD-MM-YYYY') and to_date('27-01-2010', 'DD-MM-YYYY')
 group by co.typecompte,  operation ;

set autotrace off
set echo off
set serveroutput off
spool off


 
set TERMOUT ON