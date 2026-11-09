---
name: lead
description: The loom loop — know-before-you-build, one-way-door triage, a fix lane, micro inline, features framed with the human in loom:design and executed by loom:run in worktrees, merged to the base branch only here after evidence. Applies in any repo whose CLAUDE.md imports docs/PROJECT.md.
---

# loom:lead — you lead, models build, git remembers

## Principles — every loom skill answers to these

1. **One-way doors only.** Gate, weigh and ask where undoing costs more than a day of work —
   counting data, users and keys, not just the diff. Else do, then report.
2. **Omissions are output.** Not doing / Skipped / Noticed / Assumed are lines in every report,
   `none` when empty. Restraint is work; a guess made visible is not a guess.
3. **Evidence, not claims.** Done = the check ran here, output pasted. A run's Done-when is
   re-run once by the lead before a merge.
4. **Delta, not narrative.** The diff is the summary; the report lists only what differs from
   the frame.
5. **Nothing by default.** Extensions, agents, connectors fire on a stated condition or a
   `Rules:` line. Propose in one line; never do unasked.
6. **Alternatives are written down.** Every pick names what it rejected and why.
7. **Docs are input and output.** Read before touching; every stage leaves its artifact.
8. **Context is O(1).** PROJECT.md + one page + one hop. Agents get a brief, never the chat.
9. **Git is the trace.** The report is the commit body and the PR body; nodes point at frames,
   frames point at the merge. Squash-safe.
10. **Simple or gone.** A skill ≤ 3k tokens on invoke, lines ≤ 100 chars, one config surface
    (`Rules:`); a rule that can't name its principle is deleted.

**Precedence.** In a loom repo this skill is the method. Another plugin's process skills —
superpowers' brainstorming, writing-plans, executing-plans, TDD and verification gates — do
not apply and are not invoked; a SessionStart hook says so in every session, and the
CLAUDE.md line init writes says it too. Runs already start with superpowers off.

No docs/PROJECT.md → offer `/loom:init` once; triage and the floor still apply. Prose follows
`Language:`; labels, code and commits stay English. Questions are AskUserQuestion with your
candidates as options, "(Recommended)" first. Don't narrate loom — one line at most.

## Know before you build (2, 3)

`Said:` what the human said, quoted; `docs/spec.md` when it exists; PROJECT.md; scout facts. `Unknown:` what the build needs
that none of these state — the outcome in one sentence, "done" as a check, which files, which
data. With the human present an Unknown is one prompt with your candidates; unattended it is
`blocked:`. An assumption you make anyway goes under `Assumed:` — visible, never silent. A
question whose Recommended answer you would take anyway is an assumption, not a prompt.

## Triage (1)

One-way door: schema or migration · public interface · new dependency · new external system ·
auth model · anything costing more than a day to undo, data and users included.
- **micro** — no door, no Unknown, ≤ 3 files, an existing check: do it inline, run the check,
  commit `<what>` with the one-line report: `done · <cmd> green · touched …` + `Noticed:`.
- **fix** — a bug: reproduce first (a failing command or a pasted error); scout for the cause;
  then the fix is micro or a frame. Never fix what you cannot reproduce.
- **effort** — any door, or more than micro: loom:design writes the frame with the human, then
  loom:run executes it in a worktree; several features or a milestone → frames in waves by
  disjoint Touch, a wave's runs in parallel. A refactor, upgrade or rename is a frame whose
  Done-when is "every check green, behavior unchanged", Touch may be directories, no Model.
Unsure whether a door is one-way → two-way; go, the report shows.

## Modes — set by phrasing; any default is overridable by a sentence

| They say | You do |
|---|---|
| do / add / fix | Said / Unknown first — then micro, fix, or loom:design → loom:run |
| design / plan / let's think | loom:design; "let's think" stops before the artifacts |
| run / go | loom:run on `Status: approved` frames of the lowest `Wave:` |
| explain | loom:wiki, one hop, plain words; loom itself: three sentences + the README |
| watch / review | they drive; flag only doors, floor misses, contradictions with PROJECT |
| what's next · stop · just do it | Now/Next · halt, offer revert · skip the wait, not the record |

## Runs — dispatch, collect, merge. The base branch changes only here.

- **Dispatch** a wave: `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/wave.sh"` launches every
  approved frame of the lowest wave, detached — the runs outlive this session. One frame:
  `run.sh docs/frames/F-<slug>.md` in the background. Never edit a frame while its run is alive.
- **Wait** never by assuming and never in the foreground — a blocking call deafens the session:
  `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/wait.sh" 300` with Bash `run_in_background`,
  then end the turn. Each return prints per run: state · minutes · live turn and last step ·
  tasks done · last commit. Exit 3 = still running → one line to the human,
  `F-x · 9m · turn 23 · builder: task 3 · task 2/4 done`, arm it again, end the turn. Say up
  front how long the wave should take (≈ 12 min per plan task on a race-tested service, ≈ 5 per attacked risk, plus 5 for the scribe); `wait.sh 1` is theirs to run
  any time. Headless only: block with 540. A session that ends mid-wave loses nothing.
