# Notion mapping

Tools: the Notion connector's create-page, update-page, search and
create-database tools — read their exact names from the tool list and
pass them in the courier's brief.

- Parent from `Sync: notion parent=<id>`. One child page per type
  (Flows · Features · Decisions · Risks · Concepts); nodes under them.
- Title = H1; body = markdown → blocks (headings, bullets, code kept);
  trailers dropped; `Remote: notion:page=<id>` written back.
- PROJECT.md → the parent page's own body.
- `Now` / `Next` → rows of one database under the parent, created once —
  `Remote: notion:db=<id>` in PROJECT.md. Columns: Name · Status (Now/Next) · Feature.
- `[[x]]` → a page mention by id.
