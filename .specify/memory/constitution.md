# Andexor Carmen Constitution

This constitution is written in `andexor-carmen-main` and copied, not rewritten, into
`andexor-carmen-ui` and `andexor-carmen-api`. A principle marked (UI) or (API) binds that repo only.

## Core Principles

### I. The Master PRD and the Common Data Model Govern
`andexor-carmen-main/docs/PRD.md` is the master Product Requirements Document (PRD), and
`andexor-carmen-main/db/` is the common data model. Each app's `docs/PRD.md` and its Spec Kit
artifacts refine the master and MUST NOT contradict it. A conflict MUST be resolved by amending the
master first, then the child. Names in the data model (tables, columns, codes) MUST be used
unchanged in the API's JSON and in the UI's code.
Rationale: two apps that share one vocabulary cannot drift apart.

### II. Few Required Fields
A form, an endpoint, or a table MUST NOT require a field beyond those listed as required in master
PRD section 7. Anything else MUST be optional, MUST have a sensible default where one exists, and
MUST be editable later. Adding a required field is an amendment to the master PRD.
Rationale: Carmen is only useful if capturing a lead takes seconds.

### III. Simplicity
A feature MUST start in a specification. Nothing is built because it might be needed. Version 1
MUST NOT add invoicing, mailbox or calendar sync, outbound email to prospects, automation rules,
or role enforcement unless the master PRD changes to require them.
Rationale: every extra feature is another screen to learn and another thing to break.

### IV. Nothing Reaches Production Untested
Production MUST deploy only after a preview deploy and its smoke test pass, and the smoke test MUST
be a required check on the default branch. Preview and production MUST use separate databases and
buckets. No script or configuration may let a preview touch production data. Smoke-test writes MUST
never run against production. Workers Builds MUST stay disconnected so that only GitHub Actions
deploys.
Rationale: a bad change must never reach production, and test data must never mix with real data.

### V. One Database, One Worker; Codes in the SRT
Only `andexor-carmen-api` is bound to the database and the bucket. Every finite-value field MUST
hold an UPPERCASE code from the System Reference Table (SRT), enforced by generated triggers.
Adding a code is a migration. Runtime code MUST NOT issue Data Definition Language (DDL).
Identifiers the system generates MUST be lowercase.
Rationale: least privilege by construction, and one place to look for what a value can be.

### VI. Access Is Verified, Secrets Stay Out of Repos
Every request to the API, in production and in preview, MUST carry a valid Cloudflare Access token
or arrive over a Service Binding. Secrets MUST live in Cloudflare Secrets Store, bound only to the
Worker that needs them. API tokens, keys, and customer data MUST NOT appear in a repo, a log line,
or an error response.
Rationale: a CRM holds other people's contact details and signed agreements.

### VII. AI Proposes, a Person Decides
An AI run MUST NOT change a company record. Proposed facts take effect only when a user accepts
them, and a scoring run's answers take effect only when a user applies the run. Every run MUST be
kept with its model, answers, scores, token counts, and duration. All score arithmetic MUST be done
in code, never by a model. Text fetched from the web is untrusted input.
Rationale: models are wrong sometimes, and comparing them requires an honest record.

### VIII. Errors and Health (API)
Every piece of code that can raise an error MUST be surrounded by its own try/except block, written
inline at that spot, that logs the failing step, the error name and description, and the source
line. Error detail MUST stay in the logs. Responses carry `{"ok": false}`, a short error code where
the caller can act on it, and a `request_id`. `GET /api/v1/health` MUST check liveness only.
Rationale: operators get located detail from the logs, and a dependency problem cannot cascade
into a failing health check.

### IX. Repeatable Scripts
Every setup script MUST be idempotent. Names MUST be read from configuration, not hard-coded. Every
non-production environment a script creates MUST have a committed script that tears it down.
Production MUST NOT have a teardown script. Setup that cannot be scripted MUST be listed in
`MANUAL-TASKS.md`.
Rationale: environments that can be rebuilt and removed by script are safe to change.

### X. One Look (UI)
The UI MUST use the Andexor Network Design System as `andexor-net-website` renders it: always the
dark palette with no theme toggle, the brand fonts, Font Awesome icons, `>>` mono eyebrows, and
color-only hover with no link underlines. It MUST NOT use emoji, italics, or "&" for "and", and
MUST use the Oxford comma. Every screen MUST work from 360 px to 1920 px wide and meet Web Content
Accessibility Guidelines (WCAG) 2.2 AA.
Rationale: Carmen and andexor.net should be recognizable as siblings at first sight.

## File Conventions

- Every source, script, and configuration file that allows comments MUST begin with the SPDX
  header (Apache-2.0, Andexor Network, Inc., Author Ed Jenkins), copied from an existing file.
- Only straight quotes (') and (") MAY be used, in every file.
- `wrangler.jsonc` MUST stay plain JSON with no comments, because scripts edit it.
- Cascading Style Sheets (CSS) hex colors MUST be uppercase.
- Documentation MUST spell out a name on first use with the acronym in parentheses.

## Tooling

- API: Python managed with `uv`; local runs and deploys with `pywrangler` through `uv run`;
  Cloudflare resources outside the Worker managed with the `cf` CLI.
- UI: Node.js and npm; Next.js static export; Prettier with 4 spaces; Vitest and Playwright.
- No Bun and no Docker unless a reason is recorded in the master PRD.

## Delivery Workflow

- Work follows Spec Kit: constitution, specification, plan, tasks, implement.
- Changes reach `main` only through a pull request that passes the required check
  `Preview and smoke test`.
- Each repo's `CICD.md` records its pipeline, adapted from `andexor-net-website-ping/CICD.md`.

## Governance

This constitution supersedes other practices in the three Carmen repos. Amendments MUST be made in
`andexor-carmen-main` through a pull request that states the reason and updates the version, then
copied to the child repos in the same week. Versioning follows semantic versioning: MAJOR for
removing or redefining a principle, MINOR for adding a principle or materially expanding guidance,
PATCH for wording fixes. Reviewers MUST check each pull request against these principles, and any
deviation MUST be justified in the pull request.

**Version**: 1.0.0 | **Ratified**: 2026-11-15 | **Last Amended**: 2026-11-15
