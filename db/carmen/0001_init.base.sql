-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- andexor-carmen-api: the Andexor Carmen database (the common data model).
-- Owner: andexor-carmen-api only. No other Worker is bound to this database.
-- Dialect: SQLite (Cloudflare D1). Migration 0001.
--
-- Conventions
--   * Identifiers the system generates are lowercase UUIDs (RFC 4122), no prefixes.
--   * Finite-value fields hold UPPERCASE codes defined in srt (System Reference
--     Table) and are enforced by triggers; see the bottom of this file.
--   * Timestamps are ISO-8601 UTC text, e.g. 2026-11-15T07:25:00Z. Dates are YYYY-MM-DD.
--   * Money is an integer number of cents plus a currency code.
--   * Required fields are kept to the minimum that makes a row meaningful.
--     Everything else is nullable and can be filled in later.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- srt: System Reference Table. The authoritative list of every finite-value
-- code used in this database. Adding a value is a migration that inserts into
-- srt, never a code change. The UI reads labels and ordering from here.
-- ---------------------------------------------------------------------------
CREATE TABLE srt (
    domain      TEXT NOT NULL,
    code        TEXT NOT NULL,
    label       TEXT NOT NULL,
    description TEXT NOT NULL,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    active      INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
    PRIMARY KEY (domain, code),
    CHECK (domain = upper(domain) AND code = upper(code))
);
CREATE INDEX srt_domain_idx ON srt(domain, sort_order);

