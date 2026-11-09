<p align="center"><img src="logo.png" alt="loom" width="200"></p>
<h1 align="center">loom</h1>
<p align="center"><b>You lead. Models build. Git remembers.</b></p>
<p align="center">A working method for building a product with Claude Code, packaged as a plugin.</p>

You decide what is expensive to undo; everything else is written down as a *frame* and executed
by itself in a worktree; work comes back as a delta with evidence; the reasons stay in the repo.
Nobody "writes docs" — a linked wiki grows as a side effect of the work.

Built solo-first. A team gets the same loop: a run can end in a pull request whose body is
the run's report.

One rule does most of the work: a **one-way door** — schema, public interface, new dependency,
external system, auth model, or anything that costs more than a day to undo, data and users
included. No door → it does the thing and reports one line. A door → one sitting: the gaps, the
doors weighed against their rejected alternatives, the data model, the risks and what will be
tried against them, the plan, and what happens after. That becomes a frame file. Then it runs.

## Words

- **Lead** — the attended session, the one that talks to you. It triages, designs with you,
  launches runs, watches them, and is the only thing that changes the base branch.
- **One-way door** — a decision that costs more than a day to undo: a schema, a public
  interface, a dependency, an external system, an auth model, anything touching data or users.
  Doors are weighed and asked; everything else is just done.
- **Lanes** — how a request is sized: *micro* (no door, at most three files: done inline and
  committed), *fix* (a bug: reproduce first), *effort* (a door or real work: designed, then run),
  *refactor* (behaviour kept, checks prove it).
- **Sitting** — one conversation, at most three prompts, that turns a feature or a milestone
  into frames. Gaps first, then the doors, the risks and the probes to run against them, then
  the data model — you approve each, and can strike any check you don't want paid for.
- **Frame** — the spec for one run, a file in `docs/frames/`: what you said, what was assumed,
  when it is done, the doors and what they rejected, the data model, which files it may touch,
  the risks — each with the probes the adversary will run, or none — what it is not doing, the
  plan, and what happens after.
- **Wave** — frames that don't touch the same files; they run at the same time. The next wave
  starts when this one has merged.
- **Run** — one frame executed unattended in its own worktree and branch, with a budget. It
  never asks; it stops with `blocked:` when the frame doesn't answer something.
- **Heartbeat** — the one line the lead shows every few minutes while a run is alive: elapsed,
  live step, tasks landed, anything off course.
- **Steer** — you interrupt a run with one sentence; it lands in the frame, the same session
  resumes with it.
- **Report** — the fixed block every run ends with: deviations, assumptions, evidence, what was
  skipped, noticed, new, open. It is the commit body and, for a team, the PR body.
- **Then** — what happens after a green run, chosen in the sitting: merge, a pull request, a
  review with you, or hold.
- **Nodes** — the pages under `docs/`, written for a colleague who joined yesterday: `Home.md`
  is the front page (where we are, start here, how it works, a journal); flows tell the story
  with a diagram; features are short articles; decisions and risks are sections with human
  headings. Linked so that Obsidian draws the map. `docs/PROJECT.md` is the project's system
  prompt.
- **Rules** — the one config surface, a few lines in `docs/PROJECT.md`: budgets, checks,
  models, what to pass into runs.

## The loop on one screen

       you ─ "add X" · "this bug" · "design the milestone" · "explain Y" · "stop" · "not that way: …"
        │
        ▼
      ┌──────────────────── loom:lead — your session, attended ──────────────────────┐
      │ know before you build: Said / Unknown / Assumed  →  is there a one-way door? │
      │   no door, ≤ 3 files ─▶ micro: do · run the check · commit, one-line report  │
      │   a bug ──────────────▶ fix: reproduce first · cause · fix (micro or frame)  │
      │   a door, a feature ──▶ loom:design — one sitting, ≤ 3 native prompts        │
      └──────────────────────────────────┬───────────────────────────────────────────┘
                                         ▼
                      docs/frames/F-<slug>.md — the spec · Status: approved
                      Said · Assumed · Done when · Weigh (≤ 3 doors) · Model ·
                      Touch · Map · Risks · Not doing · Plan (≤ 3 tasks of 10–15 min, 2a ‖ 2b) · Then
                                         │
              wave.sh ── every approved frame of the lowest wave, detached from you
                                         ▼
      ┌─── loom:run — headless, worktree ~/.loom/<repo>/F-<slug>, branch loom/F-<slug> ───┐
      │ builder per task (wip commit each) → adversary: your approved probes (≤ 2 passes) │
      │ → verify.sh → scribe writes the nodes → commit.sh: one commit, body = the report  │
      │ bounded: minutes · dollars · turns · allowlisted env · a guard on every command   │
      └───────┬─────────────────────────────────────────────────────────────▲─────────────┘
              │ heartbeat: F-x · 9m · turn 23 · builder: task 3 · 2/4 done  │ steer.sh F-x "…"
              ▼                                                             │ stop · frame · resume
             you ── the session stays yours: "stop" · "not that way: …" ────┘
              │
              ▼
      collect.sh → verify.sh (the checks re-run in the worktree) → Then: merge | pr | review | hold
      merge: git merge --no-ff on the base branch · frame Status: merged · feature pages ✅ · wiki linted · worktree gone

