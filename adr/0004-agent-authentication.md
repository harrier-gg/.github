# 0004: Agent authentication

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Agents control Docker on the machines they run on. Until now, any process that could reach the gateway's `/agent/ws` could pose as an agent. The gateway therefore only listens on localhost. To run agents on other machines (and later to run the panel behind a proxy such as Coolify), every agent must prove which node it is.

## Decision

- **A node is registered by an admin** and gets an agent token. In M1 via the CLI of the servers service (`npm run node:create -- --name <name>`), from M2 also in the panel. The token is shown **once** and never stored in plain text.
- **Token format:** `hrr_<nodeId>_<secret>`. `nodeId` is the node's UUIDv7, `secret` is 32 random bytes in base64url. The prefix makes leaked tokens easy to recognize (e.g. by secret scanners).
- **Storage:** the servers service stores only `SHA-256(secret)`. A slow password hash is not needed because the secret has 256 bits of entropy; brute force is not feasible. Verification uses a constant-time comparison.
- **Transport:** the agent sends the token in the `Authorization: Bearer …` header of the WebSocket upgrade request, never in the URL (URLs end up in logs). The gateway asks the servers service via NATS (`nodes.authenticate`) **before** it completes the upgrade. An invalid token gets `401` and no WebSocket at all.
- **Identity comes from the token, not from the agent.** The connection's ID is the node ID. `hostname`, `os` and `arch` from `hello` are informational only.
- **One connection per node.** A new connection with the same token replaces the old one (close code `4002`).
- **The agent reads the token from `HARRIER_AGENT_TOKEN`**, not from a command-line argument (arguments are visible to other users via `ps`). A rejected token stops the agent (exit code 2), like a protocol rejection.
- Revoking a node deletes it; its token stops working at the next connection attempt. Rotation comes with the panel UI (M2).

This does not change the protocol version: the `hello` message stays the same, and there are no released agents in use yet.

## Consequences

- The gateway may listen on other interfaces once user login (M2) protects the REST API, too.
- Every agent connection costs one NATS request to the servers service. That is negligible at the expected numbers of nodes.
- Losing a token means registering the node again (or rotating, from M2).