INSERT INTO srt (domain, code, label, description, sort_order) VALUES
  ('USER_ROLE', 'ADMIN', 'Admin', 'Full access, including settings and users', 1),
  ('USER_ROLE', 'MEMBER', 'Member', 'Works leads, deals, and customers', 2),
  ('USER_ROLE', 'READER', 'Reader', 'Read-only', 3),

  ('COMPANY_STAGE', 'LEAD', 'Lead', 'Known company, not yet contacted or not yet engaged', 1),
  ('COMPANY_STAGE', 'PROSPECT', 'Prospect', 'In conversation; the first deal was created, or set by hand', 2),
  ('COMPANY_STAGE', 'CUSTOMER', 'Customer', 'Has an agreement in effect; the first one became ACTIVE', 3),
  ('COMPANY_STAGE', 'FORMER', 'Former customer', 'Was a customer; no active agreement', 4),
  ('COMPANY_STAGE', 'DISQUALIFIED', 'Disqualified', 'Not worth pursuing; reason recorded', 5),

  ('LEAD_SOURCE', 'MANUAL', 'Manual', 'Typed in through quick-add', 1),
  ('LEAD_SOURCE', 'CONTACT_US', 'Contact Us form', 'Submitted on andexor.net', 2),
  ('LEAD_SOURCE', 'CSV', 'CSV import', 'Imported from a spreadsheet', 3),
  ('LEAD_SOURCE', 'GRASS_SPIDER', 'Grass Spider', 'Discovered by Andexor Grass Spider', 4),
  ('LEAD_SOURCE', 'REFERRAL', 'Referral', 'Referred by a person or a customer', 5),
  ('LEAD_SOURCE', 'OTHER', 'Other', 'Anything else', 6),

  ('MEETING_MODE', 'IN_PERSON', 'In person', 'Meets in person', 1),
  ('MEETING_MODE', 'ONLINE', 'Online', 'Meets online only', 2),

  ('RECOMMENDATION', 'REACH_OUT', 'Reach out', 'Fit and Need are both high enough', 1),
  ('RECOMMENDATION', 'MAYBE', 'Maybe', 'One score is high, or confidence is low', 2),
  ('RECOMMENDATION', 'SKIP', 'Skip', 'Fit or Need is too low', 3),

  ('CONTACT_ROLE', 'DECISION_MAKER', 'Decision maker', 'Can say yes', 1),
  ('CONTACT_ROLE', 'INFLUENCER', 'Influencer', 'Shapes the decision', 2),
  ('CONTACT_ROLE', 'BILLING', 'Billing', 'Receives invoices', 3),
  ('CONTACT_ROLE', 'TECHNICAL', 'Technical', 'Hands-on technical contact', 4),
  ('CONTACT_ROLE', 'OTHER', 'Other', 'Anything else', 5),

  ('SERVICE_CATEGORY', 'TECHNICAL', 'Technical services', 'Technical services on andexor.net', 1),
  ('SERVICE_CATEGORY', 'BUSINESS', 'Business services', 'Business services on andexor.net', 2),

  ('ENRICHMENT_SOURCE', 'MANUAL', 'Manual', 'Typed in by a user', 1),
  ('ENRICHMENT_SOURCE', 'AI', 'AI research', 'Accepted from an AI research run', 2),
  ('ENRICHMENT_SOURCE', 'GRASS_SPIDER', 'Grass Spider', 'Posted by Andexor Grass Spider', 3),
  ('ENRICHMENT_SOURCE', 'CONTACT_US', 'Contact Us form', 'Carried in with a form submission', 4),
  ('ENRICHMENT_SOURCE', 'CSV', 'CSV import', 'Extra columns from an import', 5),
  ('ENRICHMENT_SOURCE', 'API', 'API', 'Posted by another tool', 6),

  ('PROPOSAL_STATUS', 'PROPOSED', 'Proposed', 'Waiting for a user to accept or reject', 1),
  ('PROPOSAL_STATUS', 'ACCEPTED', 'Accepted', 'Copied into the company record', 2),
  ('PROPOSAL_STATUS', 'REJECTED', 'Rejected', 'Kept with the run for comparison; not copied', 3),

  ('RUBRIC_SECTION', 'FIT', 'Fit', 'Is this my kind of customer', 1),
  ('RUBRIC_SECTION', 'NEED', 'Need', 'How much they need one service', 2),

  ('ANSWER_TYPE', 'YES_NO', 'Yes or no', 'Yes, no, or unknown', 1),
  ('ANSWER_TYPE', 'RATING', 'Rating 0 to 5', 'A whole number from 0 to 5', 2),
  ('ANSWER_TYPE', 'NUMBER', 'Number', 'A number mapped to points by bands', 3),
  ('ANSWER_TYPE', 'CHOICE', 'Pick list', 'One choice, each with its own points', 4),

  ('ANSWER_SOURCE', 'MANUAL', 'Manual', 'Answered by a user', 1),
  ('ANSWER_SOURCE', 'AI', 'AI scoring', 'Adopted from an AI scoring run', 2),

  ('DEAL_STAGE', 'QUALIFYING', 'Qualifying', 'Reached out; learning whether there is a deal', 1),
  ('DEAL_STAGE', 'MEETING', 'Meeting', 'Meeting scheduled or held', 2),
  ('DEAL_STAGE', 'PROPOSAL', 'Proposal', 'Proposal or statement of work sent', 3),
  ('DEAL_STAGE', 'NEGOTIATION', 'Negotiation', 'Terms under discussion', 4),
  ('DEAL_STAGE', 'WON', 'Won', 'Agreement signed', 5),
  ('DEAL_STAGE', 'LOST', 'Lost', 'Closed without a sale; reason recorded', 6),

  ('ENGAGEMENT_MODEL', 'ONE_TIME', 'One-time contract', 'Fixed scope, fixed fee', 1),
  ('ENGAGEMENT_MODEL', 'RETAINER', 'Monthly retainer', 'Recurring monthly fee', 2),
  ('ENGAGEMENT_MODEL', 'PERFORMANCE', 'Performance-based', 'Paid on results; terms in text', 3),
  ('ENGAGEMENT_MODEL', 'PAY_AS_YOU_GO', 'Pay as you go', 'Setup fee, then month-to-month usage billing', 4),

  ('AGREEMENT_TYPE', 'MSA', 'Master Services Agreement', 'Umbrella terms for a customer', 1),
  ('AGREEMENT_TYPE', 'SOW', 'Statement of Work', 'Specific work under an MSA', 2),
  ('AGREEMENT_TYPE', 'NDA', 'Non-Disclosure Agreement', 'Confidentiality terms', 3),
  ('AGREEMENT_TYPE', 'CHANGE_ORDER', 'Change order', 'Amends a statement of work', 4),
  ('AGREEMENT_TYPE', 'OTHER', 'Other', 'Any other agreement', 5),

  ('AGREEMENT_STATUS', 'DRAFT', 'Draft', 'Being written', 1),
  ('AGREEMENT_STATUS', 'SENT', 'Sent', 'With the customer for signature', 2),
  ('AGREEMENT_STATUS', 'ACTIVE', 'Active', 'Signed and in effect', 3),
  ('AGREEMENT_STATUS', 'COMPLETED', 'Completed', 'Work delivered; nothing further due', 4),
  ('AGREEMENT_STATUS', 'EXPIRED', 'Expired', 'End date passed without renewal', 5),
  ('AGREEMENT_STATUS', 'TERMINATED', 'Terminated', 'Ended early by either party', 6),

  ('AMOUNT_PERIOD', 'ONE_TIME', 'One time', 'Paid once', 1),
  ('AMOUNT_PERIOD', 'MONTHLY', 'Monthly', 'Paid every month', 2),

  ('ACTIVITY_KIND', 'NOTE', 'Note', 'Free-form note', 1),
  ('ACTIVITY_KIND', 'CALL', 'Call', 'Phone or video call', 2),
  ('ACTIVITY_KIND', 'MEETING', 'Meeting', 'In-person or online meeting', 3),
  ('ACTIVITY_KIND', 'EMAIL', 'Email', 'Email sent or received, logged by hand', 4),
  ('ACTIVITY_KIND', 'STAGE_CHANGE', 'Stage change', 'Company or deal stage changed (automatic)', 5),
  ('ACTIVITY_KIND', 'SCORE_CHANGE', 'Score change', 'Fit or Need score changed (automatic)', 6),
  ('ACTIVITY_KIND', 'SYSTEM', 'System', 'Import, AI research, or other automatic event', 7),

  ('TASK_STATUS', 'OPEN', 'Open', 'To do', 1),
  ('TASK_STATUS', 'DONE', 'Done', 'Completed', 2),
  ('TASK_STATUS', 'CANCELLED', 'Cancelled', 'No longer needed', 3),

  ('AI_PROVIDER', 'CLAUDE', 'Claude API', 'Anthropic Claude API with web search', 1),
  ('AI_PROVIDER', 'WORKERS_AI', 'Cloudflare Workers AI', 'A model on the Cloudflare account, through the AI binding', 2),
  ('AI_PROVIDER', 'TYPESAFE', 'TypeSafe AI', 'TypeSafe decision models such as Jev; scoring only', 3),
  ('AI_PROVIDER', 'STUB', 'Stub', 'Returns canned proposals; for tests and previews', 4),

  ('AI_RUN_KIND', 'RESEARCH', 'Research', 'Gathers facts about a company and writes a dossier', 1),
  ('AI_RUN_KIND', 'SCORING', 'Scoring', 'Answers the rubric from a dossier and computes Fit and Need', 2),

  ('RUN_STATUS', 'QUEUED', 'Queued', 'Accepted; not started', 1),
  ('RUN_STATUS', 'RUNNING', 'Running', 'In progress', 2),
  ('RUN_STATUS', 'SUCCEEDED', 'Succeeded', 'Finished', 3),
  ('RUN_STATUS', 'FAILED', 'Failed', 'Error; see error column and logs', 4),

  ('NOTIFICATION_KIND', 'DAILY_DIGEST', 'Daily digest', 'Follow-ups due and overdue', 1),
  ('NOTIFICATION_KIND', 'RENEWAL_ALERT', 'Renewal alert', 'An agreement is approaching its end or renewal date', 2),

  ('CHANNEL', 'EMAIL', 'Email', 'Email message', 1),

  ('NOTIFICATION_STATUS', 'STUBBED', 'Stubbed', 'Rendered to log only; no provider yet', 1),
  ('NOTIFICATION_STATUS', 'QUEUED', 'Queued', 'Handed to provider', 2),
  ('NOTIFICATION_STATUS', 'SENT', 'Sent', 'Provider confirmed', 3),
  ('NOTIFICATION_STATUS', 'FAILED', 'Failed', 'Provider error', 4);

