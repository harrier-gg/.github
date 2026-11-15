# 0023: Thunderstore

- **Status:** Accepted
- **Date:** 2026-11-15

## Context

Thunderstore is the mod site for Valheim and many other Unity games, and the third content provider
planned in ADR 0017. Its packages differ from Modrinth's and Hangar's in three ways:

- The API publishes a download URL and a size, but **no hash**. The agent only installs files with
  a hash it can check (ADR 0017).
- A package is a **zip** meant to be unpacked into its own folder (for BepInEx games,
  `BepInEx/plugins/<Namespace-Name>/`), not a single file.
- Mods need a **loader** (BepInEx), itself a Thunderstore package, that every mod depends on and
  that changes how the game starts.

The documented API has no search with a query: the bulk list per community is deprecated and is
over 180 MB for Valheim. The new website uses `GET /api/cyberstorm/listing/{community}/?q=…`
(20 results per page), which is undocumented.

## Decision

- **Hash on first use:** for an artifact without a hash, the servers service downloads it once,
  computes its sha256 and keeps it in memory per URL (Thunderstore versions never change). The
  agent then downloads and checks it as before. Nothing is sent through the panel.
- **Archives:** an artifact can say `extract`. The agent then unpacks the verified zip into a
  temporary folder next to the target and swaps it in, so updates are atomic and a failed one
  changes nothing. Every entry follows the same path rules as other files; there are limits on
  the unpacked size and the number of entries. The installed row's path is that folder, so
  removing it uses the existing `deletePath`.
- **Search** uses the Cyberstorm listing, inside the Thunderstore adapter only, so it can be
  swapped when Thunderstore documents a search.
- **Loaders come from the template**, not from content: the template's install script installs
  BepInEx and its startup command loads it. A content source lists the packages the template
  `provides`, and dependency resolution skips them.
- **Side** comes from the package's categories: only "Server-side" → server, only "Client-side" →
  client, otherwise both. Uploaders pick categories freely, so the panel shows it as a hint and
  installs whatever the user picks.

## Consequences

- Hash on first use catches a file that changes between the panel's check and the agent's download
  (or a tampered download on the way to the agent), not a bad upload on Thunderstore itself.
- The servers service downloads each new mod version once more. Mods are small; the same 512 MiB
  cap as the agent applies.
- The Cyberstorm search may change without notice; then only search breaks, installed mods and
  updates keep working (they use the documented package endpoint).
- Mods arrive as folders. Packages that put files into `BepInEx/patchers` or `BepInEx/config`
  land inside their plugin folder instead; BepInEx still loads their plugins, and configs are
  created on first start. Routing those folders can come later.
- Unpacking needs an agent with `extract`; an older agent would store the zip as a file named
  like the folder.
