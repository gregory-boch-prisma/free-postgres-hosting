# Examples

Two read-only tools for inspecting a Postgres instance you are evaluating.
Neither creates or modifies anything, so both are safe to point at a database
that already holds data.

Everything here reads the DSN from an environment variable. No credentials are
stored in the repository, and none should be added to it.

## Set the DSN once

```bash
export PGDSN='postgresql://USER:PASSWORD@HOST:5432/DBNAME?sslmode=require'
```

Most providers hand you this string verbatim in their dashboard. If yours gives
you the parts separately, assemble them in that order.

## `probe_postgres.sh`

A quick shell probe. Prints server version, role, encoding, connection ceiling
and current usage, database size, installed extensions and whether the session
is on TLS.

```bash
chmod +x probe_postgres.sh
./probe_postgres.sh
./probe_postgres.sh --json          # machine-readable, one flat object
```

Requires `psql`. On Debian and Ubuntu that is `apt install postgresql-client`;
on macOS, `brew install libpq`.

The connection-headroom warning at the end is the one to pay attention to. A
free tier with a low `max_connections` and a serverless deployment model is the
combination that most often fails in production rather than in testing.

## `pg_capability_report.sql`

A longer report, run entirely through `psql`:

```bash
psql "$PGDSN" -f pg_capability_report.sql
```

Seven sections: server identity, resource ceilings, live connection headroom,
extension availability, a set of SQL feature probes, size accounting per table,
and the TLS parameters of the current session.

Section 4 is the useful one when you are migrating. It compares a list of
commonly required extensions against `pg_available_extensions`, so you learn
that `pgcrypto` is not offered before you discover it in a failing migration.
Section 5 executes small queries rather than checking a version number, so the
answers reflect what the server will actually do.

## Reading the output

Two things are worth writing down for each candidate provider:

- `max_connections` minus current backends. This is your real concurrency
  budget, and pooling in the application does not raise it.
- Which of the extensions in section 4 report `offered_by_server = false`.
  That list is the actual migration work.

Neither number is published consistently across vendors, which is why the
comparison table in the parent [README](../README.md) keeps quotas in prose
with a source link instead of asserting them in a column.
