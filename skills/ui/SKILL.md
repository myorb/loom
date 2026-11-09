---
name: ui
description: Checks a built UI against its requirement lines in the built-in browser — every flow step, four states, two viewports, keyboard focus — and returns ok/fail per line with screenshots. Called by loom:lead after verify when Touch includes UI, or by the human ("check the UI", "does it match").
---

# loom:ui — look before you report

Principles 3 and 4: a screenshot is evidence, a description of a screen is
not. Needs a built-in browser (Claude Browser / preview tools). None
available → say so and stop; never claim a check you could not run.

## Input

The requirement lines only: `Said:`, the frame's Goal, the flow steps, and
the four states — empty · error · loading · denied — for every screen the
Touch list reaches. Plus how to start the app (the `run` skill or
`preview_start`) and the routes. No taste, no redesign.

## Run — inspector (sonnet); brief = requirement lines + start command + routes

1. Start the app; screenshot the first screen. Not loading →
   `blocked: <error>`, stop.
2. Walk the flow in order. Every screen: desktop and mobile presets
   (`resize_window`), each state reachable with the data at hand, one Tab
   pass to see the focus ring.
3. Per requirement line: `ok`, or `fail: <what differs> — <screenshot>`.
   A state you could not reach is `unreachable: <why>`, never `ok`.
4. Screenshots stay in the scratch directory; only paths travel.

The main session pastes every `fail` into the report under `Deviations:`;
any fail reopens the build. Nothing is committed while a requirement line
is red.

## Not this skill

Visual taste — that is `frontend-design`, at build time. Performance.
Accessibility beyond focus visibility and the four states — say it was not
checked rather than imply it was.
