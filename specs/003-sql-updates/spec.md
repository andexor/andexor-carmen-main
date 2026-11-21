<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Updates to the common data model

**Feature Branch**: `10-sql-updates`

**Created**: 2026-11-21

**Status**: In progress. Changes are added one at a time and agreed one at a time.

**Input**: Issue #10. Changes to `db/carmen/0001_init.base.sql` before it is first used. The master Product Requirements Document (PRD) and the child PRDs are frozen, so each change is recorded here. Where this spec and a PRD differ, this spec governs.

Rules for every change in this spec:
- Edit `0001_init.base.sql`, then run `./tools/build_schema.sh && python3 tools/check_schemas.py`.
- Keep README.md, CLAUDE.md, the constitution, and `db/README.md` in sync with the change.
- Record any effect on the API or the UI here.

## Change 1: name the SRT domain next to every SRT column

### Requirements

- **FR-001**: Every column that holds a code from a System Reference Table (SRT) domain MUST carry a `-- SRT domain: X` comment on its column definition in `0001_init.base.sql`, where `X` is the domain the column is constrained to.
- **FR-002**: SQLite and Cloudflare D1 have no column comment syntax in Data Definition Language (DDL), so the SQL comment is the only form. No DDL comment is added.
- **FR-003**: `tools/check_schemas.py` MUST fail when a column listed in `tools/build_schema.sh` lacks the comment or names a different domain, and when a column not listed there carries the comment.
- **FR-004**: When a new column holds an SRT code, the same change MUST add it to the list in `tools/build_schema.sh` and add its comment.

### What changed

- 28 columns in `0001_init.base.sql` now carry the comment. Every domain seeded in the `srt` table is used by at least one of them. No other column holds an SRT code: the other code-like columns (`source_ref`, `model_id`, `ai_model_id`, `model_id_used`, `source_url`, `source_detail`, `content_type`, `provider_ref`) hold free text, identifiers, or file types.
- `tools/check_schemas.py` gained the check in FR-003.
- CLAUDE.md and `db/README.md` state the rule.
- Constitution Principle V states the rule, and the constitution version is now 2.1.0 (MINOR: guidance expanded).

### Effect on the API and the UI

None. Comments do not change the schema, the generated triggers, or the SRT rows. The UI still reads labels and order from `srt` through the API.

### Success criteria

- **SC-001**: `python3 tools/check_schemas.py` prints ALL PASS, including the comment check for 28 columns.
- **SC-002**: Removing one comment, or changing its domain, makes the check fail.

## Change 2: order the USER_ROLE codes from least to most access

### Requirements

- **FR-005**: The `USER_ROLE` domain MUST list its codes in this order, with these labels and descriptions:

| sort_order | code | label | description |
| --- | --- | --- | --- |
| 1 | `READER` | Reader | Read-only |
| 2 | `MEMBER` | Member | Works leads, deals, and customers |
| 3 | `ADMIN` | Admin | Full access, including settings and users |

### What changed

- In `0001_init.base.sql`, the `sort_order` values are now READER 1, MEMBER 2, ADMIN 3. They were ADMIN 1, MEMBER 2, READER 3. The codes, labels, and descriptions are unchanged.
- `db/README.md` lists the domain in the new order.
- `app_user.role` still defaults to `ADMIN`, so the first user created is still an administrator.

### Effect on the API and the UI

- The API returns SRT rows in `sort_order`, so any role list it returns now runs from Reader to Admin.
- The UI reads labels and order from `srt` through the API, so a role picker shows Reader, Member, Admin with no code change.
- Role enforcement is still out of scope for version 1 (constitution Principle III). Nothing in either PRD depends on the old order.

### Success criterion

- **SC-003**: `python3 tools/check_schemas.py` prints ALL PASS, and the `USER_ROLE` rows in `0001_init.sql` appear in the order above.

## Change 3: the first user is ADMIN, later users default to READER

### Requirements

- **FR-006**: The first row inserted into an empty `app_user` table MUST have role `ADMIN`, whatever role the insert supplied. A trigger sets it.
- **FR-007**: A row inserted after that MUST default to role `READER` when no role is given. The column default is `READER`.
- **FR-008**: An `ADMIN` MUST be able to change another user's role to `MEMBER` or `ADMIN`. Any role must still be a code in the `USER_ROLE` domain.

### What changed

- In `0001_init.base.sql`, `app_user.role` defaults to `READER` (it was `ADMIN`), and a new trigger, `app_user_first_admin`, sets the first row to `ADMIN`.
- `tools/check_schemas.py` tests: the first user is `ADMIN`, the second defaults to `READER`, a `READER` can be raised to `MEMBER`, and an unknown role is rejected. It also now ignores triggers that are not SRT triggers.
- `db/README.md` describes the rule.