-- ---------------------------------------------------------------------------
-- app_user: people who can sign in. Version 1 has one row (Ed). The table and
-- the owner_id columns exist so a team can be added later without a migration.
-- Identity comes from Cloudflare Access; email is the join key.
-- ---------------------------------------------------------------------------
CREATE TABLE app_user (
    id           TEXT PRIMARY KEY CHECK (id = lower(id)),
    email        TEXT NOT NULL UNIQUE CHECK (email = lower(email)),
    display_name TEXT,
    role         TEXT NOT NULL DEFAULT 'ADMIN',
    active       INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
    created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- ---------------------------------------------------------------------------
-- service: the service catalog, seeded from andexor.net. offered = 0 means
-- "they may need it, but I do not provide it"; it never counts toward Need.
-- ---------------------------------------------------------------------------
CREATE TABLE service (
    id          TEXT PRIMARY KEY CHECK (id = lower(id)),
    name        TEXT NOT NULL UNIQUE,
    category    TEXT,
    offered     INTEGER NOT NULL DEFAULT 1 CHECK (offered IN (0,1)),
    sort_order  INTEGER NOT NULL DEFAULT 0,
    active      INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1))
);

INSERT INTO service (id, name, category, sort_order) VALUES
  ('technical-seo', 'Technical SEO', 'TECHNICAL', 1),
  ('web-development', 'Web Development', 'TECHNICAL', 2),
  ('web-hosting', 'Web Hosting', 'TECHNICAL', 3),
  ('agentic-systems', 'Agentic Systems', 'TECHNICAL', 4),
  ('growth-marketing', 'Growth Marketing', 'BUSINESS', 5),
  ('lead-generation', 'Lead Generation', 'BUSINESS', 6),
  ('process-re-engineering', 'Process Re-engineering', 'BUSINESS', 7),
  ('cost-reduction', 'Cost Reduction', 'BUSINESS', 8);

