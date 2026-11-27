<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: Update Q5 and Q6

**Feature Branch**: `61-update-q5-q6`

**Created**: 2026-11-27

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #61. Ed confirmed the production emails and chose the Grass Spider transport on 2026-11-27. This spec adds to `specs/012-close-q1-q5-q6/spec.md`. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: Q5 (email provider) has no follow-up left. Ed confirmed on 2026-11-27 that the digest from production reached the inbox, and so did the proposals email from production.
- **FR-002**: Q6 (Grass Spider transport) has its transport: a Service Binding. Andexor Grass Spider (AGS) will be a Cloudflare Worker and will call `create_lead` and `add_facts` on the entry point of `andexor-carmen-api`, as the Contact Us service does. No service token is issued for it.
- **FR-003**: Cloudflare Access stays as it is: the preview has an Allow policy and a Service Auth policy for its test token, and production has an Allow policy only. Production admits no service token.
- **FR-004**: AGS makes the technical measurements of a website, and Carmen makes no call to Google. PageSpeed Insights and the Chrome UX Report (CrUX) go through AGS: Carmen sends a request to a queue, and AGS posts the data to Carmen, measuring first when it does not have the data.
- **FR-005**: The request from Carmen to AGS (the queue, the shape of the message, and when Carmen asks) is specified when AGS has the feature. It is a spec in `andexor-carmen-api` and in the Grass Spider repo.
- **FR-006**: `specs/001-review-open-items/decisions.md` and `MANUAL-TASKS.md` say the same.

## Success criteria

- **SC-001**: The rows for Q5 and Q6 in `specs/001-review-open-items/decisions.md` name no follow-up that is already done.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
