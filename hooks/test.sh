#!/bin/sh
# hooks/test.sh — guard regression cases. Run: sh hooks/test.sh   (exit 1 on any mismatch)
here=$(cd "$(dirname "$0")" && pwd); fail=0; cd /tmp
t() { printf '{"tool_name":"%s","tool_input":{"command":%s,"file_path":%s}}' "$1" "$2" "$3" | LOOM_RUN=1 sh "$here/guard.sh" 2>/dev/null; r=$?
     if [ "$r" = "$4" ]; then echo "ok   $5"; else echo "FAIL want $4 got $r  $5"; fail=1; fi; }
t Bash '"git push origin main"' null 2 "git push"
t Bash '"git -C /x push"' null 2 "git -C push"
t Bash '"cd src && git -c a=b push --force"' null 2 "git -c push after cd"
t Bash '"git commit -m \"walk through project docs, git push later\""' null 0 "commit message mentioning push"
t Bash '"grep -rn \"git push\" ."' null 0 "grep for the string"
t Bash '"git checkout -- tally/store.py"' null 0 "checkout -- file"
t Bash '"git checkout main"' null 2 "checkout branch"
t Bash '"git reset --hard HEAD~1"' null 2 "reset --hard"
t Bash '"git branch -D loom/x"' null 2 "branch -D"
t Bash '"git worktree remove ../x"' null 2 "worktree"
t Bash '"git log --oneline; git status; git diff"' null 0 "read-only git"
t Bash '"git add -A && git commit -m x"' null 0 "add + commit"
t Bash '"curl -X POST http://localhost:3000/login -d a=b"' null 0 "local POST"
t Bash '"curl -X POST https://api.example.com/x -d a=b"' null 2 "remote POST"
t Bash '"curl https://registry.npmjs.org/x"' null 0 "remote GET"
t Bash '"npm ci && npm test"' null 0 "npm ci/test"
t Bash '"npm publish"' null 2 "npm publish"
t Bash '"npm run deploy"' null 2 "npm run deploy"
t Bash '"gh pr create"' null 2 "gh"
t Bash '"ssh prod uptime"' null 2 "ssh"
t Bash '"python3 -m unittest -v"' null 0 "tests"
t Bash '"echo done | tee out.txt"' null 0 "pipes"
t Bash '"cat > msg.txt <<'"'"'EOF'"'"'\nfix: it'"'"'s done, git push later\nEOF"' null 0 "heredoc body is data (apostrophe, push text)"
t Bash '"sh <<'"'"'EOF'"'"'\ngit push origin main\nEOF"' null 2 "heredoc fed to sh"
t Bash '"git commit -m \"it'"'"'s done\""' null 0 "apostrophe in -m"
t Bash '"python3 - <<EOF\nimport os; os.system('"'"'git push'"'"')\nEOF"' null 0 "python heredoc without a bare push line (not policed)"
t Bash '"docker builder prune -f"' null 2 "docker prune"
t Bash '"docker system prune -af --volumes"' null 2 "docker system prune"
t Bash '"docker compose up -d --wait"' null 0 "docker compose up"
t Bash '"go clean -cache && go build ./..."' null 2 "go clean -cache"
t Bash '"go clean -testcache && go test ./..."' null 0 "go clean -testcache is fine"
t Write null '"/home/leo/other.py"' 2 "write outside worktree"
t Write null '"/tmp/inside.py"' 0 "write inside worktree"
t Edit null '"relative/file.py"' 0 "relative edit"
printf '{"tool_name":"Bash","tool_input":{"command":"git push"}}' | sh "$here/guard.sh" 2>/dev/null; [ $? = 0 ] && echo "ok   outside a run: no-op" || { echo "FAIL outside a run"; fail=1; }
# precedence hook: speaks only in a loom repo
d=$(mktemp -d); ( cd "$d" && printf '@docs/PROJECT.md\nWork in this repo with the loom:lead skill.\n' > CLAUDE.md && sh "$here/precedence.sh" | grep -q "takes precedence" ) && echo "ok   precedence: speaks in a loom repo" || { echo "FAIL precedence: silent in a loom repo"; fail=1; }
d2=$(mktemp -d); ( cd "$d2" && [ -z "$(sh "$here/precedence.sh")" ] ) && echo "ok   precedence: silent elsewhere" || { echo "FAIL precedence: spoke outside a loom repo"; fail=1; }
rm -rf "$d" "$d2"

exit $fail
