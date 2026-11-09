---
name: wiki
description: The docs/ graph — frames, features, flows, decisions, risks, concepts, linked for Obsidian: who writes which node at design and at run time, how "explain …" answers from them, how the graph grows, and the linter that keeps it honest. Called by loom:design, loom:run and the human ("explain", "why is it like this").
---

# loom:wiki

Principles 6, 7, 8, 9 (loom:lead). Templates and the link vocabulary: references/nodes.md —
the scribe reads it; you don't need to.

## Who writes what

- **loom:design** — scribe, brief = the frame text + the real test and file names: the frame,
  its decisions as sections of `decisions/<feature>.md` and its risks as sections of
  `risks/<feature>.md` — a human heading, a paragraph, a block id `^D-<slug>-n` / `^R-<slug>-n`
  — and a feature stub. One file per feature, one section per door or risk, newest last; ids
  namespaced by the frame slug, so branches never collide.
- **loom:init on existing code** — the *map*: scouts (haiku) inventory the code, a scribe
  (haiku) writes one article per module from those facts, the lead adds Home rows and `Core:`.
- **loom:run** — scribe, brief = the report + the code's real names: the feature page
  finished, the nodes filled, the frame `Status: done`. Only that frame's files.
- **the lead**, on the base branch: `docs/Home.md` — the front page a human opens first (where
  we are, start here, how it works, decisions worth knowing, a dated Journal) — a row and a ⏳
  line at design, ✅ and a Journal line from the report at every merge; Start here and How it
  works read oldest to newest (a new milestone's flow goes last), the Journal newest first; no
  hard wraps in any page you write — one line per paragraph and per list item; PROJECT.md (Now, Next,
  Never, Done, Core, Flows); the frame's `Merged:`; `docs/flows/*` at init and at a milestone,
  with a mermaid diagram; `docs/concepts/*` from `New:` lines after a merge; `docs/areas/*`
  past 7 features. Nobody else touches these.
- **status.sh** — the `Status:` line under every feature title and the glyph on Home's
  Where-we-are lines, derived from the frames a page's Trace line names (Status:, Wave:,
  Merged:) and PROJECT.md's Now: ⏳ planned · 🔄 building · ✅ built with the merge date. The
  lead runs it at design and after every merge, the run after its scribe; nobody writes those
  by hand, and check.sh fails while one is stale.

Core feature = a user flow, a public interface, or a config a human must set.

## Explain — main session, no agent

Read the page, then one hop along its Decided and What-must-not-change links. Plain words: no class, library or
pattern names outside "Where". Not there → scout reads the code, you answer, and offer in one
line to write it down. Never answer from memory of the chat.

## Growth — context stays O(1) (8)

- Hubs, never moves: past 7 features, `docs/areas/*.md` pages that PROJECT.md links instead.
- `Never` keeps its last 5; older → a section `## D-never-n · Not doing: <x>` in `decisions/project.md`.
- `Next` past 10 → `docs/backlog.md`, or the tracker through loom:sync; PROJECT keeps the top.
- Decisions are never deleted; `Supersedes:` keeps the chain. Risks close with `#closed` and
  `Closed by:`; the file stays. Finished milestones compress to one `Done:` line.
- PROJECT.md stays ≤ 40 lines: Now ≤ 3, Next ≤ 5 shown, Never ≤ 5, Rules ≤ 6.

## Honest docs

`sh "${CLAUDE_PLUGIN_ROOT}/skills/wiki/scripts/check.sh"` — every `[[link]]` resolves, every
`#^D-`/`#^R-` block id exists, no link is wrapped across lines or carries a backtick, every cited
`path/file:name` exists, every `Frame:` trailer has a file, every feature's Status line matches
its frames, and no feature prose says whether a thing is built. Run it at every milestone
and in CI; a miss is fixed or dropped, never left.

## Trace (9)

Node → `Frame: [[frames/F-<slug>]]` → `Merged: <sha or PR#>` → the diff. Commit and PR bodies
carry the report and the `Frame:` trailer: `git log --grep='Frame: F-<slug>'`. Squash-safe.
