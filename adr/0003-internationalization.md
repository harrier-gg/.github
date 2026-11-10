# 0003: Internationalization

- **Status:** Accepted
- **Date:** 2026-11-10

## Context

Harrier is an open-source project and should be understandable for as many people as possible. The maintainer and the first users speak German. Translations must stay easy to maintain: adding a text should not mean hunting through files, and missing translations must be visible.

## Decision

- **English is the primary language** of the project: code, comments, log messages, API error messages, commit messages, PR titles, and all Markdown files in the repositories.
- **The product is bilingual: English and German.** This covers the web panel and, later, the documentation website.
- **English is the source of truth.** German translates English, never the other way round. Missing German texts fall back to English at runtime.
- **Web panel:** `i18next` with one JSON file per language (`src/locales/en.json`, `de.json`). Keys are type-checked against `en.json`, so a typo in a key fails the build.
- **CI check (`npm run i18n:check`):**
  - fails if `de.json` contains keys that do not exist in `en.json` (stale translations),
  - fails if a translation uses different `{{placeholders}}` than the English text,
  - warns (does not fail) about keys missing in `de.json`, so contributors who do not speak German are not blocked.
- **APIs and the agent speak English only.** Errors carry a stable machine-readable `type`; the web panel translates it for display.
- **Documentation website (later):** Astro Starlight with English as the default locale and German as a second locale; untranslated pages fall back to English automatically.
- Issues and discussions may be written in English or German.

## Consequences

- Every UI text change touches two files. The PR template reminds contributors, the CI check catches drift.
- Adding a third language later is one new JSON file plus a line in the language list.