## When what fires

| You say, or it happens | What fires | What you get |
|---|---|---|
| `/loom:init` | a hello, ≤ 5 native prompts (a pasted spec answers most of them), a silent skeleton; existing code: small models map every module into a wiki page | `docs/PROJECT.md`, `Home.md`, a flow, one commit `loom: init`; on existing code a page per module |
| a small change, no door | the lead does it inline, runs `Rules: check`, commits | a one-line report in the commit |
| a bug | the fix lane: reproduce first, then the cause, then the fix | a test that pins it |
| a feature, "design", or a door inside a small ask | loom:design: gaps → the frame (doors, risks and the probes to run against them, what happens after) → the data model; you approve each | `docs/frames/F-x.md`, decision and risk sections, a feature stub |
| approved frames exist | `wave.sh` launches the lowest wave, detached | `.loom/runs/F-x.status` per run, a `loom/F-x` branch each |
| a run is alive | `wait.sh 300` in the background — one heartbeat line per return | your session answers you meanwhile |
| the heartbeat says `outside Touch: n` or `(20 since wip)`, or you say "not that way" | `steer.sh F-x "<one sentence>"` — the session stops in seconds, the sentence lands in the frame as `Steer:`, the same session resumes | a `wip: steer — …` commit, the steer under Deviations |
| a run ends `done` | `collect.sh` → `verify.sh` in the worktree → the frame's `Then:` | a merge (`--no-ff`), a PR, a review prompt, or a hold |
| a run ends `blocked:` · `timeout` · `stopped` · `failed` | the branch keeps a `wip:` commit; the question or reason is one prompt to you; your answer becomes `F-x-2` (`From: loom/F-x`) | nothing lost, the old frame `dropped` |
| "explain X" · "why is it like this" | loom:wiki reads the graph and answers with links | nothing written |
| a Goal says release or deploy | loom:release — the production floor, each item done or "N/A because" | the floor in the report |
| `Rules: sync: …` | courier mirrors changed docs/ nodes to ClickUp, Notion or Confluence | `Remote:` trailers, idempotent |

## A run, from the inside

      run.sh F-x ─▶ worktree + branch ─▶ .env linked, setup from the lockfile ─▶ claude -p, loom:run
           │
           ├─ running   .loom/runs/F-x.status (pid, session) · F-x.jsonl (live log) · wip: commits
           ├─ done      one commit: subject = Goal · body = the report · trailers Frame: Decisions: Risks:
           ├─ blocked   the frame doesn't answer a question → one prompt to you → F-x-2
           ├─ timeout   the minutes budget hit → the work is in a wip: commit → F-x-2 continues it
           ├─ stopped   steer.sh --stop → the same
           ├─ unfinished the session ended without its report → the work is a wip: commit → F-x-2
           └─ failed    the session died (reason: in the status file) → the same

The report is one block, the same everywhere — the run's last message, the commit body, the PR
body:

      Deviations:  what differs from the frame → why → the evidence
      Assumed:     readings the frame left open, now visible
      Evidence:    the Done-when command and Rules: check, output pasted
      Skipped:     the frame's Not-doing items, by name
      Noticed:     things seen and left alone
      New:         a dependency, a pattern, a concept worth a node
      Open:        what the lead has to decide

## The docs graph

      docs/Home.md      the front page a human opens: where we are · start here · how it works · journal
      docs/PROJECT.md   ≤ 40 lines: For · Numbers · Milestone · Now / Next / Never · Rules
          │             imported by CLAUDE.md into every session — the project's system prompt
          ├── spec.md        your requirements, verbatim, when you brought one
          ├── flows/         what the user does, step by step ─▶ features
          ├── features/      how each piece works, in plain words; a Status line derived from its frames ─▶ decisions · risks
          ├── frames/        the spec each run executed: Status · Then · Wave · Plan · Steer · Merged
          ├── decisions/     one file per feature, a section per choice in plain words (block ids for the trace)
          ├── risks/         one file per feature: what breaks, how you'd notice, what guards it
          └── concepts/      what you learned building this

