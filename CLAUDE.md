# andexor-carmen-main: governing repository for Andexor Carmen

This repo governs the Andexor Carmen family. It holds no runtime code. Read this file, then `PRD.md`, before doing anything in this repo or in `andexor-carmen-ui` or `andexor-carmen-api`.

## Source of truth

- **`PRD.md`** is the master Product Requirements Document (PRD). Each child repo's `PRD.md` and Spec Kit artifacts (`spec.md`, `plan.md`, `tasks.md`) refine it and may not contradict it. A conflict is resolved by amending the master first, then the child.
- **`Spec Kit`** is where new requirements are added after the PRD is written. The PRD is for the seeding of initial requirements only and will not be maintained.
- **`db/`** is the common data model both apps follow: the Data Definition Language (DDL) for the one Carmen database. Schema changes are numbered migrations; see `db/README.md`.
- **`api/`** will hold the OpenAPI 3.1 contract for `andexor-carmen-api`, drafted from the API PRD. Once code exists, FastAPI's generated specification replaces it.
- **`.specify/memory/constitution.md`** is the Spec Kit constitution. It is copied, not rewritten, into the child repos.

## Standing conventions

The conventions in `andexor-glimpse-main/CLAUDE.md` apply here unchanged: naming, lowercase identifiers, UPPERCASE System Reference Table (SRT) codes, uppercase CSS hex colors, names spelled out on first use, one database per Worker, Secrets Store, Workers Routes (never Custom Domains), observability at full sampling, robots rules, the stack, and Spec Kit. Carmen-specific points:

1. **Hostname.** `carmen.andexor.net`. `/api/*` goes to `andexor-carmen-api`; `/*` goes to `andexor-carmen-ui`. One Cloudflare Access application covers both.
2. **Few required fields.** Master PRD section 7 lists the only fields any table, endpoint, or form may require.
3. **AI proposes, a person decides.** No run changes a company record. Score arithmetic is done in code.
4. **Preview is gated.** Unlike the website services, Carmen's preview URLs sit behind Cloudflare Access.

## Working in this repo

- Edit `db/carmen/0001_init.base.sql`, never `0001_init.sql`. Then run `./tools/build_schema.sh && python3 tools/check_schemas.py`. When a new column holds an SRT code, add it to the list in `tools/build_schema.sh`.
- Until the first production deploy, `0001_init` may be edited in place. After that, every change is a new numbered migration.
- Keep `PRD.md` section numbers stable; the child PRDs cite them.
- Verify Cloudflare and GitHub state with read-only calls before the first write.

## Implementation order

`andexor-carmen-main` → `andexor-carmen-api` → `andexor-carmen-ui`. Each child PRD ends with its Spec Kit feature backlog.

## Open items

Master PRD section 12, Q1 to Q8, and discovery items R1 to R3.
