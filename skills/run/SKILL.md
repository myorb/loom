---
name: run
description: Executes one approved frame unattended in its own worktree, launched by scripts/run.sh — builders per plan task, adversary on confirmed-irreversible risks, verify, one commit on the run's branch carrying the report. Never a question, never a silent guess, never the base branch; stops with `blocked:` on anything the frame does not answer.
---

# loom:run — the frame is the whole brief

Principles 2, 3, 4, 5, 8, 9 (loom:lead). Unattended: no AskUserQuestion, no chat. Don't
narrate — no "I'll start by…", no step names; tool calls and the final report speak. The frame,
PROJECT.md and the touched feature page answer everything; a question they do not answer ends
the run with `blocked: <what>` as the last message — never a guess (5). Before that message,
commit what exists on the branch as `wip: blocked — <what>` so a follow-up frame
(`From: loom/F-<slug>`) continues from it. A judgment you made anyway is a line under
`Assumed:` in the report.

## Launch — by the lead: a wave detached, or one frame in the background

    sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/wave.sh"            # every approved frame of the lowest wave
    sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/run.sh" docs/frames/F-<slug>.md

The script makes the worktree (`~/.loom/<repo>/F-<slug>`, branch `loom/F-<slug>`), links
`.env`, runs `Rules: setup:` (or the lockfile's install), scrubs the environment, and starts
this session bounded by `Rules: budget:` (minutes, usd) and 120 turns, with `LOOM_RUN=1` so
the guard hook blocks push, publish, deploy, remote writes and writes outside the worktree. It
writes `.loom/runs/F-<slug>.status` (`pid:`, then `state:`) and `.report.md` when the session
ends. `wave.sh` launches with `setsid`/`nohup`, so the runs outlive the lead's session; the lead
polls the status files. A branch that
already exists is refused — a re-run is a new frame. Windows without Git Bash: `run.ps1`.

## Steps

1. Read the frame. `git diff <Base>..HEAD --stat -- <Touch>` non-empty → **scout** re-checks
   Said, Weigh and Model against the code; still true → note `Deviations: base moved —
   <files>` and continue; not → `blocked: frame stale — <what>`.
2. Per Plan task, in order: **builder** (sonnet; brief = the task + the frame + PROJECT.md +
   the touched feature page + this path, which the builder runs before it returns:
   `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/comments.sh"`). Its check — the task's one command, never the whole suite — pasted before the next task,
   then `git add -A && git commit -q -m "wip: task n — <what>"` — a timeout or crash leaves the branch resumable.
   Every Agent call carries `run_in_background: false` — this session is headless: a turn that
   ends while an agent runs in the background ends the session, and that agent's work is lost.
   Sibling tasks (`2a`, `2b`, …) → their builders in **one message, in parallel**, each told
   its own files and its own scoped check; one wip commit for the group. A builder's `door:`
   ends the run: `blocked: door — <what>`. The seventh builder is `blocked: budget`.
   `Rules: agents: builder=…, adversary=…` in PROJECT.md overrides the models named here.
3. After the last builder, **one message with two agents in parallel** — they touch disjoint
   files (probes; docs) and each takes ten to twenty minutes, so in sequence they cost the run
   a third of its hour:
   - **adversary** (opus) for the Risks lines with an `attack:` list: exactly those probes, ten
     tool calls a pass; its verdict carries the probe run's pasted output — a `clean` that ran
     nothing goes under `Open:` as not attacked. The probe file stays in the branch as a test —
     it is the repro of every case and the record of every clean pass; nobody deletes it, and
     its comments follow the builder's rule: no frame, risk, decision or spec ids. `attack: none`
     on every risk → the scribe alone.
   - **scribe**: finish the feature page from the real code (`Page: rewrite`, or a new page) —
     its summary says what landed, never what is missing — fill this frame's decision and risk
     nodes, set the frame `Status: done`. Never PROJECT.md, never another frame's nodes, never
     `docs/flows` or `docs/concepts`.
   A case → one builder fixes it with the repro as its check → a second adversary pass; two
   passes at most, still open → `Open:`. A fix that changes what a page says → one message to
   the same scribe (its context intact) naming the fix.
4. Verify (3), one call: `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/verify.sh" <frame>` —
   Done-when, `Rules: check:`, touch-check, tails, `VERDICT:`. A file touch-check lists is
   `git checkout -- <file>` (a new file: deleted) and goes under Deviations. UI in Touch cannot
   be inspected here; it is inspected at review.
5. One call: `sh "${CLAUDE_PLUGIN_ROOT}/skills/wiki/scripts/status.sh"` — the feature's Status
   line now reads awaiting merge; check.sh fails while it is stale.
6. Write the report block to `.loom/report.md` in the worktree, then one call:
   `sh "${CLAUDE_PLUGIN_ROOT}/skills/run/scripts/commit.sh" <frame> .loom/report.md` — the
   final commit (9): subject = Goal (or `Rules: subject:`), body = the report, trailers
   `Frame:` `Decisions:` `Risks:`; the wip commits before it stay. Nothing is pushed.
7. The same report block — nothing before it, nothing after — is the last message.

Every turn re-reads the whole context: batch commands, `tail -5` test output, read files
through scout, never `cat` a file you already have. After a builder: `git diff --stat` at most —
its Evidence is the check. After the scribe: `sh "${CLAUDE_PLUGIN_ROOT}/skills/wiki/scripts/check.sh"`,
not `cat` — the linter is the review.

A `Steer:` line in the frame means the lead stopped this session and resumed it with a
correction: it outranks the plan from that point — undo what it rules out, continue, and name it
under Deviations. Never remove it.

## Never

Push, publish, deploy, open a PR, write to a remote, write outside the worktree — the guard
blocks them; what wanted them goes under `Open:`. Tidy the host: no `docker … prune`, no
`go clean -cache`, no `rm` outside the worktree — a full disk ends the run with `blocked: disk`. PROJECT.md. Any branch but
`loom/F-<slug>`. A question. A silent guess. An agent in the background (`run_in_background:
true`) or a message that ends the turn while one runs — "waiting for the builders" is the
end of the session, not a wait.

## Report — the commit body, the last message

    Deviations:  frame line → what happened → why  (or none)
    Assumed:     judgments the frame did not cover  (or none)
    Evidence:    Done-when (+ check) command + last 5 lines, pasted
    Skipped:     Not-doing, plus anything new you chose not to do  (or none)
    Noticed:     adjacent things left alone, ≤ 3  (or none)
    New:         concepts this project didn't have — what, why here, where to read  (or none)
    Open:        risks seen, not addressed; anything the guard blocked  (or none)
