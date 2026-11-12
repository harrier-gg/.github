# 0017: Content providers (mods, plugins)

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Players want mods and plugins on their servers. Every game has its own sources: Minecraft has Modrinth, CurseForge and Hangar; Hytale uses CurseForge as its official platform; Steam games use the Workshop; Valheim mods come from Thunderstore. ADR 0005 planned content providers as adapters in the backend. This ADR makes them concrete, so that a new game is a template change and a new platform is one adapter, without agent updates.

## Decision

- **Templates describe content kinds**, each with a target directory and a list of sources with the source's own filters, for example:

  ```yaml
  content:
    - kind: mod                       # what the panel calls it
      path: mods
      sources:
        - { provider: modrinth, type: mod, loader: fabric }
  ```

  A Paper template lists `plugin` with Modrinth (`loader: paper`) and Hangar. The game version filter is the server's own version (ADR 0012).
- **One provider interface** in the servers service: search (query, kind's filters, game version), list a project's versions for the server, and resolve a version to **artifacts** (URL, file name, size, hashes) plus its dependencies (required, optional, incompatible) and, where known, its side (server, client, both). Adapters translate this to each API.
- **Installing:** the panel resolves required dependencies from the same source, skips what is installed already, and asks the agent to download each artifact into the kind's directory. **The agent downloads** (HTTPS only), checks size and hash (SHA-512 or SHA-1) and moves the file into place only if they match; nothing is proxied through the panel.
- **Installed content is tracked** by the servers service: source, project, version, file, hash, side and kind, so the panel can list it, remove it (file and record), check for updates and later share the player-side content (`.mrpack`, ADR 0005). Files added through the file manager are not tracked.
- **Only sources that work without a key.** CurseForge (amended 2026-11-12): its API needs a key that CurseForge gives only on application, so the owner of every installation would have to apply for one. Harrier does not offer it; Hytale mods and other CurseForge-only content are uploaded with the file manager until an open source exists. Sources whose files may lack a download URL show a link to download manually instead.
- **Order:** Modrinth first (Minecraft), then Hangar (Paper plugins), then Thunderstore. Sources that do not deliver files over HTTPS, like the Steam Workshop, need their own install step on the agent and come with the first Steam game.

## Alternatives

- **A mod list per game in Harrier:** every game and platform would need code; templates could not add sources.
- **The panel downloads and pushes files to the agent:** twice the traffic, and the panel would hold every jar; the agent downloading with a hash check is just as safe.

## Consequences

- Adding a game that uses an existing platform is a template entry; adding a platform is one adapter in the backend.
- The agent needs an HTTPS client.
- Update checks, modpacks (`.mrpack`) and sharing player-side content build on the tracked list.
