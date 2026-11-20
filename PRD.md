<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Andexor Carmen: Master PRD

Version 1.0 (FINAL) · 2026-11-18 · Author: Ed Jenkins (ed@andexor.net) · This is the initial Source of truth for the Andexor Carmen family of repositories, only used to seed initial requirements into Spec Kit.

Andexor Carmen is the Customer Relationship Management (CRM) system for Andexor Network. It follows a company from the first scrap of lead information, through research, qualification, and scoring, into meetings and deals, and on through signed agreements and the ongoing customer relationship.

The name is "CRM" said aloud: C-a-R-M-e-n.

## 1. Purpose

Carmen exists to answer two questions quickly and to remember everything afterward:

1. **Is this lead worth reaching out to?** Research the company, answer a short rubric, and get a Fit score, a Need score, and a plain call: Reach out, Maybe, or Skip.
2. **What do I do next, and for whom?** One Today view of follow-ups due, leads waiting to be scored, deals in motion, and agreements coming up for renewal.

It must do this with as little typing as possible. A lead can be created from a company name or a website alone. Every other field is optional and can be filled in later, by hand, by an import, by another tool, or by an AI model.

Carmen must:

1. Capture leads from four sources: manual quick-add, the Contact Us form on andexor.net, Comma-Separated Values (CSV) import, and Andexor Grass Spider.
2. Hold enriched lead data as facts, each with its source and date, from manual entry, from other tools, and from AI research.
3. Qualify each company against a rubric that is organized by service, covers only the services Andexor offers when computing Need, and can be edited without a deploy.
4. Score each company for Fit and for Need, and let research and scoring be run many times with different AI models so the models can be compared.
5. Track prospects as they become known: contacts, meetings, notes, tasks, and one or more deals per company.
6. Manage customers: Master Services Agreements (MSAs), Statements of Work (SOWs), and other agreements, under one-time, monthly retainer, performance-based, and pay-as-you-go engagement models, with the signed documents stored in Carmen.
7. Remind: a daily digest email of follow-ups, and alerts before an agreement ends or renews.

**Out of scope for version 1:** invoicing, payments, and revenue reporting; sending email to prospects or syncing a mailbox or calendar; marketing automation and sequences; generating agreement documents; e-signature; customer-facing portals; multi-user roles beyond the data model's readiness for them (section 6).

## 2. Naming convention and repository map

Names follow the standing Andexor convention (`andexor-<system>-<tier>`, governing repo `-main`). Everything lives in the `andexor` GitHub organization. All three repos are public.

| Repo | Role | Deploys |
| --- | --- | --- |
| `andexor-carmen-main` | Governing repo: this PRD, the common data model (`db/`), the API contract (`api/`), diagrams, and the Spec Kit constitution | Nothing |
| `andexor-carmen-ui` | Front-end web app (Next.js) | Worker `andexor-carmen-ui` |
| `andexor-carmen-api` | Back-end services (FastAPI) and the only owner of the database | Worker `andexor-carmen-api` |

| Resource | Production | Preview |
| --- | --- | --- |
| Hostname | `carmen.andexor.net` | `carmen-preview.andexor.net` |
| UI Worker | `andexor-carmen-ui` | `andexor-carmen-ui-preview` |
| API Worker | `andexor-carmen-api` | `andexor-carmen-api-preview` |
| Route to the API | `carmen.andexor.net/api/*` | `carmen-preview.andexor.net/api/*` |
| Route to the UI | `carmen.andexor.net/*` | `carmen-preview.andexor.net/*` |
| D1 database | `andexor-carmen-api-prod` | `andexor-carmen-api-prev` |
| R2 bucket (documents) | `andexor-carmen-api-prod` | `andexor-carmen-api-prev` |

## 3. System components

