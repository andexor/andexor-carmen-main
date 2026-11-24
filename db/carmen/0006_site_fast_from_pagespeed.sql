-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: site_fast_from_pagespeed.
-- "Is the site fast?" becomes a measured criterion: it is answered by code from the fact
-- pagespeed_mobile, YES at 90 or more and NO below. The limit is Google's guidance for the
-- PageSpeed performance score: 90 or above is good, 50 to 89 needs improvement, below 50 is poor
-- (https://developers.google.com/speed/docs/insights/v5/about, read 2026-11-24).
-- Data only: one row changes and no table does. Issue #26, and issue #37 of andexor-carmen-api
-- (specs/021-measured-criteria/spec.md there).
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE rubric_criterion
   SET config_json = '{"yes_at":90}',
       help = 'Measured, not judged. YES when the PageSpeed score for mobile is 90 or more, which Google rates as good. 50 to 89 needs improvement and below 50 is poor.'
 WHERE id = '00000000-0000-4000-8000-000000000205';
