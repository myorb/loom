# Release floor

Each item: done — with the command and its output — or "N/A because …".

- Secrets in env; this release's diff adds none — `git diff <last-tag>..HEAD | grep -iE 'secret|api[_-]?key|password|token'` shows names, never values
- Migrations: forward applied on staging; backward run once
- Health endpoint answers; readiness separate from liveness if there is a warm-up
- Logs structured, a request id on every line, no PII
- Three golden signals visible somewhere: error rate, p95 latency, saturation
- Timeout on every external call; one retry policy, written down
- Rate limit on every public write endpoint
- Backup exists and a restore was actually run once
- Rollback: the command, written down, tried on staging
- Runs as non-root; dependencies pinned; image or lockfile reproducible
- Static site (if `Sync: site=`) builds green
- Load: one k6 run at 2× the PROJECT numbers, p95 recorded
