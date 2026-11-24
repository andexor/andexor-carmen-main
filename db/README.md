<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Andexor Carmen: the common data model

One kind of Cloudflare D1 database, owned by exactly one Worker.

| Folder | Database | Owning Worker | Purpose |
| --- | --- | --- | --- |
| `carmen/` | `andexor-carmen-api-prod`, `andexor-carmen-api-prev` | `andexor-carmen-api` | Everything Carmen knows: companies, contacts, facts, rubric, runs, deals, agreements, documents, activities, tasks |

Both apps follow this model. The API implements it. The UI uses the same names for the same things, so a field called `fit_score` here is `fit_score` in the API's JSON and "Fit" on screen.

## Files

| File | What it is |
| --- | --- |
| `carmen/NNNN_name.base.sql` | One migration, hand-written. Edit it only until it is on `main`. |
| `carmen/NNNN_name.sql` | The base file plus SRT triggers generated from its `-- SRT domain:` comments. Built by `tools/build_schema.sh`. Never edit by hand. |

Migrations `0001_init` and `0002_schema_review_fixes` were applied to both databases on 2026-11-21, `0003_srt_violation_value` on 2026-11-22, and `0004_research_max_pages_16` to `0010_import_max_rows` on 2026-11-24. `0011_digest_days` is applied by the pipeline of `andexor-carmen-api`, to the preview and then to production. A migration on `main` is frozen: the build keeps it as it is, and `check_schemas.py` fails if it changes.

New migration: `./tools/new_migration.sh short_name`, write the changes, then `./tools/build_schema.sh && python3 tools/check_schemas.py`. Apply: `python3 tools/migrate.py prev`, then `prod`.

## Conventions

- Files are `NNNN_short_name.sql`, four-digit zero-padded, numbered 1, 2, 3 with no gaps, applied in order. `0001_init.sql` is the baseline.
- `tools/migrate.py` reads `schema_migration.version` to find the pending migrations and applies each file in one batch, which D1 runs as a transaction. The batch ends with `INSERT OR IGNORE` of the migration's own `schema_migration` row. `0001` and `0002` insert their own rows, and later files must not.
- Migrations are the only path that runs Data Definition Language (DDL). They run through `tools/migrate.py`. Runtime code never issues `CREATE`, `ALTER`, or `DROP`.
- Identifiers the system generates are lowercase Universally Unique Identifiers (UUIDs). Service ids are lowercase slugs that match the page names on andexor.net.
- Timestamps are ISO-8601 UTC text. Dates are `YYYY-MM-DD`.
- Money is an integer number of cents plus a currency code (default `USD`).
- Durations are whole numbers set by triggers, never by code: `ai_run.duration_ms` (milliseconds, start to finish) and `deal.total_deal_time` (seconds, `created_at` to `closed_at`, set when the stage becomes `WON` or `LOST`).
- A field is required only when a row is meaningless without it. See master PRD section 7.

## System Reference Table (SRT)

