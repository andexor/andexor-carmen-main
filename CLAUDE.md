# andexor-carmen-main: governing repository for Andexor Carmen

This repo governs the Andexor Carmen family. It holds no runtime code. Read this file, then `PRD.md`, before doing anything in this repo or in `andexor-carmen-ui` or `andexor-carmen-api`.

## Source of truth

- **`PRD.md`** is the master Product Requirements Document (PRD). Each child repo's `PRD.md` and Spec Kit artifacts (`spec.md`, `plan.md`, `tasks.md`) refine it and may not contradict it.
- **`Spec Kit`** is where all new requirements go. The master PRD and the child PRDs are frozen once the first commit of them lands: they seed the initial requirements only and are no longer edited. A later requirement that changes something the PRD says is recorded in Spec Kit, and where they differ, the Spec Kit artifact wins.
- **`db/`** is the common data model both apps follow: the Data Definition Language (DDL) for the one Carmen database. Schema changes are numbered migrations; see `db/README.md`.
- **The API contract** is the OpenAPI 3.1 specification that FastAPI generates from the code of `andexor-carmen-api`. This repo holds no hand-written draft of it and has no `api/` folder.
- **`.specify/memory/constitution.md`** is the Spec Kit constitution. It is copied, not rewritten, into the child repos.

## Standing conventions

The conventions in `andexor-glimpse-main/CLAUDE.md` apply here unchanged: naming, lowercase identifiers, UPPERCASE System Reference Table (SRT) codes, uppercase CSS hex colors, names spelled out on first use, one database per Worker, Secrets Store, Workers Routes (never Custom Domains), observability at full sampling, robots rules, the stack, and Spec Kit. Carmen-specific points:

1. **Hostnames.** `carmen.andexor.net` for production and `carmen-preview.andexor.net` for preview. On each, `/api/*` goes to `andexor-carmen-api` (`andexor-carmen-api-preview` in preview) and `/*` goes to `andexor-carmen-ui` (`andexor-carmen-ui-preview` in preview). One Cloudflare Access application per hostname covers both routes. Nothing is served from `workers.dev`.
2. **Few required fields.** Master PRD section 7 lists the only fields any table, endpoint, or form may require.
3. **AI proposes, a person decides.** No run changes a company record. Score arithmetic is done in code.
4. **Preview is gated.** Unlike the website services, Carmen's preview hostname (`carmen-preview.andexor.net`) sits behind Cloudflare Access.
5. **Positive wording.** Rubric questions, answers, and enrichment facts are worded so that yes or true is the good outcome. A need is an answer that is false or low, and the scoring code does that translation, never a person (constitution Principle VII).

## Working in this repo

- Schema changes are numbered migrations in `db/carmen/`. Every migration on `main` is applied to both databases; `python3 tools/migrate.py prev --dry-run` (or `prod`) shows whether any is pending. Never edit a migration that is already on `main`: `build_schema.py` keeps it as it is and `check_schemas.py` fails if any SQL file on `main` has changed.
- New migration: `./tools/new_migration.sh short_name`, write the changes in the `.base.sql` it creates, then `./tools/build_schema.sh && python3 tools/check_schemas.py`. A column that holds an SRT code carries a `-- SRT domain: X` comment (in `CREATE TABLE` or on an `ALTER TABLE ... ADD COLUMN` line); the triggers are generated from the comments in that file, and no list needs updating. Do not insert into `schema_migration`. The migrations need SQLite 3.47 or later; when the local SQLite is older, `build_schema.sh` and `check_schemas.py` re-run themselves on a Python that `uv` manages.
- Apply with `python3 tools/migrate.py prev`, then `python3 tools/migrate.py prod` (add `--dry-run` to see what is pending), before the pull request is opened. The pipeline of `andexor-carmen-api` (`.github/workflows/ci.yml` there) also applies whatever is pending on this repo's `main` each time it runs: a pull request there migrates the preview database, and a push to its `main` migrates production. A merge in this repo does not start that pipeline, and no workflow in this repo touches a database. After a merge, do not ask for the migration to be applied and do not suggest it; bring up the migration state only when there is evidence that one failed to apply. `schema_migration` decides what is pending. `build_schema.sh` also regenerates the E/R diagrams in `doc/uml/`, and `check_schemas.py` fails if they are stale. After a table change, run `./plantuml.sh` to redraw the SVG files in `doc/uml/images`.
- `.github/workflows/checks.yml` runs `check_schemas.py` and pyright on every pull request. Its job is named `Preview and smoke test` because the default-branch ruleset requires a check with that name; do not rename it.
- Keep `PRD.md` section numbers stable; the child PRDs cite them.
- Verify Cloudflare and GitHub state with read-only calls before the first write.

## Implementation order

`andexor-carmen-main` → `andexor-carmen-api` → `andexor-carmen-ui`. Each child PRD ends with its Spec Kit feature backlog.

## Open items

None. How every question and discovery item was closed is in `specs/001-review-open-items/decisions.md`.
