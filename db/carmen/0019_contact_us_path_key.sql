-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: contact_us_path_key.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

-- The Contact Us service (andexor-net-website-contact-us) sends the page its form was on as a fact
-- with the key contact_us_path. Carmen stored it as an unknown key with no label. This adds it to
-- the well-known keys. A hint only: facts already stored under the key need no change. Issue #63.

INSERT INTO enrichment_key (key, label, value_type, description, sort_order) VALUES
  ('contact_us_path', 'Contact Us page', 'TEXT', 'The page of andexor.net the Contact Us form was sent from', 18);