```
Browser ── Cloudflare Access ──> carmen.andexor.net
                                   ├─ /api/*  ─> andexor-carmen-api  (FastAPI, Python Worker)
                                   │               ├─ D1   (the common data model)
                                   │               ├─ R2   (agreement documents)
                                   │               ├─ AI   (Workers AI binding: open models)
                                   │               ├─ Claude API   (research with web search, scoring)
                                   │               ├─ TypeSafe API (Jev: scoring only)
                                   │               └─ Cron Trigger (daily digest, renewal alerts)
                                   └─ /*      ─> andexor-carmen-ui   (Next.js static export)

andexor-net-website-contact-us ── Service Binding: create_lead ──────────> andexor-carmen-api
Andexor Grass Spider ─────────── Service Binding or service token: ──────> andexor-carmen-api
                                  create_lead, add_facts
```

- The UI holds no data and no secrets. It calls the API on its own origin.
- The API is the only thing bound to the database and the bucket.
- Other Andexor systems never touch the database. They call two machine methods (section 9).

## 4. Platform and stack decisions

These follow `andexor-net-website`, `andexor-net-website-contact-us`, `andexor-net-website-ping`, and `andexor-glimpse-main`. Where those disagree, the more recent one wins and the difference is noted.

| Decision | Choice | Rationale or constraint |
| --- | --- | --- |
| Front-end framework | Latest Next.js as a static export (`output: "export"`), rendered client side, Node.js and npm | Same toolchain as `andexor-net-website`; a static export keeps the UI Worker to static assets only |
| Back-end framework | Latest FastAPI on Cloudflare Python Workers, managed with uv, built and deployed with pywrangler | Same as the ping and Contact Us services |
| Hosting | Cloudflare for everything: Workers, static assets, D1, R2, Workers AI, Access, Cron Triggers | One account, one bill |
| Database | One Cloudflare D1 database, owned by `andexor-carmen-api`. Separate preview and production databases | One database, one Worker |
| Documents | Cloudflare R2, private bucket, reached only through the API | Signed agreements are stored in Carmen (decision 2026-11-14) |
| Authentication | Cloudflare Access in front of `carmen.andexor.net`; the API also verifies the Access JSON Web Token (JWT) on every request | No passwords stored; defense in depth |
| Routing | Two Workers Routes per hostname: `carmen.andexor.net/api/*` to the API and `carmen.andexor.net/*` to the UI in production, and the same two routes on `carmen-preview.andexor.net` for the preview. Not Workers Custom Domains. Nothing is served from `workers.dev` | Standing convention; the existing `*.andexor.net` certificate covers both hostnames |
| API versioning | Every path starts `/api/v1/` | Same as the ping service |
| Finite values | UPPERCASE codes in the System Reference Table (SRT), enforced by triggers | Standing convention; a new stage or type is a migration, not a code change |
| Identifiers | Lowercase Universally Unique Identifiers (UUIDs) | Standing convention |
| AI | A provider interface with adapters for the Claude API, Cloudflare Workers AI, TypeSafe AI, and a stub; models are rows in the database (section 8) | Models must be addable and comparable without a code change |
| Scheduling | Cloudflare Cron Triggers on the API Worker | Daily digest and renewal alerts |
| Notifications | Email through a provider interface, stubbed until a provider is operational, exactly as in Andexor Glimpse | No provider chosen yet (Q5) |
| Secrets | Cloudflare Secrets Store, bound per Worker; never in a repo | Standing convention |
| Robots | `X-Robots-Tag: noindex, nofollow`, disallow-all `robots.txt`, robots meta tag, no sitemap | Internal tool |
| Observability | Workers Logs, Traces, and issue detection on, head sampling rate 1, structured JSON logs, a request ID in every error response | Standing convention |
| CI/CD | GitHub Actions: deploy to one shared preview, smoke test, then deploy to production; the smoke test is a required check (section 10) | Same gate as the ping service |
| Requirements | GitHub Spec Kit (`specify init --integration claude`) in all three repos; one constitution, written here and copied to the children | Standing convention |
| License and files | Apache-2.0, SPDX header on every file that allows comments, straight quotes only | Standing convention |

## 5. Lifecycle

### 5.1 One company record, three stages

There is one record per company. It is never converted, copied, or re-keyed. Its stage changes, and each stage simply makes more optional things relevant.

