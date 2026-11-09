#!/bin/sh
# check.sh — docs linter: every [[link]] resolves, every cited `path/file:name` exists, every frame id in a commit trailer has a file.
# Run from the repo root. Exit 1 on any miss. Cheap enough for CI.
set -u; bad=0; here=$(cd "$(dirname "$0")" && pwd); cd "$(git rev-parse --show-toplevel)"
for f in $(find docs -name '*.md'); do
  for l in $(grep -o '\[\[[^]|#]*' "$f" | sed 's/^\[\[//; s/\\$//' | sort -u); do   # [[a\|b]] inside tables escapes the pipe
    [ -f "docs/$l.md" ] || [ -f "docs/$l" ] || [ "$l" = "PROJECT" ] || { echo "$f: dead link [[${l}]]"; bad=1; }
  done
  for l in $(grep -oE '\[\[[^]|#]*#\^[A-Za-z0-9-]+' "$f" | sed 's/^\[\[//' | sort -u); do   # [[file#^block]] → the block id must exist
    b="docs/${l%%#*}.md"; id=${l#*#}; [ -f "$b" ] && grep -qF -- "$id" "$b" || { echo "$f: block $id missing in $b"; bad=1; }
  done
  case "$f" in docs/frames/*|docs/spec.md) ;; *) n=$(awk 'BEGIN{p=0} /^```/{f=!f} f{next} /^[-*+] |^[0-9]+\. /{p=NR; next} /^[[:space:]]*$|^#|^\||^>|^\^|^\*Trace|^\[\[|^!\[|^[A-Z][^:]{0,40}:/{p=0; next} p && NR==p+1 {print NR; p=NR}' "$f" | head -3 | tr '\n' ' '); [ -n "$n" ] && { echo "$f: a list item wrapped across lines at line(s) $n — one line per item"; bad=1; } ;; esac
  case "$f" in docs/features/*) n=$(grep -nEi 'not yet built|not built yet|is a design|designed, not|will deliver|will be built|once built|when built|to be built|later frames?|this frame|the run will|after the run|is planned|planned for wave' "$f" | grep -vE '^[0-9]+:(Status:|\*Trace:)' | head -3 | cut -d: -f1 | tr '\n' ' '); [ -n "$n" ] && { echo "$f: prose says whether a thing is built at line(s) $n — the Status line says it; describe the feature as it works"; bad=1; } ;; esac
  n=$(awk '/^```mermaid/{m=1; next} /^```/{m=0} m && /<[^b>][^>]*>|<b[^r]|[;#]/{print NR}' "$f" | head -3 | tr '\n' ' '); [ -n "$n" ] && { echo "$f: mermaid message text with ; # or a <tag> at line(s) $n — a ; ends the statement (parse error), # starts a comment, a <tag> is stripped when rendered; write /orgs/ID and use commas"; bad=1; }
  n=$(grep -nE '\[\[' "$f" | grep -vE '\[\[[^]]*\]\]' | head -3 | cut -d: -f1 | tr '\n' ' '); [ -n "$n" ] && { echo "$f: a [[link]] wrapped across lines at line(s) $n — Obsidian breaks it; one line per link"; bad=1; }
  n=$(grep -nE '\[\[[^]]*`[^]]*\]\]' "$f" | head -3 | cut -d: -f1 | tr '\n' ' '); [ -n "$n" ] && { echo "$f: a backtick inside a [[link]] at line(s) $n — plain words in an alias"; bad=1; }
  for p in $(grep -oE '`[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\.[a-z]+(:[A-Za-z0-9_.]+)?`' "$f" | tr -d '`' | cut -d: -f1 | sort -u); do
    case "$p" in *.md|*.json|*.yml|*.yaml|*.toml|*.env|*NNN*) continue ;; esac   # NNNN_name = a naming pattern, not a path
    [ -e "$p" ] || { echo "$f: cited path missing: $p"; bad=1; }
  done
done
for id in $(git log --format=%B | grep -oE '^Frame: F-[A-Za-z0-9-]+' | awk '{print $2}' | sort -u); do
  [ -f "docs/frames/$id.md" ] || { echo "commit trailer cites $id but docs/frames/$id.md is missing"; bad=1; }
done
for f in docs/frames/F-*.md; do [ -f "$f" ] || continue   # doors = decision links on the Weigh lines only; the Model line's link is not a door
  n=$(awk '/^Weigh:/{w=1} w && /^(Model|Touch|Map|Risks|Not doing|Gaps|Page|Plan|Done when|Said|Assumed):/ && !/^Weigh:/{w=0} w' "$f" | grep -oE "\[\[decisions/[^]]*D-[A-Za-z0-9-]+-[0-9]+" | sort -u | wc -l)
  [ "$n" -gt 3 ] && { echo "$f: $n doors — a frame weighs at most 3; split it or demote to Assumed"; bad=1; }; done
grep -qE '^- *(check|setup): .*`' docs/PROJECT.md 2>/dev/null && { echo "docs/PROJECT.md: Rules check:/setup: must be a bare command — no backticks, no prose"; bad=1; }
for f in $(grep -rl "^Commit:" docs 2>/dev/null); do echo "$f: stale Commit: line — nodes link Frame: now"; bad=1; done
if [ -d docs/features ]; then out=$(sh "$here/status.sh" --check) || { echo "$out"; bad=1; }; fi   # every feature's Status line and Home's glyphs match the frames; never gate on a pipe
[ "$bad" = 0 ] && echo "docs: clean"; exit $bad
