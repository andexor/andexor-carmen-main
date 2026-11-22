#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>
"""Apply pending migrations to a Carmen D1 database. Usage: tools/migrate.py prev|prod [--dry-run]
schema_migration decides what is pending. Each file runs in one batch with its own schema_migration
row (INSERT OR IGNORE, because 0001 and 0002 insert theirs). Run preview first, then production."""
import json
import pathlib
import re
import subprocess
import sys
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parent.parent
DB = ROOT / "db" / "carmen"
Migration = tuple[int, str, pathlib.Path]
NAMES = {"prev": "andexor-carmen-api-prev", "prod": "andexor-carmen-api-prod"}


def migrations() -> list[Migration]:
    """[(version, name, path)] for every built migration, checked to be numbered 1, 2, 3 without gaps."""
    out: list[Migration] = []
    for p in sorted(DB.glob("[0-9][0-9][0-9][0-9]_*.sql")):
        if p.name.endswith(".base.sql"):
            continue
        if not re.fullmatch(r"\d{4}_[a-z0-9_]+\.sql", p.name):
            raise SystemExit(f"bad migration file name: {p.name}")
        out.append((int(p.name[:4]), p.name[:-4], p))
    if [m[0] for m in out] != list(range(1, len(out) + 1)):
        raise SystemExit("migration numbers must run 1, 2, 3 with no gaps or repeats")
    return out


def pending(applied: set[int], files: list[Migration]) -> list[Migration]:
    """The migrations still to apply. The database must hold exactly the first k migrations."""
    have = sorted(applied)
    if have != [m[0] for m in files[: len(have)]]:
        raise SystemExit(f"database has versions {have}, which are not the first {len(have)} migrations in the repo")
    return files[len(have):]


def record(version: int, name: str) -> str:
    return f"\nINSERT OR IGNORE INTO schema_migration (version, name) VALUES ({version}, '{name}');\n"


def cf(*args: str) -> list[dict[str, Any]]:
    r = subprocess.run(["cf", *args], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"cf {' '.join(args[:2])} failed:\n{r.stdout}{r.stderr}")
    m = re.search(r"^\[", r.stdout, re.M)
    return json.loads(r.stdout[m.start():]) if m else []


def run(db_id: str, sql: str) -> list[dict[str, Any]]:
    result = cf("d1", "query", db_id, f"--sql={sql}")
    if not all(item.get("success") for item in result):
        raise SystemExit("a statement failed; D1 rolled the batch back")
    return result[-1]["results"]


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    if len(args) != 1 or args[0] not in NAMES:
        raise SystemExit(__doc__)
    ids = {d["name"]: d["uuid"] for d in cf("d1", "list")}
    db_id = ids.get(NAMES[args[0]]) or sys.exit(f"no database named {NAMES[args[0]]}")
    has = run(db_id, "SELECT name FROM sqlite_master WHERE name='schema_migration'")
    applied: set[int] = {r["version"] for r in run(db_id, "SELECT version FROM schema_migration")} if has else set()
    todo = pending(applied, migrations())
    if not todo:
        print(f"{NAMES[args[0]]}: up to date (versions {sorted(applied)})")
        return
    for version, name, path in todo:
        print(f"{NAMES[args[0]]}: {'would apply' if '--dry-run' in sys.argv else 'applying'} {name}")
        if '--dry-run' not in sys.argv:
            run(db_id, path.read_text() + record(version, name))


if __name__ == "__main__":
    main()
