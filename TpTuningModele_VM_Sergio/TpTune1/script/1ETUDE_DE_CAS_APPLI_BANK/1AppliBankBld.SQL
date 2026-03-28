/*-------------------------------------------------------------------------
Ce script permet de faire les actions suivbantes :
 1. Suppression des tables Transaction, Compte et Client si elles existent
 2. Création des tables  Client, Compte et Transaction
 3. Création d'un trigger sur la table transaction pour mettre à jour le solde d'un compte
 4. Insertion de lignes dans les tables CLIENT et COMPTE 
 5. Insertion de lignes dans la table TRANSACTION 
 6. Vérification d'indexes existants.

 Ce script est lancé depuis le fichier : 0AppliBankStart.sql situé dans le
 le même dossier.
----------------------------------------------------------------------------------
 */


spool &SCRIPTPATH\LOG\AppliBank.log

SET TERMOUT ON
PROMPT Building AppliBank demonstration tables.  Please wait.
-- Empêche l'affichage à l'écran
SET TERMOUT OFF

--set autotrace traceonly
set linesize 500
set pagesize 5000
-----------------------------------------------------------------------------------
--  1. Suppression des tables Transaction, Compte et Client si elles existent
-----------------------------------------------------------------------------------
drop table transaction cascade constraints;
drop table compte cascade constraints;
drop table client cascade constraints;

-----------------------------------------------------------------------------------
--2. Création des tables  Client, Compte et Transaction
-----------------------------------------------------------------------------------

Create table client (
	clientId	number(8) constraint pk_client_clientId  primary key,
	nom	 	varchar2(50)constraint nl_client_nom not null,
	prenom  	varchar2(50),
	codePostal	varchar2(10)constraint nl_client_codePostal not null,
	ville		varchar2(50)constraint nl_client_ville not null,
	adresse		varchar2(100)constraint nl_client_adresse not null,
	telephone  	varchar2(12)
) ;

Create table compte(
	compteId	varchar2(30) constraint pk_compte_compteId primary key,
	clientId	number(8) constraint fk_compte_clientId  references client(clientid),
	typeCompte	varchar2(30) constraint nl_compte_typeCpt not null
 		constraint chk_compte_type_cpt 	
		check(typeCompte IN('COMPTE CHEQUE' , 'COMPTE EPARGNE')),
	libelle  	varchar2(100), -- Description du compte
	solde		number(12,2) default 0 constraint nl_compte_solde not null
) ;

Create table transaction(
	transactionId	number(8) constraint pk_transaction_trId primary key,
	compteId	varchar2(30) constraint fk_trans_compteId references compte(compteid),
	operation	varchar2(15) constraint chk_trans_operation 	
		check(operation IN('DEBIT' , 'CREDIT'))
		constraint nl_trans_operation not null,
	OptionOperation varchar2(15) constraint chk_trans_option_op 	
		check(OptionOperation 
		IN('CB', 'CHEQUE', 'VIREMENT', 'RETRAIT CB', 
		'RETRAIT GUICHET', 'CDEPOT', 'CVIREMENT','CCHEQUE'))
		constraint nl_trans_opt_operation not null,
	montant	number(12,2) constraint nl_trans_montant not null,
	date_operation 	date constraint nl_trans_date_op not null,
	constraint chk_trans_opt_op_dep check(
		(operation='DEBIT'
		and optionOperation in ('CB', 'CHEQUE', 'VIREMENT', 'RETRAIT CB', 'RETRAIT GUICHET')
		)
		OR
		(operation='CREDIT'
		and optionOperation in ('CDEPOT', 'CVIREMENT','CCHEQUE')
		))
) ;

-----------------------------------------------------------------------------------
-- 3. Création d'un trigger sur la table transaction pour mettre à jour 
-- le solde d'un compte. Réduire le solde si DEBIT et augmenter le solde si CREDIT
-----------------------------------------------------------------------------------

create or replace trigger tr_transaction 
after insert or update or delete on transaction 
for each row 
declare

begin
	IF INSERTING AND :new.operation='CREDIT' THEN
		update compte 
		set solde=solde+:new.montant
		where compteid=:new.compteid ;
	ELSIF INSERTING AND :new.operation='DEBIT' THEN
		update compte 
		set solde=solde-:new.montant
		where compteid=:new.compteid ;

	END IF;
	IF DELETING OR UPDATING THEN
		update compte 
		set solde=solde-:old.montant+:new.montant
		where compteid=:old.compteid ;
	END IF;
	
end;
/

-----------------------------------------------------------------------------------
-- 4. Insertion de lignes dans les tables CLIENT et COMPTE 
-----------------------------------------------------------------------------------
@@2AppliBankInsert17000Clients.sql
commit;
@@3AppliBankInsert39000Comptes.sql
commit;

