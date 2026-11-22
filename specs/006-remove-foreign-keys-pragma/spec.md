<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Remove the PRAGMA foreign_keys = ON convention

**Feature Branch**: `16-remove-foreign-keys-pragma`

**Created**: 2026-11-22

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #16. `db/README.md` said that `PRAGMA foreign_keys = ON` is set by the data-access layer on every request and at the top of each migration. We are not doing that. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: `db/README.md` MUST NOT say that `PRAGMA foreign_keys = ON` is set by the data-access layer or at the top of each migration.
- **FR-002**: `tools/new_migration.sh` MUST NOT write `PRAGMA foreign_keys = ON` into a new migration.
- **FR-003**: The data-access layer does not set `PRAGMA foreign_keys`.
- **FR-004**: Migrations `0001` and `0002` are already applied and keep their `PRAGMA foreign_keys = ON` line. They are not edited.
- **FR-005**: `tools/check_schemas.py` keeps `PRAGMA foreign_keys=ON` on its in-memory SQLite connection. That is a test setting, not a convention: plain SQLite leaves foreign keys off, and the test database must enforce them.

## Success criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: A search for `foreign_keys` outside `specs/` finds only migrations `0001` and `0002` and `tools/check_schemas.py`.
- **SC-003**: In a scratch copy, `tools/new_migration.sh` creates a file with no `PRAGMA` line.
