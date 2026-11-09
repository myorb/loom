#!/bin/sh
# collect.sh [id…] — for the lead: every ended run (or the ids given): state, cost, report, files changed vs the base branch.
root=$(git rev-parse --show-toplevel); cd "$root"; base=$(git branch --show-current)
for f in .loom/runs/*.status; do
  [ -f "$f" ] || continue; id=$(sed -n 's/^id: //p' "$f"); state=$(sed -n 's/^state: //p' "$f" | tail -1)
  if [ $# -gt 0 ]; then case " $* " in *" $id "*) ;; *) continue ;; esac; fi
  [ "$state" = running ] && continue
  c=$(sed -n 's/^cost_usd: //p' "$f" | tail -1); case "$c" in [0-9]*) c="\$$(echo "$c" | cut -c1-5)" ;; "") c="cost ?" ;; esac; echo "==== $id · $state · $c · branch loom/$id"; sed -nE 's/^(note|reason|check): /  \1: /p' "$f"
  git show-ref --verify --quiet "refs/heads/loom/$id" && git diff --stat "$base...loom/$id" | tail -6
  echo "---- report"; cat ".loom/runs/$id.report.md" 2>/dev/null | head -60; echo
done
