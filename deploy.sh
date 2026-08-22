#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sqlplus_bin="${SQLPLUS_BIN:-sqlplus}"
output_path="${OUTPUT_PATH:-/aux/dbops}"

if [[ $# -ne 1 ]]; then
  echo "Usage: ORACLE_CONNECT_STRING=user/password@service $0 <output-path>" >&2
  exit 64
fi

if [[ ! "$output_path" = /* ]]; then
  echo "Output path must be absolute: $output_path" >&2
  exit 64
fi

if ! command -v "$sqlplus_bin" >/dev/null 2>&1; then
  echo "sqlplus was not found. Set SQLPLUS_BIN to its executable path." >&2
  exit 69
fi

"$sqlplus_bin" -L "$1" @"$script_dir/install.sql" "$output_path"
"$sqlplus_bin" -L "$1" @"$script_dir/EXPORT_DDL_DRIVER.sql"
