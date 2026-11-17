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
| `carmen/0001_init.base.sql` | The hand-written tables, indexes, and seed rows. Edit this one. |
| `carmen/0001_init.sql` | The base file plus generated SRT triggers. Built by `tools/build_schema.sh`. Never edit by hand. |

After any change: `./tools/build_schema.sh && python3 tools/check_schemas.py`.

## Conventions

- Files are `NNNN_short_name.sql`, four-digit zero-padded, applied in order. `0001_init.sql` is the baseline.
- The migration runner checks `schema_migration.version` before applying a file and inserts its row in the same transaction.
- Migrations are the only path that runs Data Definition Language (DDL). They run from the API repo's deploy workflow. Runtime code never issues `CREATE`, `ALTER`, or `DROP`.
- `PRAGMA foreign_keys = ON` is set by the data-access layer on every request and at the top of each migration.
- Identifiers the system generates are lowercase Universally Unique Identifiers (UUIDs). Service ids are lowercase slugs that match the page names on andexor.net.
- Timestamps are ISO-8601 UTC text. Dates are `YYYY-MM-DD`.
- Money is an integer number of cents plus a currency code (default `USD`).
- A field is required only when a row is meaningless without it. See master PRD section 7.

## System Reference Table (SRT)

The `srt` table, `(domain, code, label, description, sort_order, active)`, is the authoritative list of every finite-value code. Codes are UPPERCASE. Each column that holds a code has a pair of generated triggers that reject any value not present and active in `srt`. Adding or retiring a value is a migration that touches `srt`, never a code edit. The UI reads labels and order from `srt` through the API.

| Domain | Codes |
| --- | --- |
| `COMPANY_STAGE` | LEAD, PROSPECT, CUSTOMER, FORMER, DISQUALIFIED |
| `LEAD_SOURCE` | MANUAL, CONTACT_US, CSV, GRASS_SPIDER, REFERRAL, OTHER |
| `MEETING_MODE` | IN_PERSON, ONLINE |
| `RECOMMENDATION` | REACH_OUT, MAYBE, SKIP |
| `CONTACT_ROLE` | DECISION_MAKER, INFLUENCER, BILLING, TECHNICAL, OTHER |
| `SERVICE_CATEGORY` | TECHNICAL, BUSINESS |
| `ENRICHMENT_SOURCE` | MANUAL, AI, GRASS_SPIDER, CONTACT_US, CSV, API |
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
| `USER_ROLE` | ADMIN, MEMBER, READER |

Services, rubric criteria, AI models, and settings are not SRT domains. They are ordinary tables because Ed edits them in the UI.

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

## Rubric answers and `config_json`

`rubric_criterion.config_json` says how an answer becomes points between 0 and 1. It is optional.

| Answer type | Stored `value` | `config_json` | Points |
| --- | --- | --- | --- |
| `YES_NO` | `YES` or `NO` | `{"invert": true}` to make No the good answer | Yes = 1, No = 0 |
| `RATING` | `0` to `5` | `{"invert": true}` to make 0 the good answer | value ÷ 5 |
| `NUMBER` | the number | `{"bands": [{"min": 0, "max": 10, "points": 0.5}, ...]}`; `max: null` means no upper limit | the matching band's points; 0 if none |
| `CHOICE` | a choice code | `{"choices": [{"code": "X", "label": "...", "points": 1.0}, ...]}` | the choice's points |

An unanswered criterion has no row. The scoring formulas are in master PRD section 8.2.

## Research and scoring runs

- `ai_run.kind = 'RESEARCH'` writes `dossier` and rows in `ai_run_fact` with `decision = 'PROPOSED'`. Accepting a fact copies it into `enrichment_fact` with `source = 'AI'` and the run's id, and sets `decision = 'ACCEPTED'`.
- `ai_run.kind = 'SCORING'` writes rows in `ai_run_answer` and `ai_run_service` and the run's own `fit_score`, `need_score`, `confidence`, and `recommendation`. `input_run_id` names the research run whose dossier it read; NULL means it read the company's accepted facts.
- Applying a scoring run replaces the company's `rubric_answer` rows with the run's answers (`source = 'AI'`, `ai_run_id` set), recomputes `company_service` and the scores on `company`, and stamps `ai_run.applied_at`.
- Runs are never updated after they finish, except for `user_rating`, `user_note`, `applied_at`, and fact decisions. That is what makes them comparable.
- `ai_run.model_id_used` copies `ai_model.model_id` at run time, so changing a model row later does not rewrite history.

## Well-known enrichment keys

`enrichment_fact.key` is free text in lowercase snake case, so any tool can add facts without a schema change. These keys have agreed meanings; the list grows as tools are added.

| Key | Value |
| --- | --- |
| `location` | City and region as text |
| `employee_count` | A number |
| `current_provider` | Who handles their web and marketing today |
| `cms` | Website platform, for example WordPress |
| `core_web_vitals_mobile` | PASS or FAIL |
| `pagespeed_mobile`, `pagespeed_desktop` | 0 to 100 |
| `https` | YES or NO |
| `mobile_friendly` | YES or NO |
| `website_quality`, `hosting_quality`, `search_visibility`, `marketing_activity` | Short text |
| `registrar`, `domain_created`, `domain_expires` | From Registration Data Access Protocol (RDAP) |
| `nameservers`, `soa_primary`, `soa_serial` | From Domain Name System (DNS) |

## Documents

`document` holds metadata only. The file is an object in the R2 bucket at `r2_key` (`<company_id>/<document_id>`). The API writes the object first, then the row; it deletes the row first, then the object. `sha256` lets a download be verified.
