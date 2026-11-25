<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Drop the planned api/ contract folder from the documents

**Feature Branch**: `42-drop-api-contract-folder`

**Created**: 2026-11-24

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #42. The documents said an `api/` folder would hold a hand-written OpenAPI 3.1 draft until code existed. The code exists, and FastAPI generates the specification from it, so the draft will not be written. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: The API contract is the OpenAPI 3.1 specification that FastAPI generates from the code of `andexor-carmen-api`.
- **FR-002**: This repo holds no hand-written draft of the contract and has no `api/` folder.
- **FR-003**: `CLAUDE.md` states FR-001 and FR-002 under "Source of truth". `README.md` does not list `api/`.
- **FR-004**: The readiness checklist in `specs/001-review-open-items/decisions.md` marks the API contract as not needed and points to this spec.

## Success criteria

- **SC-001**: A search of `CLAUDE.md` and `README.md` for `api/` as a folder of this repo finds nothing.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
