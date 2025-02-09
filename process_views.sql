-- Process Views
FOR rec_view IN (
    SELECT view_name
    FROM dba_views
    WHERE owner = v_schema_name
)
LOOP
    BEGIN
    v_object_name := rec_view.view_name;

    BEGIN
        -- Get the DDL for the view
        v_ddl_clob := DBMS_METADATA.get_ddl('VIEW', v_object_name, v_schema_name);

        -- Check if the retrieved DDL is empty
        IF v_ddl_clob IS NULL THEN
            v_error_message := 'DDL retrieval returned NULL for view ' || v_schema_name || '.' || v_object_name;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            CONTINUE;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            v_error_message := 'Error getting DDL for view ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            CONTINUE;
    END;

    -- Replace spaces with underscores in the file name
    v_file_name := REPLACE(v_schema_name || '_VIEW_' || v_object_name || '.sql', ' ', '_');

    BEGIN
        -- Open the file to write the view DDL
        v_file := UTL_FILE.FOPEN(v_view_dir, v_file_name, 'w', 32767);

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
            v_error_message := 'Error writing DDL to file for view ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            IF UTL_FILE.IS_OPEN(v_file) THEN
                UTL_FILE.FCLOSE(v_file);
            END IF;
    END;

    EXCEPTION
    WHEN OTHERS THEN
        v_error_message := 'Unexpected error processing view ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
        UTL_FILE.PUT_LINE(v_error_log, v_error_message);
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
    END;
END LOOP;