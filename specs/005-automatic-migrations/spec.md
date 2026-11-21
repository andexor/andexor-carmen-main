<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Automatic migrations and tooling fixes

**Feature Branch**: `14-automatic-migrations`

**Created**: 2026-11-21

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #14. The review of the tooling after migration 0002 found that the SRT column list in `build_schema.sh` rewrites applied migrations when it grows, and that the diagrams and checks read only `0001`. Where this spec and an earlier document differ, this spec governs.

## Change 1: a migration never changes an existing SQL file

### Requirements

- **FR-001**: A migration is one hand-written file, `db/carmen/NNNN_name.base.sql`, created by `tools/new_migration.sh name`, which picks the next number.
- **FR-002**: `tools/build_schema.py` builds `NNNN_name.sql` from the base file. It generates the System Reference Table (SRT) insert and update triggers for each column whose definition carries a `-- SRT domain: X` comment, in a `CREATE TABLE` or on an `ALTER TABLE ... ADD COLUMN` line, and only from the comments in that same file. No list of columns exists anywhere else.
- **FR-003**: A migration whose `.sql` is already on `origin/main` (or `HEAD` when `origin/main` is missing) is never rebuilt.
- **FR-004**: `tools/check_schemas.py` MUST fail when any `.sql` or `.base.sql` file on `origin/main` differs from the working copy, when a built file is out of date, or when a comment has no triggers or a trigger has no comment.
- **FR-005**: The update trigger checks a value only when it changes (as in migration 0002).

## Change 2: `schema_migration` drives applying

### Requirements

- **FR-006**: `python3 tools/migrate.py prev|prod [--dry-run]` finds the database by name, reads `schema_migration`, and applies each pending migration in numeric order. The database must hold exactly the first k migrations, and the repo's numbers must run 1, 2, 3 with no gaps, otherwise it stops.
- **FR-007**: Each file runs as one batch (one transaction in D1) followed by `INSERT OR IGNORE INTO schema_migration`. Files `0001` and `0002` insert their own rows, so the runner uses `OR IGNORE`. Later files MUST NOT insert into `schema_migration`.
- **FR-008**: Preview first, then production.

## Change 3: everything reads every migration

### Requirements

- **FR-009**: `tools/gen_erd.py` and `tools/check_schemas.py` load every built migration in order. The tests load each migration the way the runner sends it.
- **FR-010**: `tools/gen_srt_triggers.py` and the column list in `build_schema.sh` are removed.

## Change 4: tooling fixes

### Requirements

- **FR-011**: `db/README.md` says `tools/migrate.py` records a migration and that SVG diagrams go to `doc/uml/images` (as `plantuml.sh` does).
- **FR-012**: `install-plantuml.sh` stops on any error, uses `curl -f`, and checks the jar against a pinned SHA-256.
- **FR-013**: `plantuml.sh` renders into `doc/uml/images.new` and replaces `doc/uml/images` only after rendering succeeds.

## Success criteria

- **SC-001**: `python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: In a scratch copy, a new `0003` with a new table and an `ALTER TABLE ... ADD COLUMN`, both SRT-commented, builds with its triggers, passes the checks, and leaves `0001` and `0002` untouched. Editing `0001_init.base.sql` makes the check fail.
- **SC-003**: `migrate.py prev --dry-run` and `migrate.py prod --dry-run` report both databases up to date at versions 1 and 2.
- **SC-004**: With Java missing, `plantuml.sh` fails and keeps all 27 images.
