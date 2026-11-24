-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: research_max_pages_16.
-- A model without web search reads up to 16 pages of a company's own website, where it read up
-- to 8. Data only: one setting changes and no table does. Issue #22, and issue #33 of
-- andexor-carmen-api (specs/019-research-max-pages/spec.md there).
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE setting
   SET value = '16', updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now')
 WHERE key = 'ai.research.max_pages';
