-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: digest_days.
-- The days of the week on which the daily digest is sent are a setting and not a constant in code.
-- The value is a list of three-letter day names in English, separated by commas. Data only: one
-- setting is added and no table changes. Issue #36, and the weekday digest of andexor-carmen-api.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

INSERT INTO setting (key, value, description) VALUES
  ('digest.days', 'MON,TUE,WED,THU,FRI', 'Days of the week the daily digest is sent');
