-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: enable_jev.
-- Enable the Jev model (TypeSafe), which was seeded disabled until a key and an adapter existed.
-- Both exist now, so it is on without a manual step. Data only: one row changes and no table
-- does. Issue #24, and issue #37 of andexor-carmen-api (specs/012-ai-adapter-typesafe/spec.md there).
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE ai_model
   SET active = 1,
       notes = 'Scoring only: answers the rubric from a dossier that another model wrote.'
 WHERE id = '00000000-0000-4000-8000-000000000006';
