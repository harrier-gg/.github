# 0005: Games, variants and providers

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Harrier must support many games, and many games come in several server variants: Minecraft Java alone has Vanilla, Paper, Purpur, Spigot, Fabric, Forge, NeoForge and proxies such as Velocity or BungeeCord. Other games work differently: Steam games install via SteamCMD, some only offer RCON instead of a console, some only run on Windows, config files come as properties, INI, JSON or XML, and mods come from different places (Modrinth, CurseForge, Hangar, Steam Workshop, Thunderstore, …).

Agents run on many machines and are updated one by one (ADR 0002). Adding a game or a mod source must therefore never require a new agent.

## Decision

### 1. The agent knows no games

The panel turns a template, the user's settings and the selected versions into a **runtime spec**: image, environment, files to download (URL + hash + target path), files to write, ports, resource limits, start and stop behaviour. The agent only executes runtime specs: it runs containers (or native processes on Windows), streams the console, reports stats, manages files and downloads artifacts after verifying their hash. Everything game-specific lives in templates and in providers in the backend.

### 2. Game → variant → version

| Level | Example | Defined by |
|---|---|---|
| Game | Minecraft Java, Valheim | `game` in the template |
| Variant | Paper, Fabric, Velocity; Valheim with BepInEx | one template per variant |
| Version | 1.21.4 + Paper build 123; Steam branch `public` | a version provider |

- **One template per variant.** Shared parts live in an abstract base template (`abstract: true`) that variants `extends`, e.g. `minecraft-java` → `minecraft-java/paper`. The panel groups templates by `game`, so users pick the game first and the variant second.
- Variants may differ fundamentally. A proxy such as Velocity has no world and connects other servers; it declares the capability `proxy`, and the panel later offers **networks** (proxy → lobby → survival) on top of it.

### 3. Providers: one interface per kind, one adapter per source

Providers are adapters in the backend behind a common interface. Templates only reference them by name.

| Kind | Interface (simplified) | Adapters (planned) |
|---|---|---|
| **Version provider** | list versions (filtered by game version / loader), resolve a version to artifacts | `mojang`, `papermc` (Paper, Folia, Velocity), `fabric`, `forge`, `neoforge`, `steamcmd`, `github-releases`, `url` |
| **Content provider** (mods, plugins, modpacks) | search (filtered by game version, loader, side), list versions, resolve dependencies, resolve to artifacts | `modrinth`, `hangar`, `curseforge`, `steam-workshop`, `thunderstore` |

An **artifact** is always: download URL, hash (SHA-512 or SHA-1 as the source provides), file name, target path. Sources that do not allow third-party downloads (e.g. CurseForge projects with distribution disabled) return no artifact; the panel then asks the user to upload the file manually.

Adding a source means adding an adapter in the backend. Templates, agents and the database model stay unchanged.

### 4. Install methods

Each template declares how the server is installed:

| Method | Meaning | Example |
|---|---|---|
| `image` | everything is in the container image | `itzg/minecraft-server` with `TYPE=PAPER` |
| `download` | download artifacts from a version provider | Paper JAR |
| `steamcmd` | install via SteamCMD (app ID, branch) | Valheim, CS2 |
| `script` | run an install script in an isolated install container | Forge installer |

### 5. Capabilities describe what differs

Everything beyond start/stop/console/files/backups is an optional capability, so games that lack something simply do not show it:

```yaml
capabilities:
  console: { via: stdin }            # or: rcon (e.g. Rust)
  players: { protocol: minecraft }   # or: a2s (Steam query)
  mods:    { sources: [modrinth, curseforge], loader: fabric, path: mods/ }
  plugins: { sources: [modrinth, hangar], path: plugins/ }
  proxy:   { forwarding: velocity-modern }
  sleep:   { wake: on-connect }
```

### 6. Installed content is tracked, with a side

For every installed mod, plugin or pack the servers service stores: source, project, version, file hash and **side**: `server`, `player` or `both`. The side is taken from the source's metadata where available (Modrinth exposes it) and can be changed by the user. This enables update checks, compatibility warnings when the game version changes, and sharing the player-side content with friends as an `.mrpack` modpack or a link (the same idea as Modrinth's "Server Play", but for self-hosted servers).

Manually uploaded files remain possible and are marked as "manual, unverified".

## Consequences

- New games, variants and mod sources ship as templates and backend adapters; agents never need an update for them.
- The runtime spec becomes the most important part of the agent protocol and is versioned with it (ADR 0002).
- Each provider adapter has to follow the source's API terms (user agent, rate limits, API keys, download permissions).
- The first implementation (M1) covers Minecraft Java with the variants Vanilla, Paper and Fabric via the `image` method. Velocity, Forge and a first Steam game follow soon after to prove the model.
