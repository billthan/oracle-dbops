#!/bin/bash

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

