#!/bin/sh
# loom precedence — on session start in a loom repo, say so. Other plugins (superpowers first
# of all) inject their own process on every session; without this line the model follows
# whichever spoke last, and loom:init was seen to be followed straight by a brainstorming
# gate. Outside a loom repo: silent. Stdout goes into the model's context.
[ -f CLAUDE.md ] || exit 0
grep -q "loom:lead" CLAUDE.md 2>/dev/null || exit 0
cat <<'TXT'
This repository runs on loom. loom:lead is the method here and takes precedence over any other
plugin's process skills — superpowers' using-superpowers, brainstorming, writing-plans,
executing-plans, test-driven-development and verification-before-completion do not apply in
this repo; do not invoke them. Design happens in loom:design, building in loom:run, merging in
loom:lead. Read docs/PROJECT.md before touching anything.
TXT