### Effect on the API and the UI

- **API:** the API creates the `app_user` row on first sign-in. It MUST NOT supply a role, so the database assigns it. This replaces the master PRD's statement that every signed-in user is treated as `ADMIN` in version 1: the stored role is now what the rule above produces. The API also needs an endpoint, open to `ADMIN` only, to change a user's role.
- **UI:** an admin screen lists users and lets an `ADMIN` change a role.
- Roles are enforced in version 1. See Change 4.
- Both effects are recorded here for when the API and UI are specified. Neither repo is changed.

### Success criterion

- **SC-004**: `python3 tools/check_schemas.py` prints ALL PASS, including the four role checks above.

## Change 4: what each role may do, enforced in version 1

This corrects the master PRD, which said roles are defined but every signed-in user is treated as `ADMIN` in version 1.

### Requirements

- **FR-009**: The API MUST enforce the signed-in user's role on every request. The database does not enforce it, because only the API is bound to the database (constitution Principle V).
- **FR-010**: `READER` MUST be able to read anything and MUST NOT create, edit, or delete anything.
- **FR-011**: `MEMBER` MUST be able to read anything and create or change records such as companies, contacts, deals, agreements, notes, tasks, and documents. `MEMBER` MUST NOT delete anything, MUST NOT create or modify users, and MUST NOT change settings, the rubric, the service catalog, or the AI model list.
- **FR-012**: `ADMIN` MUST be able to do anything, including deleting, creating and changing users, and changing settings, the rubric, the service catalog, and the AI model list.
- **FR-013**: A request the role does not allow MUST be refused with HTTP 403 and a short error code, and MUST NOT change any data.
- **FR-014**: The UI MUST hide or disable actions the signed-in user's role cannot perform. This is a convenience. The API check in FR-009 is the control.

### Consequences to carry into the API and UI specifications

- A `READER` cannot start an AI run, accept or reject proposed facts, apply a scoring run, or add a note, task, or document, because each of those creates or changes a record.
- A `READER` still sees everything, including scores, dossiers, and agreements.
- Only an `ADMIN` can open the user list and change a role (Change 3).

### Decided

- A `MEMBER` cannot delete anything. Only an `ADMIN` deletes.
- A `MEMBER` cannot change settings, the rubric, the service catalog, or the AI model list. Only an `ADMIN` does. This matches the `ADMIN` role description in the `USER_ROLE` domain.
- "At this point" applies: these may be loosened later through a new specification.

### What changed

- Constitution Principle III no longer lists role enforcement as out of scope. Principle VI now states the three role rules.
- No SQL changes. No other repository is changed, and the PRDs stay frozen.

### Success criteria

- **SC-005**: When the API is specified, each role rule above has a test that signs in as that role.

## Change 5: add BOTH to MEETING_MODE and reorder

### Requirements

- **FR-015**: The `MEETING_MODE` domain MUST list its codes in this order, with these labels and descriptions:

| sort_order | code | label | description |
| --- | --- | --- | --- |
| 1 | `ONLINE` | Online | Meets online only |
| 2 | `IN_PERSON` | In person | Meets in person |
| 3 | `BOTH` | Both | Meets online and in person |

### What changed

- In `0001_init.base.sql`, `BOTH` is a new code. `ONLINE` moved to sort order 1 and `IN_PERSON` to 2. The `ONLINE` description is unchanged.
- `db/README.md` lists the domain in the new order.
- `company.meeting_mode` stays optional, with no default.

### Effect on the API and the UI

- The API returns the three codes in `sort_order`, and accepts `BOTH` wherever it accepts a meeting mode.
- The UI reads labels and order from `srt` through the API, so a meeting-mode picker shows Online, In person, Both with no code change.

### Success criterion

- **SC-006**: `python3 tools/check_schemas.py` prints ALL PASS, and the `MEETING_MODE` rows in `0001_init.sql` appear in the order above.

## Change 6: order the services as the website presents them

### Requirements

- **FR-016**: The seeded `service` rows MUST use this order and `sort_order`, which matches the order on the website:

| sort_order | id | name | category |
| --- | --- | --- | --- |
| 1 | `web-development` | Web Development | `TECHNICAL` |
| 2 | `web-hosting` | Web Hosting | `TECHNICAL` |
| 3 | `technical-seo` | Technical SEO | `TECHNICAL` |
| 4 | `agentic-systems` | Agentic Systems | `TECHNICAL` |
| 5 | `cost-reduction` | Cost Reduction | `BUSINESS` |
| 6 | `process-re-engineering` | Process Re-engineering | `BUSINESS` |
| 7 | `lead-generation` | Lead Generation | `BUSINESS` |
| 8 | `growth-marketing` | Growth Marketing | `BUSINESS` |

