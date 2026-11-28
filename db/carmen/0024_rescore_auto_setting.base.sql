-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: rescore_auto_setting.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.


-- A change to the rubric, to a service, or to a score threshold rescores every company at once.
-- A manager who makes several such changes in one sitting pays for a full rescoring after each
-- one, and waits for it. This setting is the switch: while it is OFF, andexor-carmen-api stores
-- the change, records in rescore.requested that a rescoring is waiting, and rescores nothing,
-- not in the request and not in the scheduler. Setting it back to ON rescores once, at once,
-- when a rescoring is waiting. Issue #77.

INSERT INTO setting (key, value, description) VALUES
  ('rescore.auto', 'ON', 'ON: a change to the rubric rescores every company at once. OFF: the change is stored and the rescoring waits until this is ON again');
