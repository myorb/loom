# Wiki nodes — templates and the link vocabulary

The wiki is written for a colleague who joined yesterday: pages are short articles — headings,
sentences, links inside the text — never records. Labels are schema and stay English; prose
follows `Language:` in PROJECT.md. `[[wikilinks]]` render in Obsidian, Logseq and Foam; GitHub
shows them as text. Every page ends with one italic *Trace:* line — the only labeled line — so
the graph and the commit trailers keep working. Empty slots are omitted.

No hard wraps in prose: a paragraph is one line, a list item is one line — Obsidian wraps for the
reader, and a manual break inside a `[[link]]` or a list item breaks it. A wikilink is one line with
an alias of at most eight plain words and no backticks — `[[decisions/x#^D-x-1|the choice in five words]]`
— and the explanation follows `]]`. Mermaid message text: never `;` (it ends the statement — a parse error) or `#` (a comment); no
`<…>` (stripped when rendered — write `/orgs/ID`); `<br/>` is the only tag allowed.

Levels: Home → PROJECT (the card) → (spec) → flows → features → decisions / risks / concepts.
Frames are the runs' briefs: reached from trace lines and the Journal, never from the text.

Ids. Decisions and risks are sections in one file per feature — `decisions/<feature>.md`,
`risks/<feature>.md` — newest last, never rewritten. A section has a human heading and ends
with an Obsidian block id, `^D-<slug>-n` or `^R-<slug>-n`, namespaced by the frame slug so two
branches never mint the same id. Links point at the block with a human alias:
`[[decisions/<feature>#^D-<slug>-1|the choice in a few words]]`. Project-level decisions go to
`decisions/project.md`. Growth adds hub pages (areas/), never moves leaves.

## Home.md — the front page. Init writes it; the lead keeps it current at every merge

    # <Product>

    <one paragraph: what it is, for whom, in plain words; a link to [[spec]] when there is one>

    ## Where we are
    **Milestone n — in progress since <date> | reached <date>** — *<the sentence>*.
    - ✅ [[features/<a>|<Name>]] — <merged, one line>
    - 🔄 [[features/<b>|<Name>]] — building now
    - ⏳ [[features/<c>|<Name>]] — next          ← the glyph of a line that links a frame is kept by status.sh

    ## Start here                       ← a reading path: flows oldest first, a new one goes last
    - [[flows/<flow>|How a <who> <does what>]] — milestone 1 as a story, with a diagram.
    - [[PROJECT|Project card]] — the 40-line summary every session reads first.

    ## How it works
    | Piece | In one sentence |
    |---|---|
    | [[features/<a>\|<Name>]] | <what the user gets> |

    ## Decisions worth knowing
    - [[decisions/<feature>#^D-<slug>-1|<the choice in a few words>]] — <the one-line why>.

    ## Journal                          ← a feed: newest entry first
    - **<date>** — <what landed, what changed, what we learned — from the report>. [[frames/F-<slug>|Run brief]].

    ## For the machine
    `frames/` holds the brief each unattended run was given; `decisions/` and `risks/` carry block ids so a commit or a page can point at one choice.

## flows/<name>.md — the lead, at init and at a milestone

    # How a <who> <does what>
    *Milestone n: "<the sentence>"*

    <three or four sentences: the story, start to end>

    ```mermaid
    sequenceDiagram            ← flowchart LR when there is no back-and-forth
      actor U as <who>
      participant A as <the app>
      U->>A: <step>
    ```

    ## The steps, and what each one leans on
    1. <step> — [[features/<a>]], [[features/<b>]]

    Proven by `<e2e command>`.

    ---
    *Trace: serves [[PROJECT#Milestone n]] · from [[spec]] · runs [[frames/F-<x>]], [[frames/F-<y>]].*

## features/<name>.md — ≤ 60 lines; a stub at design, an article after the run

    # <Feature>

    Status: ✅ built — merged: [[frames/F-<slug>]] <date>      ← status.sh writes it from the frames; never by hand

    <two or three sentences: what the user gets, with an example value or a sample URL>

    ## Why
    <the problem, in human terms>

    ## How it works
    1. <the user does X> → <we do Y>          ← sentences; other features linked inline

    ## Where in the code
    - `path/file.go` — <what it is responsible for>   ← the only home of class, library and pattern names

    ## What must not change
    - <invariant> — <what breaks if it does>; [[risks/<feature>#^R-<slug>-n|…]] when a risk covers it

    ## Knobs
    `ENV_VAR=default` · <limit>

    ## Decided
    [[decisions/<feature>#^D-<slug>-1|<the choice>]] — <one line>.

    ---
    *Trace: built by [[frames/F-<slug>]] · serves [[flows/<flow>]] · depends on [[features/<x>]] · feeds [[features/<y>]].*

At design the stub carries the title, the summary, Why, a planned How, Where = Touch and the
trace line; the run finishes the rest from the real code.

The Status line is the only place a page says whether it exists. `status.sh` derives it from the frames the Trace line names and PROJECT.md's Now — `⏳ planned` (waiting, with the wave), `🔄 building` (in progress, or awaiting merge), `✅ built` (merged, with the date; `adopted <date>` for a mapped page) — and check.sh fails while it is stale. Prose never carries that state: no "not yet built", "designed, not built", "will deliver", "this frame", "later frames". The article describes the feature as it works; a page other frames still add to describes what exists today; after the run the scribe rewrites the summary from what landed.

## decisions/<feature>.md — one file per feature, one section per door, newest last

    # <Feature> — decisions

    ## <The choice, as a sentence a colleague would say>
    <one paragraph: what we chose, why, what we rejected and why — in that order. Behind a
    Model: line, the approved model as a fenced block — fields, types, keys, the example record — verbatim.>

    Decided in [[frames/F-<slug>]], <date>. ^D-<slug>-n

A Never entry that leaves PROJECT.md becomes a section in `decisions/project.md` ending in
`^D-never-n`. Sections are never edited after the frame merges; a change is a new section whose
paragraph starts "Replaces [[decisions/<feature>#^D-<other>-m|…]]".

## risks/<feature>.md — one file per feature, one section per risk

    # <Feature> — risks

    ## <What breaks, as a sentence>
    **How bad.** <blast radius; the word "irreversible" when it is>
    **How we'd notice.** <the signal>
    **What guards it.** [[decisions/<feature>#^D-<slug>-m|the decision]] and <the tests, named in prose, at most three>; <what the adversary probed, when it did>.

    ^R-<slug>-n

Closed: a line "**Closed** by <what>, <date>." above the block id. The section stays.

## concepts/<name>.md — the lead, from a merged report's `New:` line

    # <Concept>
    <what it is, why it is here, where to read more — three sentences>

    ---
    *Trace: used in [[features/<x>]] · from [[frames/F-<slug>]].*

## areas/<name>.md — hub only, appears past 7 features

    # <Area>
    <one line>
    - [[features/<a>]] — <one line>

## frames/F-<slug>.md — written by loom:design, closed by loom:run, merged by the lead

    # F-<slug> — <Goal>
    Status: approved | done | merged | dropped · Then: merge | pr | review | hold · Wave: n · Base: <sha> · Branch: <name>
    Said / Assumed / Done when / Weigh / Model / Touch / Risks / Not doing / Gaps / Page / Plan — see loom:design
    From: loom/F-<other>        ← only on a follow-up frame
    Merged: <sha or PR#>        ← the lead, after the merge

The frame is the machine's brief and stays as it is.
