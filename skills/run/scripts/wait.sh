#!/bin/sh
# wait.sh [seconds] — block until no run in .loom/runs says `state: running` (default 100 s — safe even in the foreground; 300 as a background heartbeat, 540 headless).
# Prints one line per run: id · state · minutes · turn and last step (live, from the run's log) · tasks done/planned · last commit.
# Exit 0 when nothing is running, 3 on timeout. `wait.sh 1` is a cheap "how is it going".
root=$(git rev-parse --show-toplevel); cd "$root"; limit=${1:-100}; t=0; here=$(cd "$(dirname "$0")" && pwd)
epoch() { date -u -d "$1" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null || date +%s; }   # GNU, then BSD
running() { for f in .loom/runs/*.status; do [ -f "$f" ] || continue
  if [ "$(sed -n 's/^state: //p' "$f" | tail -1)" = running ]; then pid=$(sed -n 's/^pid: //p' "$f"); [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null && printf 'state: failed\nreason: process %s is gone\n' "$pid" >> "$f" || echo "$f"; fi; done; }
laststep() {  # <jsonl> → "turn N · <last tool call>" from the live log, python3 when present
  [ -f "$1" ] || return 0
  command -v python3 >/dev/null 2>&1 || { printf 'events %s' "$(wc -l < "$1")"; return 0; }
  python3 - "$1" <<'PY' 2>/dev/null
import json,sys
turns=0; last=''; wip=0; lastid=None; sub={}   # sub: the latest step of each subagent, by the Agent call that spawned it
for line in open(sys.argv[1]):
    try: ev=json.loads(line)
    except Exception: continue
    if ev.get('type')!='assistant': continue
    pid=ev.get('parent_tool_use_id')
    if not pid: turns+=1
    for c in ev['message'].get('content',[]):
        if c.get('type')!='tool_use': continue
        i=c.get('input',{}); n=c['name']
        d=i.get('description') or i.get('subagent_type') or i.get('command','') or i.get('file_path','') or ''
        step=f"{n}: {' '.join(str(d).split())[:60]}"
        if pid: sub[pid]=step
        else:
            last=step; lastid=c['id']
            if 'wip:' in json.dumps(i): wip=turns
if lastid in sub: last=f"{last} → {sub[lastid]}"      # the lead is waiting on an agent: show what that agent is doing
since=f' ({turns-wip} since wip)' if wip and turns-wip>=20 else ''
print(f"turn {turns}{since} · {last}" if last else f"turn {turns}{since}")
PY
}
while [ -n "$(running)" ] && [ "$t" -lt "$limit" ]; do sleep 10; t=$((t+10)); done
for f in .loom/runs/*.status; do [ -f "$f" ] || continue; id=$(sed -n 's/^id: //p' "$f"); st=$(sed -n 's/^state: //p' "$f" | tail -1)
  grep -qE '^Status: (merged|dropped)' "docs/frames/$id.md" 2>/dev/null && continue   # history, not a run to watch
  base=$(sed -nE 's/.*Branch: *([^ ·]+).*/\1/p' "docs/frames/$id.md" 2>/dev/null | head -1)
  started=$(sed -n 's/^started: //p' "$f"); mins=""; [ -n "$started" ] && mins="$(( ($(date +%s) - $(epoch "$started")) / 60 ))m"
  live=""; [ "$st" = running ] && live=$(laststep ".loom/runs/$id.jsonl")
  wtd=$(sed -n 's/^worktree: //p' "$f"); out=""; [ "$st" = running ] && [ -d "$wtd" ] && out=$(cd "$wtd" && sh "$here/touch-check.sh" "docs/frames/$id.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "${out:-0}" -gt 0 ] && live="$live · outside Touch: $out"
  last=$(git log -1 --format='%s' "${base:+$base..}loom/$id" 2>/dev/null | cut -c1-60)   # the run's own commits only
  plan=$(grep -oE '^[0-9]+[a-z]?\. ' "docs/frames/$id.md" 2>/dev/null | tr -dc '0-9\n' | sort -u | wc -l | tr -d ' ')
  n=$(printf '%s' "$last" | sed -nE 's/^wip: task ([0-9]+).*/\1/p'); prog=""; [ -n "$n" ] && [ "$plan" -gt 0 ] && prog="task $n/$plan done"
  why=""; [ "$st" = failed ] && why=$(sed -n 's/^reason: //p' "$f" | tail -1)
  printf '%s · %s%s%s%s%s%s\n' "$id" "$st" "${why:+ — $why}" "${mins:+ · $mins}" "${live:+ · $live}" "${prog:+ · $prog}" "${last:+ · $last}"; done
[ -z "$(running)" ] || exit 3
