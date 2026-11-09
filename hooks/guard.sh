#!/bin/sh
# loom guard — inside a loom run (LOOM_RUN=1) block anything that leaves the machine, changes the
# world, or reaches outside the worktree. Outside a run: no-op. Exit 2 = blocked (stderr → model).
# Fails CLOSED: if the input cannot be parsed, the call is blocked.
[ "${LOOM_RUN:-}" = "1" ] || exit 0
input=$(cat)
py=""; for c in python3 python "py -3"; do if $c -c "import sys" >/dev/null 2>&1; then py=$c; break; fi; done
[ -n "$py" ] || { echo "loom guard: no Python 3 on PATH — blocked (fail closed)" >&2; exit 2; }
printf '%s' "$input" | $py "$(dirname "$0")/guard.py" "$PWD"
