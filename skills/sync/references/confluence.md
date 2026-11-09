# Confluence mapping

Tools: the Atlassian connector's create-page, update-page and
get-page tools — read their exact names from the tool list and pass
them in the courier's brief.

- Space from `Sync: confluence space=KEY`; a parent page named after the
  project — `Remote: confluence:page=<id>` in PROJECT.md.
- One child page per type; nodes under them; title = H1; body =
  markdown → storage format (headings, lists, code kept); trailers dropped.
- No task push — Confluence is not a tracker. `Now` / `Next` appear as a
  table on the parent page.
- `[[x]]` → a page link by id.
