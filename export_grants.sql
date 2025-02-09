   
   --CREATE OR REPLACE DIRECTORY GRANT_DIR AS '/aux/dbops/grants';
DECLARE
    v_file      UTL_FILE.file_type;
    v_line      VARCHAR2(4000);
BEGIN
    -- Open file for roles
    v_file := UTL_FILE.FOPEN('GRANT_DIR', 'all_grants_roles.sql', 'W');

    -- Generate grants for roles
    FOR r IN (SELECT 'GRANT ' || GRANTED_ROLE || ' TO ' || GRANTEE ||
                     CASE WHEN ADMIN_OPTION = 'YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END AS grant_sql
              FROM DBA_ROLE_PRIVS
              ORDER BY GRANTEE, GRANTED_ROLE)
    LOOP
        -- Write each grant statement to the file
        v_line := r.grant_sql;
        UTL_FILE.PUT_LINE(v_file, v_line);
    END LOOP;

    UTL_FILE.FCLOSE(v_file);

    -- Open file for system privileges
    v_file := UTL_FILE.FOPEN('GRANT_DIR', 'all_grants_sys_privs.sql', 'W');

    -- Generate grants for system privileges
    FOR sp IN (SELECT 'GRANT ' || PRIVILEGE || ' TO ' || GRANTEE ||
                     CASE WHEN ADMIN_OPTION = 'YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END AS grant_sql
               FROM DBA_SYS_PRIVS
               ORDER BY GRANTEE, PRIVILEGE)
    LOOP
        -- Write each grant statement to the file
        v_line := sp.grant_sql;
        UTL_FILE.PUT_LINE(v_file, v_line);
    END LOOP;

    UTL_FILE.FCLOSE(v_file);

    -- Open file for table grants
    v_file := UTL_FILE.FOPEN('GRANT_DIR', 'all_grants_tab_privs.sql', 'W');

    -- Generate grants for tables, views, sequences, procedures, functions, and packages
    FOR tp IN (SELECT 'GRANT ' || PRIVILEGE || ' ON ' || OWNER || '.' || TABLE_NAME || ' TO ' || GRANTEE ||
                      CASE WHEN GRANTABLE = 'YES' THEN ' WITH GRANT OPTION;' ELSE ';' END AS grant_sql
               FROM DBA_TAB_PRIVS
               ORDER BY GRANTEE, OWNER, TABLE_NAME, PRIVILEGE)
    LOOP
        -- Write each grant statement to the file
        v_line := tp.grant_sql;
        UTL_FILE.PUT_LINE(v_file, v_line);
    END LOOP;

    UTL_FILE.FCLOSE(v_file);

END;
/
