---
name: init
description: Kickstart a loom project with one command, in an empty folder or an existing repo — a hello, a few native prompts, a silent skeleton, PROJECT.md written from the actual answers; a pasted spec becomes docs/spec.md and answers most questions. Use on "/loom:init", "new project", "set this up", "adopt loom here".
---

# loom:init — kickstart

Everything you need is in this file: do not open, cat, ls or find any file of this plugin. No
tool call before the hello. The result is predictable: PROJECT.md holds only what an answer or
the spec confirmed. Anything you would have to guess becomes a prompt with your candidates as
options. Prompts are AskUserQuestion, one at a time, each built from the answers so far. Never
say what loom is or what you are doing — no "starting init", no step names, no tour.

## 1. Hello — your first message, nothing before it

    ⚓ loom — you lead, models build, git remembers.

Same turn, AskUserQuestion, header `Start from`: "What are we starting from?"
- A spec or requirements doc — I'll paste it (Recommended when they have one)
- New idea — I'll describe it
- Existing code — read it and propose
- Skeleton only — I'll fill PROJECT.md myself

**Spec** → "Paste it." Save it verbatim as `docs/spec.md` (after step 4 makes the folder;
keep the text in hand until then). The spec is `Said:` for everything it covers: name, what,
for whom, out-of-scope, stack and policies. Ask only what it does not say. A long paste (more
than ~15 lines) at any prompt is a spec — treat it the same.
**Existing code** → loom:scout (haiku) reads README, manifests, tests, CI, docs/ — ≤ 15 lines
of facts; each prompt below shows your draft as the recommended option.
**Skeleton only** → step 4 with `--template`, then commit; no questions, no flow page.

## 2. What — one line

New idea: in chat, "One line: what is it, and for whom?" — then wait. Spec or existing code:
AskUserQuestion with 2–3 one-liners you drafted; the human picks or rewrites.

## 3. Prompts, one at a time, ≤ 5 in total

- **Scale + language** — one call, two questions, skipped when the spec states them:
  header `Scale` · "A year out, how big?" — Me and a few people (≤ 10 users · ≤ 1 RPS · MBs)
  (Recommended) · Small (≤ 1k · ≤ 10 RPS · GBs) · Real traffic (10k+ · 100+ RPS · TBs) ·
  exact numbers → Other. header `Language` · "Docs language?" — English · Russian (Other: any);
  code and commits stay English either way.
- **Milestone** — header `Milestone` · "First thing a stranger could demo?" Three demos for
  this product, each an "a stranger can …" sentence with the command that would prove it;
  with a spec, the smallest end-to-end slice of it comes first (Recommended).
- **Never** — header `Not now`, multiSelect · "Out of scope for now?" Four scope traps typical
  for this kind of product, one short reason each. With a spec: its out-of-scope list is
  already Never — show it, don't ask.

Skip any prompt the human already answered in their own words.

## 4. Skeleton — one command, output not shown

    sh "${CLAUDE_PLUGIN_ROOT}/skills/init/scripts/init.sh"          # add --template for Skeleton only

If that variable is empty, the path is the directory this SKILL.md was loaded from +
`scripts/init.sh`. PowerShell without Git Bash: `init.ps1`. Idempotent, never overwrites,
safe in an existing repo: git init, `docs/` folders, two CLAUDE.md lines, `.gitignore` basics,
`docs/.obsidian/graph.json` (open `docs/` as the vault). Exit code ≠ 0 → show the error and stop. Otherwise say nothing.

## 5. PROJECT.md — write it once, ≤ 40 lines

    # <name> — <one line>
    For: <who>
    Language: en
    Numbers: <users> · <RPS> · <data>
    Spec: [[spec]]                     ← only when docs/spec.md exists

    Milestone 1: "<the chosen sentence>"
    Done when: `<its command>`

    Now (≤ 3):
    - <the first one or two steps toward the milestone; existing code: what is in progress>
    Next:
    Never (last 5; older → decisions):
    - <item> — <why>
    Flows: [[flows/<milestone-slug>]]
    Core:
    Rules:
    - check: <the test command, when known — a bare command exactly as `sh -c` runs it, no
      backticks, no prose; what it needs it starts itself: `docker compose up -d && go test ./...`>
    - <hard constraints from the spec, one line each, ≤ 6: stack, "stdlib only", policies>

Then `docs/Home.md` from `templates/Home.md`, filled from the actual answers — the product
paragraph, the milestone under Where we are, Start here, an empty How-it-works table, the first
Journal line — and `docs/flows/<milestone-slug>.md`: a title like "How a stranger becomes an
owner", three sentences of story, a mermaid sequence diagram, the milestone sentence as steps, linking the features
they imply even before they exist, `Done when:` its command, `Serves: [[PROJECT#Milestone 1]]`.
Commit only what init made: `git add docs CLAUDE.md .gitignore && git commit -q -m
"loom: init"` (`Rules: commit: ask` → ask first). In an existing repo, say in one line that two
lines were appended to CLAUDE.md.

## 5b. Map — existing code only, before the End line

One prompt, header `Map the code` · "Write the wiki for what already exists?" — Now
(Recommended: a few minutes on small models) · Later (a page is written when its code is first
touched) · Never. **Now**: loom:scout (haiku), one per group of ≤ 4 top-level code directories
(Go packages, `src/` folders, Python packages; skip generated and vendored code), all in one
message in parallel, ≤ 15 lines of facts each: what the module does, its entry points, its
files, the tests that hold it, its env knobs. Then loom:scribe with `model: haiku`, one per
module, in parallel, brief = that module's facts + the path to nodes.md + the flow it serves:
the **map** article (see the scribe). Cap 12 modules: past that, `areas/<name>.md` hubs group
the rest and only the modules the milestone touches get pages now. Then you: a row per page in
Home's How-it-works table, `Core:` in PROJECT.md for the modules a user flow crosses, one
Journal line "Mapped N modules", `status.sh` (every mapped page reads ✅ built — adopted
<date>) and `check.sh` clean, one commit `loom: map <n> modules`.

## 6. End — no file dump

The files are on disk and PROJECT.md is in every session's context; don't paste them. One
line: `PROJECT.md · Milestone 1: <sentence> · Now: <n> · Never: <n> · Rules: <n>` (+ ` ·
docs/spec.md` when saved, ` · mapped: <n> modules` after a map). Then, with a spec: one prompt — Design milestone 1 now
(Recommended) · later. Without: the line **Next: tell me what to build — or ask "what's next".**

## Existing docs — one more prompt, existing code only

If scout found docs (architecture sections, ADRs, a wiki, a CHANGELOG), header `Your docs` ·
"Bring existing docs up to loom's shape?" — Later, loom:wiki rewrites a page whenever a feature
is touched (Recommended) · Now, loom:scribe turns them into docs/ nodes, originals stay, you
review the diff · Never. "Now": scribe gets the file list and the nodes template, returns the
files written; show `git diff --stat docs/` and stop. Docs are a two-way door.
