# 0001: Repo-Aufteilung und Verträge

- **Status:** Angenommen
- **Datum:** 2026-11-10

## Kontext
Harrier besteht aus Panel-Backend (mehrere Services), Web-Frontend und einem Agent, der auf vielen Rechnern läuft. Die Teile haben verschiedene Sprachen (TypeScript, Rust) und verschiedene Release-Rhythmen. Agents werden nicht gleichzeitig mit dem Panel aktualisiert.

## Entscheidung
- Getrennte Repos nach Release-Zyklus: `backend` (alle Services als Monorepo), `web`, `agent`; später `templates`, `website`, `images`, Umbrella `harrier`.
- Die Services teilen sich ein Repo, weil sie sich `packages/contracts` teilen. Jeder Service bleibt ein eigenes, unabhängig deploybares Image.
- Zwischen den Repos gibt es genau drei Verträge, jeweils generiert und committet, mit Drift-Check in der CI:
  1. `backend` → `web`: `openapi.json` (Release-Asset des Backends). Das Web prüft beim Start den Contract-Hash gegen `GET /api/v1/meta`.
  2. `agent` ↔ `backend`: Protokoll-Typen aus der Rust-Crate `harrier-protocol` (via `ts-rs`), übernommen nach `backend/packages/protocol`. Versionierung siehe ADR 0002.
  3. `templates` → `backend`: JSON-Schema mit `schemaVersion` (ab M1).

## Konsequenzen
- Änderungen an einem Vertrag brauchen zwei PRs (Quelle, dann Übernahme). Das ist gewollt: Vertragsänderungen sollen bewusst passieren.
- Lokale Entwicklung braucht die Repos nebeneinander (`~/…/harrier/{backend,web,agent}`); `just api` und `just protocol` kopieren die Verträge.
- Später (M8) werden die Protokoll-Typen als npm-Paket `@harrier-gg/protocol` veröffentlicht statt kopiert.
