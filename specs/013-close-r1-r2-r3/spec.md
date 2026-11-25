<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Close discovery items R1, R2, and R3

**Feature Branch**: `48-close-r1-r2-r3`

**Created**: 2026-11-25

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #48. Ed gave the state of the discovery items on 2026-11-25. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: R1 (FastAPI on Python Workers) is closed. It was handled in `andexor-carmen-api`, where the API runs as FastAPI on Python Workers.
- **FR-002**: R2 (an AI run outlasts one request) is closed. A run is handled with a queue. The choice was made after measuring several tests.
- **FR-003**: R3 (Cloudflare Access on preview) is closed, as the decisions table already says.
- **FR-004**: `specs/001-review-open-items/decisions.md` and the open items in `CLAUDE.md` name Q4 as the only open item.

## Success criteria

- **SC-001**: The "Still open" table in `specs/001-review-open-items/decisions.md` holds Q4 only.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
