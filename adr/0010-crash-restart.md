# 0010: Restarting crashed servers

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Game servers crash: a mod throws, the JVM runs out of memory, a plugin deadlocks and gets killed. The agent already notices when a container exits without being asked to stop and reports `crashed` (M1). Until now the server then stays down until someone opens the panel, often the next morning.

## Decision

- **The agent restarts crashed servers itself.** It knows the container and the ready pattern, and it works while the panel is unreachable.
- Up to **3 attempts**, waiting **10 s, 30 s and 60 s**. A server that then ran for **10 minutes** without crashing counts from zero again.
- **Only servers that became ready are restarted.** A server that crashes while starting most likely has a problem a restart does not fix (bad config, missing EULA); it stays `crashed` right away.
- Exit code 0 without a stop request (e.g. `stop` typed in the console) counts as stopped, not crashed.
- While it waits, the agent reports `crashed` with `restart: { attempt, maxAttempts }`, then `starting` and `running` as usual. Stopping the server cancels the wait.
- A container killed by its memory limit is reported as "out of memory", so the owner knows to give it more.
- Protocol: a new optional field, so the version stays 1 (ADR 0002).

## Alternatives

- **Docker restart policy (`on-failure:3`):** restarts even without the agent, but the agent would lose the console and ready detection after each restart and had to follow Docker events to find out. Docker's delays start at 100 ms, too fast to read a crash log.
- **The panel restarts:** needs the panel and the connection to the node to be up, which is exactly what can fail at night.

## Consequences

- Restarting is always on; the limits are fixed. A per-server switch comes with the settings form (M3) if someone needs it.
- If the agent itself restarts while it waits, the server stays down (reported as stopped).
- The restart info is live only; the server list shows `crashed` during the wait.
