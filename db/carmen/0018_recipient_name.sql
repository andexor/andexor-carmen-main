-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: recipient_name.
-- An email now shows a name with each address (specs/028-email-names/spec.md of
-- andexor-carmen-api), and the setting digest.recipient holds the recipient as "Name <address>".
-- This puts the name in front of the address. It changes nothing where the value already holds a
-- name: on 2026-11-26 the value was set by hand in the preview and the production database, which
-- left no trail. This migration is that trail, and it gives a database built from the migrations
-- the same value. Data only: one row changes. Issue #59.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE setting
   SET value = 'Ed Jenkins <' || value || '>',
       updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now')
 WHERE key = 'digest.recipient'
   AND value NOT LIKE '%<%';
