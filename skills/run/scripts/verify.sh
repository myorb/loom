#!/bin/sh
# verify.sh <frame.md> — one call: Done-when command, Rules: check, touch-check. Prints tails and one verdict line.
# Run inside the worktree (or the repo root for a lone frame). Exit 0 only when everything is green.
set -u
frame=$1; root=$(git rev-parse --show-toplevel); cd "$root"; here=$(cd "$(dirname "$0")" && pwd); ok=1
done_when=$(sed -nE 's/^Done when: *`([^`]+)`.*/\1/p' "$frame" | head -1)
check=$(grep -m1 -E '^- *check:' docs/PROJECT.md 2>/dev/null | sed -E 's/^- *check: *//')
case "$check" in *\`*) check=$(printf '%s' "$check" | sed -nE 's/^[^`]*`([^`]+)`.*/\1/p') ;; esac   # `cmd` plus prose → the command
run() { name=$1; shift; out=$(sh -c "$*" 2>&1); code=$?; echo "== $name: $* → exit $code"; printf '%s\n' "$out" | tail -5; [ $code -eq 0 ] || ok=0; }
[ -n "$done_when" ] && run "done-when" "$done_when" || echo "== done-when: no backticked command in the frame"
[ -n "$check" ] && [ "$check" != "$done_when" ] && run "check" "$check"
echo "== touch-check"; sh "$here/touch-check.sh" "$frame" || ok=0
# comments: the trace lives in the commit body and docs/, never in code — added lines may not cite frame/risk/decision/spec ids
base=$(sed -nE 's/.*Branch: *([^ ·]+).*/\1/p' "$frame" | head -1); ids='\b[FRD]-[a-z][a-z0-9-]*-[0-9]+\b|\bspec:[0-9]+|\bframe F-'
added=$({ [ -n "$base" ] && git rev-parse -q --verify "$base" >/dev/null && git diff -U0 "$base...HEAD" -- . ':!docs' ':!*.md'; git diff -U0 -- . ':!docs' ':!*.md'; git diff -U0 --cached -- . ':!docs' ':!*.md'; } 2>/dev/null | grep -E '^\+[^+]' | grep -E "$ids"; git ls-files --others --exclude-standard -- . ':!docs' ':!*.md' 2>/dev/null | xargs -r grep -nE "$ids" 2>/dev/null)
n=$(printf '%s' "$added" | grep -c . || true)
if [ "$n" -gt 0 ]; then echo "== comments: $n added line(s) cite frame/risk/decision/spec ids — the trace lives in the commit body and docs/, not in code:"; printf '%s\n' "$added" | head -5 | cut -c1-140; ok=0; else echo "== comments: clean"; fi
[ $ok -eq 1 ] && echo "VERDICT: green" || { echo "VERDICT: red"; exit 1; }
