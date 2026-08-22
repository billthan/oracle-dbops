-- Usage: sqlplus / as sysdba @install.sql /aux/dbops
-- Run on the database server, where the Oracle instance can access the path.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
    v_base_path VARCHAR2(1000) := RTRIM('&1', '/');

    PROCEDURE create_directory(p_name IN VARCHAR2, p_path IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE
            'CREATE OR REPLACE DIRECTORY ' || p_name || ' AS ''' ||
            REPLACE(p_path, '''', '''''') || '''';
    END;
BEGIN
    IF v_base_path IS NULL OR SUBSTR(v_base_path, 1, 1) <> '/' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'The export path must be an absolute Unix path, for example /aux/dbops.'
        );
    END IF;

    create_directory('DDL_TABLE_DIR',     v_base_path || '/tables');
    create_directory('DDL_VIEW_DIR',      v_base_path || '/views');
    create_directory('DDL_PACKAGE_DIR',   v_base_path || '/packages');
    create_directory('DDL_PROCEDURE_DIR', v_base_path || '/procedures');
    create_directory('DDL_TRIGGER_DIR',   v_base_path || '/triggers');
    create_directory('DDL_INDEX_DIR',     v_base_path || '/indexes');
    create_directory('DDL_DIR',           v_base_path || '/logs');
END;
/

EXIT SUCCESS
