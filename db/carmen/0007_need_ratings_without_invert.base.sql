-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: need_ratings_without_invert.
-- The scoring code of andexor-carmen-api now turns good answers into low need for every Need
-- question: Need is the share of the points that were not earned. The two rating questions in the
-- Need section carried "invert" to get that effect one question at a time. With the code doing it,
-- the setting would turn them around twice, so it is removed. Their scores do not change.
-- Data only: two rows change and no table does. Issue #28, and
-- specs/022-need-direction/spec.md of andexor-carmen-api.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE rubric_criterion
   SET config_json = NULL
 WHERE section = 'NEED'
   AND config_json = '{"invert":true}';
