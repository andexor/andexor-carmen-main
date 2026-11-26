-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: uptime_settings.
-- Two more settings of the uptime checker, which were constants in code: how many sites one run of
-- the scheduler checks, and how many hours pass before a site is checked again. Data only. Issue #55.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

INSERT INTO setting (key, value, description) VALUES
  ('uptime.sites_per_run', '25', 'Most websites one run of the scheduler checks for uptime; the rest wait for the next run'),
  ('uptime.hours_between_checks', '23', 'Hours that must pass before a website is checked for uptime again; 23 gives one check a day');
