#!/bin/sh
# loom run — one frame, one worktree, one bounded unattended session. Never touches the base branch.
# usage: run.sh <docs/frames/F-<slug>.md> [--dry]         from anywhere inside the repo
# env:   LOOM_RUN_MODEL, LOOM_PLUGIN_DIR (forwarded as --plugin-dir), LOOM_HOME (worktrees, default ~/.loom)
set -eu
frame=$1; dry=${2:-}
root=$(git rev-parse --show-toplevel)
case "$frame" in /*) ;; *) frame="$(pwd)/$frame" ;; esac
cd "$root"; frame=${frame#"$root/"}
[ -f "$frame" ] || { echo "loom run: no such frame: $frame" >&2; exit 1; }
id=$(basename "$frame" .md)                                   # F-<slug>
repo=$(basename "$root"); br="loom/$id"
wt="${LOOM_HOME:-$HOME/.loom}/$repo/$id"; runs="$root/.loom/runs"; mkdir -p "$runs" "$(dirname "$wt")"
status="$runs/$id.status"; report="$runs/$id.report.md"; log="$runs/$id.jsonl"

rule() { grep -m1 -E "^- *$1:" docs/PROJECT.md 2>/dev/null | sed -E "s/^- *$1: *//"; }   # Rules: lines
watchdog() {   # <pid> <deadline, epoch s> <marker> — TERM the pid at the deadline, leave the marker; `timeout` is not on macOS
  ( while kill -0 "$1" 2>/dev/null; do
      [ "$(date +%s)" -lt "$2" ] || { : > "$3"; kill -TERM "$1" 2>/dev/null; exit 0; }
      sleep 2; done ) &
}
minutes=$(rule 'budget' | sed -nE 's/.*minutes=([0-9]+).*/\1/p'); minutes=${minutes:-45}
usd=$(rule 'budget' | sed -nE 's/.*usd=([0-9.]+).*/\1/p'); usd=${usd:-10}
setup=$(rule 'setup'); envvars=$(rule 'env')
run_model=$(rule 'run' | sed -nE 's/.*model=([A-Za-z0-9.-]+).*/\1/p'); [ -n "${LOOM_RUN_MODEL:-}" ] && run_model=$LOOM_RUN_MODEL

# one run per frame at a time; one worktree add at a time
[ -d "$runs/$id.lock" ] && { echo "loom run: $id is already running (lock $runs/$id.lock)" >&2; exit 1; }
mkdir "$runs/$id.lock"; trap 'rmdir "$runs/$id.lock" 2>/dev/null' EXIT INT TERM
git worktree prune
if git show-ref --verify --quiet "refs/heads/$br"; then
  echo "loom run: branch $br exists — a re-run needs a new frame ($id-2) or \`drop\` first" >&2; exit 1
fi
until mkdir "$root/.loom/wt.lock" 2>/dev/null; do sleep 1; done
from_ref=$(sed -nE 's/^From: *([^ ]+).*/\1/p' "$frame" | head -1)            # a follow-up frame continues that branch
if [ -n "$from_ref" ] && ! git show-ref --verify --quiet "refs/heads/$from_ref"; then rmdir "$root/.loom/wt.lock"; echo "loom run: From: $from_ref does not exist" >&2; exit 1; fi
ex="$(git rev-parse --path-format=absolute --git-common-dir)/info/exclude"; mkdir -p "$(dirname "$ex")"
grep -qx '.loom/' "$ex" 2>/dev/null || echo '.loom/' >> "$ex"   # the run's scratch never enters a commit
git worktree add -q -b "$br" "$wt" >/dev/null; rmdir "$root/.loom/wt.lock"   # from the current branch, which has the frame
if [ -n "$from_ref" ]; then   # a follow-up continues the earlier branch's work on top of today's base
  git -C "$wt" merge -q --no-edit "$from_ref" || { git -C "$wt" merge --abort; echo "loom run: merging From: $from_ref conflicts — resolve it or drop the old branch" >&2; exit 1; }
fi

# bootstrap: env file, dependencies — done by this script, not by the model
[ -f "$root/.env" ] && [ ! -e "$wt/.env" ] && ln -s "$root/.env" "$wt/.env"
if [ -z "$setup" ]; then
  if   [ -f pnpm-lock.yaml ]; then setup="pnpm install --frozen-lockfile"
  elif [ -f yarn.lock ];      then setup="yarn install --frozen-lockfile"
  elif [ -f package-lock.json ]; then setup="npm ci"
  elif [ -f uv.lock ];        then setup="uv sync"
  elif [ -f poetry.lock ];    then setup="poetry install"; fi
