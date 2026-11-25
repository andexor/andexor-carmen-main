-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: proposal_max_tries.
-- A new setting: the most models a proposals job tries for research, and again for scoring, when a
-- run fails. Data only: one row is added and no table changes. Issue #53, and the service proposals
-- of andexor-carmen-api.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

INSERT INTO setting (key, value, description) VALUES
  ('proposal.max_tries', '3', 'Most models a proposals job tries for research, and again for scoring, when a run fails');