### What changed

- In `0001_init.base.sql`, the rows and their `sort_order` values are in the order above. The ids, names, and categories are unchanged. Rubric criteria refer to services by id, so they are unaffected.
- The list is edited in the UI after the first deploy, so this changes only the starting order.

### Effect on the API and the UI

- The API returns services in `sort_order`, and the UI lists them in that order with no code change.

### Success criterion

- **SC-007**: `python3 tools/check_schemas.py` prints ALL PASS, and the `service` rows in `0001_init.sql` appear in the order above.

## Change 7: index contact phone numbers for lookup

### Requirements

- **FR-017**: `contact.phone` MUST have a non-unique index, `contact_phone_idx`, so a contact can be found by phone number.
- **FR-018**: The index MUST NOT be unique, because:
  - a phone number can change hands, so one number can appear to belong to two contacts when only one holds it at a time;
  - a person can move between companies, or work at two companies at once, and appear in both;
  - a business owner can own several businesses and use the same contact details for all of them.

### What changed

- `0001_init.base.sql` has `CREATE INDEX contact_phone_idx ON contact(phone)`, next to the email index.
- `tools/check_schemas.py` checks that two contacts can share a phone number and that the index is not unique.

### Effect on the API and the UI

- **API:** a lookup by phone returns a list, possibly with more than one contact, never exactly one. The index matches stored text exactly, so the API MUST normalize phone numbers as FR-019 says, both when saving and when searching. Otherwise "(555) 123-4567" and "+15551234567" would not match.
- **UI:** a phone search shows every matching contact and their company. The UI accepts any text in a phone field and never shows an error about it.

### Phone number handling

- **FR-019**: The UI and the API MUST accept any text as a phone number. They MUST make a best effort to convert it to E.164 format (for example `+15551234567`) before it is stored, and MUST NOT complain to the user about the data.
- **FR-020**: If a value cannot be converted to E.164, it MUST be stored exactly as entered, unmodified.
- **FR-021**: A phone search MUST be a "contains" search, so a partial number finds every contact whose phone includes it. The search ignores formatting characters (spaces, dashes, dots, parentheses, and the plus sign) and compares digits only, on both the stored value and the typed value. A partial number is not converted to E.164, because it cannot be.
- **FR-022**: The database does not validate or convert phone numbers. There is no check constraint on `contact.phone`.
- Consequence: because the search compares digits only, a value stored unmodified still matches when its digits include the typed digits.
- Consequence: a database index on `contact.phone` cannot speed up a "contains" search, only an exact or prefix match. At CRM volumes a full scan is fast, so the index stays, but it is no longer the main way phone lookups run.
- **FR-023**: When a number has no country code, the default is the United States, `+1`. For example `555-123-4567` and `(555) 123-4567` become `+15551234567`. A number that cannot form a valid US number this way stays unmodified under FR-020.
- **FR-024**: A contact's phone MAY be null, blank, `0`, or any other invalid value, and none of these is an error. Some people do not want to be contacted by phone. The field is optional (constitution Principle II), and no screen or endpoint may require or validate it.
- Consequence: a search for a blank or null phone is not a real lookup and matches nothing, so it never lists every contact without a phone.

### Searches that find more than one match

- **FR-025**: This applies to every search in the UI and the API, not only phone. Whenever a search finds more than one value, the user MUST be shown a list to choose from. The system MUST NOT pick one silently. The API returns the full list of matches.

### Success criterion

- **SC-008**: `python3 tools/check_schemas.py` prints ALL PASS, including the phone index checks.

## Change 8: show when a person is tied to more than one company

**Status: deferred.** A contact is tied to a single company. Finding the same person across companies will be built later as a separate batch job. Nothing is built for it now: no SQL, API, or UI work. The notes below are kept for when it is taken up.

### Requirements (for later)

- **FR-026**: Whenever the UI shows a person's contact information, it MUST notice that the person is associated with other companies and show that on the screen, for example: "Also owns...", "Is also a Registered Agent for...", "Is also an officer at...", "Also works at...", "Previously worked at...". Each line links to the other company.
- **FR-027**: The API MUST return, with each contact, the other companies the same person is associated with and the kind of tie to each, so the UI does not search for them.

### What the data model does today

