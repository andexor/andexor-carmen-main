# Andexor Carmen Constitution

This constitution is written in `andexor-carmen-main` and copied, not rewritten, into
`andexor-carmen-ui` and `andexor-carmen-api`. A principle marked (UI) or (API) binds that repo only.

## Core Principles

### I. The Master PRD and the Common Data Model Govern
`andexor-carmen-main/PRD.md` is the master Product Requirements Document (PRD), and
`andexor-carmen-main/db/` is the common data model. The master PRD and each app's `PRD.md` seed the
initial requirements and are frozen after their first commit; they MUST NOT be edited afterward. New
requirements, and any change to what a PRD says, MUST go through Spec Kit. Where a Spec Kit artifact
and a PRD differ, the Spec Kit artifact governs. Spec Kit artifacts MUST NOT contradict this
constitution. Names in the data model (tables, columns, codes) MUST be used unchanged in the API's
JSON and in the UI's code.
Rationale: two apps that share one vocabulary cannot drift apart, and one living source of
requirements cannot disagree with itself.

### II. Few Required Fields
A form, an endpoint, or a table MUST NOT require a field beyond those listed as required in master
PRD section 7. Anything else MUST be optional, MUST have a sensible default where one exists, and
MUST be editable later. Adding a required field MUST be done through a Spec Kit specification that
says why.
Rationale: Carmen is only useful if capturing a lead takes seconds.

### III. Simplicity
A feature MUST start in a specification. Nothing is built because it might be needed. Version 1
MUST NOT add invoicing, mailbox or calendar sync, outbound email to prospects, or automation rules
unless a Spec Kit specification requires them.
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
hold an UPPERCASE code from the System Reference Table (SRT), enforced by generated triggers, and
its column definition MUST carry a `-- SRT domain: X` comment naming the domain.
Adding a code is a migration. Runtime code MUST NOT issue Data Definition Language (DDL).
Identifiers the system generates MUST be lowercase.
Rationale: least privilege by construction, and one place to look for what a value can be.

### VI. Access Is Verified, Secrets Stay Out of Repos
Every request to the API, in production and in preview, MUST carry a valid Cloudflare Access token
or arrive over a Service Binding. Secrets MUST live in Cloudflare Secrets Store, bound only to the
Worker that needs them. API tokens, keys, and customer data MUST NOT appear in a repo, a log line,
or an error response. The API MUST enforce the signed-in user's role: READER reads anything and
changes nothing; MEMBER reads and changes records but cannot delete anything, change users,
settings, the rubric, the service catalog, or the AI model list; ADMIN can do anything.
Rationale: a CRM holds other people's contact details and signed agreements.

### VII. AI Proposes, a Person Decides
An AI run MUST NOT change a company record. Proposed facts take effect only when a user accepts
them, and a scoring run's answers take effect only when a user applies the run. Every run MUST be
kept with its model, answers, scores, token counts, and duration. All score arithmetic MUST be done
in code, never by a model. Text fetched from the web is untrusted input.
Rubric questions, answers, and enrichment facts MUST be worded positively, so that yes, true, or a
high value is always the good outcome (for example "Is the site mobile friendly?"). A need is
identified where an answer is false or low. The scoring and matching code, never a person, MUST do
that translation, and a person MUST NOT have to invert anything in their head.
Rationale: models are wrong sometimes, and comparing them requires an honest record. A person who
reads positive wording everywhere makes fewer mistakes than one who must flip some of it.

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
Production MUST NOT have a teardown script. Whenever a manual setup step is found that a person must do on a platform
such as Cloudflare or GitHub, it MUST be listed and tracked in `MANUAL-TASKS.md`. The file is created
when the first such step is found; a repo with no manual steps needs no such file.
Rationale: environments that can be rebuilt and removed by script are safe to change.

### X. One Look (UI)
The UI MUST use the Andexor Network Design System as `andexor-net-website` renders it: always the
dark palette with no theme toggle, the brand fonts, Font Awesome icons, `>>` mono eyebrows, and
color-only hover with no link underlines. It MUST NOT use emoji, italics, or "&" for "and", and
MUST use the Oxford comma. Every screen MUST work from 360 px to 1920 px wide and meet Web Content
Accessibility Guidelines (WCAG) 2.2 AA. Whenever a search finds more than one match, the UI MUST
present a list for the user to choose from.
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
- No Bun and no Docker unless a reason is recorded in a Spec Kit specification.
- Whenever scaffolding of a Next.js or FastAPI app begins, its initial version MUST be set to `1.0.0` (the version in `package.json` or `pyproject.toml`).

## Delivery Workflow

- Work follows Spec Kit: constitution, specification, plan, tasks, implement.
- Changes reach `main` only through a pull request that passes the required check
  `Preview and smoke test`.

## Governance

This constitution supersedes other practices in the three Carmen repos. Amendments MUST be made in
`andexor-carmen-main` through a pull request that states the reason and updates the version. Work proceeds on one repo
at a time: the child repos are not a concern until work begins in them, and each then receives the
current constitution, copied unchanged. Versioning follows semantic versioning: MAJOR for
removing or redefining a principle, MINOR for adding a principle or materially expanding guidance,
PATCH for wording fixes. Reviewers MUST check each pull request against these principles, and any
deviation MUST be justified in the pull request.

**Version**: 2.1.0 | **Ratified**: 2026-11-15 | **Last Amended**: 2026-11-21
