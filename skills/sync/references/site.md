# Static site — no courier, no connector

- Quartz (Obsidian-flavoured: keeps `[[links]]` and the graph view):
  `npx quartz create`, content dir → `docs/`, build in CI on push to main.
- MkDocs: `mkdocs.yml` with `docs_dir: docs` and `mkdocs-roamlinks-plugin`
  for `[[links]]`.

`Sync: site=quartz|mkdocs` only records the choice. Nothing in loom:sync
runs; loom:release checks that the build is green.
