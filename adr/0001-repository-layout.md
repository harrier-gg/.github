# 0001: Repository layout and contracts

- **Status:** Accepted
- **Date:** 2026-11-10

## Context

Harrier consists of a panel backend (several services), a web frontend, and an agent that runs on many machines. The parts use different languages (TypeScript, Rust) and have different release cycles. Agents are not updated at the same time as the panel.

## Decision

- Separate repositories by release cycle: `backend` (all services as a monorepo), `web`, `agent`; later `templates`, `website`, `images`, and the umbrella repo `harrier`.
- The services share one repository because they share `packages/contracts`. Each service is still built as its own, independently deployable image.
- There are exactly three contracts between repositories. Each is generated, committed, and checked for drift in CI:
  1. `backend` → `web`: `openapi.json` (release asset of the backend). On start, the web app compares its contract hash with `GET /api/v1/meta`.
  2. `agent` ↔ `backend`: protocol types generated from the Rust crate `harrier-protocol` (via `ts-rs`) and copied to `backend/packages/protocol`. Versioning: see ADR 0002.
  3. `templates` → `backend`: JSON Schema with `schemaVersion` (from M1).

## Consequences

- Changing a contract takes two PRs (source first, then the consumer). This is intended: contract changes should be deliberate.
- Local development needs the repositories side by side (`…/harrier/{backend,web,agent}`); `just api` and `just protocol` copy the contracts.
- Later (M8), the protocol types are published as the npm package `@harrier-gg/protocol` instead of being copied.