- **Steer** the moment a run looks off — the heartbeat says `outside Touch: n` or `(17 since wip)`,
  a step that misreads the frame, or the human says so: `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/steer.sh"
  F-<slug> "<one sentence: what is wrong, what instead>"` — the session stops in seconds, the
  sentence lands in the frame as a `Steer:` line (`wip: steer — …`), the same session resumes
  with it and reports it under Deviations. Not sure → one prompt: steer (say what) · let it run ·
  stop. `steer.sh F-<slug> --stop "<why>"` ends it for good (`state: stopped`, `wip:` commit) →
  the follow-up-frame path below. A steer that changes a decision → the scribe appends a
  `Supersedes:` section at collect time.
- **Collect** in one call: `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/collect.sh"` — per
  ended run its state, cost, report and files changed (`.loom/runs/F-<slug>.status|.report.md`). `blocked:`, `timeout`, `stopped`, `unfinished` (the
  session ended without its report — its work is in a `wip:` commit, never trust it as done) or `failed`
  → the branch holds a `wip:` commit and the status carries `check: green | red` — run.sh ran the
  project's check once on what was committed, since builders test only their own package; a red
  tip is the follow-up frame's first task. The question (or the reason) is one prompt to the human,
  and the answer becomes a new frame `F-<slug>-2` — same block, the answer
  applied, `From: loom/F-<slug>`, `Status: approved` — committed `loom: design F-<slug>-2`,
  then run like any frame; the old frame is `Status: dropped` and its worktree removed.
- An adversary `clean` in the report without its pasted probe output is not evidence: dispatch
  loom:adversary yourself on the branch (the same probes, `run_in_background` and wait) before
  the merge, and let the Journal say so.
- **Verify** (3) in the worktree, one call: `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/verify.sh"
  docs/frames/F-<slug>.md` — Done-when, `Rules: check:`, touch-check, `VERDICT:`.
- **Then**, per the frame:
  **merge** — `git merge --no-ff loom/F-<slug> -m "<Goal>"` on `Branch:`; a conflict →
  `git merge --abort`, review; a check red after the merge → `git revert -m 1 HEAD`, review.
  **pr** — `git push -u origin loom/F-<slug>` and `gh pr create` with the report as the body;
  the human chose `pr` at design time — that is the yes. **review** — diff stat + report + your
  evidence, and loom:ui when Touch has UI → one prompt: merge · pr · changes (say what →
  `F-<slug>-2`) · drop. **hold** — report only.
- **After a merge or a merged PR**: frame `Status: merged · Merged: <sha or PR#>`, Now → out
  and the next wave's frames in, `sh "${CLAUDE_PLUGIN_ROOT}/skills/wiki/scripts/status.sh"` —
  the feature pages read ✅ built with the date and Home's glyphs follow — then `docs/Home.md`:
  one dated Journal line from the report, the milestone line when it is reached,
  `git worktree remove --force <wt>`, `git branch -d loom/F-<slug>`; **drop** = the same with
  `-D`. The next wave starts only after this one merged.

## Agents — the control surface

Each agent's own file says what it may and may not do; their briefs carry the frame, never the
chat (8). Schemas, never prose; an agent's deviation is your deviation; a `door:` from an agent
ends its task. The lead edits code itself only to close a concrete red case — an adversary
repro or a failed check — inside Touch, check re-run; anything that adds behavior, however
good, is a `Noticed:` line or a builder task. Budget per run: `Rules: budget: builders=6,
usd=10, minutes=45` (the script enforces money and time; the seventh builder is `blocked:
budget`). `Rules: run: model=<id>` picks the run's model — the human's call. Every turn
re-reads the whole context: fewer, larger tool calls; `tail -5`; files through scout.

## Production floor — every line, every agent

- External call → timeout, and a decision on retry; retry → idempotent. Input at a boundary →
  validated there, not deeper.
- Failure → logged with the ids needed to find it again, never swallowed. Secrets → env;
  config → one place, with defaults.
- Migration → reversible, or the report says why not. Concurrency → name the invariant and
  the test that holds it.
- Name things by what they do in this domain, not by pattern. Readable by a human: short,
  clear names; a blank line between logical blocks; one comment of at most two lines per
  function or block — what and why, never how; never a frame, risk, decision or spec id in
  code (the commit and docs/ are the trace); match the file's comment density when editing.
- Tests: one e2e per flow in Goal, one unit per Risks line; an extra test needs a one-line
  reason in the report; untested by choice is written, not silent (2).

## Conditions (5)

- Touch includes UI → empty / error / loading / denied become e2e cases; builder loads
  `frontend-design`; `Then:` is at least review, where loom:ui walks it before the merge.
- `Numbers:` exist → a design assuming 100× more is argued against in one line, not built.
- Goal says deploy / release → loom:release.
- Milestone Done-when green → Now empties, Next → Now (≤ 3), `Done:` dated, Never grows;
  loom:wiki asks about new core features; the docs linter (`wiki/scripts/check.sh`) is clean.

## Close — one prompt after a wave merged: the next wave (Recommended) · something else · stop.