- A `contact` row belongs to exactly one company (`company_id`). There is no person table, so one person at two companies is two `contact` rows.
- `contact.role` says what part the person plays in a decision (`DECISION_MAKER`, `INFLUENCER`, `BILLING`, `TECHNICAL`, `OTHER`). It does not say how the person is tied to the company (owner, registered agent, officer, employee), and nothing records that a tie has ended.

### Open decisions

- [NEEDS CLARIFICATION: how is "the same person" recognized across two `contact` rows? Proposed: an exact match on email (ignoring case) or on phone digits. A name alone is not enough, because names repeat.]
- [NEEDS CLARIFICATION: how is the kind of tie stored? Proposed: a new SRT domain for it (owner, registered agent, officer, employee) on a new optional `contact` column, plus an optional end date, where an end date means "previously".]

### Effect on the API and the UI

- **API:** each contact response gains a list of other associations (company, kind of tie, current or previous). The lookup uses the email and phone indexes.
- **UI:** the contact screen shows the lines in FR-026 and a link to each company. If a person has several, they are listed.

## Change 9: record how long each AI run takes

### Requirements

- **FR-028**: `ai_run.duration_ms` MUST mean the end-to-end run time in milliseconds, `finished_at` minus `started_at`. A trigger MUST set it whenever both timestamps are present, and code MUST NOT write it. It stays null until the run has both.
- **FR-029**: `ai_run` MUST have an optional `model_ms` integer, not negative, for the time spent waiting on the model. Code writes it. It is null when unknown. It is the fairer number for comparing models, because end to end also includes queue waiting, page fetches, and parsing.
- **FR-030**: Queue wait is `created_at` to `started_at`. It is not stored as its own column.
- **FR-031**: Code MUST write `started_at` and `finished_at` as UTC with milliseconds, for example `2026-11-21T14:03:05.123Z`, so the trigger's result is accurate to the millisecond.
- A `TEXT` column named `total_run_time` was considered and not added. A number can be averaged and sorted on a dashboard, text cannot, and a second column for the same fact could disagree with `duration_ms`. Readable text such as "2m 14s" is produced when the value is displayed.

### What changed

- `0001_init.base.sql` gained `model_ms`, a comment on `duration_ms`, and two triggers (`ai_run_duration_ins`, `ai_run_duration_upd`).
- `tools/check_schemas.py` tests that the duration is null before the run finishes, is exactly 134500 ms for the sample timestamps, and that a negative `model_ms` is rejected.
- `db/README.md` describes the timings.

### Effect on the API and the UI

- **API:** it writes `started_at` and `finished_at` with milliseconds and `model_ms`, never `duration_ms`. A dashboard query averages `duration_ms` and `model_ms` per model.
- **UI:** it shows durations as readable text, derived from the milliseconds.

### Success criterion

- **SC-009**: `python3 tools/check_schemas.py` prints ALL PASS, including the three timing checks.

## Change 10: entity-relationship diagrams

### Requirements

- **FR-032**: There MUST be one summary diagram that shows every table as a block with a line wherever a foreign key joins two tables, and no columns.
- **FR-033**: For every table, there MUST be a diagram of that table with all its columns and the tables related to it, both the tables it references and the tables that reference it. A table with no relationships appears alone. (This was first limited to tables with a foreign key and was widened to every table.)
- **FR-034**: The diagrams MUST be PlantUML files, generated from the built schema by `tools/gen_erd.py` into `doc/uml/`, where the repository's `plantuml.sh` already looks. `./tools/build_schema.sh` regenerates them, and `check_schemas.py` MUST fail if they are stale, so they cannot drift from the SQL.
- **FR-035**: Relationship lines MUST show whether the parent is required (the foreign key column is `NOT NULL`) or optional, and each per-table line MUST name its foreign key column. Columns MUST be marked primary key, foreign key, required, and SRT domain.

### What changed

- New: `tools/gen_erd.py` and 26 files in `doc/uml/`: the summary and one diagram for each of the 25 tables.
- `tools/build_schema.sh` runs the generator, `check_schemas.py` checks the files, and `db/README.md`, `README.md`, and `CLAUDE.md` describe them.

### Effect on the API and the UI

None. The diagrams are documentation only.

### Success criterion

- **SC-010**: `python3 tools/check_schemas.py` prints ALL PASS, including the diagram check, and every file in `doc/uml/` renders with PlantUML without errors.

## Change 11: split the location criterion into two questions

### Requirements

- **FR-036**: The seeded Fit criterion "Is the business in metro Atlanta or willing to work online?" MUST be two separate yes-or-no questions, because one question mixing two conditions cannot be answered cleanly by a person or a model:
  1. "Is the business in metro Atlanta?"
  2. "Is the business willing to work online?"

