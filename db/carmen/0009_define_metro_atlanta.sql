-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: define_metro_atlanta.
-- "Metro Atlanta" had no definition, so a person or a model had to guess which places count.
-- Decided by Ed Jenkins on 2026-11-24: for Carmen it is our local territory, four of the five core
-- counties of the Atlanta Regional Commission: Fulton, DeKalb, Cobb, and Gwinnett. An address in
-- one of them is in metro Atlanta, and any other address is not. (The federal Office of Management
-- and Budget defines a much larger statistical area; that is not what is meant here.)
-- Data only: two rows change and no table does. Issue #32.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

UPDATE rubric_criterion
   SET help = 'Metro Atlanta means our local territory: Fulton, DeKalb, Cobb, and Gwinnett counties in Georgia. YES when the business address is in one of these four counties. NO when it is anywhere else.'
 WHERE id = '00000000-0000-4000-8000-000000000101';

UPDATE enrichment_key
   SET description = 'YES when the business address is in Fulton, DeKalb, Cobb, or Gwinnett County, Georgia. Answers: Is the business in metro Atlanta?'
 WHERE key = 'in_metro_atlanta';