fi
started=$(date -u +%Y-%m-%dT%H:%M:%SZ); t0=$(date +%s)
printf 'id: %s\nbranch: %s\nworktree: %s\nstarted: %s\npid: %s\nstate: running\n' "$id" "$br" "$wt" "$started" "$$" > "$status"
if [ -n "$setup" ]; then
  (cd "$wt" && sh -c "$setup") > "$runs/$id.setup.log" 2>&1 || { printf 'state: failed\nreason: setup failed — see %s\n' "$runs/$id.setup.log" >> "$status"; exit 1; }
fi
[ "$dry" = "--dry" ] && { printf 'state: dry\n' >> "$status"; echo "loom run $id: dry — worktree $wt on $br, setup: ${setup:-none}"; exit 0; }

# environment: a short allowlist plus Rules: env:, nothing else leaks in
keep="PATH HOME USER LOGNAME LANG LC_ALL TERM SHELL TMPDIR XDG_CONFIG_HOME XDG_DATA_HOME LOOM_RUN_MODEL"
set --   # positional args become the env allowlist from here on
for v in $keep $(printf '%s' "$envvars" | tr ',' ' '); do eval "val=\${$v:-}"; [ -n "$val" ] && set -- "$@" "$v=$val"; done
for v in $(env | sed -nE 's/^(ANTHROPIC_[A-Z_]*|CLAUDE_CONFIG_DIR|CLAUDE_CODE_[A-Z_]*)=.*/\1/p'); do eval "val=\${$v:-}"; set -- "$@" "$v=$val"; done
plugin_flag=""; [ -n "${LOOM_PLUGIN_DIR:-}" ] && plugin_flag="--plugin-dir $LOOM_PLUGIN_DIR"
# superpowers is off in runs (it injects its own process); Rules: plugins: off=a,b switches more off
off_plugins=$(rule 'plugins' | sed -nE 's/.*off=([^ ]+).*/\1/p' | tr ',' ' '); settings_json='{"enabledPlugins":{'
for pl in $(claude plugin list 2>/dev/null | sed -n 's/^ *❯ *//p'); do
  on=true; case " superpowers $off_plugins " in *" ${pl%@*} "*|*" $pl "*) on=false ;; esac
  settings_json="$settings_json\"$pl\":$on,"
done
settings_json="${settings_json%,}}}"
model_flag=""; [ -n "$run_model" ] && model_flag="--model $run_model"
deadline=$(( $(date +%s) + minutes * 60 )); rm -f "$runs/$id.timeout"   # one minutes budget for the run, steers included
prompt="Use the loom:run skill on $frame. Unattended run in worktree $wt on branch $br."; sid=""
while :; do   # one leg per steer: the lead's steer.sh stops the session, the same session resumes with the sentence
  set +e
  (cd "$wt" && exec env -i "$@" LOOM_RUN=1 claude -p $model_flag $plugin_flag --settings "$settings_json" \
    --permission-mode acceptEdits \
    --allowedTools "Read,Write,Edit,Glob,Grep,Agent,Skill,Bash" \
    --disallowedTools "AskUserQuestion,WebFetch,WebSearch" \
    --max-turns 120 --max-budget-usd "$usd" --output-format stream-json --verbose \
    ${sid:+--resume "$sid"} "$prompt") >> "$log" 2>> "$runs/$id.err" &
  session=$!; printf 'session_pid: %s\n' "$session" >> "$status"
  watchdog "$session" "$deadline" "$runs/$id.timeout"; wait "$session"; code=$?; set -e
  [ -f "$runs/$id.timeout" ] && { rm -f "$runs/$id.timeout" "$runs/$id.steer"; code=124; break; }   # out of minutes wins over a steer
  [ -f "$runs/$id.steer" ] || break
  steer=$(cat "$runs/$id.steer"); rm -f "$runs/$id.steer"
  sid=$(grep -m1 -o '"session_id":"[^"]*"' "$log" | cut -d'"' -f4)
  printf '\nSteer (%s): %s\n' "$(date -u +%H:%MZ)" "$steer" >> "$wt/$frame"       # the frame is the doc; git remembers
  git -C "$wt" add -A && git -C "$wt" commit -q -m "wip: steer — $steer" 2>/dev/null || true
  printf 'steer: %s\nstate: running\n' "$steer" >> "$status"
  prompt="The lead stopped you and steered: \"$steer\". The frame $frame now carries it as a Steer: line — re-read the frame, undo what the steer rules out, continue the plan from there, and report the steer under Deviations. Unattended run in worktree $wt on branch $br; loom:run rules apply."
