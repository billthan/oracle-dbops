--CREATE OR REPLACE DIRECTORY ROLE_DIR AS '/aux/dbops/roles';
DECLARE
    v_file       UTL_FILE.file_type;
    v_line       VARCHAR2(4000);
BEGIN
    -- Open file for create role statements
    v_file := UTL_FILE.FOPEN('ROLE_DIR', 'create_roles.sql', 'W');

    -- Generate create role statements for all roles in the database
    FOR r IN (SELECT 'CREATE ROLE ' || ROLE || ';' AS create_role_sql
              FROM DBA_ROLES
              ORDER BY ROLE)
    LOOP
        -- Write each CREATE ROLE statement to the file
        v_line := r.create_role_sql;
        UTL_FILE.PUT_LINE(v_file, v_line);
    END LOOP;

    -- Close the file for create roles
    UTL_FILE.FCLOSE(v_file);

    -- Open file for role grants
    v_file := UTL_FILE.FOPEN('GRANT_DIR', 'grant_roles.sql', 'W');

    -- Generate role grants to users and roles
    FOR g IN (SELECT 'GRANT ' || GRANTED_ROLE || ' TO ' || GRANTEE ||
                     CASE WHEN ADMIN_OPTION = 'YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END AS grant_sql
              FROM DBA_ROLE_PRIVS
              ORDER BY GRANTEE, GRANTED_ROLE)
    LOOP
        -- Write each GRANT statement to the file
        v_line := g.grant_sql;
        UTL_FILE.PUT_LINE(v_file, v_line);
    END LOOP;

    -- Close the file for role grants
    UTL_FILE.FCLOSE(v_file);

END;
/
