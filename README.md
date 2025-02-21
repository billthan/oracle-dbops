# DBOps (Oracle) 
<img width="623" alt="oracle" src="https://github.com/user-attachments/assets/27d25e34-d605-49a9-8841-7b2eb6274d22" />


This repository is configured to take snapshots of database object DDLs. This is to assist with the tracking database changes over time. 


# Usage

## First time Setup:

Ensure DBA directories are created:

```
-- /aux/dbops can be replaced with your directory of choice
CREATE OR REPLACE DIRECTORY DDL_TABLE_DIR AS '/aux/dbops/tables';
CREATE OR REPLACE DIRECTORY DDL_VIEW_DIR AS '/aux/dbops/views';
...
CREATE OR REPLACE DIRECTORY DDL_PACKAGE_DIR AS '/aux/dbops/packages';
CREATE OR REPLACE DIRECTORY DDL_PROCEDURE_DIR AS '/aux/dbops/procedures';
CREATE OR REPLACE DIRECTORY DDL_TRIGGER_DIR AS '/aux/dbops/triggers';
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
