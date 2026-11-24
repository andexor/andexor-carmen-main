-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: import_max_rows.
-- The largest CSV import, in rows, is a setting and not a constant in code. 2,000 rows were
-- measured on the preview on 2026-11-24: about 30 seconds. Data only: one setting is added and no
-- table changes. Issue #34, and issue #40 of andexor-carmen-api (specs/013-csv-import/spec.md there).
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

INSERT INTO setting (key, value, description) VALUES
  ('import.max_rows', '2000', 'Most rows a CSV import accepts');
