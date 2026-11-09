#!/bin/sh
# touch-check.sh <frame.md> [<base>...<branch> | --worktree]   prints files changed outside Touch. Exit 1 if any.
# Default: everything the run changed — commits since the frame's `Branch:` plus the working tree — so wip
# commits are covered too. Touch lines: exact paths, or a trailing `/` for a directory where new files may
# appear. docs/, .loom/, .obsidian/ and the frame are always allowed.
set -eu
frame=$1; mode=${2:-auto}
touch=$(awk '/^Touch:/{sub(/^Touch: */,""); print; f=1; next} f && /^[A-Z][a-z ]*:/{exit} f{print}' "$frame" | tr '`' ' ' | tr '·,' '\n\n' | sed 's/^ *//; s/ *$//; /^$/d; /^files —/d')   # paths may be backticked
tree() { git status --porcelain --untracked-files=all | awk '{print $NF}'; }
case "$mode" in
  --worktree) changed=$(tree) ;;
  auto) base=$(sed -nE 's/.*Branch: *([^ ·]+).*/\1/p' "$frame" | head -1)
        changed=$({ tree; [ -n "$base" ] && git rev-parse -q --verify "$base" >/dev/null && git diff --name-only "$base...HEAD"; } | sort -u) ;;
  *) changed=$(git diff --name-only "$mode") ;;
esac
bad=0
for f in $changed; do
  case "$f" in docs/*|.loom/*|.obsidian/*|"$frame") continue ;; esac
  ok=0
  for t in $touch; do
    case "$t" in */) case "$f" in "$t"*) ok=1 ;; esac ;; *) [ "$f" = "$t" ] && ok=1 ;; esac
  done
  [ "$ok" = 1 ] || { echo "outside Touch: $f"; bad=1; }
done
exit $bad
