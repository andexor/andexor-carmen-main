-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: reliably_up_unknown.
-- "Is the site reliably up?" cannot be answered from one visit to a website: "reliably" needs
-- monitoring over months. Until it is decided how to measure it, no model is asked the question
-- and it stays unknown, which lowers confidence and changes no score. A person can still answer it.
-- Decided 2026-11-24, to be revisited: see NOTES.md and specs/021-measured-criteria/spec.md of
-- andexor-carmen-api. Data only: one row changes and no table does. Issue #30.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE rubric_criterion
   SET config_json = '{"measured":true}',
       help = 'Not answered by a model. One visit cannot show that a site is reliably up: that needs monitoring over months. Left unknown until it is decided how to measure it.'
 WHERE id = '00000000-0000-4000-8000-000000000213';
