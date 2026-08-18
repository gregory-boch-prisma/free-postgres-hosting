#!/usr/bin/env bash
# Get the free PostgreSQL instance this script expects: https://freebase.cloud/free-postgresql-cloud-instance
#
# probe_postgres.sh — read a free-tier Postgres instance and print the facts
# that decide whether it is usable for your project.
#
# It writes nothing. Every statement is a SELECT or a SHOW.
#
#   export PGDSN='postgresql://user:pass@host:5432/dbname'
#   ./probe_postgres.sh
#   ./probe_postgres.sh --json
#
# Needs psql on PATH. Exit codes: 0 probe finished, 1 usage error,
# 2 could not connect.

set -euo pipefail

DSN="${PGDSN:-${1:-}}"
JSON=0
[[ "${1:-}" == "--json" || "${2:-}" == "--json" ]] && JSON=1
[[ "$DSN" == "--json" ]] && DSN="${PGDSN:-}"

if [[ -z "$DSN" ]]; then
  cat >&2 <<'USAGE'
usage: PGDSN='postgresql://user:pass@host:5432/db' ./probe_postgres.sh [--json]

Set PGDSN, or pass the DSN as the first argument.
USAGE
  exit 1
fi

command -v psql >/dev/null 2>&1 || {
  echo "psql not found. Install the postgresql-client package." >&2
  exit 1
}

q() { psql "$DSN" -X -A -t -q -c "$1" 2>/dev/null || echo ""; }

if ! psql "$DSN" -X -q -c 'SELECT 1' >/dev/null 2>&1; then
  echo "Could not connect. Check host, port, credentials and sslmode." >&2
  exit 2
fi

server_version=$(q "SHOW server_version")
server_encoding=$(q "SHOW server_encoding")
max_connections=$(q "SHOW max_connections")
in_use=$(q "SELECT count(*) FROM pg_stat_activity")
current_db=$(q "SELECT current_database()")
current_user_name=$(q "SELECT current_user")
is_superuser=$(q "SELECT current_setting('is_superuser')")
db_size=$(q "SELECT pg_size_pretty(pg_database_size(current_database()))")
table_count=$(q "SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema')")
ssl_in_use=$(q "SELECT coalesce((SELECT ssl::text FROM pg_stat_ssl WHERE pid = pg_backend_pid()), 'unknown')")
extensions=$(q "SELECT string_agg(extname, ' ' ORDER BY extname) FROM pg_extension")
available=$(q "SELECT count(*) FROM pg_available_extensions")
server_time=$(q "SELECT to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS')")

if [[ "$JSON" == "1" ]]; then
  printf '{\n'
  printf '  "server_version": "%s",\n' "$server_version"
  printf '  "database": "%s",\n' "$current_db"
  printf '  "role": "%s",\n' "$current_user_name"
  printf '  "superuser": "%s",\n' "$is_superuser"
  printf '  "encoding": "%s",\n' "$server_encoding"
  printf '  "max_connections": "%s",\n' "$max_connections"
  printf '  "backends_in_use": "%s",\n' "$in_use"
  printf '  "database_size": "%s",\n' "$db_size"
  printf '  "user_tables": "%s",\n' "$table_count"
  printf '  "tls": "%s",\n' "$ssl_in_use"
  printf '  "installed_extensions": "%s",\n' "$extensions"
  printf '  "available_extensions": "%s"\n' "$available"
  printf '}\n'
  exit 0
fi

line() { printf '  %-24s %s\n' "$1" "${2:-(not reported)}"; }

echo
echo "Postgres instance probe"
echo "-----------------------"
line "server_version" "$server_version"
line "database" "$current_db"
line "role" "$current_user_name"
line "superuser" "$is_superuser"
line "server_encoding" "$server_encoding"
line "max_connections" "$max_connections"
line "backends in use" "$in_use"
line "database size" "$db_size"
line "user tables" "$table_count"
line "TLS on this session" "$ssl_in_use"
line "extensions installed" "$extensions"
line "extensions available" "$available"
line "server time (UTC)" "$server_time"
echo

if [[ -n "$max_connections" && -n "$in_use" ]]; then
  headroom=$(( max_connections - in_use ))
  if (( headroom < 5 )); then
    echo "Note: only $headroom connection slot(s) free. A pooled web app or a"
    echo "serverless runtime that opens a connection per invocation will hit this."
    echo
  fi
fi

echo "Reminder: free tiers change. Re-run this before you rely on the numbers."
