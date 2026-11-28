<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: A setting that switches automatic rescoring off and on

**Feature Branch**: `77-rescore-auto-setting`

**Created**: 2026-11-28

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #77. Asked for by Ed on 2026-11-28: switch automatic rescoring off, make several changes to the rubric, switch it on again, and have every company rescored once. The code that uses the setting is `specs/040-rescore-switch/spec.md` in `andexor-carmen-api`. This spec adds to `specs/018-rescore-requested-setting/spec.md`. Where this spec and an earlier document differ, this spec governs.

## User Scenarios and Testing

### User Story 1 - The rubric is changed in one sitting and rescored once (Priority: P2)

**Independent Test**: `GET /api/v1/settings` of `andexor-carmen-api` lists `rescore.auto` with the value `ON`.

**Acceptance Scenarios**:

1. **Given** `rescore.auto` is `ON`,\
   **When** a rubric question is changed,\
   **Then** every company is rescored at once, as before.
2. **Given** `rescore.auto` is `OFF`,\
   **When** several rubric questions are changed,\
   **Then** the changes are stored, `rescore.requested` is set, and no company is rescored.
3. **Given** `rescore.auto` is `OFF` and a rescoring is waiting,\
   **When** the setting is changed to `ON`,\
   **Then** every company is rescored once, and `rescore.requested` is empty.

## Requirements

- **FR-001**: The migration `0024_rescore_auto_setting` adds the setting `rescore.auto` with the value `ON`.
- **FR-002**: The values are `ON` and `OFF`. `andexor-carmen-api` refuses any other value, and treats a missing setting as `ON`.
- **FR-003**: No table changes, and no stored score is changed.
- **FR-004**: The migration is applied to the preview database first and then to the production database.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 24 and hold the setting with the value `ON`. Checked on 2026-11-28.
