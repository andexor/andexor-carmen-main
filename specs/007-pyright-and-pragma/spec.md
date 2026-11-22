<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Remove the pragma from check_schemas.py and fix Pylance errors

**Feature Branch**: `18-pyright-and-pragma`

**Created**: 2026-11-22

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #18. Spec 006 kept `PRAGMA foreign_keys=ON` on the test connection in `tools/check_schemas.py`. It is removed too. The Python tools had no type checker configuration and showed Pylance errors in strict mode. Where this spec and an earlier document differ, this spec governs; it replaces FR-005 of spec 006.

## Change 1: no pragma in the schema check

### Requirements

- **FR-001**: `tools/check_schemas.py` MUST NOT run `PRAGMA foreign_keys`. It loads each migration the way `tools/migrate.py` sends it and adds nothing.
- **FR-002**: The foreign key tests still pass, because migrations `0001` and `0002` carry their own `PRAGMA foreign_keys = ON` line. Those files are applied and are not edited.

## Change 2: strict type checking

### Requirements

- **FR-003**: `pyrightconfig.json` at the repo root is copied from `andexor-carmen-api` and keeps `"typeCheckingMode": "strict"`. `include` and `extraPaths` are `tools`, where this repo's Python files are. The virtual environment settings are left out, because this repo has no virtual environment and its tools use only the standard library.
- **FR-004**: Every function in `tools/build_schema.py`, `tools/check_schemas.py`, `tools/gen_erd.py`, and `tools/migrate.py` has parameter and return types, and Pyright (Pylance) reports no errors in strict mode.
- **FR-005**: The types change no behavior, with one exception: when an SRT trigger does not match the expected pattern, `tools/check_schemas.py` no longer stops with an exception. It fails the check and prints the trigger's name, the likely cause, and the fix.

## Success criteria

- **SC-001**: `npx pyright` prints 0 errors, 0 warnings.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-003**: A search for `foreign_keys` outside `specs/` finds only migrations `0001` and `0002`.