- **FR-037**: Every rubric question MUST be asked and answered on its own, one question at a time, so each answer is known to belong to one question. When a question is split, each new question keeps the weight of the original, so splitting never lowers a question's influence. Criteria are scored independently.

### What changed

- In `0001_init.base.sql`, criterion `...101` is now the first question and keeps its enrichment hint, `location`. The second question is a new criterion, `...106`, with no enrichment hint. The later Fit criteria moved down one `sort_order`.
- Each question has weight 3, the weight the combined question had. The Fit weights now total 16 (they were 13).

### Effect on scoring, the API, and the UI

- The two questions are scored separately and add up. A business in Atlanta that is not willing to work online now earns only part of what the combined question gave, and a business outside Atlanta that is willing to work online earns the other part. The combined question gave full credit if either was true.
- The weights are editable in the UI, and the real rubric is written once the UI exists. These are starting values.
- The API and the UI read criteria from the database, so neither needs a code change.

### Success criterion

- **SC-011**: `python3 tools/check_schemas.py` prints ALL PASS, and the seed holds the two questions in place of the one.

## Change 12: split the website criterion into two questions

### Requirements

- **FR-038**: The seeded Need criterion for web development, "Do they have no website, or one that looks out of date?", MUST be two separate yes-or-no questions, following FR-037:
  1. "Do they have a website?" (originally "Do they have no website?")
  2. "Does their website look up to date?" (originally "Does their website look out of date?")

### What changed

- In `0001_init.base.sql`, criterion `...203` is now the first question. The second is a new criterion, `...211`. Both keep the original weight, 4, and both keep the `website_quality` hint, because that one fact answers either. The next web development criterion moved down one `sort_order`.
- A company with no website has nothing to judge for the second question, so it is left unanswered. An unanswered question is left out of the score and lowers confidence, as for any criterion.

### Effect on the API and the UI

- None. Both read criteria from the database.

### Success criterion

- **SC-012**: `python3 tools/check_schemas.py` prints ALL PASS, and the seed holds the two questions in place of the one.

## Change 13: split the hosting criterion into three questions

### Requirements

- **FR-039**: The seeded Need criterion for web hosting, "Is the site slow, insecure, or often down?", MUST be three separate yes-or-no questions, following FR-037:
  1. "Is the site fast?" (originally "Is the site slow?")
  2. "Is the site secure?" (originally "Is the site insecure?")
  3. "Is the site reliably up?" (originally "Is the site often down?")

### What changed

- In `0001_init.base.sql`, criterion `...205` is now the first question. The other two are new criteria, `...212` and `...213`. Each keeps the original weight, 3.
- Each question points at the fact that usually answers it: `pagespeed_mobile` for slow, `https` for insecure, and `hosting_quality` for often down. The original question pointed all three at `hosting_quality`. These are hints only and are easy to change.

### Effect on the API and the UI

- None. Both read criteria from the database.

### Success criterion

- **SC-013**: `python3 tools/check_schemas.py` prints ALL PASS, and the seed holds the three questions in place of the one.

## Change 14: record how long each deal took to close

### Requirements

- **FR-040**: `deal` MUST have a `total_deal_time` column holding the whole seconds from `created_at` to `closed_at`. It is an integer, so a dashboard can average and sort it. Readable text such as "12 days" is produced when it is displayed.
- **FR-041**: A trigger MUST set it every time `stage` is updated to `WON` or `LOST`, and when a deal is inserted already in one of those stages. Code MUST NOT write it. It stays null while a deal is open.
- **FR-042**: If `closed_at` is empty when the stage becomes `WON` or `LOST`, the trigger stamps it with the current time first, so the value is never missing.

### What changed

- `0001_init.base.sql` gained the column and two triggers, `deal_total_time_ins` and `deal_total_time_upd`.
- `tools/check_schemas.py` tests a deal that is open, one that moves to a non-closing stage, one that closes with a given `closed_at` (exactly 216000 seconds for 2.5 days), and one that closes without one.
- `db/README.md` lists the durations under Conventions.

### Decided

- If a deal leaves `WON` or `LOST` and is reopened, `closed_at` and `total_deal_time` keep their old values. Reopening is not expected. If a reopened deal closes again, `closed_at` is already set, so it and the total stay as they were.

### Not covered

- A `closed_at` earlier than `created_at` gives a negative total. No check blocks it.

### Effect on the API and the UI

- **API:** it may set `closed_at` when it changes the stage, but it never writes `total_deal_time`. A dashboard query averages `total_deal_time` by engagement model, owner, or service.
- **UI:** it shows the value as readable text.

