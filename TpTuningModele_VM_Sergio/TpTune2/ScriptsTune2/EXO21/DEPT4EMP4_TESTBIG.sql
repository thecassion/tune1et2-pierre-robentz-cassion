alter session set nls_date_format='DD-MON-YYYY';
alter session set nls_language=american;

drop table testbig.dept4 cascade constraint;
drop table testbig.emp4 cascade constraint;

DROP TYPE testbig.TabNoms4_T;
CREATE OR REPLACE TYPE testbig.TabNoms4_T 
as Varray(20) of varchar2(20)
/


CREATE TABLE testbig.dept4
       (DEPTNO NUMBER(2),
        DNAME VARCHAR2(14),
        LOC VARCHAR2(13) );

CREATE TABLE testbig.emp4
       (EMPNO NUMBER(8) NOT NULL,
        ENAME VARCHAR2(50),
        JOB VARCHAR2(9),
        MGR NUMBER(4),
        HIREDATE DATE,
        SAL NUMBER(7,2),
        COMM NUMBER(7,2),
        DEPTNO NUMBER(2));

alter table testbig.dept4 add constraint pk_dept4
primary key (deptno);
alter table testbig.emp4 add constraint pk_emp4
primary key (empno);
alter table testbig.emp4 add constraint fk_emp4_deptno
foreign key (deptno) references testbig.dept4(deptno);

drop sequence testbig.seq4_empno;
drop sequence testbig.seq_ename;
create sequence testbig.seq4_empno start with 7935;
create sequence testbig.seq_ename start with 1;

-- insertion dans la table des départements
INSERT INTO testbig.dept4 VALUES
        (10,'ACCOUNTING','NEW YORK');
INSERT INTO testbig.dept4 VALUES (20,'RESEARCH','DALLAS');
INSERT INTO testbig.dept4 VALUES
        (30,'SALES','CHICAGO');
INSERT INTO testbig.dept4 VALUES
        (40,'OPERATIONS','BOSTON');


-- Insertion dans la table des employés
INSERT INTO testbig.emp4 VALUES
        (7369,'SMITH','CLERK',7902,'17-DEC-1980',800,NULL,20);
INSERT INTO testbig.emp4 VALUES
        (7499,'ALLEN','SALESMAN',7698,'20-FEB-1981',1600,300,30);
INSERT INTO testbig.emp4 VALUES
        (7521,'WARD','SALESMAN',7698,'22-FEB-1981',1250,500,30);
INSERT INTO testbig.emp4 VALUES
        (7566,'JONES','MANAGER',7839,'2-APR-1981',2975,NULL,20);
INSERT INTO testbig.emp4 VALUES
        (7654,'MARTIN','SALESMAN',7698,'28-SEP-1981',1250,1400,30);
INSERT INTO testbig.emp4 VALUES
        (7698,'BLAKE','MANAGER',7839,'1-MAY-1981',2850,NULL,30);
INSERT INTO testbig.emp4 VALUES
        (7782,'CLARK','MANAGER',7839,'9-JUN-1981',2450,NULL,10);
INSERT INTO testbig.emp4 VALUES
        (7788,'SCOTT','ANALYST',7566,'09-DEC-1982',3000,NULL,20);
INSERT INTO testbig.emp4 VALUES
        (7839,'KING','PRESIDENT',NULL,'17-NOV-1981',5000,NULL,10);
INSERT INTO testbig.emp4 VALUES
        (7844,'TURNER','SALESMAN',7698,'8-SEP-1981',1500,0,30);
INSERT INTO testbig.emp4 VALUES
        (7876,'ADAMS','CLERK',7788,'12-JAN-1983',1100,NULL,20);
INSERT INTO testbig.emp4 VALUES
        (7900,'JAMES','CLERK',7698,'3-DEC-1981',950,NULL,30);
INSERT INTO testbig.emp4 VALUES
        (7902,'FORD','ANALYST',7566,'3-DEC-1981',3000,NULL,20);
INSERT INTO testbig.emp4 VALUES
        (7934,'MILLER','CLERK',7782,'23-JAN-1982',1300,NULL,10);


-- Insertion d'employés supplémentaires
DECLARE
	lesNoms	testbig.TabNoms4_t:= testbig.TabNoms4_t('Dupont', 'Durand', 'Foudil', 'Foudelle', 'Akim', 'Bleck', 'Zembla', 'Tintin', 'Milou', 'Mopolo', 'Malik', 'Amidou', 'Mamadou', 'Mariama', 'Marine', 'Mouloud', 'Chang', 'Li', 'Bruce', 'Balak');
	j		number:=1;
BEGIN
	For i In 1 .. 100000
	loop
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
	
	INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'CLERK',7902,'17-DEC-1980',800,NULL,20);
	j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'20-FEB-1981',1600,300,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'22-FEB-1981',1250,500,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'2-APR-1981',2975,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'28-SEP-1981',1250,1400,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'1-MAY-1981',2850,NULL,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'MANAGER',7839,'9-JUN-1981',2450,NULL,10);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'ANALYST',7566,'09-DEC-1982',3000,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'SALESMAN',7698,'8-SEP-1981',1500,0,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'CLERK',7788,'12-JAN-1983',1100,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'CLERK',7698,'3-DEC-1981',950,NULL,30);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'ANALYST',7566,'3-DEC-1981',3000,NULL,20);
j:=j+1;
	If j>lesNoms.limit THEN -- j ne doit pas dépasser la taille de l'ARRAY
	j:=1;
	END IF;		
INSERT INTO testbig.emp4 VALUES
        (TESTBIG.seq4_empno.nextval,lesNoms(j),'CLERK',7782,'23-JAN-1982',1300,NULL,10);

	j:=j+1;	-- incrémenter j
	End loop;
	COMMIT;
END;
/