| Stage | Meaning | Enters when | What becomes relevant |
| --- | --- | --- | --- |
| `LEAD` | A company Carmen knows about | Created from any source | Enrichment facts, rubric answers, Fit and Need scores |
| `PROSPECT` | In conversation | The first deal is created, or set by hand | Contacts, meetings, notes, tasks, deals |
| `CUSTOMER` | Has an agreement in effect | The first agreement becomes `ACTIVE` | Agreements, documents, renewals |
| `FORMER` | Was a customer | The last agreement ends and none is active | History; can become `PROSPECT` again |
| `DISQUALIFIED` | Not worth pursuing | Set by hand, with a reason | Kept so it is not re-imported as new |

Stage changes that follow from a fact (first deal, first active agreement, last agreement ended) happen automatically and are written to the timeline. A stage can always be set by hand.

### 5.2 Deals

A company can have several deals at once, for example a website rebuild and a monthly retainer. Deal stages: `QUALIFYING`, `MEETING`, `PROPOSAL`, `NEGOTIATION`, `WON`, `LOST`. A lost deal records a reason. A deal names the services it covers and, optionally, an engagement model, a one-time value, and a monthly value.

### 5.3 Agreements

- A Master Services Agreement (MSA) carries the umbrella terms for a customer.
- A Statement of Work (SOW) describes specific work and points at its parent MSA. A change order points at its SOW.
- Any agreement can stand alone, for example a Non-Disclosure Agreement (NDA) signed before any deal.
- Statuses: `DRAFT`, `SENT`, `ACTIVE`, `COMPLETED`, `EXPIRED`, `TERMINATED`.

Engagement models, kept to the fields a CRM needs:

| Model | What Carmen records |
| --- | --- |
| `ONE_TIME` | Amount, paid once |
| `RETAINER` | Amount per month, start date, optional end date, auto-renewal, renewal notice days |
| `PERFORMANCE` | Performance terms as text (what is measured and how it is paid), optional base amount |
| `PAY_AS_YOU_GO` | Optional setup fee, start date; month to month, usage billed elsewhere |

Carmen records what was agreed. It does not calculate invoices or track payments.

## 6. Users, security, and access

- **Version 1 has one user: Ed.** Cloudflare Access protects `carmen.andexor.net` (the UI at `/` and the API at `/api/*` share one Access application), with an allow-list of email addresses. `carmen-preview.andexor.net` has its own Access application, covering `/` and `/api/*` the same way.
- **Ready for a team.** The `app_user` table and an `owner_id` on companies, deals, agreements, and tasks exist from the first migration. The API creates the `app_user` row for an allowed email on first sign-in. Roles (`ADMIN`, `MEMBER`, `READER`) are defined but, in version 1, every signed-in user is treated as `ADMIN`. Adding people later is an Access policy change plus role enforcement, with no data migration.
- **The API trusts nothing.** It verifies the Access JWT (signature, audience, expiry) on every request and takes the user's email from it. A request without a valid token gets 401, including on `carmen-preview.andexor.net`.
- **Machine callers.** Other Workers use Service Bindings. Anything that is not a Worker uses a Cloudflare Access service token. Neither path is reachable anonymously (section 9).
- **Documents.** The R2 bucket is private. Files are streamed through the API to a signed-in user; there are no public or pre-signed links.
- **Personal data.** Carmen holds business contact details for people at companies. It holds no payment card data and no passwords. Deleting a company deletes its contacts, facts, answers, runs, activities, and tasks. A company with agreements or documents cannot be deleted, only archived.
- **Secrets.** `carmen-claude-api-key`, `carmen-typesafe-api-key`, and any email provider key live in Cloudflare Secrets Store and are bound only to the API Worker.
- **DNS.** Two hand-made records: proxied `AAAA carmen` and proxied `AAAA carmen-preview`, each with content `100::`.

## 7. Data model

The common data model is the Data Definition Language (DDL) in [`db/carmen/0001_init.sql`](db/carmen/0001_init.sql), explained in [`db/README.md`](db/README.md). Both apps follow it: the API implements it, and the UI uses the same names for the same things. The table below is a summary; the DDL governs.