### Success criterion

- **SC-014**: `python3 tools/check_schemas.py` prints ALL PASS, including the four deal timing checks.

## Change 15: positive wording everywhere, and the code finds the needs

### Requirements

- **FR-043**: Every rubric question, answer, and enrichment fact MUST be worded positively, so that yes, true, or a high value is the good outcome. Examples: "Is the site mobile friendly?", `mobile_friendly`, `https`.
- **FR-044**: A need MUST be identified where an answer to a Need question is false or low. The scoring and matching code in the API MUST do this translation. A person MUST NOT have to invert anything.
- **FR-045**: Fit questions need no translation: a yes or high answer counts toward Fit, as before.
- **FR-046**: The polarity comes from the section of the question (`FIT` or `NEED`), not from a per-question setting. No new `invert` setting is added to a yes-or-no question.

### Consequences for the data and the code

- **API:** when it turns an answer into points for a Need question, a false answer earns the points and a true answer earns none. The enrichment hints then agree with the question: `mobile_friendly` being false is the evidence for a need, with no flipping.
- **UI:** it shows the questions and facts in their positive wording and shows the needs it found, for example as the gaps. It never asks the user to answer a question backwards.
- **Seed rubric:** the seeded Need questions are reworded in Change 16. The two rating questions that use `"invert": true` are already positive: higher means better. The setting is how the code does the translation, and it is covered by the ratings item that is on hold.

### What changed

- Constitution Principle VII states the rule, and CLAUDE.md lists it as a standing convention. No SQL changed.

### Success criterion

- **SC-015**: when the API is specified, a test shows that a false answer to a positive Need question counts as a need and a true answer does not.

## Change 16: reword the Need questions positively

### Requirements

- **FR-047**: Every seeded Need question MUST use positive wording (FR-043). Only the wording changed. The ids, services, weights, answer types, hints, and order are unchanged.

| Service | Was | Now |
| --- | --- | --- |
| `technical-seo` | Does the site fail Core Web Vitals on mobile? | Does the site pass Core Web Vitals on mobile? |
| `web-development` | Do they have no website? | Do they have a website? |
| `web-development` | Does their website look out of date? | Does their website look up to date? |
| `web-development` | Is the site hard to use on a phone? | Is the site easy to use on a phone? |
| `web-hosting` | Is the site slow? | Is the site fast? |
| `web-hosting` | Is the site insecure? | Is the site secure? |
| `web-hosting` | Is the site often down? | Is the site reliably up? |
| `agentic-systems` | Do they answer the same customer questions by hand, over and over? | Are their repeated customer questions answered automatically? |
| `lead-generation` | Do they say they need more customers or more leads? | Do they have enough new customers and leads? |
| `process-re-engineering` | Do they describe manual, repetitive, or error-prone work? | Do they describe their work as automated and reliable? |
| `cost-reduction` | Are they paying for tools or vendors they could consolidate? | Are their tools and vendors already consolidated? |

- The two Need rating questions, "How visible are they for their main search terms?" and "How active is their marketing today?", were already positive and are unchanged.
- The Fit questions were already positive and are unchanged.

### Still holds two or more conditions

Three of the new questions still joined conditions: "customers and leads", "automated and reliable", and "tools and vendors". They are split in Change 17.

### Effect on the API and the UI

- A false answer to any of these is a need (FR-044). The API does that translation when it computes points. Neither it nor the UI needs a schema change.
- Each enrichment hint now agrees with its question: `https` true means "Is the site secure?" is yes, and `pagespeed_mobile` high means "Is the site fast?" is yes.

### Success criterion

- **SC-016**: `python3 tools/check_schemas.py` prints ALL PASS, and no seeded Need question is worded as a problem.

## Change 17: split the three questions that still held two conditions

### Requirements

- **FR-048**: Following FR-037, each of these Need questions MUST be two separate questions, each keeping the weight of the original:

| Service | Original (weight) | New questions |
| --- | --- | --- |
| `lead-generation` | Do they have enough new customers and leads? (4) | Do they have enough new customers? Do they have enough new leads? |
| `process-re-engineering` | Do they describe their work as automated and reliable? (3) | Do they describe their work as automated? Do they describe their work as reliable? |
| `cost-reduction` | Are their tools and vendors already consolidated? (3) | Are their tools already consolidated? Are their vendors already consolidated? |

### What changed

- In `0001_init.base.sql`, the original ids `...208`, `...209`, and `...210` are now the first question of each pair. The second questions are new criteria `...214`, `...215`, and `...216`. None has an enrichment hint. Each service's questions are numbered 1 and 2.
- Each service now has two questions of equal weight, so a need for customers and a need for leads are found separately, and the service is matched to the one that is actually lacking.

