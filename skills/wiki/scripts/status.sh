#!/bin/sh
# status.sh — the Status line under every feature title, and the glyph on Home's Where-we-are lines, derived from
# the frames a page's Trace line names (their Status:, Wave:, Merged:) and PROJECT.md's Now — never written by hand.
# `--check` writes nothing and exits 1 where a line is stale. Run from the repo root: the lead at design and at every
# merge, the run after its scribe. Dates come from the Merged: sha when the history has it; --check ignores them.
set -u; cd "$(git rev-parse --show-toplevel)"; check=0; [ "${1:-}" = "--check" ] && check=1; bad=0
now=$(awk '/^Now/{n=1; next} /^[A-Z][A-Za-z]* ?[(:]/{n=0} n' docs/PROJECT.md 2>/dev/null | grep -oE 'frames/F-[A-Za-z0-9-]+' | sort -u)
state() {  # slug → merged | done | now | approved | dropped | missing
  f="docs/frames/$1.md"; [ -f "$f" ] || { echo missing; return; }
  s=$(grep -m1 -oE '^Status: [a-z]+' "$f" | awk '{print $2}')
  case "$s" in merged|done|dropped) echo "$s" ;; *) echo "$now" | grep -qx "frames/$1" && echo now || echo approved ;; esac
}
wave() { grep -m1 -oE 'Wave: [0-9]+' "docs/frames/$1.md" | awk '{print $2}'; }
mdate() { sha=$(grep -m1 -oE '^Merged: [^ ]+' "docs/frames/$1.md" | awk '{print $2}'); [ -n "$sha" ] && git log -1 --format=%as "$sha" -- 2>/dev/null; }
norm() { sed -E 's/ [0-9]{4}-[0-9]{2}-[0-9]{2}//g'; }
line() {  # feature page → the Status line it should carry; nothing when the Trace names no frame and no adoption
  trace=$(grep -m1 '^\*Trace:' "$1"); merged=""; prog=""; await=""; wait=""; seen=0
  for s in $(echo "$trace" | grep -oE 'frames/F-[A-Za-z0-9-]+' | sed 's#frames/##' | awk '!x[$0]++'); do
    seen=1; case "$(state "$s")" in
      merged) d=$(mdate "$s"); merged="$merged, [[frames/$s]]${d:+ $d}" ;;
      done) await="$await, [[frames/$s]]" ;;
      now) prog="$prog, [[frames/$s]] (wave $(wave "$s"))" ;;
      approved) wait="$wait, [[frames/$s]] (wave $(wave "$s"))" ;;
      missing) echo "$1: Trace names $s but docs/frames/$s.md is missing" >&2 ;;
    esac
  done
  adopted=$(echo "$trace" | grep -oE 'adopted [0-9]{4}-[0-9]{2}-[0-9]{2}')
  [ "$seen" = 0 ] && [ -z "$adopted" ] && return
  c=""; [ -n "$adopted" ] && c="$adopted, before loom"
  [ -n "$merged" ] && c="$c · merged: ${merged#, }"
  [ -n "$prog" ] && c="$c · 🔄 in progress: ${prog#, }"
  [ -n "$await" ] && c="$c · 🔄 awaiting merge: ${await#, }"
  [ -n "$wait" ] && c="$c · ⏳ waiting: ${wait#, }"
  c=${c# · }
  if [ -n "$merged" ] || [ -n "$adopted" ]; then h="✅ built"
  elif [ -n "$prog" ] || [ -n "$await" ]; then h="🔄 building"; c=$(echo "$c" | sed 's/^🔄 //')
  elif [ -n "$wait" ]; then h="⏳ planned"; c="nothing is built yet; $(echo "$c" | sed 's/^⏳ //')"
  else h="✖ dropped"; c="every frame that carried it was dropped"; fi
  echo "Status: $h — $c"
}
for f in docs/features/*.md; do [ -f "$f" ] || continue
  want=$(line "$f"); [ -n "$want" ] || { echo "$f: the Trace line names no frame and no adoption — no Status line to derive"; bad=1; continue; }
  k=$(grep -n -m1 '^Status: ' "$f" | cut -d: -f1); [ -n "$k" ] && [ "$k" -gt 6 ] && k=""
  have=""; [ -n "$k" ] && have=$(sed -n "${k}p" "$f")
  [ "$(echo "$want" | norm)" = "$(echo "$have" | norm)" ] && continue
  if [ "$check" = 1 ]; then echo "$f: Status line stale — sh skills/wiki/scripts/status.sh rewrites it (want: $want)"; bad=1; continue; fi
  if [ -n "$k" ]; then awk -v k="$k" -v s="$want" 'NR==k{print s; next} {print}' "$f" > "$f.tmp"
  else awk -v s="$want" 'NR==1{print; print ""; print s; next} {print}' "$f" > "$f.tmp"; fi
  mv "$f.tmp" "$f"; echo "$f: $want"
done
h=docs/Home.md; [ -f "$h" ] && for n in $(awk '/^## Where we are/{w=1; next} /^## /{w=0} w && /^- (✅|🔄|⏳) .*\[\[frames\/F-/{print NR}' "$h"); do
  l=$(sed -n "${n}p" "$h"); r=0; slug=""   # every frame the line links, dropped ones ignored: in progress beats merged beats waiting
  for s in $(echo "$l" | grep -oE 'frames/F-[A-Za-z0-9-]+' | sed 's#frames/##' | awk '!x[$0]++'); do
    case "$(state "$s")" in now|done) k=3 ;; merged) k=2 ;; approved) k=1 ;; *) k=0 ;; esac
    [ "$k" -gt "$r" ] && { r=$k; slug=$s; }
  done
  case "$r" in 3) g="🔄" ;; 2) g="✅" ;; 1) g="⏳" ;; *) continue ;; esac
  case "$l" in "- $g "*) continue ;; esac
  if [ "$check" = 1 ]; then echo "$h:$n: the glyph is stale — $slug is $(state "$slug"), the line should start with $g"; bad=1; continue; fi
  awk -v n="$n" -v g="$g" 'NR==n{sub(/^- (✅|🔄|⏳) /, "- " g " ")} {print}' "$h" > "$h.tmp" && mv "$h.tmp" "$h"; echo "$h:$n: → $g ($slug)"
done
[ "$check" = 1 ] && [ "$bad" = 0 ] && echo "status: current"; exit $bad
