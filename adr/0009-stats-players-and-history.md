# 0009: Live stats, players and history

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Friends want to see at a glance who is online, and the owner wants to know whether the server is busy or running out of memory, also afterwards ("was it lagging last night?"). Docker stats already reach the panel live (M1) but are not kept. Players are game-specific (ADR 0005: capability `players`).

## Decision

- **The agent asks the game.** A template declares `capabilities.players.protocol`; the panel turns it into `query: { protocol, port }` in the runtime spec. Query protocols are network protocols, not games, so the agent still knows no games: `minecraft` (Server List Ping) now, `a2s` (Steam query) with the first Steam game. The agent asks `127.0.0.1:<host port>` every 10 s and reports `serverPlayers { online, max, names }`.
- The query is stored as a container label, so an agent that restarts while servers keep running continues asking.
- **Live:** the gateway forwards stats and players to browsers over the existing console WebSocket.
- **History:** the gateway condenses each server's values per minute (average CPU, peak memory, peak players) and the servers service stores them in Postgres (`server_metrics`), kept for **7 days**. The API returns buckets: 1 h in 1-minute steps, 24 h in 10-minute steps, 7 days in 1-hour steps.
- Protocol: a new optional field and a new message type, so the protocol version stays 1 (ADR 0002). Agents ignore query protocols they do not know.

## Alternatives

- **Prometheus / TimescaleDB:** one more service or extension to install and update on a homelab, for a few thousand rows per server and week. Postgres is enough; TimescaleDB stays the upgrade path if we keep data longer.
- **Reading join/leave lines from the console:** works without network access, but every game and mod logs differently, and the list is wrong after an agent restart.

## Consequences

- Minecraft sends at most 12 names in its status reply; with more players the panel shows the count and "+N more". RCON can deliver the full list later.
- Servers without a query protocol still get CPU and memory graphs, just no player list.
- History is written once per minute, so the graphs lag up to a minute behind the live values.
