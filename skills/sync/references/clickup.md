# ClickUp mapping

Tools: `clickup_create_document`, `clickup_create_document_page`,
`clickup_update_document_page`, `clickup_get_document_pages`,
`clickup_create_task`, `clickup_update_task`, `clickup_filter_tasks`.
Pass exactly these names in the courier's brief.

- One Doc named after the project — `Remote: clickup:doc=<id>` in PROJECT.md.
- A parent page per type: Flows · Features · Decisions · Risks · Concepts.
- One page per node under its parent; title = the node's H1; body = the
  markdown with the `Remote:` and `Commit:` trailers dropped; trailer
  `Remote: clickup:page=<id>` written back.
- PROJECT.md → the Doc's first page.
- `Now` → open tasks in `list=`; `Next` → tasks tagged `next`; `Never` → not pushed.
  Task description = the PROJECT line + the feature page URL.
  Idempotency: `Remote: clickup:task=<id>` appended to the Now / Next line.
- `[[features/x]]` → that page's URL from its trailer.
