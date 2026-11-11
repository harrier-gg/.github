# 0013: Sleep and wake

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Game servers of a group of friends are empty most of the day but keep using memory and CPU. Stopping them by hand means someone has to start them again before playing. The panel should put empty servers to sleep and wake them when somebody wants to play, ideally just by joining from the game.

PLAN.md planned a `scheduler` service for the idle check. But the agent already asks every server for its players (ADR 0009), and waking on connect has to happen on the node, where the game port is.

## Decision

- **The agent decides.** The panel puts `sleep: { idleMinutes, wake }` into the runtime spec. When the player query reports nobody online for `idleMinutes`, the agent stops the server gracefully (the game saves on stop) and reports the new status `sleeping`. It works while the panel is unreachable; no `scheduler` service is needed for it.
- **Only servers with a player query can sleep**, since the agent must know that nobody is online. A template declares `capabilities.sleep: { wake: minecraft }` and a config field with `limit: sleep` (minutes, 0 = never; Minecraft: 15). The owner changes it like any other setting.
- **Waking on connect (Minecraft):** while sleeping, the agent listens on the game port itself. A server list ping gets a status reply ("Sleeping – join to wake it up", in English and German, one line each); a login attempt is answered with "Waking up – join again in a minute" and starts the server. The agent closes the port before the container starts. Wake protocols are network protocols, like query protocols (ADR 0009); games without one are woken from the panel (later Discord, M5).
- **Starting from the panel while sleeping wakes the server**: the same container starts again. Stopping while sleeping ends the sleep and closes the port.
- **The sleep survives an agent restart:** the sleep spec is a container label, and a marker file outside the servers' data directories records that a server sleeps; the agent resumes listening.
- **Protocol:** `RuntimeSpec.sleep` is a new optional field, `sleeping` a new status. Only a panel that knows `sleeping` sends `sleep`, so an older panel never sees it: the protocol version stays 1 (ADR 0002).

## Alternatives

- **A `scheduler` service in the panel** that stops servers: one more service, depends on the panel being up, and still needs the agent for waking. A scheduler still comes for timed jobs (backups, M6).
- **Forwarding the first connection to the starting server:** the Minecraft client times out long before a server has started; joining again after a minute is simpler and honest.

## Consequences

- An empty server frees its memory after `idleMinutes`; the first player waits about a minute.
- The wake listener needs the game port on the node to be free, which it is while the container is stopped. If something else holds it, the server still sleeps and is woken from the panel.
- Changed settings apply when the server is started from scratch (stop, then start), not when it wakes, because waking restarts the existing container.
