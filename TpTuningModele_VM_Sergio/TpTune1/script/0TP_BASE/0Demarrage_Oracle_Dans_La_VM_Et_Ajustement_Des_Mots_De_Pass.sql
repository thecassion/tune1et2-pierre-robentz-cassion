# L''objectifs des manipulations qui suivent est de s''assurer que oracle fonctionne
# normalement.

# s''assurer que que VM vagrant a été lancée avec la commande vagrant ssh

# Ouvrir un CMD se déplacer dans la racine vagrant et ouvrir un shell dans la VM

cd C:\Logiciels\19VM_SERGIO\vagrant-projects\OracleDatabase\21.3.0

vagrant ssh

# Lancer la base oracle en faisant ce qui suit

sudo -su oracle

# ne entre de password
sqlplus sys as sysdba

[oracle@oracle-21c-vagrant vagrant]$ sqlplus sys as sysdba

SQL*Plus: Release 21.0.0.0.0 - Production on Thu Mar 14 17:39:04 2024
Version 21.3.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.

Enter password:

Connected to:
Oracle Database 21c Enterprise Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

Enter password:
Connected to an idle instance.

SQL>

# Si vous avez le message suivant : Connected to an idle instance.
# votre base n''est pas démarré
# démarré là comme suit

sql> startup

ORACLE instance started.

Total System Global Area 1207957744 bytes
Fixed Size                  9685232 bytes
Variable Size             603979776 bytes
Database Buffers          587202560 bytes
Redo Buffers                7090176 bytes
Database mounted.
Database opened.



# vérifier la présence des pluggble databse
SQL>show pdbs

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         3 ORCLPDB1                       READ WRITE NO
		 
# La pluggable ORCLPDB1 doit être en mode "READ WRITE"
# si ce n''est pas le cas faire ce qui suit
SQL>alter pluggable database orclpdb1 open;
SQL>alter pluggable database orclpdb1 save state;

# Modifier les mots de passes des comptes Oracle : SYS et SYSTEM

sql> alter user sys identified by Welcome1;
sql> alter user system identified by Welcome1;

# Se connecter dans la pluggable ORCLPDB1 afin de modifier le mot de passe
# du compte administrateur PDBADMIN de la PDB et lui donner les droits

sql> connect system/Welcome1@orclpdb1

SQL> connect system/Welcome1@orclpdb1
ERROR:
ORA-12541: TNS:no listener


Warning: You are no longer connected to ORACLE.
# Si vous avez le message : ORA-12541: TNS:no listener
# Votre Listener ne tourne pas.
# Activer le comme suit:

# Ouvrir un cmd

cd C:\Logiciels\19VM_SERGIO\vagrant-projects\OracleDatabase\21.3.0

vagrant ssh

# Lancer le listener en faisant ce qui suit

sudo -su oracle


[oracle@oracle-21c-vagrant vagrant]$ lsnrctl

LSNRCTL for Linux: Version 21.0.0.0.0 - Production on 14-MAR-2024 18:01:44

Copyright (c) 1991, 2021, Oracle.  All rights reserved.

Welcome to LSNRCTL, type "help" for information.

# Vérification du status du listener
LSNRCTL> status
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1)))
TNS-12541: TNS:no listener
 TNS-12560: TNS:protocol adapter error
  TNS-00511: No listener
   Linux Error: 111: Connection refused
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521)))
TNS-12541: TNS:no listener
 TNS-12560: TNS:protocol adapter error
  TNS-00511: No listener
   Linux Error: 111: Connection refused
LSNRCTL>

# Arret du listener
LSNRCTL> stop
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1)))
TNS-12541: TNS:no listener
 TNS-12560: TNS:protocol adapter error
  TNS-00511: No listener
   Linux Error: 111: Connection refused
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521)))
TNS-12541: TNS:no listener
 TNS-12560: TNS:protocol adapter error
  TNS-00511: No listener
   Linux Error: 111: Connection refused
   
# démarrage du listener   
LSNRCTL> start
Starting /opt/oracle/product/21c/dbhome_1/bin/tnslsnr: please wait...

TNSLSNR for Linux: Version 21.0.0.0.0 - Production
System parameter file is /opt/oracle/homes/OraDB21Home1/network/admin/listener.ora
Log messages written to /opt/oracle/diag/tnslsnr/oracle-21c-vagrant/listener/alert/log.xml
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 21.0.0.0.0 - Production
Start Date                14-MAR-2024 18:02:53
Uptime                    0 days 0 hr. 0 min. 0 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /opt/oracle/homes/OraDB21Home1/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/oracle-21c-vagrant/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))
The listener supports no services
The command completed successfully
LSNRCTL>


# Attendre 2 minutes puis reverifier le status
LSNRCTL> status
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 21.0.0.0.0 - Production
Start Date                14-MAR-2024 18:02:53
Uptime                    0 days 0 hr. 0 min. 51 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /opt/oracle/homes/OraDB21Home1/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/oracle-21c-vagrant/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oracle-21c-vagrant)(PORT=5500))(Security=(my_wallet_directory=/opt/oracle/admin/ORCLCDB/xdb_wallet))(Presentation=HTTP)(Session=RAW))
Services Summary...
Service "ORCLCDB" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "ORCLCDBXDB" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "eed6d9acdc237a0be0530101007f32a4" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "orclpdb1" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
The command completed successfully
LSNRCTL>

# Si vous voyez ci-dessus ce qui suit c''est que le listener écoute votre cdb et votre pluggable
Service "ORCLCDB" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "orclpdb1" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
  
  
#Tentez à nouveau de vous connecter sur votre pluggable  
# Se connecter dans la pluggable ORCLPDB1 afin de modifier le mot de passe
# du compte administrateur PDBADMIN de la PDB et lui donner les droits
# dans le cmd ou sqlplus avait été lancé
sql> connect system/Welcome1@orclcdb
sql> connect system/Welcome1@orclpdb1
Connected.
SQL> alter user pdbadmin identified by Welcome1;
sql> grant dba to pdbadmin;
sql> revoke unlimited tablespace from pdbadmin;
Sql> alter user pdbadmin 
default tablespace users
temporary tablespace temp
quota unlimited on users;

alter user pdbadmin identified by Welcome1;
grant dba to pdbadmin;
revoke unlimited tablespace from pdbadmin;
alter user pdbadmin 
default tablespace users
temporary tablespace temp
quota unlimited on users;


User altered.

# Vous pouvez maintenant ouvrir le fichier pour commencer les exercices Tune1
1ModeleCorrigeExercicesTune_Local_VM_SERGO.sql

# 
 