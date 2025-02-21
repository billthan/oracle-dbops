/*
EXPORT_DDL.sql

Description:
   Exports DDL of database objects for DevOps tracking purposes
   Each object is put into a folder structure

First time Setup:

   Ensure DBA directories are created:

   Sample:
   
   /aux/dbops/ - can be swapped
   
   CREATE OR REPLACE DIRECTORY DDL_TABLE_DIR AS '/aux/dbops/tables';
   CREATE OR REPLACE DIRECTORY DDL_VIEW_DIR AS '/aux/dbops/views';
   CREATE OR REPLACE DIRECTORY DDL_PACKAGE_DIR AS '/aux/dbops/packages';
   CREATE OR REPLACE DIRECTORY DDL_PROCEDURE_DIR AS '/aux/dbops/procedures';
   CREATE OR REPLACE DIRECTORY DDL_TRIGGER_DIR AS '/aux/dbops/triggers';
   CREATE OR REPLACE DIRECTORY DDL_DIR AS '/exp1/ddl_dir2';


For DevOps process:

   At end of sprint - execute EXPORT_DDL.sql 
   Create new branch on DevOps and copy contents of the script output
   Create PR once UAT testing is complete and merge to main

*/

DECLARE
   v_table_dir     VARCHAR2(50) := 'DDL_TABLE_DIR';     -- Directory for tables
   v_view_dir      VARCHAR2(50) := 'DDL_VIEW_DIR';      -- Directory for views
   v_package_dir   VARCHAR2(50) := 'DDL_PACKAGE_DIR';   -- Directory for packages
   v_procedure_dir VARCHAR2(50) := 'DDL_PROCEDURE_DIR'; -- Directory for procedures and functions
   v_trigger_dir   VARCHAR2(50) := 'DDL_TRIGGER_DIR';   -- Directory for triggers
   v_version_dir   VARCHAR2(50) := 'DDL_DIR';           -- Directory for the summary and error log files
   v_index_dir     VARCHAR2(50) := 'DDL_INDEX_DIR';     -- Directory for the indexes

   v_schema_name   VARCHAR2(50);
   v_file          UTL_FILE.file_type;
   v_error_log     UTL_FILE.file_type;
   v_object_type   VARCHAR2(50);
   v_object_name   VARCHAR2(100);
   v_ddl_clob      CLOB;
   v_file_name     VARCHAR2(255);
   v_file_count    NUMBER := 0; -- Counter for number of files generated
   v_username      VARCHAR2(50);
   v_dbname        VARCHAR2(50);
   v_run_date      DATE := SYSDATE;
   v_error_message VARCHAR2(4000);
BEGIN
   -- Open the error log file
   v_error_log := UTL_FILE.FOPEN(v_version_dir, 'error_log.txt', 'w');

   -- Set up DBMS_METADATA session transformations
   DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform,'STORAGE',FALSE);
   DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform,'TABLESPACE',FALSE);
   DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform,'SEGMENT_ATTRIBUTES',FALSE);
   DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform,'REF_CONSTRAINTS',FALSE);
   DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform,'SQLTERMINATOR',TRUE);
   DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform,'PRETTY',TRUE);

   -- Get the current user and database name

   v_username := USER;
   v_dbname := SYS_CONTEXT('USERENV', 'DB_NAME');

   -- Loop through all schemas, excluding system schemas and others
   FOR rec_schema IN (
      SELECT username
      FROM all_users
      WHERE username NOT IN (
         'SYS', 'SYSTEM', 'XDB', 'MDSYS', 'EXFSYS', 'ANONYMOUS', 'APPQOSSYS', 
         'AUDSYS', 'CTXSYS', 'DBSNMP', 'DIP', 'DVF', 'DVSYS', 'FLOWS_FILES', 
         'GSMADMIN_INTERNAL', 'GSMCATUSER', 'GSMUSER', 'LBACSYS', 'MDDATA', 
         'OJVMSYS', 'OLAPSYS', 'ORACLE_OCM', 'ORDDATA', 'ORDPLUGINS', 'ORDSYS', 
         'OUTLN', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 
         'SYSBACKUP', 'SYSMAN', 'SYSDG', 'SYSKM', 'WMSYS', 'XS$NULL'
      ) AND username NOT LIKE '%APEX%'
   )
    LOOP
         v_schema_name := rec_schema.username;


         @process_tables.sql v_schema_name

         @process_views.sql v_schema_name

         @process_procedures_and_functions.sql v_schema_name

         @process_packages.sql v_schema_name

         @process_triggers.sql v_schema_name

         @process_indexes.sql v_schema_name

    END LOOP;

   -- Create summary file
   v_file := UTL_FILE.FOPEN(v_version_dir, 'summary.txt', 'w');
   UTL_FILE.PUT_LINE(v_file, 'Database user: ' || v_username);
   UTL_FILE.PUT_LINE(v_file, 'Database name: ' || v_dbname);
   UTL_FILE.PUT_LINE(v_file, 'Time run: ' || TO_CHAR(v_run_date, 'YYYY-MM-DD HH24:MI:SS'));
   UTL_FILE.PUT_LINE(v_file, 'Number of files generated: ' || v_file_count);
   UTL_FILE.FCLOSE(v_file);

   -- Error loggin
   IF UTL_FILE.IS_OPEN(v_error_log) THEN
      UTL_FILE.FCLOSE(v_error_log);
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      v_error_message := 'Unexpected error in main block: ' || SQLERRM;
      IF UTL_FILE.IS_OPEN(v_error_log) THEN
         UTL_FILE.PUT_LINE(v_error_log, v_error_message);
         UTL_FILE.FCLOSE(v_error_log);
      END IF;
      RAISE;
END;
/
