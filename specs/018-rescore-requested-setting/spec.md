<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: A setting that says a rescoring is waiting

**Feature Branch**: `69-rescore-requested-setting`

**Created**: 2026-11-27

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #69. Finding 6 of the audit of `andexor-carmen-api` on 2026-11-27: a change to the rubric, to a service, or to a score threshold is stored first, and the scores of every company are recomputed after it. When the recomputing failed, nothing tried again, and sending the same change again did nothing, because it was already stored. Ed chose on 2026-11-27 to record that a rescoring is waiting and to have the scheduler make it. The code that uses the setting is `specs/034-rescore-retry/spec.md` in `andexor-carmen-api`. Where this spec and an earlier document differ, this spec governs.

## User Scenarios and Testing

### User Story 1 - A rescoring that failed is not forgotten (Priority: P1)

**Independent Test**: `GET /api/v1/settings` of `andexor-carmen-api` lists `rescore.requested`.

**Acceptance Scenarios**:

1. **Given** no rescoring is waiting,\
   **When** the settings are listed,\
   **Then** `rescore.requested` is there, and its value is empty.
2. **Given** a change to the rubric was stored and the rescoring after it failed,\
   **When** the settings are listed,\
   **Then** `rescore.requested` holds a value, until a rescoring succeeds.

## Requirements

- **FR-001**: The migration `0021_rescore_requested_setting` adds the setting `rescore.requested`, with an empty value.
- **FR-002**: An empty value means that no rescoring is waiting. Any other value means that one is. `andexor-carmen-api` writes the time of the request and a tag that tells two requests apart; no code reads a meaning from the value beyond empty or not.
- **FR-003**: The key does not start with `score.`. Those keys are thresholds, and a change to one of them starts a rescoring.
- **FR-004**: No table changes, and no stored score is changed.
- **FR-005**: The migration is applied to the preview database first and then to the production database.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 21 and hold the setting. Checked on 2026-11-27.
