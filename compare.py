#!/usr/bin/env python3
# Free PostgreSQL instance: https://freebase.cloud/free-postgresql-cloud-instance
"""Render the provider comparison tables in README.md from providers.yaml.

The README is generated output. Contributors edit providers.yaml.

    python3 compare.py                 # print the tables to stdout
    python3 compare.py --write         # splice them into README.md
    python3 compare.py --check         # exit 1 if README.md is out of date
    python3 compare.py --stale 120     # list rows not re-verified in 120 days
    python3 compare.py --format csv    # dump the live table as CSV

Requires PyYAML (pip install pyyaml). Nothing else.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import io
import pathlib
import re
import sys

try:
    import yaml
except ImportError:  # pragma: no cover - dependency hint only
    sys.exit("compare.py needs PyYAML:  pip install pyyaml")

ROOT = pathlib.Path(__file__).resolve().parent
DATA = ROOT / "providers.yaml"
README = ROOT / "README.md"

BEGIN = "<!-- BEGIN GENERATED TABLE -->"
END = "<!-- END GENERATED TABLE -->"

LIVE_COLUMNS = [
    ("name", "Provider"),
    ("free_tier", "Free tier"),
    ("expiry", "What ends it"),
    ("card", "Card needed"),
    ("best_at", "What it does best"),
]

REQUIRED = ("name", "url", "status", "free_tier", "expiry", "card", "best_at",
            "source", "verified")


def load() -> dict:
    with DATA.open(encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def squash(value) -> str:
    """Collapse a folded YAML block into one table-safe line."""
    text = "" if value is None else str(value)
    text = " ".join(text.split())
    return text.replace("|", "\\|")


def validate(doc: dict) -> list[str]:
    problems = []
    for row in doc.get("providers", []):
        for field in REQUIRED:
            if not row.get(field):
                problems.append(f"{row.get('name', '<unnamed>')}: missing '{field}'")
        if row.get("best_at") and len(squash(row["best_at"])) < 40:
            problems.append(
                f"{row['name']}: 'best_at' is too short to be a fair summary"
            )
    seen = set()
    for row in doc.get("providers", []):
        key = row.get("name", "").lower()
        if key in seen:
            problems.append(f"duplicate provider row: {row.get('name')}")
        seen.add(key)
    return problems


def markdown_table(rows: list[dict], columns) -> str:
    head = "| " + " | ".join(label for _, label in columns) + " |"
    rule = "|" + "|".join("---" for _ in columns) + "|"
    body = []
    for row in rows:
        cells = []
        for key, _ in columns:
            cell = squash(row.get(key, ""))
            if key == "name" and row.get("url"):
                cell = f"[{cell}]({row['url']})"
            cells.append(cell)
        body.append("| " + " | ".join(cells) + " |")
    return "\n".join([head, rule, *body])


def former_table(rows: list[dict]) -> str:
    lines = ["| No longer on this list | What changed |", "|---|---|"]
    for row in rows:
        lines.append(
            f"| [{squash(row['name'])}]({row['source']}) | {squash(row['what_changed'])} |"
        )
    return "\n".join(lines)


def render(doc: dict) -> str:
    live = [r for r in doc.get("providers", []) if r.get("status") == "live"]
    parts = [
        markdown_table(live, LIVE_COLUMNS),
        "",
        former_table(doc.get("former", [])),
    ]
    dates = [str(r.get("verified", "")) for r in live if r.get("verified")]
    if dates:
        parts += ["", f"Last verified: {max(dates)}"]
    return "\n".join(parts)


def splice(readme: str, block: str) -> str:
    pattern = re.compile(
        re.escape(BEGIN) + r".*?" + re.escape(END), re.DOTALL
    )
    replacement = f"{BEGIN}\n\n{block}\n\n{END}"
    if not pattern.search(readme):
        raise SystemExit(
            f"README.md has no {BEGIN} / {END} markers — nothing to replace."
        )
    return pattern.sub(lambda _: replacement, readme)


def as_csv(doc: dict) -> str:
    buf = io.StringIO()
    keys = [k for k, _ in LIVE_COLUMNS] + ["url", "limits", "source", "verified"]
    writer = csv.DictWriter(buf, fieldnames=keys, extrasaction="ignore")
    writer.writeheader()
    for row in doc.get("providers", []):
        if row.get("status") == "live":
            writer.writerow({k: squash(row.get(k, "")) for k in keys})
    return buf.getvalue()


def stale_report(doc: dict, days: int) -> int:
    cutoff = dt.date.today() - dt.timedelta(days=days)
    late = []
    for row in doc.get("providers", []) + doc.get("former", []):
        raw = row.get("verified")
        if not raw:
            late.append((row.get("name", "?"), "never"))
            continue
        when = raw if isinstance(raw, dt.date) else dt.date.fromisoformat(str(raw))
        if when < cutoff:
            late.append((row.get("name", "?"), when.isoformat()))
    if not late:
        print(f"All rows re-verified within the last {days} days.")
        return 0
    print(f"Rows not re-verified in {days} days:")
    for name, when in late:
        print(f"  {name:<28} {when}")
    return 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--write", action="store_true", help="update README.md in place")
    ap.add_argument("--check", action="store_true", help="fail if README.md is stale")
    ap.add_argument("--format", choices=("md", "csv"), default="md")
    ap.add_argument("--stale", type=int, metavar="DAYS",
                    help="report rows older than DAYS since verification")
    args = ap.parse_args()

    doc = load()

    problems = validate(doc)
    if problems:
        for line in problems:
            print(f"providers.yaml: {line}", file=sys.stderr)
        return 2

    if args.stale is not None:
        return stale_report(doc, args.stale)

    if args.format == "csv":
        sys.stdout.write(as_csv(doc))
        return 0

    block = render(doc)

    if args.check:
        current = README.read_text(encoding="utf-8")
        if splice(current, block) != current:
            print("README.md is out of date. Run: python3 compare.py --write",
                  file=sys.stderr)
            return 1
        print("README.md matches providers.yaml.")
        return 0

    if args.write:
        current = README.read_text(encoding="utf-8")
        updated = splice(current, block)
        if updated == current:
            print("README.md already up to date.")
        else:
            README.write_text(updated, encoding="utf-8")
            print("README.md updated.")
        return 0

    print(block)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