Every page ends with a Trace line that links up (the flow it serves), sideways (what it depends on and feeds) and
down (its frame, decisions and risks). Open `docs/` in Obsidian as a vault: `Home.md` is the front page and the graph view is the
project's map, colored by folder. `skills/wiki/scripts/check.sh` keeps it honest — dead links, missing cited paths, orphan
frame ids, more than three doors in a frame, markdown Obsidian cannot render, a feature whose Status line disagrees with its
frames or whose prose claims a build state — run it in CI. `skills/wiki/scripts/status.sh` writes those Status lines — ⏳ planned ·
🔄 building · ✅ built with the merge date — from the frames and PROJECT.md's Now: at design, after every merge, after a run's scribe.

## Principles

1. **One-way doors only.** Gate, weigh and ask where undoing costs more than a day — data, users and keys included. Else do, then report.
2. **Omissions are output.** Not doing / Skipped / Noticed / Assumed are lines in every report. A guess made visible is not a guess.
3. **Evidence, not claims.** Done = the check ran, output pasted. A run's check is re-run by the lead before a merge.
4. **Delta, not narrative.** The diff is the summary; the report lists only what differs from the frame.
5. **Nothing by default.** Extensions, agents, connectors fire on a stated condition or a `Rules:` line.
6. **Alternatives are written down.** Every pick names what it rejected and why.
7. **Docs are input and output.** Read before touching; every stage leaves its artifact.
8. **Context is O(1).** PROJECT.md + one page + one hop. Agents get a brief, never the chat.
9. **Git is the trace.** The report is the commit body and the PR body; nodes point at frames, frames point at the merge. Squash-safe.
10. **Simple or gone.** A skill ≤ 3k tokens on invoke; one config surface; a rule that can't name its principle is deleted.

## Skills — they share PROJECT.md and one report schema, nothing else

| Skill | Does | Triggered by |
|---|---|---|
| `loom:lead` | the loop: know-before-you-build, triage (micro · fix · effort · refactor), dispatch runs, heartbeat, steer, verify, merge or PR per `Then:`, close | any work in a repo whose CLAUDE.md imports docs/PROJECT.md |
| `loom:init` | five prompts, an idempotent skeleton for any OS, PROJECT.md as the project's system prompt | `/loom:init` in an empty or existing folder |
| `loom:design` | one sitting that answers everything and writes frame files; groups them into waves | "design", "plan the milestone", or any effort |
| `loom:run` | executes one frame unattended in a worktree: builders, adversary, verify, one commit carrying the report; `blocked:` on anything the frame doesn't answer | the lead, per frame of a wave |
| `loom:wiki` | who writes which docs/ node, "explain …", growth rules, the docs linter | design, run, milestones, "explain …" |
| `loom:release` | the production floor, each item done or "N/A because" | a Goal that says deploy / release |
| `loom:ui` *(experimental)* | walks a built UI in the browser against its requirement lines | review, when Touch includes UI |
| `loom:sync` *(experimental)* | one-way mirror of docs/ to ClickUp, Notion, Confluence or a static site | `Rules: sync:` |

## Agents — right-sized, under explicit control

| Agent | Model | Brief | Returns |
|---|---|---|---|
| scout | haiku | question + PROJECT.md | facts with file:line, ≤ 15 lines |
| builder | sonnet | one task + the frame + PROJECT.md + the feature page | deviations, assumptions, pasted evidence |
| adversary | opus | diff + one confirmed-irreversible risk; ten tool calls, one probe | a reproducible failing case, or `clean` + the probes it ran |
| scribe | sonnet | the frame or the report + real test names | pages written, for a colleague who joined yesterday |
| inspector *(exp.)* | sonnet | requirement lines + start command | ok / fail per line, screenshots |
| courier *(exp.)* | sonnet | changed nodes + target mapping | ids created / updated |

Agents read the repo, write inside the frame's Touch, run checks. They never talk to you, never
decide a one-way door (they return `door:` and stop), never approve their own work, never spawn
agents, never touch config or secrets, never push or deploy. `Rules: agents: builder=opus`
changes a model; a copy of `agents/<name>.md` in the project's `.claude/agents/` changes a brief.

## What a run can and cannot do

A run is a headless session in its own worktree and branch, bounded by minutes, dollars and
turns, with the environment scrubbed to an allowlist. While it runs, a hook blocks — mechanically,
before the command executes — push, publish, deploy, remote writes, `gh`, `ssh`, destructive git,
and any file write outside the worktree. It stops with `blocked:` on anything its frame doesn't
answer. It never touches the base branch or PROJECT.md. Its scratch (`.loom/`) never enters a
commit.

You are never locked out of a run. The heartbeat shows the live step, tasks done, and two
off-course signals — a file outside the frame's `Touch`, or twenty turns with no task landed.
`steer.sh F-x "<one sentence>"` stops the session within seconds, writes the sentence into the
frame as a `Steer:` line (committed `wip: steer — …`), and resumes the same session with it; the
report names it under Deviations. `steer.sh F-x --stop "<why>"` ends the run with its work in a
`wip:` commit, and the correction becomes a follow-up frame.

