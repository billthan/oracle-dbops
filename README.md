# DBOps (Oracle) 
<img width="623" alt="oracle" src="https://github.com/user-attachments/assets/27d25e34-d605-49a9-8841-7b2eb6274d22" />


This repository is configured to take snapshots of database object DDLs. This is to assist with the tracking database changes over time. 


# Usage

## Compatibility

The exporter supports Oracle Database 11gR2 and later, including 12c, 18c, 19c, 21c, and 23ai. It uses `DBMS_METADATA`, `DBMS_LOB`, `UTL_FILE`, and `DBMS_UTILITY`, which are available across these releases. Each export summary records the detected database version and compatibility setting.

## One-command deployment

Install an Oracle client with SQL*Plus on a host that can connect as a DBA user. The export directory must exist on the **database server** and be writable by the Oracle database process.

```bash
./create_dirs.sh /aux/dbops
./deploy.sh 'user/password@service' /aux/dbops
```

`deploy.sh` creates the required Oracle directory objects and runs the exporter. Set `SQLPLUS_BIN` when `sqlplus` is not on `PATH`. The connection account needs privileges to create directory objects, read `DBA_*` views, execute `DBMS_METADATA`, and write through the created directories.

## Manual setup

Ensure DBA directories are created:

```
-- /aux/dbops can be replaced with your directory of choice
CREATE OR REPLACE DIRECTORY DDL_TABLE_DIR AS '/aux/dbops/tables';
CREATE OR REPLACE DIRECTORY DDL_VIEW_DIR AS '/aux/dbops/views';
...
CREATE OR REPLACE DIRECTORY DDL_PACKAGE_DIR AS '/aux/dbops/packages';
CREATE OR REPLACE DIRECTORY DDL_PROCEDURE_DIR AS '/aux/dbops/procedures';
CREATE OR REPLACE DIRECTORY DDL_TRIGGER_DIR AS '/aux/dbops/triggers';
CREATE OR REPLACE DIRECTORY DDL_INDEX_DIR AS '/aux/dbops/indexes';
CREATE OR REPLACE DIRECTORY DDL_DIR AS '/aux/dbops/logs';
```

## Create the folder structure

```
./create_dirs.sh
```


## Clean any previous runs

```
./rm_sql_clean.sh
```

## Execute

To run DDL export, execute `EXPORT_DDL_DRIVER.sql` in Oracle as `dba` 


# Error handling

Errors are output to `error_log.txt`

# Contributors

* Bill Than
* [Nathan Ackerson](https://www.linkedin.com/in/nathan-ackerson-66aa68197)
* [Joshua Wry](https://www.linkedin.com/in/jw1999/)