-- ---------------------------------------------------------------------------
-- import_batch: one row per CSV upload or bulk push, so a bad import can be
-- found and undone.
-- ---------------------------------------------------------------------------
CREATE TABLE import_batch (
    id              TEXT PRIMARY KEY CHECK (id = lower(id)),
    source          TEXT NOT NULL,
    file_name       TEXT,
    row_count       INTEGER NOT NULL DEFAULT 0,
    created_count   INTEGER NOT NULL DEFAULT 0,
    duplicate_count INTEGER NOT NULL DEFAULT 0,
    error_count     INTEGER NOT NULL DEFAULT 0,
    created_by      TEXT REFERENCES app_user(id),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

-- ---------------------------------------------------------------------------
-- company: the one record that moves LEAD > PROSPECT > CUSTOMER. Nothing is
-- ever converted or re-keyed. The only requirement is a name or a website.
-- ---------------------------------------------------------------------------
CREATE TABLE company (
    id                  TEXT PRIMARY KEY CHECK (id = lower(id)),
    name                TEXT,
    website             TEXT,
    domain              TEXT CHECK (domain = lower(domain)),  -- derived from website; duplicate detection
    stage               TEXT NOT NULL DEFAULT 'LEAD',
    source              TEXT NOT NULL DEFAULT 'MANUAL',
    source_ref          TEXT,                                 -- e.g. contact_us row id, Grass Spider id
    import_batch_id     TEXT REFERENCES import_batch(id),
    phone               TEXT,
    email               TEXT,
    street              TEXT,
    city                TEXT,
    region              TEXT,
    postal_code         TEXT,
    country             TEXT,
    industry            TEXT,
    naics_code          TEXT,
    employee_count      INTEGER,
    meeting_mode        TEXT,
    summary             TEXT,
    fit_score           INTEGER CHECK (fit_score BETWEEN 0 AND 100),
    need_score          INTEGER CHECK (need_score BETWEEN 0 AND 100),
    confidence          INTEGER CHECK (confidence BETWEEN 0 AND 100),
    recommendation      TEXT,
    scored_at           TEXT,
    disqualified_reason TEXT,
    owner_id            TEXT REFERENCES app_user(id),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    archived_at         TEXT,
    CHECK (name IS NOT NULL OR website IS NOT NULL)
);
CREATE UNIQUE INDEX company_domain_uq ON company(domain) WHERE domain IS NOT NULL AND archived_at IS NULL;
CREATE INDEX company_stage_idx ON company(stage);
CREATE INDEX company_scores_idx ON company(fit_score, need_score);
CREATE INDEX company_name_idx ON company(name);

-- ---------------------------------------------------------------------------
-- contact: a person at a company. The only requirement is a name or an email.
-- ---------------------------------------------------------------------------
CREATE TABLE contact (
    id          TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id  TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    name        TEXT,
    title       TEXT,
    email       TEXT,
    phone       TEXT,
    role        TEXT,
    is_primary  INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0,1)),
    notes       TEXT,
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (name IS NOT NULL OR email IS NOT NULL)
);
CREATE INDEX contact_company_idx ON contact(company_id);
CREATE INDEX contact_email_idx ON contact(email);
CREATE UNIQUE INDEX contact_primary_uq ON contact(company_id) WHERE is_primary = 1;

-- ---------------------------------------------------------------------------
-- AI models. Research and scoring are separate jobs, and a model is offered
-- for each job only if its flag is set and it is enabled (active = 1). Models
-- are configured, enabled, and disabled in Settings. Adding a model is one row here (through
-- the Settings screen), provided its provider already has an adapter.
-- ---------------------------------------------------------------------------
CREATE TABLE ai_model (
    id           TEXT PRIMARY KEY CHECK (id = lower(id)),
    provider     TEXT NOT NULL,
    model_id     TEXT NOT NULL,              -- the provider's own model identifier
    label        TEXT NOT NULL,
    can_research INTEGER NOT NULL DEFAULT 0 CHECK (can_research IN (0,1)),
    can_score    INTEGER NOT NULL DEFAULT 0 CHECK (can_score IN (0,1)),
    web_search   INTEGER NOT NULL DEFAULT 0 CHECK (web_search IN (0,1)),
    active       INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
    sort_order   INTEGER NOT NULL DEFAULT 0,
    notes        TEXT,
    UNIQUE (provider, model_id),
    CHECK (can_research = 1 OR can_score = 1)
);

INSERT INTO ai_model (id, provider, model_id, label, can_research, can_score, web_search, active, sort_order, notes) VALUES
  ('00000000-0000-4000-8000-000000000001', 'CLAUDE', 'claude-sonnet-5-5', 'Claude', 1, 1, 1, 1, 1,
     'Research uses web search. Change model_id in Settings to try another Claude model.'),
  ('00000000-0000-4000-8000-000000000002', 'WORKERS_AI', '@cf/openai/gpt-oss-120b', 'gpt-oss-120b', 1, 1, 0, 1, 2,
     'No web search: the API fetches the company pages and the model reads them.'),
  ('00000000-0000-4000-8000-000000000003', 'WORKERS_AI', '@cf/zai-org/glm-5.3', 'GLM-5.3', 1, 1, 0, 1, 3,
     'No web search in version 1: reads fetched pages. Needs the Workers Paid plan.'),
  ('00000000-0000-4000-8000-000000000004', 'WORKERS_AI', '@cf/meta/llama-3.3-70b-instruct-fp8-fast', 'Llama 3.3 70B', 1, 1, 0, 1, 4,
     'Small context (24,000 tokens): research reads fewer pages than the other models.'),
  ('00000000-0000-4000-8000-000000000005', 'WORKERS_AI', '@hf/nousresearch/hermes-2-pro-mistral-7b', 'Hermes', 1, 1, 0, 0, 5,
     'Disabled: not in the Workers AI catalog on 2026-11-15. Set the model id and enable it when a host is available.'),
  ('00000000-0000-4000-8000-000000000006', 'TYPESAFE', 'jev-latest', 'Jev', 0, 1, 0, 0, 6,
     'Scoring only. Disabled until a TypeSafe key is in Secrets Store.'),
  ('00000000-0000-4000-8000-000000000009', 'STUB', 'stub', 'Stub (canned results)', 1, 1, 0, 0, 99,
     'For tests and the preview environment. The preview setup script enables it.');

