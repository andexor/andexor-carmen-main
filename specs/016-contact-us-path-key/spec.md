<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: A known fact key for the Contact Us page

**Feature Branch**: `63-contact-us-path-key`

**Created**: 2026-11-27

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #63. Asked for on 2026-11-27: add `contact_us_path` to Carmen's list of known fact keys. The Contact Us service (`andexor-net-website-contact-us`) sends every form submission to Carmen as a lead, and sends the page the form was on as a fact with that key. The key was not in `enrichment_key`, so the fact showed with no label. Where this spec and an earlier document differ, this spec governs.

## User Scenarios and Testing

### User Story 1 - The page of a Contact Us lead has a label (Priority: P1)

**Independent Test**: `GET /api/v1/facts/keys` of `andexor-carmen-api` lists `contact_us_path` with its label.

**Acceptance Scenarios**:

1. **Given** a lead that came from the Contact Us form,\
   **When** its facts are shown,\
   **Then** the page the form was sent from has the label "Contact Us page".
2. **Given** a fact stored under the key before this migration,\
   **When** it is shown,\
   **Then** it has the label too, and its value is unchanged.

## Requirements

- **FR-001**: The migration `0019_contact_us_path_key` adds one row to `enrichment_key`: the key `contact_us_path`, the label "Contact Us page", the value type `TEXT`, the description "The page of andexor.net the Contact Us form was sent from", and the sort order 18.
- **FR-002**: The list stays a hint, as before: `enrichment_fact.key` has no foreign key to it, and no stored fact is changed.
- **FR-003**: The migration is applied to the preview database first and then to the production database.
- **FR-004**: Nothing changes in `andexor-carmen-api` or in `andexor-net-website-contact-us`. The models of `andexor-carmen-api` are generated from the tables, and no table changes.

### Not in this feature

- Closing Q4 (Contact Us change). It stays open.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 19 and hold the row. Checked on 2026-11-27.
