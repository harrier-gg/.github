# 0002: Agent protocol versioning

- **Status:** Accepted
- **Date:** 2026-11-10

## Context

Agents run on users' machines and are updated one by one. Panel and agents therefore run different versions for a while. A panel update must not make running agents unusable right away.

## Decision

- The agent always connects outbound to the gateway via WebSocket (`/agent/ws`).
- The first message is `hello` with `protocol` (an integer). The gateway answers with `welcome` or `reject` (including `minProtocol`/`maxProtocol` and a reason) and then closes the connection.
- The protocol version only increases for incompatible changes. New optional fields and new message types the other side may ignore do not increase it.
- The gateway always supports the current and the previous version (`PROTOCOL` in `apps/gateway/src/agents/handshake.ts`).
- A rejected agent exits (exit code 2) instead of reconnecting forever.

## Consequences

- A panel update with a new protocol version keeps agents of the previous version working; users have one release to update.
- The gateway has to keep compatibility code for the previous version and remove it one release later.
