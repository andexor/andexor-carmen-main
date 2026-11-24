<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Decision log: review of open risks and questions

Issue: #6. Date: 2026-11-20. Status: decided, with items still open listed below.

## Purpose

This note records the outcome of a review of Product Requirements Document (PRD) section 12 (risks and questions) and section 14 (readiness checklist). The PRD is frozen, so the outcomes are recorded here. Where this note and the PRD differ, this note governs. Nothing here changes a requirement except where "Changes to what the PRD says" says so.

## Closed

| Item | Decision | Carried to |
| --- | --- | --- |
| R3: Cloudflare Access on preview | Closed by decision. Preview is served on `carmen-preview.andexor.net`, an ordinary hostname on the andexor.net zone, so the workers.dev concern no longer applies. The API verifies the Access token on every request (constitution Principle VI), which is the fallback the PRD named. | api repo: D3 (Access plus a GitHub Actions service token). ui repo: D2 (Playwright signs in with that token). Also, a service-token request carries no user email, so the API needs a rule for machine callers, such as a service-token identity in place of the email. |
| R4: D1 limits | Accepted. The 10 GB limit is far above CRM volume, and documents live in R2. | api repo: batch the Comma-Separated Values (CSV) import and "accept all facts" writes, and check the current D1 per-query limits when those features are specified. |
| R5: AI answers can be wrong | Mitigated by design. Nothing is applied without a user action (Principle VII), every answer keeps its source and run id, and ratings and comparison views show which models to trust. The risk itself remains. | none |
| R6: AI cost | Mitigated. Tokens and duration are recorded per run, and the new `ai_run.search_count` column records web searches, which are billed per search. | api repo: fill `search_count`, and cap searches per run (discovery task D5). |
| R7: Prompt injection from fetched pages | Mitigated by design. Fetched text is untrusted (Principle VII), models get no tools beyond search, and nothing is applied automatically. | api repo: parse model output strictly into fixed fields, and reject output that does not match the schema. |
| Q3: Jev access | Closed. Access is obtained and the keys exist. | api setup: store the TypeSafe Console key in Secrets Store as `carmen-typesafe-api-key`, then enable the Jev model in Settings. A copy in GitHub secrets is not visible to the Worker. |

## Still open

| Item | What closes it |
| --- | --- |
| Q1: The real rubric | Ed writes the Fit and Need criteria in the UI once it exists. Not a blocker. The placeholders stay in the seed as sample data. |
| Q4: Contact Us change | A spec in `andexor-net-website-contact-us` once `create_lead` exists. |
| Q5: Email provider | See the decision below. Closes when a real digest reaches the inbox from the running Worker. |
| Q6: Grass Spider transport | Chosen when Grass Spider is ready to call `create_lead` and `add_facts`. |
| Q8: Which Claude model | Ed picks after comparing runs. |
| R1: FastAPI on Python Workers | Discovery in the api repo. |
| R2: An AI run outlasts one request | Discovery in the api repo. |

## Q5: Email provider (decided, not yet closed)

- Provider: Cloudflare Email Sending, through the `send_email` binding. Version 1 sends to Ed only.
- Sending domain: `carmen.andexor.net`. Its records sit on `cf-bounce.carmen.andexor.net` (Mail Exchange (MX) and Sender Policy Framework (SPF)), `cf-bounce._domainkey.carmen.andexor.net` (DomainKeys Identified Mail (DKIM)), and `_dmarc.carmen.andexor.net` (Domain-based Message Authentication, Reporting, and Conformance (DMARC)). The root records belong to Google Workspace and are unchanged.
- Verified on 2026-11-19: a test email sent with the REST API reached `ed@andexor.net`, and SPF, DKIM, and DMARC all pass.
- Remaining: in the api repo, add the `send_email` binding and send one real digest to confirm it reaches the inbox.
- Manual steps are tracked in `MANUAL-TASKS.md`.

## Changes to what the PRD says

1. `ai_run_answer.probability` means the model's probability that the answer is correct, when the model reports one. It does not mean the model's confidence. The schema comment now says so.
2. Confidence and probability are different numbers and the UI MUST label them apart. Confidence is the run-level coverage of the rubric (0 to 100). Probability is per answer. The UI MUST show both, and MUST NOT use one word for both.
3. `ai_run` gains an optional `search_count` column (whole number, not negative, NULL when the model has no web search).

## Readiness checklist (section 14)

- Repos created in the `andexor` organization: done. Pushed: `andexor-carmen-main` only. The api and ui repos get their content when work begins there.
- Ed reviews the PRD and the two child PRDs: done.
- Q answers: Q2, Q3, and Q7 closed. Q1, Q4, Q5, Q6, and Q8 open (see above).
- API contract (`api/carmen-api.openapi.yaml`): not needed. The contract is the specification FastAPI generates from the code (spec 010).
- Discovery R1 to R3: not started.

## Setup steps found during the review

Listed and tracked in `MANUAL-TASKS.md`: DNS, Cloudflare Access (applications and the CI service token), Account API tokens, Secrets Store keys, a Workers AI billing notification, and the default-branch ruleset.
