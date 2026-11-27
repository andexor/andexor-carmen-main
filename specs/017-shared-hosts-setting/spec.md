<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins
-->

# Feature Specification: A setting for shared sites

**Feature Branch**: `67-shared-hosts-setting`

**Created**: 2026-11-27

**Status**: Implemented. The migration is applied to the preview and the production database.

**Input**: Issue #67. Found by the audit of `andexor-carmen-api` on 2026-11-27: a company is matched to another by the host of its website, so two businesses whose websites are pages of one shared site (`facebook.com/joes-plumbing`, `facebook.com/anns-bakery`) were taken for one company. Ed decided on 2026-11-27 that the list of shared sites is a setting in the database. The code that uses it is `specs/033-audit-fixes/spec.md` in `andexor-carmen-api`. Where this spec and an earlier document differ, this spec governs.

## User Scenarios and Testing

### User Story 1 - The list of shared sites can be changed without a code change (Priority: P1)

**Independent Test**: `GET /api/v1/settings` of `andexor-carmen-api` lists `company.shared_hosts`.

**Acceptance Scenarios**:

1. **Given** the setting holds `facebook.com`,\
   **When** a lead arrives whose website is a page on Facebook,\
   **Then** the company is stored with its website and with no domain.
2. **Given** a site is added to the setting,\
   **When** the next company on that site is stored,\
   **Then** it gets no domain either, and no code was changed.

## Requirements

- **FR-001**: The migration `0020_shared_hosts_setting` adds the setting `company.shared_hosts`. Its value is host names separated by commas: `facebook.com`, `fb.com`, `instagram.com`, `linkedin.com`, `x.com`, `twitter.com`, `youtube.com`, `tiktok.com`, `yelp.com`, `linktr.ee`, `nextdoor.com`, `pinterest.com`, and `google.com`.
- **FR-002**: A host name covers its subdomains: `google.com` covers `sites.google.com`, and `facebook.com` covers `m.facebook.com`.
- **FR-003**: `company.domain` keeps its meaning: the host of the website. It is NULL for a company whose website is a page of a shared site. No table changes.
- **FR-004**: No stored company is changed. On 2026-11-27 neither database held a company whose domain is a shared site.
- **FR-005**: The migration is applied to the preview database first and then to the production database.

### Not in this feature

- A site that gives each business its own host name (`acme.wixsite.com`). Such a host already tells businesses apart.

## Success Criteria

- **SC-001**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
- **SC-002**: Both databases are at schema version 20 and hold the setting. Checked on 2026-11-27.