| Table | Holds | Required to create a row |
| --- | --- | --- |
| `company` | The lead, prospect, or customer; its stage, source, and current scores | A name or a website |
| `contact` | People at a company | A name or an email |
| `service` | The service catalog, each with an "offered" switch | A name |
| `enrichment_fact` | Enriched lead data as key and value, with source and date | Company, key, value |
| `rubric_criterion` | The rubric: Fit criteria, and Need criteria per service | Section, prompt |
| `rubric_answer` | The answers in effect for a company | Company, criterion, value (points are computed in code) |
| `company_service` | Need score per company per service | Computed |
| `ai_model` | The models offered for research and for scoring | Provider, model id, label |
| `ai_run` | One research run or one scoring run | Company, kind, model |
| `ai_run_fact`, `ai_run_answer`, `ai_run_service` | What a run proposed or answered, and the scores it produced | Written by the run |
| `deal`, `deal_service` | Potential sales and the services they cover | Company (the API fills in the name) |
| `agreement`, `agreement_service` | MSAs, SOWs, and other agreements | Company, type |
| `document` | Metadata for files in R2 | A company and a file (the API fills in the name, type, size, checksum, and storage key) |
| `activity` | The timeline: notes, calls, meetings, emails, automatic entries | Company |
| `task` | Next steps with optional due dates | A title |
| `import_batch` | One row per CSV upload | Written by the import |
| `notification` | Every digest and alert | Written by the scheduler |
| `setting` | Tunable values: score thresholds, digest hour, defaults | Seeded |
| `app_user` | People who can sign in | Created on first sign-in |
| `srt`, `schema_migration` | Reference codes; applied migrations | Seeded |

**The fewest-required-fields rule.** The right-hand column lists what a person or another system must supply. No table may require a field beyond those, other than values the system generates or computes itself (identifiers, timestamps, and the items noted in the column). Adding a required field needs a Spec Kit specification that says why. Defaults fill the rest: stage `LEAD`, source `MANUAL`, deal stage `QUALIFYING`, deal name "<company> deal", agreement status `DRAFT`, activity kind `NOTE`, task status `OPEN`.

**Duplicates.** A company's `domain` is derived from its website (lowercase, no scheme, no `www.`, no path). Two unarchived companies cannot share a domain. Every intake path matches on domain first and adds to the existing company instead of creating a second one.

## 8. Qualification, scoring, and AI

### 8.1 The rubric

- The rubric has two sections. **Fit** criteria apply to every company and ask whether it is Andexor's kind of customer. **Need** criteria belong to one service and ask how much the company needs that service.
- Each criterion has a prompt, a weight from 1 to 10, and its own answer type:

| Answer type | Answer | Points (0 to 1) |
| --- | --- | --- |
| `YES_NO` | Yes, No, or left unknown | Yes = 1, No = 0, or reversed per criterion |
| `RATING` | 0 to 5 | Answer divided by 5, or reversed per criterion |
| `NUMBER` | A number | Looked up in bands set on the criterion |
| `CHOICE` | One choice from a list | Set per choice |

- Criteria and services are edited in the UI. The migration seeds eight services from andexor.net and a small starter rubric to be replaced with real criteria (Q1).
- Each service has an **offered** switch. A service that is not offered can still be recorded as something a company needs, but it never counts toward the Need score.
- An unanswered criterion is unknown. Unknown never lowers a score; it lowers confidence.

### 8.2 The scores

All arithmetic is done in code, never by a model.

- **Fit** (0 to 100) = 100 × (sum of weight × points) ÷ (sum of weights), over answered Fit criteria.
- **Need per service** (0 to 100) = the same formula over that service's answered criteria.
- **Need** (0 to 100) = the highest Need per service among offered services. One strong need is enough to make a company worth a call.
- **Confidence** (0 to 100) = the weight of answered criteria ÷ the weight of all active criteria in play.
- **Recommendation**, from thresholds in `setting`: `REACH_OUT` when Fit and Need are both at or above 60 and confidence is at or above 40; `SKIP` when Fit or Need is below 30; otherwise `MAYBE`.