The `srt` table, `(domain, code, label, description, sort_order, active)`, is the authoritative list of every finite-value code. Codes are UPPERCASE. Each column that holds a code has a pair of generated triggers that reject any value not present and active in `srt` (the update trigger checks only when the column's value changes, so a row that holds a retired code can still be edited), and a `-- SRT domain: X` comment on its column definition naming the domain (SQLite has no column comment syntax, so a SQL comment is the only form). The comments are the only source: `build_schema.py` generates the triggers from the comments in each migration file, and `check_schemas.py` verifies every comment has its triggers and every SRT trigger has a comment. Adding or retiring a value is a migration that touches `srt`, never a code edit. The UI reads labels and order from `srt` through the API.

A rejected value fails the statement with a message that names the table, column, value, and domain, for example `SRT violation: company.stage value 'HOT' is not in COMPANY_STAGE`. The message is built from the row, which needs SQLite 3.47 or later. Both databases have it. When the SQLite in your `python3` is older, `build_schema.sh` and `check_schemas.py` re-run themselves on a Python that `uv` manages, so `uv` must be installed.

| Domain | Codes |
| --- | --- |
| `COMPANY_STAGE` | LEAD, PROSPECT, CUSTOMER, FORMER, DISQUALIFIED |
| `LEAD_SOURCE` | MANUAL, CONTACT_US, CSV, GRASS_SPIDER, REFERRAL, OTHER, SBE-2026-ATLANTA |
| `MEETING_MODE` | ONLINE, IN_PERSON, BOTH |
| `RECOMMENDATION` | REACH_OUT, MAYBE, SKIP |
| `CONTACT_ROLE` | DECISION_MAKER, INFLUENCER, BILLING, TECHNICAL, OTHER |
| `SERVICE_CATEGORY` | TECHNICAL, BUSINESS |
| `ENRICHMENT_SOURCE` | MANUAL, AI, GRASS_SPIDER, CONTACT_US, CSV, API |
| `ENRICHMENT_VALUE_TYPE` | YES_NO, NUMBER, RATING, DATE, CODE, TEXT |
| `RUBRIC_SECTION` | FIT, NEED |
| `ANSWER_TYPE` | YES_NO, RATING, NUMBER, CHOICE |
| `ANSWER_SOURCE` | MANUAL, AI |
| `PROPOSAL_STATUS` | PROPOSED, ACCEPTED, REJECTED |
| `AI_PROVIDER` | CLAUDE, WORKERS_AI, TYPESAFE, STUB |
| `AI_RUN_KIND` | RESEARCH, SCORING |
| `RUN_STATUS` | QUEUED, RUNNING, SUCCEEDED, FAILED |
| `DEAL_STAGE` | QUALIFYING, MEETING, PROPOSAL, NEGOTIATION, WON, LOST |
| `ENGAGEMENT_MODEL` | ONE_TIME, RETAINER, PERFORMANCE, PAY_AS_YOU_GO |
| `AGREEMENT_TYPE` | MSA, SOW, NDA, CHANGE_ORDER, OTHER |
| `AGREEMENT_STATUS` | DRAFT, SENT, ACTIVE, COMPLETED, EXPIRED, TERMINATED |
| `AMOUNT_PERIOD` | ONE_TIME, MONTHLY |
| `ACTIVITY_KIND` | NOTE, CALL, MEETING, EMAIL, STAGE_CHANGE, SCORE_CHANGE, SYSTEM |
| `TASK_STATUS` | OPEN, DONE, CANCELLED |
| `NOTIFICATION_KIND` | DAILY_DIGEST, RENEWAL_ALERT |
| `CHANNEL` | EMAIL |
| `NOTIFICATION_STATUS` | STUBBED, QUEUED, SENT, FAILED |
| `USER_ROLE` | READER, MEMBER, ADMIN |

Services, rubric criteria, AI models, and settings are not SRT domains. They are ordinary tables because Ed edits them in the UI.

Roles on `app_user`: the first row in an empty table is always `ADMIN` (a trigger sets it), and every user added after that defaults to `READER`. An `ADMIN` raises a user to `MEMBER` or `ADMIN`.

## How the tables relate

```
company ─┬─ contact
         ├─ enrichment_fact            (accepted facts, each with a source)
         ├─ rubric_answer ── rubric_criterion ── service
         ├─ company_service ── service (Need score per service)
         ├─ ai_run ─┬─ ai_run_fact     (RESEARCH: proposed facts)
         │          ├─ ai_run_answer   (SCORING: the run's answers)
         │          └─ ai_run_service  (SCORING: the run's Need per service)
         ├─ deal ── deal_service ── service
         ├─ agreement ─┬─ agreement (parent: SOW under MSA)
         │             ├─ agreement_service ── service
         │             └─ document     (bytes in R2)
         ├─ activity
         └─ task
```

## Entity-relationship diagrams

PlantUML diagrams are in `doc/uml/`, generated from the built schema by `tools/gen_erd.py`, so they cannot drift from the SQL:

- `erd-summary.puml` shows every table as a block and a line wherever a foreign key joins two tables. The `company` and `app_user` tables are joined to many others, so this one is dense.
- `erd-<table>.puml` exists for every table. It shows that table with all its columns, plus the tables it references and the tables that reference it. A table with no relationships, such as `srt`, `setting`, and `schema_migration`, appears alone. Those related tables list only their key columns. The line ends use crow's foot notation: a bar means exactly one parent, a circle means optional, and the fork means many. Each line is labeled with the foreign key column.

Columns are marked `<<PK>>`, `<<FK>>`, and `<<SRT DOMAIN>>`, and `*` means required. `./tools/build_schema.sh` regenerates the files, and `check_schemas.py` fails if they are stale. To draw them, run `./install-plantuml.sh` once and then `./plantuml.sh`, which writes SVG files to `doc/uml/images`. Run `./plantuml.sh` after a table change.

## Rubric answers and `config_json`

`rubric_criterion.config_json` says how an answer becomes points between 0 and 1. It is optional.

| Answer type | Stored `value` | `config_json` | Points |
| --- | --- | --- | --- |
| `YES_NO` | `YES` or `NO` | `{"invert": true}` to make No the good answer. `{"yes_at": 90}` makes the criterion measured: code answers it from the fact named by `enrichment_key`, Yes at or above the number and No below, and no model is asked. `{"measured": true}` alone means there is no rule yet: no model is asked, and the criterion stays unknown until a person answers it | Yes = 1, No = 0 |
| `RATING` | `0` to `5` | `{"invert": true}` to make 0 the good answer | value ÷ 5 |
| `NUMBER` | the number | `{"bands": [{"min": 0, "max": 10, "points": 0.5}, ...]}`; `max: null` means no upper limit | the matching band's points; 0 if none |
| `CHOICE` | a choice code | `{"choices": [{"code": "X", "label": "...", "points": 1.0}, ...]}` | the choice's points |

Points say how good an answer is: every question is worded so that Yes, or a high value, is the good outcome. For a question in the `NEED` section the scoring code of `andexor-carmen-api` turns that into need: Need is the share of the points that were not earned. No Need question carries `invert` for that, and `invert` is only for a question whose wording cannot be made positive.

An unanswered criterion has no row. The scoring formulas are in master PRD section 8.2.

## Research and scoring runs

- `ai_run.kind = 'RESEARCH'` writes `dossier` and rows in `ai_run_fact` with `decision = 'PROPOSED'`. Accepting a fact copies it, including its `notes`, into `enrichment_fact` with `source = 'AI'` and the run's id, and sets `decision = 'ACCEPTED'`.
- `ai_run.kind = 'SCORING'` writes rows in `ai_run_answer` and `ai_run_service` and the run's own `fit_score`, `need_score`, `confidence`, and `recommendation`. `input_run_id` names the research run whose dossier it read; NULL means it read the company's accepted facts.
- Applying a scoring run replaces the company's `rubric_answer` rows with the run's answers (`source = 'AI'`, `ai_run_id` set), recomputes `company_service` and the scores on `company`, and stamps `ai_run.applied_at`.
- Runs are never updated after they finish, except for `user_rating`, `user_note`, `applied_at`, and fact decisions. That is what makes them comparable.
- `ai_run.model_id_used` copies `ai_model.model_id` at run time, so changing a model row later does not rewrite history.
- Timings: `duration_ms` is end to end, `started_at` to `finished_at`, and a trigger sets it when both are present; code never writes it. `model_ms` is the time spent waiting on the model, written by code. Queue wait is `created_at` to `started_at`. Code writes `started_at` and `finished_at` as UTC with milliseconds, for example `2026-11-21T14:03:05.123Z`.

## Well-known enrichment keys

`enrichment_fact.key` is free text in lowercase snake case, so any tool can add facts without a schema change. The well-known keys are rows in the `enrichment_key` table, seeded in `0001_init.base.sql`:

| Column | Meaning |
| --- | --- |
| `key` | The key, for example `has_website` |
| `label` | The name shown in the UI |
| `value_type` | `YES_NO`, `NUMBER`, `RATING`, `DATE`, `CODE`, or `TEXT` (the `ENRICHMENT_VALUE_TYPE` domain), so the UI can show a toggle for a quick YES or NO |
| `description` | What it means, and for a `CODE` key the allowed codes |
| `sort_order`, `active` | Display order, and whether it is suggested |

The table is a hint list, not a constraint. `enrichment_fact.key` has no foreign key to it, so a new key never needs a migration. The API suggests the well-known keys plus any key already used in `enrichment_fact`, for auto-complete. A fact that answers a rubric question is an exact value, usually YES or NO, so the matcher can use it without reading prose. Any fact can also carry optional `notes`. `source_detail` says where a fact came from, such as a URL or a tool name. `check_schemas.py` fails if a rubric question's hint is not a key in the table.

## Documents

`document` holds metadata only. The file is an object in the R2 bucket at `r2_key` (`<company_id>/<document_id>`). The API writes the object first, then the row; it deletes the row first, then the object. `sha256` lets a download be verified.
