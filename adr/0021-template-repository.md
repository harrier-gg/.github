# 0021: Template repository

- **Status:** Accepted
- **Date:** 2026-11-13

## Context

Templates (ADR 0005) live in `backend/templates` and ship with the backend. A new game, or a fix
to one, therefore waits for a backend release, and nobody can add templates without touching the
panel's code. Pterodactyl keeps its eggs in their own repositories for the same reason, and
PLAN.md always planned a `templates` repository and template sources (like Homebrew taps).

## Decision

- **`harrier-gg/templates`** holds the official templates, one folder per template:
  `<game>/<variant>/template.yaml`, optionally `install.sh` and `README.md`. A generated
  `index.json` at the root lists every template file's content (YAML as JSON; `extends` stays
  unresolved, the panel resolves it).
- **The format is defined by the backend.** It exports its template schema as
  `template.schema.json` (generated from the zod schema and committed, like `openapi.json`). The
  templates repository's CI validates every template against the schema on the backend's `main`
  and checks that `index.json` is current.
- **The panel loads `index.json`** from `HARRIER_TEMPLATES_URL` (default: the file on the
  templates repository's `main`), at start and every hour. It keeps the last good index in its
  database, so a panel without internet still starts with the templates it had. Templates with a
  `schemaVersion` the panel does not know are skipped; a template that does not validate is
  skipped and logged, never fatal.
- `file://` URLs are allowed, for development and for installations that keep their own copy.
- More sources (community repositories, templates made in the panel) come later on the same
  index format.

## Consequences

- Games ship without panel releases. A template that needs a newer panel feature waits until
  panels have it: new fields are optional, and incompatible changes raise `schemaVersion`.
- The panel depends on GitHub at its first start; afterwards only for updates.
- Backend tests use a fixture copy of a few templates instead of the real ones.
