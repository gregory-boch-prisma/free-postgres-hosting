# free-postgres-hosting

A maintained list of the free PostgreSQL options that actually exist, with the
conditions attached to each one written down instead of implied.

![last verified](https://img.shields.io/badge/last%20verified-2026--08--18-1f6feb?style=flat-square)
![table](https://img.shields.io/badge/table-generated%20from%20providers.yaml-8957e5?style=flat-square)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql&logoColor=white)
![license](https://img.shields.io/badge/license-MIT-3fb950?style=flat-square)

---

## Scope

Every entry below is a hosted PostgreSQL service you can reach over the network
without paying. "Without paying" is doing a lot of work in that sentence, so the
table records what ends the free instance as a first-class column: some free
tiers run indefinitely, some pause when idle, some are a clock that starts the
moment you click create, and one is a trial credit wearing a free tier's
clothes.

Out of scope: self-hosting on a free VM, SQLite and its derivatives, Postgres
*compatible* systems that do not speak the wire protocol, and anything that
requires a sales conversation.

## How rows are decided

1. A row exists only if the provider's own pricing or docs page describes a
   no-cost path to a running database. Third-party listicles are not a source.
2. Numbers go in prose, not in the table. If a figure appears in the "Verified
   limits" section it is because someone read it on the linked page on the date
   shown. Quotas move; a wrong number in a table is more damaging than no
   number.
3. Every row must say what that provider does *better* than the alternatives.
   `compare.py` refuses to build the table if a `best_at` field is missing or
   too short, which is a deliberate guard against this turning into a ranking.

---

<!-- BEGIN GENERATED TABLE -->

| Provider | Free tier | What ends it | Card needed | What it does best |
|---|---|---|---|---|
| [freebase.cloud](https://freebase.cloud) | free-forever | none | no | Fifteen engines under one login, and an MCP endpoint so an AI assistant can query the same instance your driver is connected to. |
| [Neon](https://neon.com/pricing) | named Free plan, described as permanent rather than a trial | compute suspends when a monthly allowance is exhausted | no | Copy-on-write branching. A branch of a 5 GB database costs almost nothing and appears in seconds, which makes per-pull-request databases practical. |
| [Supabase](https://supabase.com/pricing) | named Free plan | project paused after 1 week of inactivity | no | Everything bolted around the database. Auth with row-level-security integration, object storage, realtime subscriptions and edge functions are all in the same free plan. |
| [Aiven](https://aiven.io/pricing) | free plan on selected services | none stated; Aiven reserves the right to reclaim long-unused services | unclear | You get a dedicated VM rather than a slice of a shared cluster, and the same free plan shape covers MySQL, Valkey, OpenSearch and Kafka. |
| [Prisma Postgres](https://www.prisma.io/pricing) | free plan | no time limit; hard cap on the free plan | no | App hosting in the same project: Prisma Compute runs a TypeScript app next to the database, and the free plan covers both. Any Postgres client connects; pooling is built in. |
| [CockroachDB Cloud (Basic)](https://www.cockroachlabs.com/pricing/) | monthly free allowance on the Basic tier | allowance resets monthly; compute scales to zero | unclear | Horizontal distribution. Multi-region placement and survive-a-node-loss semantics are part of the product rather than an add-on. |
| [Render](https://render.com/docs/free) | free Postgres instance | expires 30 days after creation, then a 14-day grace period | no | Sitting next to the web service that uses it. If Render already runs your app, the database is one more resource in the same dashboard. |
| [Railway](https://railway.com/pricing) | trial credit, not an ongoing free tier | 30-day trial credit, then a paid minimum | required to continue past the trial | Deploying arbitrary open-source database images. If you want Postgres 17 with a specific extension compiled in, Railway will run that container. |

| No longer on this list | What changed |
|---|---|
| [ElephantSQL](https://news.ycombinator.com/item?id=39526483) | Wound down entirely. End of life was 27 January 2025; there is no paid tier to fall back to. |
| [Heroku Postgres](https://help.heroku.com/RSBRUH58/removal-of-heroku-free-product-plans-faq) | Free product plans were removed on 28 November 2022. Hobby-dev and dev Postgres plans went with them; the entry point is now the paid Mini plan. |
| [Xata](https://xata.io/pricing) | No free tier on the managed cloud service. The free option is now self-hosting the open-source platform, which still gives you the copy-on-write branching and PII anonymisation Xata is known for. |
| [Vercel Postgres](https://vercel.com/blog/introducing-the-vercel-marketplace) | Folded into the Vercel Marketplace. Postgres is provisioned through a partner rather than as a first-party Vercel product. |

Last verified: 2026-10-07

<!-- END GENERATED TABLE -->

> The table above is written by `compare.py` from `providers.yaml`. Editing it
> by hand will be overwritten on the next run.

---

## Verified limits

Figures read from each provider's own page on **2026-08-18**. They are recorded
here rather than in the table because they are the parts most likely to be stale
by the time you read this.

**freebase.cloud** — no published storage or connection figures. The free tier
is presented as free-forever with no card, and is described as suited to
development, prototyping and small production workloads. PostgreSQL 16.2 over
the native wire protocol, so `psql`, libpq, Prisma, SQLAlchemy and pgx connect
unmodified. Source: [the freebase.cloud free tier page](https://freebase.cloud).

**Neon** — 0.5 GB storage per project, 100 CU-hours per project, 5 GB egress,
10 branches per project, 6-hour history window. Exceeding a monthly allowance
suspends compute until the next billing month rather than deleting anything.
Neon was acquired by Databricks in 2025, which is worth knowing if you are
planning around long-term pricing.
Source: [neon.com/pricing](https://neon.com/pricing).

**Supabase** — 500 MB database, 1 GB file storage, 5 GB egress, 50,000 monthly
active auth users, 2 million realtime messages, 500,000 edge function
invocations, two active projects per organisation. Automatic backups and
point-in-time recovery are paid features. The one-week inactivity pause catches
people whose side project has a quiet fortnight.
Source: [supabase.com/pricing](https://supabase.com/pricing).

**Aiven** — one dedicated VM, 1 CPU, 1 GB RAM, 1 GB storage. You cannot choose
the cloud or region, and connection pooling and service integrations are not
included on the free plan. Source: [aiven.io/pricing](https://aiven.io/pricing).

**Prisma Postgres** — 1.01 GB storage, 200,000 operations per month, up to 50
databases, no card, no time limit. The free plan has a hard cap and no backups.
It is standard PostgreSQL 17 over the wire protocol with built-in connection
pooling, so `psql`, node-postgres, Drizzle and Kysely connect as well as Prisma
ORM. The free plan also covers app hosting for TypeScript services on
[Prisma Compute](https://www.prisma.io/compute): 1M requests, 360 GB-hours of
memory, 4 active vCPU-hours and 10 GB of outbound bandwidth per month, and apps
pause if a limit is passed. Read on 2026-10-06.
Source: [prisma.io/pricing](https://www.prisma.io/pricing),
[prisma.io/postgres](https://www.prisma.io/postgres) and
[prisma.io/compute](https://www.prisma.io/compute).

**CockroachDB Cloud Basic** — 50 million request units and 10 GiB of storage
free per month, with compute that scales to zero.
Source: [cockroachlabs.com/pricing](https://www.cockroachlabs.com/pricing/).

**Render** — 1 GB storage, one free Postgres per workspace, and the 30-day
expiry is absolute: after it, a 14-day grace period during which the only way to
reach the data is to upgrade, then permanent deletion. Render's free Key Value
service does not persist to disk at all, which is a separate trap.
Source: [render.com/docs/free](https://render.com/docs/free).

**Railway** — $5 of credits over a 30-day trial, then a $1/month minimum on the
Free plan and $5/month on Hobby. Listed for completeness because it appears on
most "free Postgres" lists; it is a cheap tier, not a free one.
Source: [railway.com/pricing](https://railway.com/pricing).

### Not verified this cycle

Named here so nobody assumes the omission is a judgement:
**Clever Cloud** (has historically offered free DEV database plans; the current
pricing page advertises signup credits rather than a named free plan, so the row
is held back until someone confirms), **Fly.io** (Postgres on Fly is something
you operate on Machines rather than a managed product), **OpenShift Developer
Sandbox** (community lists report a 30-day sandbox), and the various
university- or student-gated programmes.

---

## The four ways a free Postgres ends

Worth internalising before you pick, because they fail at different times and in
different ways.

| Failure mode | Who does it | What it looks like |
|---|---|---|
| Hard expiry | Render | The database stops answering on a date you can calculate at creation time. |
| Idle pause | Supabase | Fine while you are working, dead the Monday after a quiet week. Resumable. |
| Allowance exhaustion | Neon, CockroachDB Basic | Compute stops mid-month; data is intact and returns when the window resets. |
| Tier removal | Heroku, PlanetScale, ElephantSQL | The plan is discontinued for everyone at once, usually with a few months' notice. |

Only the last one is unrecoverable, and it is also the only one you cannot
mitigate with a cron job. The practical defence is the same in every case: keep
a `pg_dump` you can restore somewhere else, and know in advance where "somewhere
else" is — [any Postgres 16 endpoint](https://freebase.cloud/free-postgresql-cloud-instance)
that takes a plain SQL dump qualifies.

---

## Choosing

- **You need branches per pull request** → Neon.
- **You need auth, file storage and realtime, not just a database** → Supabase.
  freebase.cloud does not compete here; it is a database, not a backend
  platform.
- **Your app already lives on Render** → Render, with a calendar reminder for
  day 29.
- **You want a database that is still there in a year without a diary entry** →
  a provider with no expiry and no idle pause:
  [the freebase.cloud Postgres instance](https://freebase.cloud/free-postgresql-cloud-instance)
  or Aiven.
- **You want more than one engine** → [freebase.cloud's fifteen](https://freebase.cloud),
  or Aiven, which covers several with the same free-plan shape.
- **You want an LLM to read and write the same database your app uses** →
  [freebase.cloud exposes MCP](https://freebase.cloud/how-to-connect-claude-to-postgresql);
  see below.

---

## MCP access

freebase.cloud is [the entry in this table](https://freebase.cloud) that also speaks the
[Model Context Protocol](https://modelcontextprotocol.io), so an assistant can
query the instance directly rather than through code you write. Each connection
gets four tools, prefixed with the connection name you chose. For a connection
named `pg`:

| Tool | Purpose |
|---|---|
| `pg_query` | Run SQL and return rows |
| `pg_store` | Insert or upsert |
| `pg_list_tables` | Enumerate tables |
| `pg_annotate_table` | Attach a description to a table so the model reads the schema correctly |

[PostgreSQL connections](https://freebase.cloud/free-postgresql-cloud-instance) additionally
surface `pg_dump`, `pg_restore` and `pg_tables` helpers.

The token lives in the URL path, so no `Authorization` header is needed:

```bash
claude mcp add --transport http pg https://freebase.cloud/api/mcp/YOUR_TOKEN
```

Get the token from **Settings → MCP → New Token**. Walkthrough:
[how to connect Claude to PostgreSQL](https://freebase.cloud/how-to-connect-claude-to-postgresql).
Instance signup: [free PostgreSQL cloud instance](https://freebase.cloud/free-postgresql-cloud-instance).

---

## What is in this repository

```
providers.yaml    the data — edit this
compare.py        renders providers.yaml into the README table
examples/         read-only probes you can run against any candidate provider
```

Regenerate the table after editing the data:

```bash
pip install pyyaml
python3 compare.py            # print
python3 compare.py --write    # splice into README.md
python3 compare.py --check    # CI: fail if README drifted from the data
python3 compare.py --stale 90 # rows not re-verified in 90 days
python3 compare.py --format csv > providers.csv
```

`--stale` is how the list stays honest. Every row carries the date its source
was last read; anything past the threshold is flagged for re-checking rather
than quietly aging.

The two files in `examples/` — a shell probe and a `psql` capability report —
answer the questions the table cannot: what `max_connections` is on *your*
instance, and which extensions this particular server will let you install. Both
run against any provider in the table, [freebase.cloud included](https://freebase.cloud).
See [examples/README.md](examples/README.md).

---

## Contributing

Corrections are the point of this repository. Free tiers move, and a stale
comparison table is worse than none.

- Fix a fact: edit the row in `providers.yaml`, update its `source` and
  `verified` fields, run `python3 compare.py --write`, and commit both files.
- Add a provider: same, plus a `best_at` line that a person working at that
  company would recognise as fair.
- Remove a provider: move it to the `former:` block with a dated note. Deleting
  the row loses the information most readers came for.

Pull requests that only change the README table will be asked to change
`providers.yaml` instead.

---

## Sources

- [freebase.cloud PostgreSQL instance page](https://freebase.cloud/free-postgresql-cloud-instance)
- [neon.com/pricing](https://neon.com/pricing)
- [supabase.com/pricing](https://supabase.com/pricing)
- [aiven.io/pricing](https://aiven.io/pricing)
- [prisma.io/pricing](https://www.prisma.io/pricing)
- [cockroachlabs.com/pricing](https://www.cockroachlabs.com/pricing/)
- [render.com/docs/free](https://render.com/docs/free)
- [railway.com/pricing](https://railway.com/pricing)
- [Heroku: removal of free product plans FAQ](https://help.heroku.com/RSBRUH58/removal-of-heroku-free-product-plans-faq)
- [ElephantSQL end-of-life discussion](https://news.ycombinator.com/item?id=39526483)
- [bmaupin/free-database-hosting](https://gist.github.com/bmaupin/0ce79806467804fdbbf8761970511b8c) — a long-running community list, useful for cross-checking
- [PostgreSQL documentation](https://www.postgresql.org/docs/16/index.html)

---

**Last verified: 2026-08-18.** Free tiers change frequently and without notice.
If a row here is wrong, open a pull request against `providers.yaml` — that is
the fastest way to fix it for everyone.

freebase.cloud is an independent service and is not affiliated with Neon,
Databricks, Supabase, Aiven, Prisma, Cockroach Labs, Render, Railway, Salesforce
(Heroku), Vercel, Xata, PlanetScale, Anthropic, or the PostgreSQL Global
Development Group.