The UI shows Fit and Need separately, as two numbers and as a position on a two-by-two grid, with the per-service breakdown beneath.

### 8.3 Research and scoring runs

Research and scoring are two separate jobs, and each can be run any number of times per company with any model that supports the job.

- A **research run** gathers information about a company and produces a written dossier and a list of proposed facts. A model with web search searches for itself. For a model without web search, the API fetches the company's website pages and gives the model the text.
- A **scoring run** answers the rubric and produces Fit, Need, per-service Need, and confidence. It reads either the dossier of one research run or the company's accepted facts. One dossier can be scored by several models, which makes the comparison fair: same input, different judge.
- **Nothing a run produces changes the company until Ed says so.** He accepts or rejects proposed facts one at a time or all at once. He applies one scoring run, which makes its answers the answers in effect; he can then change any answer by hand.
- **Every run is kept**, with its model, the model identifier used at the time, its answers, its scores, input and output tokens, and duration. Ed can rate a run from 1 to 5 and leave a note.
- **Comparison.** For one company: runs side by side, criterion by criterion, with disagreements highlighted. Across companies: per model, the number of runs, average rating, average duration, average tokens, and how often its answers match the answers in effect (the answers Ed ended up keeping).

### 8.4 Models

| Model | Provider | Model id | Research | Scoring | At launch |
| --- | --- | --- | --- | --- | --- |
| Claude | Claude API | `claude-sonnet-5-5` | Yes, with web search | Yes | Enabled |
| gpt-oss-120b | Cloudflare Workers AI | `@cf/openai/gpt-oss-120b` | Yes, from fetched pages | Yes | Enabled |
| GLM-5.3 | Cloudflare Workers AI | `@cf/zai-org/glm-5.3` | Yes, from fetched pages | Yes | Enabled |
| Llama 3.3 70B | Cloudflare Workers AI | `@cf/meta/llama-3.3-70b-instruct-fp8-fast` | Yes, from fewer fetched pages (24,000-token context) | Yes | Enabled |
| Hermes | To be decided | To be decided | Yes, from fetched pages | Yes | Disabled: not in the Workers AI catalog on 2026-11-15 |
| Jev | TypeSafe AI | `jev-latest` | No | Yes | Disabled until Ed has a key |
| Stub | Built in | `stub` | Yes | Yes | Disabled in production; enabled in preview |

- **Models are configuration.** A model is one row in `ai_model` with its provider, model id, label, what it can do, and an enabled switch. Ed adds, changes, enables, and disables models in Settings. Only enabled models are offered when starting a run. Disabling a model never removes its past runs.
- Adding a model from a provider that already has an adapter needs no code change. A new provider needs a new adapter in the API.
- The research step sizes what it sends to each model's context window, so a small-context model reads fewer pages.
- **Jev** is a decision model: it answers questions that have a defined set of answers and returns a probability for each, and it does not write text. That matches rubric criteria closely: `YES_NO`, `RATING`, and `CHOICE` criteria are sent to Jev as its three question types. It has no research ability, so it always scores a dossier written by another model, and it returns no written rationale. Its vendor says it cannot do arithmetic or counting, so `NUMBER` criteria are not sent to it; the API answers those from accepted facts in code, and leaves them unknown when there is no fact.

## 9. Lead intake and machine methods

| Source | How it arrives | Notes |
| --- | --- | --- |
| Manual quick-add | UI form: name or website | Everything else optional |
| Contact Us form | `andexor-net-website-contact-us` calls `create_lead` over a Service Binding after it stores its own row | Name, email, phone, website, and the help text become a company, a primary contact, and a first note. Needs a small change in the Contact Us repo (Q4) |
| CSV import | UI upload: map columns, preview, import | Unmapped columns can become facts; duplicates are reported, not created |
| Andexor Grass Spider | Will call `create_lead` and `add_facts` | A future integration: Grass Spider is at an early stage. Carmen provides the methods now so nothing here has to change later. Domains will arrive with their Registration Data Access Protocol (RDAP) and Start of Authority (SOA) data as facts (Q6) |

