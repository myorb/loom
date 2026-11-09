---
name: release
description: The production floor for a first deploy or release — every item done or "N/A because". Use when a Goal mentions deploy, release or production, or the human asks whether it is ready to ship.
---

# loom:release

Principle 2: a skipped item is written with its reason, never silent.
Principle 3: "done" on any line means the command ran and its output was seen.

Fill references/floor.md into the report under `Release:`. Anything not
done becomes either a Now item or a Skipped line with a reason — the
human picks, one question for the whole list. A failed item on an
irreversible risk (data, money, auth) blocks the release; say so plainly.

Load test only when `Numbers:` exist: one k6 run per flow at 2× the
numbers, p95 into the report. No numbers → say that; never invent them.

The check itself may run in a builder (sonnet) — the brief is floor.md
plus PROJECT.md; it returns the filled list with pasted evidence per line.
