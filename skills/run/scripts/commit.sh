#!/bin/sh
# commit.sh <frame.md> <report.md> — one commit: subject = the frame's Goal (or Rules: subject:), body = the report,
# trailers Frame: / Decisions: / Risks: read from the frame. Stages everything the worktree changed; .loom/ (the run's
# own scratch) never enters the commit. Then names any committed file outside Touch — those belong under Deviations.
# Says so and exits 1 when nothing was committed. Never pushes.
set -eu
frame=$1; report=$2; case "$report" in /*) ;; *) report="$(pwd)/$report" ;; esac
root=$(git rev-parse --show-toplevel); cd "$root"; here=$(cd "$(dirname "$0")" && pwd)
id=$(basename "$frame" .md)
goal=$(sed -nE '1s/^# *F-[^ ]+ *— *//p' "$frame")
tmpl=$(grep -m1 -E '^- *subject:' docs/PROJECT.md 2>/dev/null | sed -E 's/^- *subject: *//; s/^"//; s/"$//')
[ -n "$tmpl" ] && goal=$(printf '%s' "$tmpl" | sed "s/{goal}/$(printf '%s' "$goal" | sed 's/[&/\]/\\&/g')/")
dec=$(grep -oE 'D-[A-Za-z0-9-]+' "$frame" | sort -u | tr '\n' ' ' | sed 's/ *$//; s/ /, /g')
rsk=$(grep -oE 'R-[A-Za-z0-9-]+' "$frame" | sort -u | tr '\n' ' ' | sed 's/ *$//; s/ /, /g')
msg=$(mktemp); { printf '%s\n\n' "$goal"; cat "$report"; printf '\nFrame: %s\n' "$id"; [ -n "$dec" ] && printf 'Decisions: %s\n' "$dec"; [ -n "$rsk" ] && printf 'Risks: %s\n' "$rsk"; } > "$msg"
git add -A
git rm -r -q --cached --ignore-unmatch .loom >/dev/null 2>&1 || true
if git commit -q -F "$msg"; then rm -f "$msg"; else rm -f "$msg"; echo "commit.sh: nothing committed — git commit failed with $(git status --porcelain | wc -l | tr -d ' ') paths pending"; exit 1; fi
echo "committed $(git rev-parse --short HEAD) on $(git branch --show-current): $goal"
sh "$here/touch-check.sh" "$frame" | sed 's/^/note: /; s/$/ — a Deviation, or remove it/'
