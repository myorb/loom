#!/bin/sh
# loom init — idempotent project skeleton. Never overwrites. Run from the project root.
# Ubuntu / Arch / macOS / Windows (Git Bash, which Claude Code needs anyway).
# Prints one line. LOOM_VERBOSE=1 lists every path.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
TPL="$HERE/../templates"
made=0; kept=0; detail=""

note() { detail="$detail
  $1 $2"; }
put() {  # put <src> <dst> — copy if dst is absent
  if [ -e "$2" ]; then kept=$((kept+1)); note kept "$2"
  else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; made=$((made+1)); note made "$2"; fi
}
line() {  # line <file> <text> — append if that exact line is absent; never glue to a last line without newline
  if [ -e "$1" ] && grep -qxF -- "$2" "$1"; then kept=$((kept+1)); note kept "$1: $2"
  else
    [ -s "$1" ] && [ "$(tail -c1 "$1" | od -An -c | tr -d ' ')" != '\n' ] && printf '\n' >> "$1"
    printf '%s\n' "$2" >> "$1"; made=$((made+1)); note made "$1: $2"
  fi
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then kept=$((kept+1)); note kept "git (already a repo)"; else git init -q; made=$((made+1)); note made .git; fi

for d in flows features frames decisions risks concepts; do
  mkdir -p "docs/$d"
  if [ -e "docs/$d/.gitkeep" ]; then kept=$((kept+1)); else : > "docs/$d/.gitkeep"; made=$((made+1)); note made "docs/$d/"; fi
done

case " $* " in *" --template "*) put "$TPL/PROJECT.md" docs/PROJECT.md ;; esac   # the lead writes PROJECT.md itself unless asked for the template
put "$TPL/graph.json" docs/.obsidian/graph.json   # docs/ is the vault: links are docs-relative

[ -e CLAUDE.md ] || : > CLAUDE.md
line CLAUDE.md "@docs/PROJECT.md"
line CLAUDE.md "Work in this repo with the loom:lead skill; it takes precedence over any other plugin's process here, superpowers included."

[ -e .gitignore ] || : > .gitignore
while IFS= read -r l; do line .gitignore "$l"; done < "$TPL/gitignore"

echo "loom skeleton: $made made · $kept kept"
[ "${LOOM_VERBOSE:-}" = "1" ] && printf '%s\n' "$detail" || true