-- ---------------------------------------------------------------------------
-- ai_run: one research run or one scoring run, for one company, by one model.
-- A company can have any number of runs, so models can be compared.
--   RESEARCH: writes a dossier and proposes facts (ai_run_fact).
--   SCORING:  answers the rubric (ai_run_answer) from the dossier of
--             input_run_id, or from the accepted facts when input_run_id is
--             NULL, and stores the Fit and Need scores it produced.
-- Nothing in a run changes the company record until a user accepts facts or
-- applies a scoring run.
-- ---------------------------------------------------------------------------
CREATE TABLE ai_run (
    id             TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id     TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    kind           TEXT NOT NULL,
    ai_model_id    TEXT NOT NULL REFERENCES ai_model(id),
    model_id_used  TEXT,                     -- copy of ai_model.model_id at run time
    input_run_id   TEXT REFERENCES ai_run(id) ON DELETE SET NULL,
    status         TEXT NOT NULL DEFAULT 'QUEUED',
    dossier        TEXT,                     -- RESEARCH: the written findings
    fit_score      INTEGER CHECK (fit_score BETWEEN 0 AND 100),
    need_score     INTEGER CHECK (need_score BETWEEN 0 AND 100),
    confidence     INTEGER CHECK (confidence BETWEEN 0 AND 100),
    recommendation TEXT,
    input_tokens   INTEGER,
    output_tokens  INTEGER,
    duration_ms    INTEGER,
    user_rating    INTEGER CHECK (user_rating BETWEEN 1 AND 5),  -- how good was this run
    user_note      TEXT,
    applied_at     TEXT,                     -- SCORING: when its answers became the company's answers
    requested_by   TEXT REFERENCES app_user(id),
    error          TEXT,
    created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    started_at     TEXT,
    finished_at    TEXT,
    CHECK (input_run_id IS NULL OR kind = 'SCORING')
);
CREATE INDEX ai_run_company_idx ON ai_run(company_id, kind, created_at);
CREATE INDEX ai_run_model_idx ON ai_run(ai_model_id, kind);

-- Facts a research run proposes. Accepting one copies it into enrichment_fact.
CREATE TABLE ai_run_fact (
    id         TEXT PRIMARY KEY CHECK (id = lower(id)),
    ai_run_id  TEXT NOT NULL REFERENCES ai_run(id) ON DELETE CASCADE,
    key        TEXT NOT NULL CHECK (key = lower(key)),
    value      TEXT NOT NULL,
    source_url TEXT,
    decision   TEXT NOT NULL DEFAULT 'PROPOSED'
);
CREATE INDEX ai_run_fact_idx ON ai_run_fact(ai_run_id);

