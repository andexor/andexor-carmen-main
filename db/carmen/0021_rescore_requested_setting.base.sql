-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: rescore_requested_setting.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.


-- A change to the rubric, to a service, or to a score threshold changes the scores of every
-- company. andexor-carmen-api stores such a change first and recomputes the scores after it. When
-- that recomputing failed, nothing tried again, and the stored scores stayed out of date with no
-- sign of it. This setting is the sign: the change sets it in the same transaction, the
-- recomputing empties it when it is done, and the scheduler recomputes when it finds it set.
-- Empty means that nothing is waiting. Issue #69.

INSERT INTO setting (key, value, description) VALUES
  ('rescore.requested', '', 'Set by Carmen when every score must be recomputed, and emptied when that is done. The scheduler recomputes while it is set');