done
if [ "$code" -eq 126 ] || [ "$code" -eq 127 ]; then   # the session never started: nothing to inspect, clean up
  printf 'ended: %s\nexit: %s\nstate: failed\nreason: session did not start — see %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$runs/$id.err" >> "$status"
  (cd "$root" && git worktree remove --force "$wt" && git branch -D "$br" -q) 2>/dev/null
  echo "loom run $id: failed to start (exit $code) — $(tail -1 "$runs/$id.err")"; exit 1
fi
# the last assistant message is the report; the result event carries it as `result`
python3 - "$log" "$report" <<'PY' 2>/dev/null || cp "$runs/$id.err" "$report"
import json, sys
res = None; turns = 0; out_tok = 0
for line in open(sys.argv[1]):
    try: ev = json.loads(line)
    except Exception: continue
    if ev.get('type') == 'result': res = ev
    if ev.get('type') == 'assistant': turns += 1; out_tok += ((ev.get('message') or {}).get('usage') or {}).get('output_tokens', 0) or 0
open(sys.argv[2], 'w').write((res or {}).get('result', '') or '')
if res: extra = f"turns: {res.get('num_turns')}\ncost_usd: {res.get('total_cost_usd')}\nsubtype: {res.get('subtype')}\n"
else: extra = f"turns: {turns}\ncost_usd: unknown — the session was killed before its result record; {out_tok} output tokens\nsubtype: killed\n"   # a timeout or a stop
open(sys.argv[1].replace('.jsonl', '.status'), 'a').write(extra)
PY
state=done; grep -qE '^blocked:' "$report" && state=blocked; [ "$code" -eq 124 ] && state=timeout; [ "$code" -ne 0 ] && [ "$state" = done ] && state=failed
[ "$state" = done ] && ! grep -qE '^Deviations:' "$report" 2>/dev/null && { state=unfinished; printf 'reason: the session ended without its report — its last message was not the report block (an agent left in the background dies with the session)\n' >> "$status"; }
grep -qiE 'Failed to authenticate|OAuth session expired' "$report" 2>/dev/null && { state=failed; printf 'reason: the CLI login has expired — run `claude login`, then launch the frame again\n' >> "$status"; }
[ -f "$runs/$id.stop" ] && { state=stopped; printf 'reason: %s\n' "$(cat "$runs/$id.stop")" >> "$status"; rm -f "$runs/$id.stop"; }   # steer.sh --stop
if [ "$state" != done ] && [ -n "$(git -C "$wt" status --porcelain)" ]; then   # never lose work: a follow-up frame continues from here
  git -C "$wt" add -A && git -C "$wt" commit -q -m "wip: $state after $(( ($(date +%s) - t0) / 60 ))m — see .loom/runs/$id.status" 2>/dev/null || true
fi
if [ "$state" != done ]; then   # a run that stopped early still says whether its branch is green — the lead never finds out by hand
  chk=$(sed -n 's/^- check: //p' "$wt/docs/PROJECT.md" 2>/dev/null | head -1)
  if [ -n "$chk" ]; then
    (cd "$wt" && exec sh -c "$chk") > "$runs/$id.check.log" 2>&1 & chk_pid=$!
    watchdog "$chk_pid" "$(( $(date +%s) + 900 ))" "$runs/$id.check.timeout"   # 15 minutes
    if wait "$chk_pid"; then printf 'check: green — %s\n' "$chk" >> "$status"
    else c="exit $?"; [ -f "$runs/$id.check.timeout" ] && { rm -f "$runs/$id.check.timeout"; c="timed out after 15m"; }
      printf 'check: red (%s) — %s — tail: %s\n' "$c" "$chk" "$(tail -3 "$runs/$id.check.log" | tr '\n' ' ' | cut -c1-200)" >> "$status"; fi
  fi
fi
if [ "$state" = done ] && [ -n "$(git -C "$wt" status --porcelain)" ]; then   # the session skipped its final commit: make it here, from the extracted report
  here=$(cd "$(dirname "$0")" && pwd)
  if (cd "$wt" && sh "$here/commit.sh" "$frame" "$report") >> "$runs/$id.err" 2>&1; then printf 'note: the session left changes uncommitted — run.sh made the final commit\n' >> "$status"; else state=unfinished; fi
fi
printf 'ended: %s\nexit: %s\nstate: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$code" "$state" >> "$status"
echo "loom run $id: $state (exit $code) — report: $report · status: $status"
[ "$state" = done ]