Machine methods on `andexor-carmen-api`:

- `create_lead(source, name?, website?, contact?, note?, source_ref?, facts?)` returns the company id and whether it was created or matched.
- `add_facts(company_id or domain, facts[])` adds enrichment facts.

Both are idempotent on `(source, source_ref)`.

## 10. Environments and CI/CD

Both app repos use a gated CI/CD pipeline like this:

```
Pull request   -> deploy to the preview Worker -> smoke test -> required check
Merge to main  -> deploy to the preview Worker -> smoke test -> deploy to production -> health check
```

- One shared preview environment at `carmen-preview.andexor.net`, served by the Workers `andexor-carmen-ui-preview` and `andexor-carmen-api-preview` through Workers Routes; runs take turns. The `workers.dev` subdomain and `workers.dev` preview URLs are turned off for every Carmen Worker.
- Preview and production never share a database or a bucket. The smoke test's writes never run against production.
- The required status check `Preview and smoke test` and the default-branch ruleset are as in the ping service.
- Workers Builds stays disconnected; only GitHub Actions deploys.
- Each repo has its own Cloudflare API token.
- Create and teardown scripts for the preview environment are committed. Production has no teardown script.
- **Preview is gated too.** Unlike the ping service, Carmen's preview must not be public, because a CRM's preview is one mistake away from real data. Cloudflare Access is turned on for `carmen-preview.andexor.net`, and CI signs in with an Access service token held in GitHub secrets (R3).
- **Migrations.** The API's deploy workflow applies numbered migrations from `andexor-carmen-main/db/carmen/` to the preview database before the smoke test and to production before the production deploy. Runtime code never issues DDL.

## 11. User experience requirements

These bind the UI PRD.

- **Related at first sight.** Carmen uses the Andexor Network Design System as the website renders it: always dark, Andexor Blue and Old Gold, Play, Roboto, and Source Code Pro, `>>` mono eyebrows, Font Awesome icons, no emoji, no link underlines.
- **Phone matters.** Every screen works from 360 px to 1920 px. Quick-add, notes, and tasks are designed thumb-first.
- **Today first.** The home screen is the Today view.
- **Few required fields.** No form shows more than the fields required by section 7 as required. Optional fields are grouped and collapsed.
- **Fast capture.** A lead can be added in one field and one tap. A note can be added from any company screen without leaving it.
- **Long operations.** AI runs and imports return at once with a job and show progress; the user is never left looking at a frozen screen.
- **Accessibility.** Web Content Accessibility Guidelines (WCAG) 2.2 AA: keyboard operable, labeled controls, visible focus, sufficient contrast.
- **Dates and money.** Dates in the viewer's time zone. Money formatted from cents.

## 12. Risks, constraints, and open questions