-----------------------------------------------------------------------------------
-- 5. Insertion de lignes dans la table TRANSACTION 
-----------------------------------------------------------------------------------

-- Créer un type compte pour récupérer plus loins les informations sur chaque
-- compte.
Create or replace type compte_t as object(
	compteId	varchar2(30),
	clientId	number(8),
	typeCompte	varchar2(30),
	libelle  	varchar2(100), 
	solde		number(12,2)
)
/


-- créer un type collection de comptes.
create or replace type ListCompte_t as table of compte_t
/

-- donner une allure objet à la table relationnelle compte.
create or replace view v_compte of compte_t
with object identifier (compteId)
as select * from compte;

-- Supprimer tous les comptes s'ils existent déjà
truncate table transaction;

-- create sequence id transaction
drop sequence seq_trans;
create sequence seq_trans
start with 1;

-- Insertion des transactions dans la table TRANSACTION
--set serveroutput on
declare
LC ListCompte_t;
dateop 	date :=sysdate - 12;

begin
select cast (collect(value(c)) as ListCompte_t) into LC 
from v_compte c ;

for i in LC.first ..LC.last
	loop
	-- Opération de CREDIT de type 'CDEPOT', 'CVIREMENT','CCHEQUE'
	
	
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid, 'CREDIT', 'CDEPOT', round(dbms_random.value(5000, 100000)),dateop );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid, 'CREDIT', 'CCHEQUE', round(dbms_random.value(5000, 10000)),dateop+1 );

	-- Operation de DEBIT de type 'CB', 'CHEQUE', 'VIREMENT', 'RETRAIT CB',
	-- 'RETRAIT GUICHET'
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid, 'DEBIT', 'CB', round(dbms_random.value(15, 3000)),dateop+2 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'CB', round(dbms_random.value(15, 3000)),dateop+3 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'RETRAIT CB', round(dbms_random.value(20, 800)),dateop+4 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'RETRAIT CB', round(dbms_random.value(20, 800)),dateop+5 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'CHEQUE', round(dbms_random.value(20, 1500)),dateop+6 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'CHEQUE', round(dbms_random.value(20, 1500)),dateop+7 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'CB', round(dbms_random.value(20, 800)),dateop+8 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'CHEQUE', round(dbms_random.value(20, 1000)),dateop+9 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'RETRAIT CB', round(dbms_random.value(20, 800)),dateop+10 );
	INSERT INTO transaction VALUES(seq_trans.nextval, 
	LC(i).compteid,  'DEBIT', 'RETRAIT CB', round(dbms_random.value(20, 800)),dateop+11 );

	end loop;
	commit;
end;
/

-- Vérification de la structure des tables
/*
BANK , orcl >desc transaction
 Nom                                       NULL ?   Type
 ----------------------------------------- -------- -----------------------
 TRANSACTIONID                             NOT NULL NUMBER(8)
 COMPTEID                                           VARCHAR2(30)
 OPERATION                                 NOT NULL VARCHAR2(15)
 OPTIONOPERATION                           NOT NULL VARCHAR2(15)
 MONTANT                                   NOT NULL NUMBER(12,2)
 DATE_OPERATION                            NOT NULL DATE

BANK , orcl >desc compte
 Nom                                       NULL ?   Type
 ----------------------------------------- -------- -----------------
 COMPTEID                                  NOT NULL VARCHAR2(30)
 CLIENTID                                           NUMBER(8)
 TYPECOMPTE                                NOT NULL VARCHAR2(30)
 LIBELLE                                            VARCHAR2(100)
 SOLDE                                              NUMBER(12,2)

 
 BANK , orcl >desc client
 Nom                                       NULL ?   Type
 ----------------------------------------- -------- ------------------
 CLIENTID                                  NOT NULL NUMBER(8)
 NOM                                       NOT NULL VARCHAR2(50)
 PRENOM                                             VARCHAR2(50)
 CODEPOSTAL                                NOT NULL VARCHAR2(10)
 VILLE                                     NOT NULL VARCHAR2(50)
 ADRESSE                                   NOT NULL VARCHAR2(100)
 TELEPHONE                                          VARCHAR2(12)
*/
 -- vérification de la présence d'index
 
set linesize 200
col column_name format a20
col index_name format A30
col table_name format A12
select table_name, column_name, index_name 
from user_ind_columns
where table_name in ('CLIENT',  'COMPTE',  'TRANSACTION')
order by table_name, index_name, column_name;

/*
 TABLE_NAME                     COLUMN_NAME          INDEX_NAME
------------------------------ -------------------- ---------------------------
CLIENT                         CLIENTID             PK_CLIENT_CLIENTID
COMPTE                         COMPTEID             PK_COMPTE_COMPTEID
TRANSACTION                    TRANSACTIONID        PK_TRANSACTION_TRID

*/
commit;
set linesize 80
--set autotrace off
SET TERMOUT ON
spool off