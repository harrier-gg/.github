# 0020: Modpack servers

- **Status:** Accepted
- **Date:** 2026-11-13

## Context

Players want a server for a whole modpack, not one mod at a time. A Modrinth pack (`.mrpack`)
names a Minecraft version, a loader (Fabric, Forge, NeoForge or Quilt) and its files, with
overrides (configs) to unpack. Installing that in the panel would mean a template per loader,
reading the pack, installing every file through the content providers (ADR 0017) and an agent
step to unpack overrides. The image we run, `itzg/minecraft-server`, already installs Modrinth
packs: loader, server-side files, overrides, and swapping them all when the pack version changes.

CurseForge packs are out: its API needs a key that is only given on application.

## Decision

- A template config field of type `modpack` names a Modrinth modpack: its slug or ID, its project
  or version page on modrinth.com, a link to a hosted `.mrpack`, or a `.mrpack` uploaded to the
  server's files (`/data/….mrpack`). The template passes it to the image (`MODRINTH_MODPACK`).
- The variant `minecraft-java/modrinth-modpack` sets `TYPE: MODRINTH`. Its `version` field is the
  Minecraft version the pack version must support; `LATEST` (the default) means the pack's newest
  release and is passed on as it is, so the image picks the pack version.
- The panel asks Modrinth which Minecraft version that pack version is for, and picks the image
  with the Java it needs (ADR 0012). Saving checks that the pack exists on Modrinth for that
  version; offline, and for files, only the name is checked.
- The pack is one unit: the panel does not list its mods as installed content. A pack version is
  pinned through the modpack link (its version page); with a project link the image resolves the
  newest release when the server starts.

## Consequences

- Every loader works with one template and almost no code; the image's exclusion lists keep
  client-only mods off the server.
- Mods of a pack cannot be updated or removed one by one in the panel, and the panel does not
  offer the pack to players (they install the same pack from Modrinth in their launcher).
- Packs are found with a search in the panel (`GET /templates/modpacks`, Modrinth packs for the
  chosen Minecraft version, without packs only for players) or named by link.
- Other games can use `modpack` fields once a provider for their packs exists.
