<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: When an agreement's proposals job was started

**Feature Branch**: `73-proposals-started-at`

**Created**: 2026-11-28

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #73. Finding 8 of the audit of `andexor-carmen-api` on 2026-11-27: a proposals job that runs a second time pays for the models again and sends a second email. Ed chose the fix on 2026-11-28: the job uses fresh results again, a second start is refused with a plain answer, and a person can still ask for a fresh job. The code that uses the column and the setting is `specs/036-proposals-once/spec.md` in `andexor-carmen-api`. Where this spec and an earlier document differ, this spec governs.

## User Scenarios and Testing

### User Story 1 - Carmen knows that a proposals job was started (Priority: P1)

**Independent Test**: `GET /api/v1/agreements/{agreement_id}` of `andexor-carmen-api` shows `proposals_started_at`, and `GET /api/v1/settings` lists `proposal.reuse_minutes`.

**Acceptance Scenarios**:

1. **Given** an agreement whose proposals job was never started,\
   **When** it is read,\
   **Then** `proposals_started_at` is empty.
2. **Given** an agreement whose proposals job was put on the queue,\
   **When** it is read,\
   **Then** `proposals_started_at` holds that time.

## Requirements

- **FR-001**: The migration `0022_proposals_started_at` adds the column `agreement.proposals_started_at`, a time in ISO 8601 form. It is NULL for every stored agreement.
- **FR-002**: The same migration adds the setting `proposal.reuse_minutes` with the value 60. 0 turns the refusal and the reuse off.
- **FR-003**: The column is set by `andexor-carmen-api` alone. It is not a field of the agreement's body, and a change to it is not an edit by a person.
- **FR-004**: `db/README.md` describes the column and the setting.
- **FR-005**: The migration is applied to the preview database first and then to the production database.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 22, the column exists, and the setting holds 60. Checked on 2026-11-28.
