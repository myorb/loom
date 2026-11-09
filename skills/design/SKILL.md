---
name: design
description: One sitting with the human that turns a feature, several features, or a milestone into approved frame files — gaps, doors, data model, risks, plan, and what happens after — so loom:run can execute them unattended, in parallel where they don't touch the same files. Use on "design", "plan the milestone", "frame this", or when loom:lead reaches an effort.
---

# loom:design — answer everything once, then let it run

Principles 1, 2, 5, 6, 7 (loom:lead). The frame is the spec: a run may deviate from it
visibly, never silently. Nothing enters a frame that an answer did not confirm; what you
assumed is under `Assumed:`. ≤ 5 frames per sitting, ≤ 3 prompts per frame — the Model loop
counts as one; more is another sitting.

## Sitting

1. **scout** (haiku) → facts on the current branch. `Base:` = `git rev-parse --short HEAD`,
   `Branch:` = `git branch --show-current`. Per feature it also returns the entry points a
   builder will change or copy — the functions, routes, queries, templates and tests, each as
   file:line — which become the frame's `Map:`; a builder starts there and never surveys the
   codebase.
2. Said / Unknown for the whole request, as in loom:lead — prompts until no Unknown is left.
   `docs/spec.md`, when it exists, is Said for everything it covers: scout extracts the lines
   for the features at hand (≤ 15), and every frame quotes the spec lines it implements.
3. Per feature, in order:
   - **Gaps** — at most one prompt, ≤ 4 questions, and only for what you cannot undo cheaply
     or defend as a default: an edge case that changes the design, what "done" looks like when
     two readings exist, the thing they didn't mention that forks the build. Numbers with sane
     defaults (timeouts, limits, sizes), names, wording, anything env-overridable → one
     `Assumed:` line each, never a question. A question whose Recommended option you would
     take anyway is an assumption, not a question. Options are one axis each — never bundle
     unrelated choices into presets. Touching an existing core feature → rewrite its page
     (Recommended) / leave it.
   - **Frame** — the block as text, then one prompt: a question per door (your pick
     (Recommended) vs the rejected — why), one per risk you would mark irreversible — confirm
     with the one or two probes the adversary will run (Recommended, e.g. `attack: retry, clock`
     from boundary · retry · clock · race · partial failure) / tests only — `attack: none` /
     downgrade, by `Numbers:` — and `Then:` — merge (Recommended: no irreversible risk, no
     remote) · pr (Recommended when `origin` exists) · review (Recommended with an irreversible
     risk, a Model, or UI in Touch) · hold. Answering is the yes. Three doors at most: a fourth
     means the frame is two frames, or it was never a door — an `Assumed:` line.
   - **Model** — its own prompt whenever data is stored or exchanged: fields · types · keys ·
     one example record; approve, or change (say what); loops until approved.
   - **Plan** — the tasks, one line each: what · Touch · check. **A task is ten to fifteen
     minutes of one builder**: one package's worth of change — a migration with its queries
     and test, one service with its tests, one page with its e2e. "Every mail through the
     queue" or "the JSON API" is a frame, not a task: when the sitting cannot name a task
     that small, the frame is two frames in consecutive waves. **≤ 3** tasks — each is a
     builder with a fresh context against a real database, so a run's wall time is the plan's
     depth; **two** when every task lands in the same package (auth, the token path). What
     does not fit is `2a`/`2b` with disjoint files, or another frame — never a fourth task.
     A rewrite of paths that already exist counts double. Tasks that don't
     depend on each other and touch different files share a number with a letter — `2a`, `2b`
     — and run in parallel inside the run; their checks must be scoped to their own files (a
     test module, not the whole suite). Independent work that is its own feature (tooling, CI)
     is its own frame in the same wave. Shown under the frame; the Go covers it.
4. **Waves** — frames whose Touch sets, feature pages, lockfiles and migrations are pairwise
   disjoint share a wave; the rest wait. Say the waves in one line; prompt only if the order
   could matter to the human.
5. **Artifacts** — **scribe** (pass `model: haiku` in the Agent call — the stubs and sections
   come from the frame's own text, no code is read, and sonnet took ten minutes a frame) writes them now: `docs/frames/F-<slug>.md` (`Status: approved`;
   a slug already used gets `-2`), a section per Weigh line in `decisions/<feature>.md` (a human
   heading, the paragraph, the Model inside, the block id `^D-<slug>-n`), a section per Risks
   line in `risks/<feature>.md` (`^R-<slug>-n`), a `features/<name>.md` stub for a
   new feature. You
   update PROJECT.md: Now ← wave 1 (≤ 3, as `[[frames/F-<slug>]]`), Next ← later waves.
   You add the feature's row to `docs/Home.md` under How it works (one sentence) and its ⏳
   line under Where we are — Home is the lead's, never the scribe's. Then one call,
   `sh "${CLAUDE_PLUGIN_ROOT}/skills/wiki/scripts/status.sh"`, writes the Status line under
   each feature title from its frames (⏳ waiting · 🔄 for a frame in Now) and keeps Home's
   glyphs; `check.sh` clean; commit only those files: `loom: design <what>`. A new milestone's flow
   goes at the end of Start here and its block below the earlier milestones: the page reads
   oldest to newest; only the Journal is newest first.
6. **End** — one prompt: run wave 1 now (Recommended) · adjust — I'll say · later.

## Frame file — the run's whole brief

    # F-<slug> — <Goal, one sentence>
    Status: approved · Then: merge | pr | review | hold · Wave: n · Base: <sha> · Branch: <name>

    Said:       the human's constraints, quoted
    Assumed:    what you decided without asking, one line each — or none
    Done when:  one backticked command + expected output — verify.sh runs exactly that one;
                extra conditions go into it with `&&`; for UI, "inspector ok on the lines below"
    Weigh:      door → pick vs rejected — why → [[decisions/<feature>#^D-<slug>-n]]   (≤ 3)
    Model:      approved — fields · types · keys · example → [[decisions/<feature>#^D-<slug>-n]]
    Touch:      exact paths to change; `dir/` where new files may appear; nothing else. Name the
                package, not its sub-folders: a migration's tests live in `internal/db/`, not in
                `internal/db/migrations/` — every run so far has tripped on this
    Map:        where each task starts — the functions, routes, queries, templates and tests it
                changes or copies, as file:line from the scout, one line per task; a builder
                reads these files first and surveys nothing else
    Risks:      R-<slug>-n — what breaks · how bad · how you'd know · irreversible: confirmed | no · attack: <probes> | none
    Not doing:  one reason each
    Gaps:       each question and its answer, one line each
    Page:       rewrite | leave — for an existing feature page
    Plan:
    1. <what> — <Touch> — <check>
    2a. <what> — <its files> — <its own check>     ← 2a and 2b run in parallel; disjoint files
    2b. <what> — <its files> — <its own check>

What the run needs and nothing from the chat (8). The run reports deviations against this file;
the lead merges by its `Then:`. `From: loom/F-<slug>` on a follow-up frame continues that branch.

## Let's think

"Let's think / what if" is this sitting without steps 5 and 6: doors, options, your pick and
the rejected one, in chat. Nothing is written.
