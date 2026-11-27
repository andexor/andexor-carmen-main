-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: shared_hosts_setting.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

-- Sites that many businesses share: a page there (facebook.com/joes-plumbing) does not say which
-- business it is. andexor-carmen-api gives a company on such a site no domain, so that two
-- businesses on one site are never taken for the same company, in a lead, an import, or by hand.
-- The list is a setting so that it can be changed without a code change (decided 2026-11-27).
-- A host name covers its subdomains: google.com covers sites.google.com. Issue #67.

INSERT INTO setting (key, value, description) VALUES
  ('company.shared_hosts', 'facebook.com,fb.com,instagram.com,linkedin.com,x.com,twitter.com,youtube.com,tiktok.com,yelp.com,linktr.ee,nextdoor.com,pinterest.com,google.com', 'Sites shared by many businesses, separated by commas. A company whose website is a page there gets no domain');
