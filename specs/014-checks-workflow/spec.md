<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Add a workflow that runs check_schemas.py and pyright

**Feature Branch**: `51-checks-workflow`

**Created**: 2026-11-25

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #51. The default-branch ruleset requires a check named `Preview and smoke test`, but this repo had no workflow, so nothing produced the check and nothing ran the schema checks or the type checker before a merge. Where this spec and an earlier document differ, this spec governs.

## Acceptance Scenarios

1. **Given** a pull request that edits a migration already on `main`,
   **When** the workflow runs,
   **Then** the check `Preview and smoke test` fails at the step "Schema checks".
2. **Given** a pull request that adds a function without types to a file in `tools/`,
   **When** the workflow runs,
   **Then** the check fails at the step "Type checks".
3. **Given** a pull request that breaks neither,
   **When** the workflow runs,
   **Then** the check passes and the pull request can merge without a bypass.

## Requirements

- **FR-001**: `.github/workflows/checks.yml` runs on every pull request and on every push to `main`.
- **FR-002**: It runs `python3 tools/check_schemas.py`. It does not run `build_schema.sh` first, so that a built file or diagram that was not regenerated fails the check.
- **FR-003**: It runs pyright with `pyrightconfig.json` (strict mode). The pyright version is pinned in the workflow.
- **FR-004**: The job is named `Preview and smoke test`, the name the default-branch ruleset requires. This repo deploys nothing, so here the name stands for these two checks. The job MUST NOT be renamed while the ruleset requires that name.
- **FR-005**: The checkout fetches the full history, because `check_schemas.py` compares the migrations with `origin/main`.
- **FR-006**: The workflow installs `uv`, because `check_schemas.py` needs SQLite 3.47 or later and re-runs itself on a Python that `uv` manages (spec 008).
- **FR-007**: Each action is pinned to a commit, with its version in a comment. The job has `contents: read` and no other permission, and the checkout does not keep its credentials.

## Success criteria

- **SC-001**: On this change's own pull request, the check `Preview and smoke test` passes, with both steps run.
- **SC-002**: Locally, `python3 tools/check_schemas.py` prints ALL PASS and pyright reports 0 errors.
