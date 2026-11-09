---
name: sync
description: One-way mirror of loom docs/ and Now/Next into an external wiki or tracker — ClickUp, Notion, Confluence, or a static site. Never two-way. Runs on the cadence set by `Rules: sync:` or on "/loom:sync". Obsidian needs nothing; it reads the files.
---

# loom:sync

The repo is the truth (9). The remote is a mirror: nothing flows back,
and automation never deletes remotely — it archives.

## Config — in PROJECT.md

    Sync: clickup list=901234 · notion parent=<page-id> · confluence space=ENG · site=quartz
    Rules: sync: on milestone | on report | manual        (default: manual)

No `Sync:` line → this skill does nothing (5). Several targets → one
courier run per target, in the order written.

## Run — courier (sonnet); brief = changed files + the target's reference + exact tool names

1. Changed since last sync: `git diff --name-only loom/synced -- docs/` (no tag → all of docs/).
2. Push each node: no `Remote:` trailer → create and write the trailer back;
   trailer present → update. PROJECT.md → the index page. Now / Next →
   tasks or rows, trackers only.
3. Second pass: rewrite `[[links]]` in remote bodies using the `Remote:` ids.
4. Return created / updated / skipped, with ids.
5. Main session checks `git diff --name-only`: only `Remote:` trailers may
   have changed. Then `git tag -f loom/synced` — local, not pushed — and
   commit the trailers: `docs: sync <target>`.

## Targets — one reference each, loaded only for the configured one

references/clickup.md · notion.md · confluence.md · site.md

## Alternatives, simplest first (6)

- none — Obsidian, Logseq, Foam read `docs/` as it is.
- site — Quartz or MkDocs build `docs/` into a read-only site in CI; zero mapping, no courier.
- tracker or wiki product — this skill; costs an MCP connector and a courier run per sync.

## Auth

The target's MCP connector must already be authorized in claude.ai
connector settings. If its tools are absent, say which and stop. Never
ask for tokens, never put credentials in a brief.
