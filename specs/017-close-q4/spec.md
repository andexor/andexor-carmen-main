<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: Close Q4

**Feature Branch**: `65-close-q4`

**Created**: 2026-11-27

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #65. Ed reported on 2026-11-27 that `andexor-net-website-contact-us` now sends leads to Carmen. This spec adds to `specs/012-close-q1-q5-q6/spec.md`. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: Q4 (the Contact Us change) is closed. `andexor-net-website-contact-us` calls `create_lead` on the entry point of `andexor-carmen-api` over a Service Binding named `CARMEN`, once, after it stores its own row.
- **FR-002**: The binding points at `andexor-carmen-api` in production and at `andexor-carmen-api-preview` in the preview.
- **FR-003**: The lead carries the source `CONTACT_US`, the row's id as the source reference, the website, the help text as the note, the person as the contact, and the page the form was on as the fact `contact_us_path` (spec 016).
- **FR-004**: A failure or a refusal from Carmen never fails the form. The Contact Us service logs it with the row's id.
- **FR-005**: No open item remains. `specs/001-review-open-items/decisions.md` and `CLAUDE.md` say so.

## Acceptance Scenarios

1. **Given** a person who sends the Contact Us form,\
   **When** the Contact Us service has stored its row,\
   **Then** a company whose source is `CONTACT_US` is in Carmen without anyone typing.

## Verification

Checked on 2026-11-27 with read-only calls:

- The `main` branch of `andexor-net-website-contact-us` holds the binding for both environments and the call.
- The preview database holds 54 companies whose source is `CONTACT_US` and 6 `contact_us_path` facts.
- The production database holds 1 such company, made on 2026-11-27, and 1 `contact_us_path` fact.

## Success criteria

- **SC-001**: `specs/001-review-open-items/decisions.md` lists Q4 as closed and lists nothing as open.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
