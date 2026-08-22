#!/bin/bash

base_dir="${1:-/aux/dbops}"

# List of directories to be created
directories=(
  "$base_dir/tables"
  "$base_dir/views"
  "$base_dir/packages"
  "$base_dir/procedures"
  "$base_dir/triggers"
  "$base_dir/sequences"
  "$base_dir/indexes"
  "$base_dir/synonyms"
  "$base_dir/mviews"
  "$base_dir/types"
  "$base_dir/dblinks"
  "$base_dir/functions"
  "$base_dir/libraries"
  "$base_dir/users"
  "$base_dir/roles"
  "$base_dir/profiles"
  "$base_dir/privileges"
  "$base_dir/contexts"
  "$base_dir/jobs"
  "$base_dir/grants"
  "$base_dir/logs"
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
