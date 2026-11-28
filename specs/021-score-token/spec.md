<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: A version mark for a company's scores

**Feature Branch**: `75-score-token`

**Created**: 2026-11-28

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #75. Finding 12 of the audit of `andexor-carmen-api` on 2026-11-27: two writers of a company's scores at the same moment can leave scores that do not follow from the stored answers. Ed chose the fix on 2026-11-28: a version mark on the company; a write goes through only while the mark is unchanged, and a writer whose mark has moved reads again and redoes its work. The code that uses the column is `specs/039-score-version-mark/spec.md` in `andexor-carmen-api`. Where this spec and an earlier document differ, this spec governs.

## User Scenarios and Testing

### User Story 1 - The scores of a company carry a mark that changes with every write (Priority: P1)

**Independent Test**: `GET /api/v1/companies/{company_id}` of `andexor-carmen-api` shows `score_token`, and it is another value after the company's answers are saved.

**Acceptance Scenarios**:

1. **Given** a company whose scores were never written since this migration,\
   **When** it is read,\
   **Then** `score_token` is empty.
2. **Given** a company whose answers are saved,\
   **When** it is read again,\
   **Then** `score_token` holds a new value.

## Requirements

- **FR-001**: The migration `0023_score_token` adds the column `company.score_token`, a text. It is NULL for every stored company.
- **FR-002**: The value has no meaning. Only whether it changed is read.
- **FR-003**: The column is set by `andexor-carmen-api` alone, with every write of the company's scores. It is not a field of the company's body, and a change to it is not an edit by a person.
- **FR-004**: No stored score is changed.
- **FR-005**: `db/README.md` describes the column.
- **FR-006**: The migration is applied to the preview database first and then to the production database.

## Verification

Checked on the preview database on 2026-11-28, with read-only statements: a statement can be made to fail when the mark it is given is not the stored mark (`malformed JSON: SQLITE_ERROR`), and to succeed when it is. A failed statement rolls back its whole batch, so a write of scores with a stale mark stores nothing.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 23, and the column exists and is empty for every company. Checked on 2026-11-28.
