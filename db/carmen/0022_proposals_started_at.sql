-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: proposals_started_at.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.


-- The proposals job of an agreement researches and scores the company with paid models and sends
-- one email. Nothing recorded that it had been started, so a second start soon after the first (a
-- double click, two people, a retry after an error that was not one) paid again and sent a second
-- email. This column is the record: andexor-carmen-api sets it when it puts the job on the queue,
-- and refuses a second start within proposal.reuse_minutes unless a person asks for a fresh job.
-- A job also uses a research or scoring run again when it is newer than that. Issue #73.

ALTER TABLE agreement ADD COLUMN proposals_started_at TEXT;  -- when its proposals job was last put on the queue; NULL: never

INSERT INTO setting (key, value, description) VALUES
  ('proposal.reuse_minutes', '60', 'A proposals job started again within this many minutes is refused, and a research or scoring run newer than this is used again. 0 turns both off');
