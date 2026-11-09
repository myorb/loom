#!/bin/sh
# comments.sh — the trace lives in the commit body and docs/, never in code. Prints every changed or new
# code line in the working tree (against HEAD, staged and untracked included) that cites a frame, risk,
# decision or spec id; exit 1 if there is one. A builder runs it before returning its report, so the
# run never spends a second builder on rewording; verify.sh runs the same scan over the whole branch.
ids='\b[FRD]-[a-z][a-z0-9-]*-[0-9]+\b|\bspec:[0-9]+|\bframe F-'
hits=$( { git diff -U0 HEAD -- . ':!docs' ':!*.md' 2>/dev/null | grep -E '^\+[^+]' | grep -E "$ids"; git ls-files --others --exclude-standard -- . ':!docs' ':!*.md' 2>/dev/null | xargs -r grep -nE "$ids" 2>/dev/null; } )
n=$(printf '%s' "$hits" | grep -c . || true)
if [ "$n" -gt 0 ]; then echo "comments: $n line(s) cite frame/risk/decision/spec ids — plain words instead:"; printf '%s\n' "$hits" | head -10 | cut -c1-140; exit 1; fi
echo "comments: clean"
