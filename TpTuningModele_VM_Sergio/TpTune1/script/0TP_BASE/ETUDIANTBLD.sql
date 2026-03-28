	DROP TABLE ETUDIANT;
	CREATE TABLE ETUDIANT(-- pourquoi PCTFREE est –il mis à 0  ?
	ETU# NUMBER (10) constraint pk_etu primary key,
	NOM	VARCHAR2(30),
	CV	VARCHAR2(1000)) pctfree 0 tablespace USERS;	
	-- Créer une séquence 
	DROP SEQUENCE Seq_ETU_NUMERO;
	CREATE SEQUENCE Seq_ETU_NUMERO start with 1;
	-- Array de 20 noms
	DROP TYPE TabENoms_T;
	CREATE OR REPLACE TYPE TabENoms_T 
	as Varray(131) of varchar2(20)
	/
	DECLARE
		CV1	ETUDIANT.CV%TYPE:='UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN,  UN CV PLEIN, UN CV PLEIN, UN CV PLEIN,  UN CV PLEIN, UN CV PLEIN, UN CV PLEIN,  UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN, UN CV PLEIN';
	lesNoms	TabENoms_T:= TabENoms_T('Dupont', 'Durand', 'Foudil', 'Foudelle', 
	'Akim', 'Bleck', 'Zembla', 'Tintin', 'Milou', 'Mopolo', 'Malik', 
	'Amidou', 'Mamadou', 'Mariama', 'Marine', 'Mouloud', 
	'Chang', 'Li', 'Bruce', 'Balak','Martin','Bernard','Dubois','Thomas','Robert','Richard',
	'Petit', 'Durand', 'Leroy', 'Moreau', 'Simon', 'Laurent', 'Lefebvre', 'Michel',
	'Garcia', 'David', 'Bertrand', 'Roux', 'Vincent', 'Fournier', 'Morel', 'Girard', 'Andre',
	'Lefevre', 'Mercier', 'Dupont', 'Lambert', 'Bonnet', 'Francois', 'Martinez', 'Legrand',
	'Garnier', 'Faure', 'Rousseau', 'Blanc', 'Guerin', 'Muller', 'Henry', 'Roussel',
	'Nicolas', 'Perrin', 'Morin', 'Mathieu', 'Clement', 'Gauthier', 'Dumont', 'Lopez',
	'Fontaine', 'Chevalier', 'Robin', 'Masson', 'Sanchez', 'Gerard', 'Nguyen', 'Boyer',
	'Denis', 'Lemaire', 'Duval', 'Joly', 'Gautier', 'Julien', 'Benoit', 'Paris', 'Maillard',
	'Marchal', 'Aubry', 'Vasseur', 'Le roux', 'Renault', 'Jacquet', 'Collet', 'Prevost',
	'Poirier', 'Charpentier', 'Royer', 'Huet', 'Baron', 'Dupuy', 'Pons', 'Paul',
	'Laine', 'Carre', 'Breton', 'Remy', 'Schneider', 'Perrot', 'Guyot', 'Barre',
	'Marty', 'Cousin', 'Roger', 'Roche', 'Roy', 'Noel', 'Meyer', 'Lucas', 'Meunier',
	'Jean', 'Perez', 'Marchand', 'Dufour', 'Blanchard', 'Marie', 'Barbier', 'Brun',
	'Dumas', 'Brunet', 'Schmitt', 'Leroux','Colin','Fernandez');
	j		number:=1;
	BEGIN
	For i In 1 .. 100000
	loop
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la table l'ARRAY
	j:=1;
	END IF;
	 INSERT INTO ETUDIANT
	VALUES (seq_etu_numero.nextval,lesNoms(j), cv1);
	j:=j+1;	-- incrémenter j
	End loop;
	COMMIT;
	END;
	/