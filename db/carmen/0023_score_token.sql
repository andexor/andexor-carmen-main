-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: score_token.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.


-- The scores of a company are computed by andexor-carmen-api from its answers and the rubric, in
-- three steps: read, compute, write. Two writers at the same moment (two people answering, a
-- person answering during a full rescoring, two rubric changes) could leave scores that do not
-- follow from the stored answers, with no sign of it. This column is the version mark that ends
-- that: a writer notes it when it reads, its write goes through only while the mark is unchanged,
-- and every write of scores gives the company a new mark. A writer whose mark has moved reads
-- again and redoes its work. NULL: the scores were never written since this migration. Issue #75.

ALTER TABLE company ADD COLUMN score_token TEXT;  -- changes with every write of the scores; set by the API alone
