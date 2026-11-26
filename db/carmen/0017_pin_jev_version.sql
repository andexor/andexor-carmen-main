-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: pin_jev_version.
-- Jev was called by the name jev-latest, an alias that moves to each new release, so its answers
-- could change with no change of ours. It is now called by a numbered version: jev-1.14.0, the
-- latest one on 2026-11-26 and the one jev-latest pointed to. The thresholds in andexor-carmen-api
-- were set against this version. A later version is a coordinated upgrade: read the release notes
-- first, then a new migration. Data only: one row changes. Issue #57, and
-- specs/027-pin-jev-version/spec.md of andexor-carmen-api.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE ai_model
   SET model_id = 'jev-1.14.0',
       notes = 'Scoring only: answers the rubric from a dossier that another model wrote. Pinned to a numbered version; an upgrade is a migration, made after the release notes were read.'
 WHERE id = '00000000-0000-4000-8000-000000000006';