-- ---------------------------------------------------------------------------
-- enrichment_fact: enriched lead data as key and value pairs, so any tool can
-- post anything without a schema change. Each fact records where it came from.
-- Well-known keys are documented in db/README.md.
-- ---------------------------------------------------------------------------
CREATE TABLE enrichment_fact (
    id            TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id    TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    key           TEXT NOT NULL CHECK (key = lower(key)),
    value         TEXT NOT NULL,
    source        TEXT NOT NULL DEFAULT 'MANUAL',
    source_detail TEXT,                      -- URL, tool name, or note
    ai_run_id     TEXT REFERENCES ai_run(id) ON DELETE SET NULL,
    observed_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
CREATE INDEX enrichment_company_idx ON enrichment_fact(company_id, key, observed_at);

-- ---------------------------------------------------------------------------
-- Qualification rubric. FIT criteria apply to every company. NEED criteria
-- belong to one service. Each criterion picks its own answer type; config_json
-- says how an answer becomes points between 0 and 1 (see db/README.md).
-- ---------------------------------------------------------------------------
CREATE TABLE rubric_criterion (
    id             TEXT PRIMARY KEY CHECK (id = lower(id)),
    section        TEXT NOT NULL,
    service_id     TEXT REFERENCES service(id),
    prompt         TEXT NOT NULL,
    help           TEXT,
    answer_type    TEXT NOT NULL DEFAULT 'YES_NO',
    weight         INTEGER NOT NULL DEFAULT 1 CHECK (weight BETWEEN 1 AND 10),
    config_json    TEXT,
    enrichment_key TEXT,                     -- fact that usually answers this; hint for AI and UI
    sort_order     INTEGER NOT NULL DEFAULT 0,
    active         INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
    CHECK ((section = 'FIT' AND service_id IS NULL) OR (section = 'NEED' AND service_id IS NOT NULL))
);
CREATE INDEX rubric_criterion_idx ON rubric_criterion(section, service_id, sort_order);

-- The answers in effect for a company: typed by a user, or adopted from one
-- scoring run. The company's Fit and Need scores are computed from these.
CREATE TABLE rubric_answer (
    company_id   TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    criterion_id TEXT NOT NULL REFERENCES rubric_criterion(id),
    value        TEXT NOT NULL,               -- YES / NO, 0-5, a number, or a choice code
    points       REAL NOT NULL CHECK (points BETWEEN 0 AND 1),
    source       TEXT NOT NULL DEFAULT 'MANUAL',
    ai_run_id    TEXT REFERENCES ai_run(id) ON DELETE SET NULL,
    answered_by  TEXT REFERENCES app_user(id),
    answered_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (company_id, criterion_id)
);

-- The answers one scoring run gave. Kept forever so runs can be compared with
-- each other and with the answers in effect.
CREATE TABLE ai_run_answer (
    ai_run_id    TEXT NOT NULL REFERENCES ai_run(id) ON DELETE CASCADE,
    criterion_id TEXT NOT NULL REFERENCES rubric_criterion(id),
    value        TEXT NOT NULL,
    points       REAL NOT NULL CHECK (points BETWEEN 0 AND 1),
    probability  REAL CHECK (probability BETWEEN 0 AND 1),  -- the model's own confidence, when it reports one
    rationale    TEXT,                                      -- NULL for models that cannot write text
    PRIMARY KEY (ai_run_id, criterion_id)
);

-- The per-service Need scores one scoring run produced.
CREATE TABLE ai_run_service (
    ai_run_id   TEXT NOT NULL REFERENCES ai_run(id) ON DELETE CASCADE,
    service_id  TEXT NOT NULL REFERENCES service(id),
    need_score  INTEGER CHECK (need_score BETWEEN 0 AND 100),
    confidence  INTEGER CHECK (confidence BETWEEN 0 AND 100),
    PRIMARY KEY (ai_run_id, service_id)
);

-- Per-service Need score for a company, recomputed whenever an answer in effect changes.
CREATE TABLE company_service (
    company_id  TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    service_id  TEXT NOT NULL REFERENCES service(id),
    need_score  INTEGER CHECK (need_score BETWEEN 0 AND 100),
    confidence  INTEGER CHECK (confidence BETWEEN 0 AND 100),
    PRIMARY KEY (company_id, service_id)
);

INSERT INTO rubric_criterion (id, section, service_id, prompt, answer_type, weight, config_json, enrichment_key, sort_order) VALUES
  ('00000000-0000-4000-8000-000000000101', 'FIT', NULL, 'Is the business in metro Atlanta or willing to work online?', 'YES_NO', 3, NULL, 'location', 1),
  ('00000000-0000-4000-8000-000000000102', 'FIT', NULL, 'How many employees does it have?', 'NUMBER', 2,
     '{"bands":[{"min":0,"max":1,"points":0.4},{"min":2,"max":250,"points":1.0},{"min":251,"max":null,"points":0.3}]}', 'employee_count', 2),
  ('00000000-0000-4000-8000-000000000103', 'FIT', NULL, 'Can I reach a decision maker?', 'YES_NO', 3, NULL, NULL, 3),
  ('00000000-0000-4000-8000-000000000104', 'FIT', NULL, 'How well does their likely budget match my pricing?', 'RATING', 3, NULL, NULL, 4),
  ('00000000-0000-4000-8000-000000000105', 'FIT', NULL, 'Who handles their web and marketing today?', 'CHOICE', 2,
     '{"choices":[{"code":"NOBODY","label":"Nobody","points":1.0},{"code":"OWNER","label":"The owner, part time","points":0.9},{"code":"FREELANCER","label":"A freelancer","points":0.6},{"code":"AGENCY","label":"Another agency","points":0.3},{"code":"IN_HOUSE","label":"An in-house team","points":0.2}]}', 'current_provider', 5),
  ('00000000-0000-4000-8000-000000000201', 'NEED', 'technical-seo', 'Does the site fail Core Web Vitals on mobile?', 'YES_NO', 3, NULL, 'core_web_vitals_mobile', 1),
  ('00000000-0000-4000-8000-000000000202', 'NEED', 'technical-seo', 'How visible are they for their main search terms? (0 = invisible, 5 = dominant)', 'RATING', 3, '{"invert":true}', 'search_visibility', 2),
  ('00000000-0000-4000-8000-000000000203', 'NEED', 'web-development', 'Do they have no website, or one that looks out of date?', 'YES_NO', 4, NULL, 'website_quality', 1),
  ('00000000-0000-4000-8000-000000000204', 'NEED', 'web-development', 'Is the site hard to use on a phone?', 'YES_NO', 2, NULL, 'mobile_friendly', 2),
  ('00000000-0000-4000-8000-000000000205', 'NEED', 'web-hosting', 'Is the site slow, insecure, or often down?', 'YES_NO', 3, NULL, 'hosting_quality', 1),
  ('00000000-0000-4000-8000-000000000206', 'NEED', 'agentic-systems', 'Do they answer the same customer questions by hand, over and over?', 'YES_NO', 3, NULL, NULL, 1),
  ('00000000-0000-4000-8000-000000000207', 'NEED', 'growth-marketing', 'How active is their marketing today? (0 = none, 5 = very active)', 'RATING', 3, '{"invert":true}', 'marketing_activity', 1),
  ('00000000-0000-4000-8000-000000000208', 'NEED', 'lead-generation', 'Do they say they need more customers or more leads?', 'YES_NO', 4, NULL, NULL, 1),
  ('00000000-0000-4000-8000-000000000209', 'NEED', 'process-re-engineering', 'Do they describe manual, repetitive, or error-prone work?', 'YES_NO', 3, NULL, NULL, 1),
  ('00000000-0000-4000-8000-000000000210', 'NEED', 'cost-reduction', 'Are they paying for tools or vendors they could consolidate?', 'YES_NO', 3, NULL, NULL, 1);

-- ---------------------------------------------------------------------------
-- deal: one potential sale. A company can have several at once. The only
-- requirement is the company; the name defaults in the API.
-- ---------------------------------------------------------------------------
CREATE TABLE deal (
    id                    TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id            TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    name                  TEXT NOT NULL,
    stage                 TEXT NOT NULL DEFAULT 'QUALIFYING',
    engagement_model      TEXT,
    primary_contact_id    TEXT REFERENCES contact(id) ON DELETE SET NULL,
    one_time_value_cents  INTEGER CHECK (one_time_value_cents >= 0),
    monthly_value_cents   INTEGER CHECK (monthly_value_cents >= 0),
    currency              TEXT NOT NULL DEFAULT 'USD',
    expected_close_date   TEXT,
    closed_at             TEXT,
    lost_reason           TEXT,
    notes                 TEXT,
    owner_id              TEXT REFERENCES app_user(id),
    created_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
CREATE INDEX deal_company_idx ON deal(company_id);
CREATE INDEX deal_stage_idx ON deal(stage);

CREATE TABLE deal_service (
    deal_id    TEXT NOT NULL REFERENCES deal(id) ON DELETE CASCADE,
    service_id TEXT NOT NULL REFERENCES service(id),
    PRIMARY KEY (deal_id, service_id)
);

-- ---------------------------------------------------------------------------
-- agreement: a Master Services Agreement (MSA), a Statement of Work (SOW)
-- under it, or any other agreement. A SOW or change order points at its parent.
-- The only requirements are the company and the type.
-- ---------------------------------------------------------------------------
CREATE TABLE agreement (
    id                  TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id          TEXT NOT NULL REFERENCES company(id) ON DELETE RESTRICT,
    deal_id             TEXT REFERENCES deal(id) ON DELETE SET NULL,
    parent_agreement_id TEXT REFERENCES agreement(id) ON DELETE RESTRICT,
    type                TEXT NOT NULL,
    title               TEXT,
    status              TEXT NOT NULL DEFAULT 'DRAFT',
    engagement_model    TEXT,
    amount_cents        INTEGER CHECK (amount_cents >= 0),
    amount_period       TEXT,
    setup_fee_cents     INTEGER CHECK (setup_fee_cents >= 0),
    performance_terms   TEXT,                -- how results are measured and paid
    currency            TEXT NOT NULL DEFAULT 'USD',
    signed_date         TEXT,
    effective_date      TEXT,
    end_date            TEXT,
    auto_renews         INTEGER NOT NULL DEFAULT 0 CHECK (auto_renews IN (0,1)),
    renewal_notice_days INTEGER CHECK (renewal_notice_days >= 0),
    terminated_at       TEXT,
    notes               TEXT,
    owner_id            TEXT REFERENCES app_user(id),
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (parent_agreement_id IS NULL OR parent_agreement_id <> id)
);
CREATE INDEX agreement_company_idx ON agreement(company_id);
CREATE INDEX agreement_parent_idx ON agreement(parent_agreement_id);
CREATE INDEX agreement_end_idx ON agreement(status, end_date);

CREATE TABLE agreement_service (
    agreement_id TEXT NOT NULL REFERENCES agreement(id) ON DELETE CASCADE,
    service_id   TEXT NOT NULL REFERENCES service(id),
    PRIMARY KEY (agreement_id, service_id)
);

-- ---------------------------------------------------------------------------
-- document: metadata for a file held in Cloudflare R2. The bytes are never in
-- D1. Deleting a row is how the API knows to delete the object.
-- ---------------------------------------------------------------------------
CREATE TABLE document (
    id           TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id   TEXT NOT NULL REFERENCES company(id) ON DELETE RESTRICT,
    agreement_id TEXT REFERENCES agreement(id) ON DELETE SET NULL,
    file_name    TEXT NOT NULL,
    content_type TEXT NOT NULL,
    size_bytes   INTEGER NOT NULL CHECK (size_bytes >= 0),
    sha256       TEXT NOT NULL CHECK (sha256 = lower(sha256)),
    r2_key       TEXT NOT NULL UNIQUE,
    uploaded_by  TEXT REFERENCES app_user(id),
    uploaded_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
CREATE INDEX document_company_idx ON document(company_id);
CREATE INDEX document_agreement_idx ON document(agreement_id);

-- ---------------------------------------------------------------------------
-- activity: the timeline. Hand-logged notes, calls, meetings, and emails, plus
-- automatic entries for stage and score changes. Append-only in the API.
-- ---------------------------------------------------------------------------
CREATE TABLE activity (
    id          TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id  TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    deal_id     TEXT REFERENCES deal(id) ON DELETE SET NULL,
    contact_id  TEXT REFERENCES contact(id) ON DELETE SET NULL,
    kind        TEXT NOT NULL DEFAULT 'NOTE',
    body        TEXT,
    occurred_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    created_by  TEXT REFERENCES app_user(id),
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
CREATE INDEX activity_company_idx ON activity(company_id, occurred_at);

-- ---------------------------------------------------------------------------
-- task: a next step with an optional due date. The only requirement is a title.
-- ---------------------------------------------------------------------------
CREATE TABLE task (
    id           TEXT PRIMARY KEY CHECK (id = lower(id)),
    title        TEXT NOT NULL,
    company_id   TEXT REFERENCES company(id) ON DELETE CASCADE,
    deal_id      TEXT REFERENCES deal(id) ON DELETE SET NULL,
    agreement_id TEXT REFERENCES agreement(id) ON DELETE SET NULL,
    due_date     TEXT,
    status       TEXT NOT NULL DEFAULT 'OPEN',
    completed_at TEXT,
    owner_id     TEXT REFERENCES app_user(id),
    created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (status <> 'DONE' OR completed_at IS NOT NULL)
);
CREATE INDEX task_due_idx ON task(status, due_date);
CREATE INDEX task_company_idx ON task(company_id);

-- ---------------------------------------------------------------------------
-- notification: every digest and alert, whether stubbed or sent.
-- ---------------------------------------------------------------------------
CREATE TABLE notification (
    id           TEXT PRIMARY KEY CHECK (id = lower(id)),
    kind         TEXT NOT NULL,
    channel      TEXT NOT NULL DEFAULT 'EMAIL',
    recipient    TEXT NOT NULL,
    subject      TEXT,
    body         TEXT,
    status       TEXT NOT NULL DEFAULT 'STUBBED',
    agreement_id TEXT REFERENCES agreement(id) ON DELETE SET NULL,
    provider_ref TEXT,
    error        TEXT,
    created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    sent_at      TEXT
);
CREATE INDEX notification_created_idx ON notification(kind, created_at);

-- ---------------------------------------------------------------------------
-- setting: tunable values that are not finite codes (score thresholds, digest
-- hour, renewal lead time). Edited in the UI; no deploy needed.
-- ---------------------------------------------------------------------------
CREATE TABLE setting (
    key         TEXT PRIMARY KEY CHECK (key = lower(key)),
    value       TEXT NOT NULL,
    description TEXT NOT NULL,
    updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

INSERT INTO setting (key, value, description) VALUES
  ('score.reach_out.min_fit', '60', 'Fit at or above this, with Need at or above its threshold, means Reach out'),
  ('score.reach_out.min_need', '60', 'Need at or above this, with Fit at or above its threshold, means Reach out'),
  ('score.skip.max_fit', '30', 'Fit below this means Skip'),
  ('score.skip.max_need', '30', 'Need below this means Skip'),
  ('score.min_confidence', '40', 'Below this confidence a Reach out becomes a Maybe'),
  ('digest.hour_local', '7', 'Hour of the day the daily digest is sent'),
  ('digest.time_zone', 'America/New_York', 'Time zone for the digest hour and for due dates'),
  ('digest.recipient', 'ed@andexor.net', 'Where digests and alerts are sent'),
  ('renewal.default_notice_days', '30', 'Days before an end date to alert when an agreement sets none'),
  ('document.max_size_bytes', '26214400', 'Largest upload accepted (25 MiB)'),
  ('ai.default_research_model', '00000000-0000-4000-8000-000000000001', 'ai_model.id preselected for research'),
  ('ai.default_scoring_model', '00000000-0000-4000-8000-000000000001', 'ai_model.id preselected for scoring'),
  ('ai.research.max_pages', '8', 'Most pages the API fetches for a model without web search');

-- ---------------------------------------------------------------------------
-- schema_migration: which migrations have been applied.
-- ---------------------------------------------------------------------------
CREATE TABLE schema_migration (
    version     INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    applied_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
INSERT INTO schema_migration (version, name) VALUES (1, '0001_init');

-- ---------------------------------------------------------------------------
-- SRT enforcement triggers (generated by tools/gen_srt_triggers.py through
-- tools/build_schema.sh; never edit by hand).
-- ---------------------------------------------------------------------------
