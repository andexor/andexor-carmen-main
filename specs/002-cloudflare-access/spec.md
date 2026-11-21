<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Cloudflare Access for Carmen

**Feature Branch**: `8-cloudflare-access`

**Created**: 2026-11-20

**Status**: Draft

**Input**: Issue #8. Gate both Carmen hostnames with Cloudflare Access before the first deploy, as the master Product Requirements Document (PRD) and the constitution (Principles IV and VI) require.

## User Scenarios and Testing

### User Story 1 - Ed signs in to production (Priority: P1)

Ed opens `https://carmen.andexor.net`, signs in through Cloudflare Access, and reaches Carmen. Anyone else is refused.

**Why this priority**: Carmen holds other people's contact details and signed agreements. Nothing should be reachable without Access in front of it.

**Independent Test**: Open the hostname in a private browser window. It shows the Access sign-in page. After Ed signs in, the request reaches the Worker (or, before the first deploy, an error page from the missing Worker). A different email address is refused.

**Acceptance Scenarios**:

1. **Given** no session, **When** a browser requests any path on `carmen.andexor.net`, **Then** it is sent to the Access sign-in page.
2. **Given** an address that is not on the allow list, **When** it tries to sign in, **Then** it is refused.
3. **Given** a signed-in Ed, **When** a request is made to `/api/*`, **Then** the request carries a valid Access token to the API Worker.

---

### User Story 2 - The preview is gated and CI can sign in (Priority: P1)

`https://carmen-preview.andexor.net` is gated the same way for people. The continuous integration (CI) smoke test signs in with a service token, so the pipeline can test the preview without a person.

**Why this priority**: The smoke test is a required check on the default branch (Principle IV), so without a working token nothing can be merged.

**Independent Test**: A request with the service token headers to the preview is not answered with 401, 403, or a redirect to the sign-in page. The same token against production is refused.

**Acceptance Scenarios**:

1. **Given** the CI service token, **When** a request with its two headers reaches the preview hostname, **Then** Access lets it through.
2. **Given** the same token, **When** a request reaches the production hostname, **Then** Access answers 401 or 403.
3. **Given** a wrong or expired token, **When** a request reaches the preview, **Then** Access answers 401 or 403.

---

### User Story 3 - The api repo can verify tokens (Priority: P2)

The API checks the Access token on every request (Principle VI). It needs the team domain and each application's Audience (AUD) tag, so both are recorded where the api repo can use them.

**Why this priority**: The values must exist before the api repo can write or test its token check.

**Independent Test**: The team domain and two AUD tags (production and preview) are written in `MANUAL-TASKS.md` or the api repo's configuration.

**Acceptance Scenarios**:

1. **Given** the two applications exist, **When** the api repo is set up, **Then** it has the team domain and the AUD tag for its environment.

### Edge Cases

- Deleting and recreating an application changes its AUD tag, so every configuration that holds the tag must be updated.
- Changing the team name changes the team domain and the token issuer, so every configuration that holds it must be updated.
- The service token expires. Cloudflare renews it in place, so the Client ID and Secret stay the same and the GitHub secrets do not change. An "Expiring Access Service Token" notification emails a week before the date. Rotating the secret is only for a suspected leak.
- One-time PIN emails come from `noreply@notify.cloudflare.com` and can land in spam. The sender is added to the approved senders list.
- The account-wide setting "Block traffic to all domains in this account" would block every hostname without an Access application, including public andexor.net sites. It stays off.
- A Service Auth policy on production would let CI touch production data. It is never added there.

## Requirements

### Functional Requirements

- **FR-001**: There MUST be one Access application per hostname: `carmen.andexor.net` and `carmen-preview.andexor.net`. Each MUST cover the whole hostname with no path, so `/` and `/api/*` are both protected.
- **FR-002**: Each application MUST have an Allow policy that includes only the email addresses of approved users. In version 1 that is `ed@andexor.net`.
- **FR-003**: Each application MUST allow the login methods Cloudflare and One-time PIN.
- **FR-004**: A service token named `andexor-carmen-api` MUST exist. Its Client ID and Client Secret MUST be stored only in GitHub secrets for the repos that run the smoke test, and MUST NOT appear in any repo, log line, or error response.
- **FR-005**: The preview application MUST have a Service Auth policy that includes `andexor-carmen-api`. The production application MUST NOT.
- **FR-006**: The team domain (`andexor.cloudflareaccess.com`) and the AUD tag of each application MUST be recorded for the api repo.
- **FR-007**: No Carmen Worker MAY be deployed to a hostname until that hostname's Access application exists.
- **FR-008**: The account setting "Block traffic to all domains in this account" MUST stay off.
- **FR-009**: A Cloudflare notification of type "Expiring Access Service Token" MUST be set up so the token is renewed before it expires.
- **FR-010**: Every step MUST be listed in `MANUAL-TASKS.md` and marked with its date when done (Principle IX).

### Key Entities

- **Access application**: the gate for one hostname, with its policies and its AUD tag.
- **Policy**: Allow (people, by email) or Service Auth (machines, by service token).
- **Service token**: `andexor-carmen-api`, a Client ID and Client Secret pair with an expiry date.
- **Team domain**: `andexor.cloudflareaccess.com`, the issuer of every Access token.
- **AUD tag**: the identifier of one application, checked in each token.

## Success Criteria

### Measurable Outcomes

- **SC-001**: An unauthenticated request to either hostname never reaches a Worker.
- **SC-002**: Ed can sign in to both hostnames.
- **SC-003**: The CI token is accepted by the preview and refused by production.
- **SC-004**: The team domain and both AUD tags are recorded before work on the api repo's token check begins.

## Assumptions

- The Zero Trust organization exists, on the Free plan, with team name `andexor`. The Cloudflare and One-time PIN identity providers are already added.
- The proxied `AAAA` records for `carmen` and `carmen-preview` exist (done 2026-11-19).
- Strict service token authentication is on, because the organization was created after 2026-10-05. A bad token therefore gets 401 or 403, not a login redirect.
- Only Ed signs in during version 1. Teammates' addresses are added to the Allow policies later.
- The service token duration is one year (8760h). The token expires on 2027-11-17 and is renewed in place before then.
