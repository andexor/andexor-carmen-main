-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: task_link_triggers.
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.


-- A task names a company, a deal, and an agreement, each on its own, and the foreign keys check
-- only that each record exists. A task under one company could so point to another company's
-- deal: that deal then looks planned in the digest, and an edit of the task is recorded on the
-- wrong company's timeline. andexor-carmen-api checks the links of a task before it writes
-- (specs/042-task-links/spec.md there). These triggers are the same rule for every writer: a
-- task's deal and agreement are under the task's own company. A task with a deal or an agreement
-- has a company. A deal and an agreement never change company, so only task is watched.
-- Issue #79.

CREATE TRIGGER task_links_ins BEFORE INSERT ON task
WHEN (NEW.deal_id IS NOT NULL
      AND NEW.company_id IS NOT (SELECT company_id FROM deal WHERE id = NEW.deal_id))
  OR (NEW.agreement_id IS NOT NULL
      AND NEW.company_id IS NOT (SELECT company_id FROM agreement WHERE id = NEW.agreement_id))
BEGIN SELECT RAISE(ABORT, 'task link outside its company'); END;

CREATE TRIGGER task_links_upd BEFORE UPDATE OF company_id, deal_id, agreement_id ON task
WHEN (NEW.deal_id IS NOT NULL
      AND NEW.company_id IS NOT (SELECT company_id FROM deal WHERE id = NEW.deal_id))
  OR (NEW.agreement_id IS NOT NULL
      AND NEW.company_id IS NOT (SELECT company_id FROM agreement WHERE id = NEW.agreement_id))
BEGIN SELECT RAISE(ABORT, 'task link outside its company'); END;
