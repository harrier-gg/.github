# Mitmachen bei Harrier

Gilt für alle Repos der Organisation (GitHub nimmt diese Datei als Standard, wenn ein Repo keine eigene hat).

## Arbeitsweise: GitHub Flow

- `main` ist immer releasefähig. Niemand pusht direkt auf `main`, auch nicht die Maintainer.
- Jede Änderung läuft über einen **kurzlebigen Branch** und einen **Pull Request**.
- Ein PR wird gemergt, wenn die CI grün ist. Gemergt wird **nur per Squash**, der Branch wird danach automatisch gelöscht.

```
main ──●───────────●───────────●──────  (jeder Punkt = ein gesquashter PR)
        \         /             \
         feat/agent-token        fix/handshake-timeout
```

### Branch-Namen

`<typ>/<kurze-beschreibung>`, z. B. `feat/agent-token`, `fix/ws-reconnect`, `docs/install-guide`.
Typen wie bei den Commits (siehe unten).

### PR-Titel = Commit auf main = Changelog

Weil per Squash gemergt wird, wird der **PR-Titel** zur Commit-Nachricht auf `main`. Daraus erzeugt
release-please Version und Changelog. Deshalb muss der Titel [Conventional Commits](https://www.conventionalcommits.org) folgen
(die CI prüft das):

| Titel | Wirkung beim nächsten Release |
|---|---|
| `fix(gateway): Timeout beim Handshake` | Patch (0.1.0 → 0.1.1) |
| `feat(agent): Agent-Token beim Verbinden` | Minor (0.1.0 → 0.2.0) |
| `feat!: Protokoll v2` oder `BREAKING CHANGE:` im Text | Major (vor 1.0: Minor) |
| `docs:`, `test:`, `ci:`, `build:`, `refactor:`, `chore:` | kein Release |

Die Commits **im** Branch dürfen beliebig sein, sie verschwinden beim Squash.

## Was die CI bei jedem PR prüft

| Repo | Prüfungen |
|---|---|
| backend | Lint, Typen, Tests, Build, `openapi.json` aktuell |
| web | Lint, API-Client aktuell, Build |
| agent | `cargo fmt`, Clippy, Tests, Protokoll-Typen aktuell |
| alle | PR-Titel nach Conventional Commits |

Lokal vorher dasselbe prüfen: `just check`.

## Releases

1. Nach jedem Merge auf `main` pflegt release-please einen PR „chore(main): release x.y.z“ mit Changelog.
2. Diesen PR mergen = Release: Git-Tag, GitHub Release, Artefakte.
3. Release-PRs werden von GitHub Actions erstellt; dabei startet GitHub keine weiteren Workflows. Maintainer mergen sie deshalb mit der Bypass-Berechtigung der Branch-Regel (nur über den PR, nie per Direkt-Push).

Release-Branches (`release/1.x`) gibt es erst, wenn ältere Versionen noch Fixes brauchen.

## Änderungen über mehrere Repos

Verträge zwischen den Repos (ADR 0001) ändern sich immer in dieser Reihenfolge:

1. **Quelle** zuerst: `agent` (Protokoll) bzw. `backend` (API). PR mergen, Release abwarten.
2. **Nutzer** danach: `backend` übernimmt das Protokoll (`just protocol`), `web` die API (`just api`). Eigener PR.
3. Inkompatible Protokolländerungen nur mit neuer Protokollversion (ADR 0002).

Lokal kann man beides gleichzeitig entwickeln, weil die Repos nebeneinander liegen. Gemergt wird trotzdem in dieser Reihenfolge.

## Architekturentscheidungen

Entscheidungen, die über ein Repo hinausgehen, als ADR in diesem Repo (`adr/`).
