# 0022: Script installs and Pterodactyl eggs

- **Status:** Accepted
- **Date:** 2026-11-13

## Context

So far every template runs an image that installs the game itself (`install: image`, ADR 0005).
Most Steam games have no such image. Pterodactyl solves this with **eggs**: an installer image
runs a script once (usually SteamCMD) into the server's directory, and a generic runtime image (a
"yolk") runs a startup command in it. There are about 150 maintained, MIT-licensed eggs for Steam
games (`pelican-eggs/games-steamcmd`, `pterodactyl/game-eggs`), with images ready to use.

Our agent runs every game without root and without capabilities, with the data at `/data`. Egg
install scripts expect root (they install packages), their data at `/mnt/server` during the
install and at `/home/container` at runtime, several ports, and the same port inside and outside
the container.

## Decision

- **Eggs are imported, not executed.** An importer in the templates repository converts an egg into
  a Harrier template; our format stays the only one the panel reads. The egg's origin and the MIT
  notice are kept in the repository's `NOTICE`.
- **Script installs** (`install: { method: script, image, entrypoint, script }`): before the first
  start, and again when an owner or admin reinstalls the server, the agent runs the installer image
  once:
  - as root with Docker's default capabilities, `no-new-privileges` set;
  - with only the server's data directory mounted, at `/mnt/server`;
  - with the server's environment;
  - and the agent appends `chown -R` of `/mnt/server` to the data directory's owner, then removes
    the container. The game itself keeps running as that owner without capabilities.
  The output appears in the console while the server is `installing`; a failed script fails the
  start with its exit code and last lines.
- **Runtime:** `runtime.startup` becomes the `STARTUP` variable yolks run, and `runtime.mountPath`
  says where the data is mounted (default `/data`). The panel sets what eggs expect:
  `SERVER_PORT`, `SERVER_IP=0.0.0.0`, `SERVER_MEMORY`, `TZ`.
- **Ports:** a template names several ports with an `offset` from the server's first host port
  (Valheim: game `0`, query `1`). The panel reserves the whole block per server. With
  `samePort: true`, the container uses the host port itself, as eggs expect.
- **Stopping:** `lifecycle.stop` is a signal (`SIGINT`, `SIGTERM`) or a console command.
- **Players:** `players: { protocol: a2s, port: <port name> }`, the Steam server query.
- **Settings:** config types `boolean` and `secret` (passwords). A secret is not shown in the panel
  and not returned to members, but stored like other settings. A secret with an empty default gets
  a random value per server when it is created; the importer never takes over an egg's default
  password, since it is public.

## Consequences

- Most Steam games become a template conversion instead of an image to build and maintain.
- Install scripts run as root inside their container. They come from the template sources the
  panel trusts (only official ones for now); a malicious template could misuse the network and
  the server's own directory, not the host.
- Installs depend on third-party images (`ghcr.io/parkervcp/*`); a template can switch to our own
  images later without changing the format.
- Many games only exist for x86-64; on ARM nodes they need emulation or do not run.
