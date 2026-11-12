# 0018: Sharing player content

- **Status:** Accepted
- **Date:** 2026-11-12

## Context

A modded server only works for friends who have the same client-side mods. Today the owner sends a list and everyone hunts for files and versions. Harrier knows what is installed and, per mod, whether players need it (ADR 0017), so it can hand friends one file their launcher understands.

## Decision

- **The template names a sharing format**, e.g. `share: { format: mrpack, loader: fabric-loader }` for Fabric. Games and variants without one share nothing (Paper plugins only run on the server). Formats are adapters in the backend, like content providers; the first is Modrinth's `.mrpack`, which Prism Launcher, the Modrinth App and ATLauncher import.
- **The panel builds the pack** from the installed content that players need (side `client` or `both`): the files' download URLs, SHA-1 and SHA-512 and sizes, the server's game version, and the newest stable loader version for it. Nothing is downloaded or hosted by Harrier; launchers fetch the files from the source. Content without both hashes or a URL is left out and listed.
- **Every member can download it** (`viewServers`): friends are who it is for. The panel shows how many mods it contains and how to import it.
- Installed content now also records the download URL and size (ADR 0017).

## Alternatives

- **Zip the jars themselves:** larger, and redistributing other people's files breaks many licences; links to the source respect them.
- **A public link without login:** easier to pass around, but the server's address and mod list would be public; members are logged in anyway.

## Consequences

- Friends import one file and get exactly the client mods the server expects.
- Packs follow the installed content: after an update, members download the pack again.
- More formats (CurseForge's manifest, Thunderstore profiles) are more adapters behind the same `share` entry.
