<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: Who applies a migration

**Feature Branch**: `71-who-applies-a-migration`

**Created**: 2026-11-27

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #71. On 2026-11-27, after the pull request for migration `0021` merged, Ed was pointed at `tools/migrate.py` although both databases were already up to date. This spec adds to `specs/009-docs-up-to-date/spec.md`. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: A migration is applied by hand with `python3 tools/migrate.py prev`, then `python3 tools/migrate.py prod`, before its pull request is opened. `CLAUDE.md` says so.
- **FR-002**: `CLAUDE.md` says that the pipeline of `andexor-carmen-api` also applies whatever is pending on this repo's `main` each time it runs: a pull request there migrates the preview database, and a push to its `main` migrates production.
- **FR-003**: `CLAUDE.md` says that a merge in this repo does not start that pipeline, and that no workflow in this repo touches a database.
- **FR-004**: After a merge, nobody asks for the migration to be applied or suggests it. The migration state is brought up only when there is evidence that a migration failed to apply.

## Acceptance Scenarios

1. **Given** a pull request with a migration that has merged,\
   **When** the branches are cleaned up,\
   **Then** nothing is said about applying the migration.

## Verification

Checked on 2026-11-27 with read-only calls:

- `.github/workflows/checks.yml`, the only workflow in this repo, runs `check_schemas.py` and pyright. It does not run `tools/migrate.py`.
- `.github/workflows/ci.yml` in `andexor-carmen-api` checks out this repo and runs `tools/migrate.py`. It starts on a pull request and on a push to `main` of that repo.
- `schema_migration` records version 21 at 20:26:26Z in the preview and at 20:26:51Z in production. Its pull request was opened at 20:26:55Z and merged at 20:27:49Z, so the migration was applied by hand, before the pull request.
- `python3 tools/migrate.py prev --dry-run` and `prod --dry-run` report both databases up to date at versions 1 to 21.

## Success criteria

- **SC-001**: `CLAUDE.md` holds the rule in "Working in this repo".
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
