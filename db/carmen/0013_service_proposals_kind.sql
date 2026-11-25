-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: service_proposals_kind.
-- A new kind of notification: the email that proposes other services for a customer when a
-- one-time agreement is completed. Data only: one code is added and no table changes. Issue #50,
-- and the service proposals of andexor-carmen-api.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

INSERT INTO srt (domain, code, label, description, sort_order) VALUES
  ('NOTIFICATION_KIND', 'SERVICE_PROPOSALS', 'Service proposals', 'Other services to offer a customer, with the research and the scores behind them', 3);
