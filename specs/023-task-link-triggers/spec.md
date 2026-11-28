<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: The database refuses a task linked to another company

**Feature Branch**: `79-task-link-triggers`

**Created**: 2026-11-28

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #79. Finding 14 of the audit of `andexor-carmen-api` on 2026-11-27: a task can point to another company's deal. Ed asked on 2026-11-28 for the check in the API and for the database to hold the same rule. The code that checks before it writes is `specs/042-task-links/spec.md` in `andexor-carmen-api`. Where this spec and an earlier document differ, this spec governs.

## Why

A task names a company, a deal, and an agreement, each on its own, and the foreign keys check only that each record exists. A task under one company that points to another company's deal makes that deal look planned in the digest, and an edit of the task is recorded on the wrong company's timeline. Carmen will have more than one writer: several people, a second client, a script. The rule belongs in the database, so that no writer can break it.

## User Scenarios and Testing

### User Story 1 - A task's deal and agreement are under the task's company (Priority: P2)

**Independent Test**: The triggers are run against a scratch database with the four tables and fourteen writes. Each write is stored or refused as the scenarios say.

**Acceptance Scenarios**:

1. **Given** a deal of company B,\
   **When** a task of company A is stored with that deal,\
   **Then** the write is refused with `task link outside its company`.
2. **Given** an agreement of company B,\
   **When** a task of company A is stored with that agreement,\
   **Then** the write is refused.
3. **Given** a deal or an agreement,\
   **When** a task is stored with it and with no company,\
   **Then** the write is refused.
4. **Given** a task of company A with a deal of company A,\
   **When** the task's company is changed to company B or taken away,\
   **Then** the write is refused.
5. **Given** a task with no deal and no agreement,\
   **When** it is stored, with or without a company,\
   **Then** it is stored as before.
6. **Given** a task with a deal,\
   **When** the deal is deleted,\
   **Then** the task stays, with no deal, as before.

### Edge Cases

- A deal and an agreement never change company: `andexor-carmen-api` takes `company_id` out of every edit of one. So the triggers watch `task` only.
- A task that names a deal that does not exist is refused, by the trigger when the task has a company and by the foreign key when it has none.
- A refused write stops the whole statement, and in a D1 batch the whole batch.

## Requirements

- **FR-001**: The migration `0025_task_link_triggers` adds the trigger `task_links_ins`, before an insert on `task`, and the trigger `task_links_upd`, before an update of `company_id`, `deal_id`, or `agreement_id` on `task`.
- **FR-002**: Each trigger refuses the write with `task link outside its company` when the task has a deal whose company is not the task's company, or an agreement whose company is not the task's company. No company is not the same company.
- **FR-003**: No table changes, and no stored task is changed. Both databases held no task that the triggers refuse, counted before the migration.
- **FR-004**: `db/README.md` states the rule in the section "The links of a task".
- **FR-005**: The migration is applied to the preview database first and then to the production database.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 25 and hold both triggers. Checked on 2026-11-28.