### Effect on the API and the UI

- None. Both read criteria from the database.

### Success criterion

- **SC-017**: `python3 tools/check_schemas.py` prints ALL PASS, and no seeded Need question joins two conditions.

## Change 18: exact facts with optional notes

### Requirements

- **FR-049**: A fact that answers a rubric question MUST be an exact value, usually YES or NO, so the matcher can use it without reading text. One fact answers one question.
- **FR-050**: Every fact, whether proposed by an AI run or saved on the company, MAY carry an optional `notes` text for details. A quick answer needs no note. Notes stay with the single fact they describe, not in one shared field.
- **FR-051**: `source_detail` keeps one job: where the fact came from, such as a URL or a tool name.

### What changed

| Was | Now |
| --- | --- |
| `website_quality` (short text), the hint for two questions | `has_website` and `website_up_to_date`, each YES or NO, one per question |
| `hosting_quality` (short text) | `site_reliably_up`, YES or NO |
| `location` (text), the hint for the Atlanta question | `in_metro_atlanta`, YES or NO. `location` stays as a general text fact, no longer a hint. |
| `current_provider` (text) | one code: `NOBODY`, `OWNER`, `FREELANCER`, `AGENCY`, or `IN_HOUSE`, the same codes as the question's choices |

- New key `current_provider_name`: the name of whoever handles their web and marketing, for example an agency or a freelancer, present only when known. It is a separate fact, not a note, so it can be searched and grouped. Its own `notes` and `source_detail` say how it was found.
- `0001_init.base.sql`: the hints on four rubric criteria point at the new keys, and `ai_run_fact` and `enrichment_fact` each gained an optional `notes` column. The `source_detail` comment now says where a fact came from.
- `db/README.md`: the well-known keys table lists the new keys, and accepting a fact copies its `notes`.
- `tools/check_schemas.py` tests a fact with only a key and value, and a fact with a note.

### Left as they are

- `search_visibility` and `marketing_activity` were left as short text here. They became YES or NO facts in Change 20.
- Questions that never had a hint (for example the lead and cost questions) get none. Their answer is the quick YES or NO itself.

### Effect on the API and the UI

- **API:** it writes the exact fact and, when given, its note. Accepting an AI fact copies the note too. A false positive-worded fact is a need (FR-044).
- **UI:** a fact shows its value with an optional note beside it, so a quick YES or NO takes one click and a note is optional.

### Success criterion

- **SC-018**: `python3 tools/check_schemas.py` prints ALL PASS, including the two fact checks.

## Change 19: a table of well-known enrichment keys, for auto-complete

### Requirements

- **FR-052**: The well-known enrichment keys MUST be data, in a table named `enrichment_key`, so the UI can offer them as auto-complete suggestions. Each row has a key, a label, a value type, a description, a sort order, and an active flag.
- **FR-053**: `enrichment_key` is a hint list, not a constraint. `enrichment_fact.key` MUST NOT have a foreign key to it, so any tool can still post a fact with a new key.
- **FR-054**: The value type is a new System Reference Table (SRT) domain, `ENRICHMENT_VALUE_TYPE`: `YES_NO`, `NUMBER`, `RATING` (added in Change 20), `DATE`, `CODE`, and `TEXT`. The UI uses it to show a YES or NO toggle for a quick answer and a number field where a number belongs.
- **FR-055**: The API MUST suggest the active well-known keys plus every key already used in `enrichment_fact`, so a new key appears in the suggestions after its first use.
- **FR-056**: Every enrichment hint on a rubric question MUST be a key in `enrichment_key`. `check_schemas.py` MUST fail otherwise.

### What changed

- `0001_init.base.sql` gained the `enrichment_key` table, seeded with the 22 keys that were listed in `db/README.md`, and the `ENRICHMENT_VALUE_TYPE` domain. `tools/build_schema.sh` lists the new SRT column, so it has its trigger and its `-- SRT domain` comment.
- `db/README.md` describes the table and no longer carries its own copy of the key list, so the two cannot drift.
- `tools/check_schemas.py` checks FR-056, rejects an unknown value type, and confirms a fact with a brand-new key is still accepted.
- The diagrams now include `enrichment_key`: 27 files.

### Effect on the API and the UI

- **API:** an endpoint returns the suggestions in FR-055. Editing the table is an `ADMIN` action, like the service catalog (Change 4).
- **UI:** the fact editor offers auto-complete on the key, and shows a toggle, number field, or date field from the value type.

