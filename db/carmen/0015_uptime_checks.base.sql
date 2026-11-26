-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: uptime_checks.
-- Our own uptime measurement of a prospect's website. The scheduler of andexor-carmen-api checks
-- the website of each lead and prospect once a day for uptime.window_days days, keeps one row per
-- check, and stores the share of successful checks as the fact uptime_percent. The question
-- "Is the site reliably up?" becomes measured: code answers it from that fact, and 99 or more is
-- YES (decided 2026-11-26). Issue #55, and the uptime checker of andexor-carmen-api.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

-- ---------------------------------------------------------------------------
-- uptime_check: one check of a company's website by the scheduler.
-- ---------------------------------------------------------------------------
CREATE TABLE uptime_check (
    id          TEXT PRIMARY KEY CHECK (id = lower(id)),
    company_id  TEXT NOT NULL REFERENCES company(id) ON DELETE CASCADE,
    up          INTEGER NOT NULL CHECK (up IN (0,1)),  -- 1: the site answered below 500
    status      INTEGER,                   -- the HTTP status; NULL when there was no answer
    duration_ms INTEGER,
    detail      TEXT,                      -- why it counts as down, in words safe to show
    checked_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);
CREATE INDEX uptime_check_company_idx ON uptime_check(company_id, checked_at);

INSERT INTO srt (domain, code, label, description, sort_order) VALUES
  ('ENRICHMENT_SOURCE', 'UPTIME_CHECK', 'Uptime check', 'Measured by the scheduled uptime checker', 7);

INSERT INTO enrichment_key (key, label, value_type, description, sort_order) VALUES
  ('uptime_percent', 'Uptime, percent', 'NUMBER', '0 to 100: the share of successful uptime checks. Answers: Is the site reliably up?', 15);

INSERT INTO setting (key, value, description) VALUES
  ('uptime.window_days', '14', 'Days a company''s website is checked for uptime, once a day, before the checks stop');

UPDATE rubric_criterion
   SET enrichment_key = 'uptime_percent',
       config_json = '{"yes_at":99}',
       help = 'Not answered by a model. Measured by the uptime checker: the fact uptime_percent is the share of successful daily checks, and 99 or more is YES.'
 WHERE id = '00000000-0000-4000-8000-000000000213';
