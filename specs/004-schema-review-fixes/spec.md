<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Schema review fixes

**Feature Branch**: `12-schema-review-fixes`

**Created**: 2026-11-21

**Status**: Implemented. Migration 0002 is applied to preview and production.

**Input**: Issue #12. A review of the schema found four gaps. `0001_init` is already applied to `andexor-carmen-api-prod` and `andexor-carmen-api-prev`, so the fixes ship as a new numbered migration, `db/carmen/0002_schema_review_fixes.sql`, and `0001_init` is not edited. Where this spec and an earlier document differ, this spec governs.

Rules for every change in this spec:
- Edit `0002_schema_review_fixes.base.sql` or `tools/gen_srt_triggers.py`, then run `./tools/build_schema.sh && python3 tools/check_schemas.py`.
- Apply to preview first, then production, only when `schema_migration` has no row for version 2.

## Change 1: a retired SRT code does not block unrelated updates

### Requirements

- **FR-001**: The generated update trigger on every System Reference Table (SRT) column MUST reject a new value that is not active in `srt`, and MUST NOT check a value that is unchanged (`NEW.col IS NOT OLD.col`).
- **FR-002**: The insert triggers are unchanged. A retired code can never be inserted.
- **FR-003**: Migration 0002 drops and recreates the 28 update triggers from `tools/gen_srt_triggers.py --replace-upd`.

### Effect on the API and the UI

An update that writes every column of a row no longer fails when the row holds a retired code. Changing a row to a retired code still fails.

## Change 2: reopening a deal clears its close data

### Requirements

- **FR-004**: When `deal.stage` is set to a value other than `WON` or `LOST`, a trigger MUST set `closed_at` and `total_deal_time` to NULL.

### Effect on the API and the UI

None to send. A reopened deal shows no close date and no deal time.

## Change 3: clearing a run timestamp clears its duration

### Requirements

- **FR-005**: When `ai_run.started_at` or `ai_run.finished_at` is updated and either is NULL afterward, `duration_ms` MUST be NULL. When both are set it is the difference in milliseconds, as before.

## Change 4: index four foreign keys

### Requirements

- **FR-006**: These indexes MUST exist: `activity_contact_idx` on `activity(contact_id)`, `activity_deal_idx` on `activity(deal_id)`, `enrichment_ai_run_idx` on `enrichment_fact(ai_run_id)`, and `rubric_answer_run_idx` on `rubric_answer(ai_run_id)`.

## Success criteria

- **SC-001**: `python3 tools/check_schemas.py` prints ALL PASS. It loads 0001 then 0002 and tests each change.
- **SC-002**: `schema_migration` in both databases lists versions 1 and 2.
- **SC-003**: `0001_init.sql` is byte-for-byte what was applied.
