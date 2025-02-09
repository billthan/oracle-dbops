-- Process Indexes
FOR rec_index IN (
    SELECT index_name
    FROM dba_indexes
    WHERE owner = v_schema_name
)
LOOP
    BEGIN
        v_object_name := rec_index.index_name;

        BEGIN
            -- Get the DDL for the index
            v_ddl_clob := DBMS_METADATA.get_ddl('INDEX', v_object_name, v_schema_name);

            -- Check if the retrieved DDL is empty
            IF v_ddl_clob IS NULL THEN
                v_error_message := 'DDL retrieval returned NULL for index ' || v_schema_name || '.' || v_object_name;
                UTL_FILE.PUT_LINE(v_error_log, v_error_message);
                CONTINUE;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_message := 'Error getting DDL for index ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
                UTL_FILE.PUT_LINE(v_error_log, v_error_message);
                CONTINUE;
        END;

        -- Replace spaces with underscores in the file name
        v_file_name := REPLACE(v_schema_name || '_INDEX_' || v_object_name || '.sql', ' ', '_');

        BEGIN
            -- Open the file to write the index DDL
            v_file := UTL_FILE.FOPEN(v_index_dir, v_file_name, 'w', 32767);

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
                v_error_message := 'Error writing DDL to file for index ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
                UTL_FILE.PUT_LINE(v_error_log, v_error_message);
                IF UTL_FILE.IS_OPEN(v_file) THEN
                    UTL_FILE.FCLOSE(v_file);
                END IF;
        END;

    EXCEPTION
        WHEN OTHERS THEN
            v_error_message := 'Unexpected error processing index ' || v_schema_name || '.' || v_object_name || ': ' || SQLERRM;
            UTL_FILE.PUT_LINE(v_error_log, v_error_message);
            IF UTL_FILE.IS_OPEN(v_file) THEN
                UTL_FILE.FCLOSE(v_file);
            END IF;
    END;
END LOOP;
