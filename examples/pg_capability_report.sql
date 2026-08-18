-- Part of the freebase.cloud examples — https://freebase.cloud
-- pg_capability_report.sql
--
-- A read-only capability report for a managed Postgres instance.
-- Answers the question "which of the features my schema depends on will
-- actually work here", before you spend an afternoon migrating.
--
--   psql "$PGDSN" -f pg_capability_report.sql
--
-- Nothing here creates, alters or drops an object. Safe to run against a
-- database that already has data in it.

\pset border 2
\pset null '(null)'
\timing on

\echo
\echo '== 1. Server identity =================================================='

SELECT
    current_setting('server_version')            AS server_version,
    current_setting('server_version_num')::int   AS version_num,
    current_database()                           AS database,
    current_user                                 AS role,
    current_setting('is_superuser')              AS superuser,
    current_setting('server_encoding')           AS encoding,
    current_setting('TimeZone')                  AS timezone;

\echo
\echo '== 2. Resource ceilings you will notice first =========================='

SELECT name, setting, unit, short_desc
FROM pg_settings
WHERE name IN (
    'max_connections',
    'superuser_reserved_connections',
    'shared_buffers',
    'work_mem',
    'maintenance_work_mem',
    'max_worker_processes',
    'max_parallel_workers_per_gather',
    'statement_timeout',
    'idle_in_transaction_session_timeout',
    'temp_file_limit'
)
ORDER BY name;

\echo
\echo '== 3. Connection headroom right now ==================================='

SELECT
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
    count(*)                                                              AS backends_now,
    count(*) FILTER (WHERE state = 'active')                              AS active,
    count(*) FILTER (WHERE state = 'idle in transaction')                 AS idle_in_txn,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - count(*) AS headroom
FROM pg_stat_activity;

\echo
\echo '== 4. Extensions ======================================================'
\echo '-- installed:'

SELECT extname AS extension, extversion AS version
FROM pg_extension
ORDER BY extname;

\echo '-- commonly required, and whether this server can install them:'

WITH wanted(name) AS (
    VALUES ('uuid-ossp'), ('pgcrypto'), ('citext'), ('hstore'),
           ('pg_trgm'), ('btree_gin'), ('postgis'), ('vector'),
           ('pg_stat_statements'), ('timescaledb')
)
SELECT
    w.name,
    (a.name IS NOT NULL)                     AS offered_by_server,
    (i.extname IS NOT NULL)                  AS already_installed,
    a.default_version
FROM wanted w
LEFT JOIN pg_available_extensions a ON a.name = w.name
LEFT JOIN pg_extension          i ON i.extname = w.name
ORDER BY w.name;

\echo
\echo '== 5. SQL features your schema may rely on ============================'

SELECT 'window functions'      AS feature,
       (SELECT count(*) FROM (SELECT row_number() OVER () FROM generate_series(1, 3)) t) = 3 AS works
UNION ALL
SELECT 'recursive CTE',
       (WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 5)
        SELECT count(*) FROM c) = 5
UNION ALL
SELECT 'JSONB path query',
       ('{"a":[1,2,3]}'::jsonb @? '$.a[*] ? (@ > 2)')
UNION ALL
SELECT 'stored generated columns (PG 12+)',
       current_setting('server_version_num')::int >= 120000
UNION ALL
SELECT 'MERGE available (PG 15+)',
       current_setting('server_version_num')::int >= 150000
UNION ALL
SELECT 'logical replication slots permitted',
       (SELECT setting FROM pg_settings WHERE name = 'wal_level') = 'logical';

\echo
\echo '== 6. Size accounting ================================================='

SELECT
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
      WHERE table_schema NOT IN ('pg_catalog', 'information_schema')) AS user_tables;

SELECT
    schemaname AS schema,
    relname    AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_live_tup AS approx_rows
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

\echo
\echo '== 7. Transport ======================================================='

SELECT ssl, version AS tls_version, cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();

\echo
\echo 'Report complete. Nothing was modified.'
\timing off
