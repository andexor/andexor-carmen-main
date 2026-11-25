<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Close Q1, Q5, and Q6, and update Q4

**Feature Branch**: `46-close-q1-q5-q6`

**Created**: 2026-11-25

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #46. Ed gave the state of the remaining open questions on 2026-11-25. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: Q1 (the real rubric) is closed. Ed read the seeded Fit and Need criteria and accepted them as the rubric. They are no longer placeholders or sample data. They stay editable in the UI.
- **FR-002**: Q5 (email provider) is closed. A digest was sent from the running Worker on the preview and tested. One follow-up remains: test a digest from production.
- **FR-003**: Q6 (Grass Spider transport) is closed. The API side is done. The Grass Spider service that will call the API is not written yet and may need work when it is.
- **FR-004**: Q4 (Contact Us change) stays open. The API side is done. It closes when `andexor-net-website-contact-us` has been checked and any work it still needs is done.
- **FR-005**: `specs/001-review-open-items/decisions.md` and the open items in `CLAUDE.md` name Q4 as the only open question.

## Success criteria

- **SC-001**: The "Still open" table in `specs/001-review-open-items/decisions.md` holds Q4, R1, and R2 only.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
