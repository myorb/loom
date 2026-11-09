#!/bin/sh
# wave.sh — launch every approved frame of the lowest wave, detached from this session, and return at once.
# usage: wave.sh [wave-number]      then poll .loom/runs/*.status until none says `state: running`.
set -eu
root=$(git rev-parse --show-toplevel); cd "$root"
want=${1:-}
frames=""
for f in docs/frames/F-*.md; do
  [ -f "$f" ] || continue
  grep -q '^Status: approved' "$f" || continue
  w=$(sed -nE 's/.*Wave: *([0-9]+).*/\1/p' "$f" | head -1); w=${w:-1}
  if [ -z "$want" ] || [ "$w" = "$want" ]; then frames="$frames $f:$w"; fi
done
[ -n "$frames" ] || { echo "wave: no approved frames${want:+ in wave $want}"; exit 1; }
if [ -z "$want" ]; then want=$(printf '%s\n' $frames | cut -d: -f2 | sort -n | head -1); fi
mkdir -p .loom/runs
launched=""
for fw in $frames; do
  f=${fw%:*}; w=${fw#*:}; [ "$w" = "$want" ] || continue
  id=$(basename "$f" .md)
  if git show-ref --verify --quiet "refs/heads/loom/$id"; then echo "wave: $id skipped — branch loom/$id exists (a follow-up frame continues it, or drop it)"; continue; fi
  if command -v setsid >/dev/null 2>&1; then setsid nohup sh "$(dirname "$0")/run.sh" "$f" > ".loom/runs/$id.launch.log" 2>&1 < /dev/null &
  else nohup sh "$(dirname "$0")/run.sh" "$f" > ".loom/runs/$id.launch.log" 2>&1 < /dev/null & fi
  launched="$launched $id"; sleep 2   # let each worktree add finish before the next starts
done
echo "wave $want launched:$launched — poll: grep -H '^state:' .loom/runs/*.status"
