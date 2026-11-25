# Andexor Carmen Main

Andexor Carmen is the Customer Relationship Management (CRM) system for Andexor Network. It tracks a company from first lead information, through research, qualification, and scoring, into deals, agreements, and the ongoing customer relationship.

This is the **governing repository** (`andexor-carmen-main`). It holds the master PRD ([`PRD.md`](PRD.md)), the common data model ([`db/README.md`](db/README.md)), and the Spec Kit constitution ([`.specify/memory/constitution.md`](.specify/memory/constitution.md)). Runtime code lives in the sibling repos:

| Repo | Role |
| --- | --- |
| `andexor-carmen-ui` | Front-end web app (Next.js on Cloudflare Workers) |
| `andexor-carmen-api` | Back-end services (FastAPI on Cloudflare Python Workers, D1, R2) |

Start with [`CLAUDE.md`](CLAUDE.md) for the standing conventions, then [`PRD.md`](PRD.md).

```
CLAUDE.md             conventions for the three Carmen repos; read first
PRD.md                master Product Requirements Document (draft 0.1, 2026-11-15)
db/                   the common data model: D1 schema, SRT codes, conventions
doc/uml/              PlantUML E/R diagrams, generated from the schema
tools/                build_schema.sh, check_schemas.py, new_migration.sh, migrate.py, gen_erd.py
.specify/             Spec Kit; memory/constitution.md is copied to the child repos
```

## Check the data model

```
./tools/build_schema.sh
python3 tools/check_schemas.py
```

Both need SQLite 3.47 or later. When the SQLite in your `python3` is older, they re-run themselves on a Python that `uv` manages, so install `uv`.

The workflow `.github/workflows/checks.yml` runs `check_schemas.py` and pyright on every pull request and on every push to `main`. It reports as `Preview and smoke test`, the check the default-branch ruleset requires.