| # | Risk or question | Why it matters | Resolution path |
| --- | --- | --- | --- |
| R1 | FastAPI on Python Workers: package support and cold start | Third-party Software Development Kits (SDKs) may not load on the Pyodide runtime | Call the Claude and TypeSafe APIs with plain HTTP requests, not SDKs; measure cold start in discovery |
| R2 | An AI run outlasts one request | Research with web search can take a minute or more | Return 202 with a run id; do the work with `waitUntil` or a Cloudflare Queue; the UI polls. Discovery task in the API PRD |
| R3 | Cloudflare Access on `carmen-preview.andexor.net`, with a service token from GitHub Actions | The preview gate depends on it | Verify in discovery; fall back to the API rejecting any request without a valid Access JWT or service token, which it does anyway |
| R4 | D1 limits | 10 GB per database and per-query limits | Far above CRM volume; documents live in R2, not D1 |
| R5 | AI answers can be wrong | A wrong answer can send Ed after a bad lead or away from a good one | Nothing is applied without Ed's action; every answer shows its source; comparison and ratings exist to learn which models to trust |
| R6 | AI cost | Web search research is paid per use | Tokens recorded per run; the comparison view shows cost drivers per model; no automatic or bulk runs in version 1 |
| R7 | Prompt injection from fetched pages | A company's website is untrusted text handed to a model | Models get no tools beyond search, output is parsed into fixed fields, and nothing is applied automatically |
| Q1 | The real rubric | The seeded criteria are placeholders | Ed writes the Fit criteria and the Need criteria per service in the UI once it exists, or supplies them for a seed migration |
| Q2 (closed 2026-11-15) | Hermes is not on Workers AI | Checked 2026-11-15: the Workers AI catalog lists 40 text models and none from Nous Research. Hermes would need another host and therefore another adapter | Resolved: launch with Claude plus three Workers AI models (`@cf/openai/gpt-oss-120b`, `@cf/zai-org/glm-5.3`, `@cf/meta/llama-3.3-70b-instruct-fp8-fast`). Hermes stays in the model list, disabled, until a host is chosen |
| Q3 | Jev access | Ed does not have Jev yet and intends to get it | The adapter is built against TypeSafe's published interface and the model stays disabled until a key is in Secrets Store |
| Q4 | Contact Us change | Sending form submissions to Carmen needs a Service Binding and a call in `andexor-net-website-contact-us` | A spec in that repo once `create_lead` exists |
| Q5 | Email provider | The digest and alerts are stubbed until a provider exists | Same decision as Andexor Glimpse; one provider for both |
| Q6 | Grass Spider transport | Grass Spider is a long-term project that has barely started, so nothing can call Carmen yet | Carmen ships `create_lead` and `add_facts` and the `GRASS_SPIDER` source code now; the transport (Service Binding or Access service token) is chosen when Grass Spider is ready to call them |
| Q7 (closed 2026-11-15) | Pay as you go | `PAY_AS_YOU_GO` was added to the three engagement models requested, to match the setup-fee-plus-month-to-month model in the services agreement | Resolved: keep it |
| Q8 | Which Claude model | The seed row uses a mid-tier Claude model; any Claude model id can be set in Settings | Ed picks after comparing runs |

## 13. Child PRDs

Each app has its own PRD in its own repo at `PRD.md`. A child may refine this document but not contradict it. A conflict is resolved by amending this document first.

| Child PRD | Repo | Owns |
| --- | --- | --- |
| Front end | `andexor-carmen-ui` | Screens, navigation, design system use, responsive behavior, accessibility, UI tests, UI pipeline |
| Back end | `andexor-carmen-api` | Endpoints, scoring engine, AI adapters and runs, intake, documents, scheduler, migrations runner, API pipeline |

Implementation order: `andexor-carmen-main` (this PRD, data model, constitution) → `andexor-carmen-api` → `andexor-carmen-ui`. Each child PRD ends with its Spec Kit feature backlog, in the order the features should be specified.

## 14. Readiness checklist

- [x] Name chosen: Andexor Carmen (2026-11-14)
- [x] Repo names chosen: `andexor-carmen-main`, `-ui`, `-api`
- [x] Users: Ed now, team later (section 6)
- [x] Record model: one company record with stages, plus separate deals (section 5)
- [x] Lead sources: manual, Contact Us, CSV, Grass Spider (section 9)
- [x] Agreements: tracked, with documents stored in R2 (section 5.3)
- [x] Rubric: mixed answer types (section 8.1)
- [x] Scores: Fit and Need, separately (section 8.2)
- [x] AI: repeatable research and scoring runs, model comparison, Claude plus three Workers AI models at launch, Hermes and Jev listed but disabled (sections 8.3, 8.4)
- [x] Relationship tracking: timeline, tasks, daily digest, renewal alerts
- [x] UI: Today view first, always dark, phone matters
- [x] Engagement models: one-time, retainer, performance-based, pay as you go
- [x] Common data model drafted and passing `tools/check_schemas.py`
- [X] Ed reviews this PRD and the two child PRDs
- [ ] Q1, Q3, Q4, Q5, Q6, Q8 answered (Q2 and Q7 closed)
- [ ] API contract (`api/carmen-api.openapi.yaml`) drafted from the API PRD
- [X] Repos created in the `andexor` organization and pushed
- [ ] Discovery: R1, R2, R3
