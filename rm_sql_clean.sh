#!/bin/bash
#
# rm_sql_clean.sh
#
# Clears the previous snapshot so a new export starts from a clean slate.
#
# Paths below are RELATIVE, so run this from the parent of the object folders
# on the database server (/aux/dbops with the default layout), not from the
# repository:
#
#   cd /aux/dbops && ./rm_sql_clean.sh
#
# Note: grants/ and the summary.txt / error_log.txt in DDL_DIR are not cleaned
# here; error_log.txt is truncated by the driver at the start of each run.

# Remove .sql files from each directory
rm ./procedures/*.sql
rm ./tables/*.sql
rm ./triggers/*.sql
rm ./packages/*.sql
rm ./views/*.sql
rm ./sequences/*.sql
rm ./indexes/*.sql
rm ./synonyms/*.sql
rm ./mviews/*.sql
rm ./types/*.sql
rm ./dblinks/*.sql
rm ./users/*.sql
rm ./roles/*.sql
rm ./profiles/*.sql
rm ./jobs/*.sql
rm ./functions/*.sql
rm ./libraries/*.sql
rm ./privileges/*.sql
rm ./contexts/*.sql

