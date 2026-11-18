# andexor-carmen-main: governing repository for Andexor Carmen

This repo governs the Andexor Carmen family. It holds no runtime code. Read this file, then `PRD.md`, before doing anything in this repo or in `andexor-carmen-ui` or `andexor-carmen-api`.

## Source of truth

- **`PRD.md`** is the master Product Requirements Document (PRD). Each child repo's `PRD.md` and Spec Kit artifacts (`spec.md`, `plan.md`, `tasks.md`) refine it and may not contradict it.
- **`Spec Kit`** is where all new requirements go. The master PRD and the child PRDs are frozen once the first commit of them lands: they seed the initial requirements only and are no longer edited. A later requirement that changes something the PRD says is recorded in Spec Kit, and where they differ, the Spec Kit artifact wins.
- **`db/`** is the common data model both apps follow: the Data Definition Language (DDL) for the one Carmen database. Schema changes are numbered migrations; see `db/README.md`.
- **`api/`** will hold the OpenAPI 3.1 contract for `andexor-carmen-api`, drafted from the API PRD. Once code exists, FastAPI's generated specification replaces it.
- **`.specify/memory/constitution.md`** is the Spec Kit constitution. It is copied, not rewritten, into the child repos.

## Standing conventions

The conventions in `andexor-glimpse-main/CLAUDE.md` apply here unchanged: naming, lowercase identifiers, UPPERCASE System Reference Table (SRT) codes, uppercase CSS hex colors, names spelled out on first use, one database per Worker, Secrets Store, Workers Routes (never Custom Domains), observability at full sampling, robots rules, the stack, and Spec Kit. Carmen-specific points:

1. **Hostnames.** `carmen.andexor.net` for production and `carmen-preview.andexor.net` for preview. On each, `/api/*` goes to `andexor-carmen-api` (`andexor-carmen-api-preview` in preview) and `/*` goes to `andexor-carmen-ui` (`andexor-carmen-ui-preview` in preview). One Cloudflare Access application per hostname covers both routes. Nothing is served from `workers.dev`.
2. **Few required fields.** Master PRD section 7 lists the only fields any table, endpoint, or form may require.
3. **AI proposes, a person decides.** No run changes a company record. Score arithmetic is done in code.
4. **Preview is gated.** Unlike the website services, Carmen's preview hostname (`carmen-preview.andexor.net`) sits behind Cloudflare Access.

## Working in this repo

- Edit `db/carmen/0001_init.base.sql`, never `0001_init.sql`. Then run `./tools/build_schema.sh && python3 tools/check_schemas.py`. When a new column holds an SRT code, add it to the list in `tools/build_schema.sh`.
- Until the first production deploy, `0001_init` may be edited in place. After that, every change is a new numbered migration.
- Keep `PRD.md` section numbers stable; the child PRDs cite them.
- Verify Cloudflare and GitHub state with read-only calls before the first write.

## Implementation order

`andexor-carmen-main` → `andexor-carmen-api` → `andexor-carmen-ui`. Each child PRD ends with its Spec Kit feature backlog.

## Open items

Master PRD section 12, Q1 to Q8, and discovery items R1 to R3.
