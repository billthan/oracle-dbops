-- Process Procedures and Functions
-- Included by EXPORT_DDL_DRIVER.sql via @process_procedures_and_functions.sql.
-- Not standalone: this is a fragment spliced into the driver's schema loop.
-- Source:     DBA_OBJECTS where object_type IN ('PROCEDURE','FUNCTION')
-- DDL types:  PROCEDURE and FUNCTION
-- Output dir: v_procedure_dir (DDL_PROCEDURE_DIR) -- functions land here too
-- File name:  <SCHEMA>_<PROCEDURE|FUNCTION>_<OBJECT_NAME>.sql
-- Requires:   v_schema_name, v_object_name, v_object_type, v_ddl_clob, v_file,
--             v_file_name, v_file_count, v_error_log, v_error_message,
--             v_procedure_dir
-- Errors are written to v_error_log and the object is skipped, so a single
-- failure does not abort the export.
FOR rec_proc IN (
    SELECT object_name, object_type
    FROM dba_objects
    WHERE owner = v_schema_name
    AND object_type IN ('PROCEDURE', 'FUNCTION')
)
LOOP
    BEGIN
    v_object_name := rec_proc.object_name;
    v_object_type := rec_proc.object_type;

    BEGIN
        -- Get the DDL for the procedure or function
        v_ddl_clob := DBMS_METADATA.get_ddl(v_object_type, v_object_name, v_schema_name);

        -- Check if the retrieved DDL is empty
        IF v_ddl_clob IS NULL THEN
            v_error_message := 'DDL retrieval returned NULL for ' || v_object_type || ' ' || v_schema_name || '.' || v_object_name;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            CONTINUE;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            v_error_message := 'Error getting DDL for ' || v_object_type || ' ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            CONTINUE;
    END;

    -- Replace spaces with underscores in the file name
    v_file_name := REPLACE(v_schema_name || '_' || v_object_type || '_' || v_object_name || '.sql', ' ', '_');

    BEGIN
        -- Open the file to write the procedure/function DDL
        v_file := UTL_FILE.FOPEN(v_procedure_dir, v_file_name, 'w', 32767);

        -- Initialize variables for reading the CLOB
        DECLARE
            v_offset      NUMBER := 1;
            v_chunk_size  NUMBER := 32767;
            v_clob_length NUMBER := DBMS_LOB.GETLENGTH(v_ddl_clob);
            v_buffer      VARCHAR2(32767);
        BEGIN
            -- Read and write the CLOB in chunks
            WHILE v_offset <= v_clob_length LOOP
                IF v_offset + v_chunk_size - 1 > v_clob_length THEN
                v_chunk_size := v_clob_length - v_offset + 1;
                END IF;

                DBMS_LOB.READ(v_ddl_clob, v_chunk_size, v_offset, v_buffer);
                UTL_FILE.PUT(v_file, v_buffer);

                v_offset := v_offset + v_chunk_size;
            END LOOP;
        END;

        -- Close the file
        UTL_FILE.FCLOSE(v_file);

        -- Increment the file count
        v_file_count := v_file_count + 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_message := 'Error writing DDL to file for ' || v_object_type || ' ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            IF UTL_FILE.IS_OPEN(v_file) THEN
                UTL_FILE.FCLOSE(v_file);
            END IF;
    END;

    EXCEPTION
    WHEN OTHERS THEN
        v_error_message := 'Unexpected error processing ' || v_object_type || ' ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
        UTL_FILE.PUT_LINE(v_error_log, v_error_message);
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
    END;
END LOOP;