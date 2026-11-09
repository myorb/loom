#!/bin/sh
# steer.sh F-<slug> "<one sentence>"   — stop the run's session now; the sentence goes into the frame as a `Steer:` line
#                                        (committed `wip: steer — …`) and the same session resumes with it. Seconds, not minutes.
# steer.sh F-<slug> --stop ["<why>"]   — stop for good: `state: stopped`, a `wip:` commit; continue with a follow-up frame.
set -eu
root=$(git rev-parse --show-toplevel); cd "$root"; id=${1:-}; [ -n "$id" ] || { echo "usage: steer.sh F-<slug> \"<sentence>\" | --stop [why]"; exit 2; }; shift
st=".loom/runs/$id.status"
[ -f "$st" ] && [ "$(sed -n 's/^state: //p' "$st" | tail -1)" = running ] || { echo "steer: $id is not running"; exit 1; }
session=$(sed -n 's/^session_pid: //p' "$st" | tail -1); [ -n "$session" ] || { echo "steer: $id has no session yet — try again in a moment"; exit 1; }
if [ "${1:-}" = --stop ]; then printf '%s' "${2:-stopped by the lead}" > ".loom/runs/$id.stop"; want=stopped
else [ -n "${1:-}" ] || { echo "usage: steer.sh F-<slug> \"<sentence>\" | --stop [why]"; exit 2; }; printf '%s' "$1" > ".loom/runs/$id.steer"; want=steer; fi
kill -TERM "$session" 2>/dev/null || true
t=0; while [ $t -lt 30 ]; do sleep 2; t=$((t+2))
  if [ "$want" = stopped ]; then [ "$(sed -n 's/^state: //p' "$st" | tail -1)" = stopped ] && { echo "$id: stopped — $(git log -1 --format=%s "loom/$id")"; exit 0; }
  else grep -q '^steer:' "$st" && [ ! -f ".loom/runs/$id.steer" ] && { echo "$id: steered — resumed with: $(sed -n 's/^steer: //p' "$st" | tail -1)"; exit 0; }; fi
done
echo "$id: signal sent, still ending — check: sh wait.sh 1"; exit 3
