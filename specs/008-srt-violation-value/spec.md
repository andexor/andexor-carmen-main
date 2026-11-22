<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Name the rejected value in SRT violation errors

**Feature Branch**: `20-srt-violation-value`

**Created**: 2026-11-22

**Status**: Implemented. Migration `0003_srt_violation_value` applied to preview and production on 2026-11-22.

**Input**: Issue #20. When the database refuses a code that is not in the System Reference Table (SRT), the error named the table, column, and domain but not the value that was attempted. Where this spec and an earlier document differ, this spec governs.

## Change 1: the message names the value

### Acceptance Scenarios

1. **Given** a company row,
   **When** a statement sets `stage` to `HOT`,
   **Then** the statement fails with `SRT violation: company.stage value 'HOT' is not in COMPANY_STAGE` and no row changes.
2. **Given** the same statement as an insert,
   **When** it runs,
   **Then** it fails with the same message and no row is added.

### Requirements

- **FR-001**: An SRT violation message MUST read `SRT violation: <table>.<column> value <value> is not in <DOMAIN>`, with the value written as an SQL literal (text in single quotes). The `SRT violation:` prefix is unchanged.
- **FR-002**: Migration `0003_srt_violation_value` drops and recreates the insert and update trigger of each of the 29 SRT columns (58 triggers) with that message. It changes no data, and migrations `0001` and `0002` are not edited.
- **FR-003**: `tools/build_schema.py` generates the same message for SRT columns in later migrations.
- **FR-004**: The update trigger still checks a value only when it changes (as in migration 0002).

## Change 2: the tools need SQLite 3.47 or later

### Requirements

- **FR-005**: The message is built from the row, which SQLite supports from version 3.47. Both databases support it.
- **FR-006**: `./tools/build_schema.sh` and `python3 tools/check_schemas.py` are typed as before. When the SQLite in the running Python is older than 3.47, `tools/gen_erd.py` and `tools/check_schemas.py` re-run themselves with `uv run --managed-python --python 3.14`, whose Python carries a newer SQLite. No package is added.
- **FR-007**: When `uv` is missing, or the Python `uv` chooses is also too old, the script MUST stop with a message that states the SQLite version found, the version needed, and what to run.

## Success criteria

- **SC-001**: `python3 tools/check_schemas.py` prints ALL PASS, including the exact message on insert and on update and a check that no SRT trigger has the old message.
- **SC-002**: On preview, a rejected insert returns `SRT violation: company.stage value 'HOT' is not in COMPANY_STAGE` and adds no row.
- **SC-003**: Both databases report `schema_migration` version 3 and 58 SRT triggers, all with the new message.
- **SC-004**: `npx pyright` prints 0 errors, 0 warnings.