This is a boundary against an honest model making mistakes, not a sandbox against a hostile one:
the run can read the repo and its `.env`, and GET requests are allowed (package installs need
them). Don't hand it credentials it shouldn't have. Runs need Python 3 on PATH for the guard —
without it, every command in a run is blocked.

## Traceability

    request → sitting → docs/frames/F-<slug>.md (the spec)
                        → run → commit on loom/F-<slug>: subject = Goal, body = report, trailers Frame: / Decisions: / Risks:
                        → merge or PR (the report is the PR body) → the frame records Merged:

`git log --grep='Frame: F-billing'` finds the code behind a frame; a node's `Frame:` points at
it; the frame's `Merged:` points at the merge; a `Steer:` line says where a human changed course
mid-run. Squashing keeps the report (it's the PR body) and the links (they're by frame id, not
hash).

## Layout

    README.md · logo.png     this manual
    .claude-plugin/          plugin.json · marketplace.json — the repo is its own marketplace
    agents/                  scout · builder · adversary · scribe · inspector · courier
    hooks/                   guard.sh + guard.py — the run boundary, PreToolUse on Bash/Write/Edit
    skills/lead/SKILL.md     the loop and the principles
    skills/init/             SKILL.md · scripts/init.sh · scripts/init.ps1 · templates/
    skills/design/SKILL.md   the sitting that produces frames
    skills/run/              SKILL.md · scripts/run.sh · wave.sh · wait.sh · steer.sh · collect.sh ·
                             verify.sh · commit.sh · touch-check.sh · run.ps1
    skills/wiki/             SKILL.md · references/nodes.md · scripts/check.sh (docs linter)
    skills/release/          SKILL.md · references/floor.md
    skills/ui/ · skills/sync/   experimental

## Install

The repo is the plugin and its own one-plugin marketplace, `loom`:

    claude plugin marketplace add https://gitlab.plat4m.sh/rnd/krel.git
    claude plugin install loom@loom

From a local clone: `claude plugin marketplace add ./loom`. To work on it: `claude --plugin-dir ./loom`
(runs launched from such a session need `LOOM_PLUGIN_DIR` exported). After a change: bump the
version, `claude plugin update loom@loom`. Runs launch their own `claude -p` sessions, so loom
must be installed at user scope.

If the superpowers plugin is installed, the two coexist: loom switches it off inside runs, and
in the main session a SessionStart hook states, in any repo whose CLAUDE.md names loom:lead,
that loom is the method there and superpowers' process skills do not apply. Nothing to
configure; outside loom repos the hook is silent and superpowers works as before.

## Start

`claude`, then `/loom:init` — in an empty folder or an existing repo. Have a spec? Paste it at
the first prompt: it becomes `docs/spec.md`, answers most of the questions, and the sitting
that frames milestone 1 quotes it. Otherwise: a hello, up to five native prompts (what, scale,
language, first demo, what's out of scope; existing code gets a sixth about its docs), a silent
skeleton, and `docs/PROJECT.md` written from your actual answers and committed with nothing
else. On an existing codebase it then offers to map it: haiku scouts read each module, haiku
scribes write one short page per module, and `Home.md` lists them — a knowledge base on day
one, at small-model prices. Then "design milestone 1", approve the frames, and let the waves
run.

## Customize — one config surface, `Rules:` in PROJECT.md

`budget: builders=6, usd=10, minutes=45` · `setup: npm ci` (worktree bootstrap; detected from the
lockfile when absent) · `check: npm test` (a project-wide check run at verify and after merge) ·
`env: DATABASE_URL,STRIPE_KEY` (variables passed into runs) · `subject: "feat: {goal}"` ·
`run: model=claude-sonnet-5` · `agents: builder=opus` · `plugins: off=a,b` · `commit: ask` ·
`wiki: update without asking` · `sync: on milestone` · `build inline` (no worktree, no guard —
solo and tiny only).

## Alternatives, in case you want less

- No agents: `Rules: build inline`. The loop is the same, one context, no boundary.
- No wiki product: Obsidian reads `docs/` as is; Quartz or MkDocs publish it read-only.
- No wiki at all: keep `docs/PROJECT.md` and `docs/frames/`. The loop still works; you lose the map.

## Status

1.0 is verified on Linux and Mac OS: init from a spec, design sittings, detached runs with heartbeat and
steer, follow-up frames, merges, the wiki and its linter — on a Python CLI and a small HTTP
service built from a pasted spec. Untested so far: `init.ps1` and `run.ps1` (Windows), runs that
end in a pull request, `loom:ui`, `loom:sync`, and the adversary's approved probe list with its
ten-call budget (new in 1.0). Say what broke; the report schema is the bug report.

---

Made by Oleksandr Shalaiev and Claude (Anthropic), 2026.
