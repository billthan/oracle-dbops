#!/bin/bash
#
# create_dirs.sh
#
# Creates the OS folder structure that the Oracle directory objects point at.
# Run once on the DATABASE SERVER, as an OS user that can create these paths.
# The directories must be writable by the OS user that owns the Oracle
# processes, otherwise UTL_FILE raises ORA-29283 during the export.
#
# Folders not populated by the current scripts (sequences, synonyms, mviews,
# types, dblinks, functions, libraries, users, profiles, privileges, contexts,
# jobs) are placeholders reserved for future object types.

# List of directories to be created
directories=(
  "/aux/dbops/tables"
  "/aux/dbops/views"
  "/aux/dbops/packages"
  "/aux/dbops/procedures"
  "/aux/dbops/triggers"
  "/aux/dbops/sequences"
  "/aux/dbops/indexes"
  "/aux/dbops/synonyms"
  "/aux/dbops/mviews"
  "/aux/dbops/types"
  "/aux/dbops/dblinks"
  "/aux/dbops/functions"
  "/aux/dbops/libraries"
  "/aux/dbops/users"
  "/aux/dbops/roles"
  "/aux/dbops/profiles"
  "/aux/dbops/privileges"
  "/aux/dbops/contexts"
  "/aux/dbops/jobs"
  "/aux/dbops/grants"
  "/aux/dbops/roles"
  "/exp1/ddl_dir2"
)

# Loop through the directory list
for dir in "${directories[@]}"; do
  if [ ! -d "$dir" ]; then
    echo "Creating directory: $dir"
    mkdir -p "$dir"
  else
    echo "Directory already exists: $dir"
  fi
done

echo "All directories checked and created if necessary."

