# DBOps (Oracle)
<img width="623" alt="oracle" src="https://github.com/user-attachments/assets/27d25e34-d605-49a9-8841-7b2eb6274d22" />


This repository is configured to take snapshots of database object DDLs. This is to assist with the tracking database changes over time.

The export writes **one `.sql` file per database object**, grouped into per-object-type folders on the database server. Those files can then be committed to source control, so schema changes become reviewable in a pull request just like application code.


# How it works

`EXPORT_DDL_DRIVER.sql` is a single anonymous PL/SQL block that:

1. Opens `error_log.txt` in the `DDL_DIR` directory.
2. Sets `DBMS_METADATA` session transforms so the generated DDL is environment neutral (see [DDL formatting](#ddl-formatting)).
3. Loops over every schema in `ALL_USERS`, skipping Oracle-maintained schemas and anything matching `%APEX%`.
4. For each schema, includes the `process_*.sql` files with SQL\*Plus `@` includes. These are **not** standalone scripts — they are text fragments spliced into the driver's loop and rely on the variables the driver declares.
5. Writes `summary.txt` to `DDL_DIR` with the run details.

Because the `process_*.sql` files are pulled in with `@`, the driver **must** be run from the directory containing them, using a client that supports SQL\*Plus include syntax (SQL\*Plus or SQLcl).

> **Files are written by the database, not the client.** `UTL_FILE` writes to the paths behind the Oracle directory objects, which resolve on the **database server** filesystem. After a run, collect the files from the server (or from a share mounted by the server) before committing them.


# Prerequisites

| Requirement | Detail |
| --- | --- |
| Privileges | A DBA-level account. The scripts read `DBA_TABLES`, `DBA_VIEWS`, `DBA_INDEXES`, `DBA_TRIGGERS`, `DBA_OBJECTS`, `DBA_ROLES`, `DBA_ROLE_PRIVS`, `DBA_SYS_PRIVS` and `DBA_TAB_PRIVS`. |
| Packages | `EXECUTE` on `DBMS_METADATA`, `DBMS_LOB` and `UTL_FILE`. |
| Client | SQL\*Plus or SQLcl (required for the `@` includes). |
| Server access | The Oracle OS user must be able to write to the target directories. |


# Usage

## First time setup

### 1. Create the folder structure

Run on the **database server**, as an OS user that can create the paths (`/aux` and `/exp1` are the defaults; edit the script to use directories of your choice):

```
./create_dirs.sh
```

The directories must be writable by the OS user that owns the Oracle processes.

### 2. Create the Oracle directory objects

Each directory object below is referenced by name from the scripts, so the names must match exactly. Only the paths should be changed if you edited `create_dirs.sh`.

```
-- /aux/dbops can be replaced with your directory of choice
CREATE OR REPLACE DIRECTORY DDL_TABLE_DIR     AS '/aux/dbops/tables';
CREATE OR REPLACE DIRECTORY DDL_VIEW_DIR      AS '/aux/dbops/views';
CREATE OR REPLACE DIRECTORY DDL_PACKAGE_DIR   AS '/aux/dbops/packages';
CREATE OR REPLACE DIRECTORY DDL_PROCEDURE_DIR AS '/aux/dbops/procedures';
CREATE OR REPLACE DIRECTORY DDL_TRIGGER_DIR   AS '/aux/dbops/triggers';
CREATE OR REPLACE DIRECTORY DDL_INDEX_DIR     AS '/aux/dbops/indexes';
CREATE OR REPLACE DIRECTORY DDL_DIR           AS '/exp1/ddl_dir2';

-- Only needed for the optional grant/role exports
CREATE OR REPLACE DIRECTORY GRANT_DIR         AS '/aux/dbops/grants';
CREATE OR REPLACE DIRECTORY ROLE_DIR          AS '/aux/dbops/roles';
```

| Directory object | Written by | Contents |
| --- | --- | --- |
| `DDL_TABLE_DIR` | `process_tables.sql` | One file per table |
| `DDL_VIEW_DIR` | `process_views.sql` | One file per view |
| `DDL_PACKAGE_DIR` | `process_packages.sql` | One file per package spec **and** one per package body |
| `DDL_PROCEDURE_DIR` | `process_procedures_and_functions.sql` | One file per procedure **and** per function |
| `DDL_TRIGGER_DIR` | `process_triggers.sql` | One file per trigger |
| `DDL_INDEX_DIR` | `process_indexes.sql` | One file per index |
| `DDL_DIR` | `EXPORT_DDL_DRIVER.sql` | `summary.txt` and `error_log.txt` |
| `GRANT_DIR` | `export_grants.sql`, `export_roles.sql` | `all_grants_roles.sql`, `all_grants_sys_privs.sql`, `all_grants_tab_privs.sql`, `grant_roles.sql` |
| `ROLE_DIR` | `export_roles.sql` | `create_roles.sql` |

## Clean any previous runs

`rm_sql_clean.sh` deletes `*.sql` using **relative** paths, so run it from the parent of the object folders (`/aux/dbops` with the default layout), not from this repository:

```
cd /aux/dbops
./rm_sql_clean.sh
```

## Execute

To run DDL export, execute `EXPORT_DDL_DRIVER.sql` in Oracle as `dba`, from the directory holding the `process_*.sql` files:

```
cd /path/to/oracle-dbops
sqlplus / as sysdba @EXPORT_DDL_DRIVER.sql
```

## Optional: grants and roles

These are standalone blocks and are **not** called by the driver. Run them separately when a permissions snapshot is needed:

```
sqlplus / as sysdba @export_roles.sql
sqlplus / as sysdba @export_grants.sql
```


# Output

## File naming

Every exported object is written as `<SCHEMA>_<OBJECT_TYPE>_<OBJECT_NAME>.sql`, with spaces replaced by underscores. For example:

```
tables/HR_TABLE_EMPLOYEES.sql
views/HR_VIEW_EMP_DETAILS_VIEW.sql
packages/HR_PACKAGE_SPEC_EMP_MGMT.sql
packages/HR_PACKAGE_BODY_EMP_MGMT.sql
procedures/HR_PROCEDURE_ADD_JOB_HISTORY.sql
procedures/HR_FUNCTION_GET_SALARY.sql
triggers/HR_TRIGGER_UPDATE_JOB_HISTORY.sql
indexes/HR_INDEX_EMP_NAME_IX.sql
```

Because the file name is deterministic, re-running the export overwrites the previous snapshot of an object in place, which keeps diffs clean between runs.

## DDL formatting

The driver sets these `DBMS_METADATA` transforms before exporting, so that DDL from different environments is comparable:

| Transform | Value | Effect |
| --- | --- | --- |
| `STORAGE` | `FALSE` | Omits storage clauses |
| `TABLESPACE` | `FALSE` | Omits tablespace names |
| `SEGMENT_ATTRIBUTES` | `FALSE` | Omits segment attributes |
| `REF_CONSTRAINTS` | `FALSE` | **Omits referential (foreign key) constraints from table DDL** |
| `SQLTERMINATOR` | `TRUE` | Appends a statement terminator |
| `PRETTY` | `TRUE` | Formats the output for readability |

The suppressed attributes are intentionally environment specific. Note that the exported table DDL is therefore **not** a complete rebuild script on its own — foreign keys are not included.

## Summary file

`summary.txt` is written to `DDL_DIR` at the end of a successful run:

```
Database user: <user that ran the export>
Database name: <SYS_CONTEXT('USERENV','DB_NAME')>
Time run: YYYY-MM-DD HH24:MI:SS
Number of files generated: <count>
```


# Error handling

Errors are output to `error_log.txt` (in `DDL_DIR`, alongside `summary.txt`). The file is truncated at the start of every run and is excluded from git by `.gitignore`.

Failures are handled per object, so a single bad object does not abort the export:

* **DDL retrieval failure** — logged, and the object is skipped.
* **File write failure** — logged, the file handle is closed, and processing continues with the next object.
* **Unexpected error on an object** — logged, and processing continues with the next object.
* **Unexpected error in the main block** — logged, the log file is closed, and the error is re-raised so the run visibly fails.

Because errors are logged rather than raised, **check `error_log.txt` after every run**; a run can complete "successfully" while silently skipping objects.

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| `SP2-0310: unable to open file "process_tables.sql"` | The driver was not run from the directory containing the `process_*.sql` files. |
| `ORA-06564: object DDL_INDEX_DIR does not exist` | A directory object from the setup step was not created, or the name does not match. |
| `ORA-29280: invalid directory path` | The directory object points at an OS path that does not exist — run `create_dirs.sh` on the database server. |
| `ORA-29283: invalid file operation` | The Oracle OS user cannot write to the target path; check ownership and permissions. |
| `ORA-01031: insufficient privileges` | The account lacks access to the `DBA_*` views or to `DBMS_METADATA` / `UTL_FILE`. |
| `ORA-31603: object not found` in `error_log.txt` | The object was dropped between the catalog query and the DDL fetch, or the account cannot see it. |
| No files on the client machine | Expected — output is written on the database server. |


# Script reference

| File | Type | Purpose |
| --- | --- | --- |
| `EXPORT_DDL_DRIVER.sql` | Driver | Entry point. Declares shared variables, sets transforms, loops over schemas, includes the `process_*.sql` fragments, writes `summary.txt`. |
| `process_tables.sql` | Include | Exports `TABLE` DDL for the current schema. |
| `process_views.sql` | Include | Exports `VIEW` DDL for the current schema. |
| `process_procedures_and_functions.sql` | Include | Exports `PROCEDURE` and `FUNCTION` DDL for the current schema. |
| `process_packages.sql` | Include | Exports `PACKAGE_SPEC` and `PACKAGE_BODY` DDL for the current schema. |
| `process_triggers.sql` | Include | Exports `TRIGGER` DDL for the current schema. |
| `process_indexes.sql` | Include | Exports `INDEX` DDL for the current schema. |
| `export_grants.sql` | Standalone | Generates `GRANT` statements for roles, system privileges and object privileges. |
| `export_roles.sql` | Standalone | Generates `CREATE ROLE` statements and the role grants. |
| `create_dirs.sh` | Shell | Creates the OS folder structure on the database server. |
| `rm_sql_clean.sh` | Shell | Deletes `*.sql` from the object folders before a fresh run. |

The `process_*.sql` files cannot be run on their own. They are fragments that depend on variables declared by the driver (`v_schema_name`, `v_object_name`, `v_ddl_clob`, `v_file`, `v_file_name`, `v_error_log`, `v_error_message`, `v_file_count` and the directory variables), and each file's header comment documents exactly what it expects.


# DevOps process

1. At the end of a sprint, run the export.
2. Review `error_log.txt` and `summary.txt`.
3. Create a new branch and copy in the script output.
4. Commit and open a PR once UAT testing is complete, then merge to main.


# Known limitations

* The driver exports tables, views, procedures, functions, packages, triggers and indexes only. `create_dirs.sh` also creates folders for sequences, synonyms, materialized views, types, database links, users, roles, profiles, privileges, contexts, jobs and libraries — these are placeholders and are not populated by the current scripts.
* Functions are written to the procedures directory (`DDL_PROCEDURE_DIR`), not to `functions/`.
* Foreign key constraints are excluded from table DDL (`REF_CONSTRAINTS` is `FALSE`).
* `rm_sql_clean.sh` does not clean `grants/`, nor the `summary.txt` / `error_log.txt` in `DDL_DIR`.
* `export_grants.sql` and `export_roles.sql` are not wired into the driver and must be run manually.


# Contributors

* Bill Than
* [Nathan Ackerson](https://www.linkedin.com/in/nathan-ackerson-66aa68197)
* [Joshua Wry](https://www.linkedin.com/in/jw1999/)


# License

Released under the [MIT License](LICENSE).
