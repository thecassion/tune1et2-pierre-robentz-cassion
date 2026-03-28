spool &SCRIPTPATH\LOG\AppliBankCreateIndexes.log
set echo on
set serveroutput on
SET TERMOUT ON
PROMPT Creating AppliBank Indexes.  Please wait.
-- Empêche l'affichage à l'écran
SET TERMOUT OFF

-- Proposer des indexes pour chacune des requêtes contenues dans le 
-- Fichier : 

-- Index sur la requête 1 : 
drop index idx_compte_clientid;
create index idx_compte_clientid on compte (clientid)
/

-- Index sur la requête 2 : 
--


-- Index sur la requête 3 : 
drop index idx_client_nom;
create index idx_client_nom on client (nom)
/



-- Index sur la requête 4 : 

drop index idx_compte_solde;
create index idx_compte_solde on compte (solde)
/

-- Index sur la requête 5 : 

drop index idx_transaction_compteid
/
create index idx_transaction_compteid on transaction(compteid)
/

-- Index sur la requête 6 : 



-- Index sur la requête 7 : 



-- Index sur la requête 8 : 
drop index idx_transaction_date_operation
/
create index idx_transaction_date_operation on transaction(date_operation)
/


-- Index sur la requête 9 : 
drop index idx_transaction_operation;
create index idx_transaction_operation on transaction(operation)
/


-- Index sur la requête 10 : 



-- Index sur la requête 11 : 



-- Index sur la requête 12 : 



-- Index sur la requête 13 : 



-- Index sur la requête 14 : 



-- Index sur la requête 15 : 

