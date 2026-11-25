<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Bring the migration notes and the manual task list up to date

**Feature Branch**: `40-docs-up-to-date`

**Created**: 2026-11-24

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #40. `CLAUDE.md` named the applied migrations up to `0005` and `db/README.md` up to `0012` by name, while 12 are applied, and both lists needed an edit for every new migration. The last manual task was done but not marked. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: `CLAUDE.md` and `db/README.md` MUST NOT list applied migrations one by one. They say that every migration on `main` is applied to both databases, the preview first and then production.
- **FR-002**: Both documents name the way to check: `python3 tools/migrate.py prev --dry-run` (or `prod`). `db/README.md` also says that `schema_migration` records each migration and when it was applied.
- **FR-003**: `db/README.md` keeps the one fact that is history: `0001` to `0010` were applied by hand, and later ones by the pipeline.
- **FR-004**: `MANUAL-TASKS.md` marks the default-branch ruleset task `[x]` with the date 2026-11-24. No manual task is left open.

## Success criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: `python3 tools/migrate.py prev --dry-run` and `prod --dry-run` report both databases up to date at versions 1 to 12.
- **SC-003**: The GitHub API shows the ruleset `andexor-default-ruleset` active on the default branch with the required check `Preview and smoke test`.
- **SC-004**: A search of `MANUAL-TASKS.md` for `[ ]` finds nothing.