### Success criterion

- **SC-019**: `python3 tools/check_schemas.py` prints ALL PASS, including the hint check and the open-key check.

## Change 20: search visibility and marketing activity become 0 to 5 ratings with notes

### Requirements

- **FR-057**: `search_visibility` and `marketing_activity` MUST be ratings from 0 to 5, higher is better, with optional notes. A new `ENRICHMENT_VALUE_TYPE` code, `RATING`, says so, and the UI shows a 0 to 5 selector for it.
  - `search_visibility`: 0 = invisible, 5 = dominant, for their main search terms.
  - `marketing_activity`: 0 = none, 5 = very active, today.
- **FR-058**: What each level from 0 to 5 means is a general guideline, written later. Nothing in the database depends on it.
- **FR-059**: The notes of these two facts MAY hold two kinds of observation: what the customer says and what we observe. Suggested form, one line each: "Customer says: ..." and "We observe: ...". This is a convention, not a rule the database checks.

### What changed

- `0001_init.base.sql` gained the `RATING` value type, and both keys use it, with labels "Search visibility" and "Marketing activity" and descriptions that give the two ends of the scale. They match the two rating questions they hint at.
- `db/README.md` lists the new value type.
- These two facts were briefly YES or NO facts, and were changed to ratings before anything was built on them.

### Still open

- The 0 to 5 scale belongs to the rating changes that are on hold. If ratings later move to another scale, these two keys and the `RATING` value type change with them.

### Effect on the API and the UI

- **API:** it accepts a whole number from 0 to 5 for these keys, and an optional note. Accepting an AI fact copies the note.
- **UI:** it shows a 0 to 5 selector with a notes box beside it.

### Success criterion

- **SC-020**: `python3 tools/check_schemas.py` prints ALL PASS, and both keys have value type `RATING` in the seed.

## Change 21: keep only the registration and DNS keys the CRM uses

### Requirements

- **FR-060**: The CRM MUST hold an enrichment key only if something in it uses the fact. Andexor Grass Spider (AGS) owns its raw Registration Data Access Protocol (RDAP) and Domain Name System (DNS) data, so the CRM does not copy it.
- **FR-061**: `domain_expires` stays, because an expiring domain is a signal for a service to add to a proposal. Carmen MAY look it up itself until AGS provides it. After that, AGS posts it.

### What changed

- Removed from the `enrichment_key` seed: `registrar`, `domain_created`, `nameservers`, `soa_primary`, and `soa_serial`. The seed has 17 keys.
- Keys are open, so a tool can still post any of the removed keys. They are simply not suggested in auto-complete.
- `domain_expires` has a new description that says why it is kept. It is the only `DATE` key.

### Effect on the API and the UI

- **API:** it may look up the domain expiry date, until AGS does. Where the signal feeds a proposal is decided when proposals are specified.
- **UI:** none beyond the shorter suggestion list.

### Success criterion

- **SC-021**: `python3 tools/check_schemas.py` prints ALL PASS, and the seed has the 17 keys, with `domain_expires` as the only date.

## Change 22: new apps start at version 1.0.0

### Requirements

- **FR-062**: Whenever scaffolding of a Next.js or FastAPI app begins, its initial version MUST be set to `1.0.0`. This applies to every new project, not only Carmen. For Carmen, it governs the UI (Next.js) and the API (FastAPI).

### What changed

- The constitution's Tooling section states the rule. No SQL changed.

### Effect on the API and the UI

- Each is scaffolded at `1.0.0`: the `version` in `package.json` for the UI and in `pyproject.toml` for the API.

### Success criterion

- **SC-022**: when either app is scaffolded, its version file reads `1.0.0` before the first commit.



## Change 23: add the SBE-2026-ATLANTA lead source

### Requirements

- **FR-063**: The `LEAD_SOURCE` domain MUST include `SBE-2026-ATLANTA`, label "SBE 2026 Atlanta", description "Small Business Expo 2026 Atlanta", sort order 7, so leads gathered at that event can be tagged.

### What changed

- `0001_init.base.sql` has the new row after `OTHER`. `db/README.md` lists it, and `tools/check_schemas.py` checks that a company can use it as its source.
- The other codes use underscores, such as `CONTACT_US`. This one has hyphens. The SRT check only requires uppercase, so it is accepted as given.

### Effect on the API and the UI

- None. Both read lead sources from the SRT, so the new source appears in pickers by itself. `import_batch.source` and `company.source` accept it.

### Success criterion

- **SC-023**: `python3 tools/check_schemas.py` prints ALL PASS, including the company that uses the new source.
