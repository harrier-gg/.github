# 0012: Version providers

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

The Minecraft version was a free text field checked by a pattern. It rejected new version names (`26.4-snapshot-8`, `25w46a`, `1.21.11-rc3`), nobody could see which versions exist, and every version ran on Java 25, so older versions (1.16 needs Java 8) did not start. Maintaining a version list in Harrier, or copying a community list, would need a Harrier update for every Minecraft release. ADR 0005 already planned version providers.

## Decision

- **A template names a version provider**, e.g. `versions: { provider: mojang }`; variants override it (`papermc`, `fabric`). A config field of type `version` is filled from it. The servers service asks the source directly:

  | Provider | Source | Release / snapshot |
  |---|---|---|
  | `mojang` | `piston-meta.mojang.com` version manifest | type in the manifest (`old_alpha`/`old_beta` left out) |
  | `papermc` | `fill.papermc.io/v3/projects/paper` | type of the same id in the Mojang manifest |
  | `fabric` | `meta.fabricmc.net/v2/versions/game` | `stable` flag |

- **Lists are cached for an hour** in the servers service; a failed refresh keeps the last list. Nothing is stored in the database.
- **`latest` means the newest release at every start**: the panel resolves it and passes a concrete version to the image, so panel and image never disagree. Explicit versions stay as chosen.
- **The Java runtime follows the version.** Mojang's per-version file names the Java major version (`javaVersion.majorVersion`). The template maps Java versions to images (`runtime.java: { 8: …:java8, …, 25: …:java25 }`); the panel takes the smallest one that is at least what the version needs. Per-version files never change and are cached without expiry.
- **Offline is not fatal.** Without a list, a version is accepted if it looks like a version name, and the template's default image is used. A server that is already installed keeps starting while Mojang is unreachable.

## Alternatives

- **A version list in Harrier or a community gist:** needs a release or someone else's update for every Minecraft version. The gist is generated from the same Mojang manifest.
- **Let the image resolve `LATEST` and pick Java itself:** the panel could not choose the matching image before the container exists, and would not know which version actually runs.

## Consequences

- New Minecraft versions appear without a Harrier update, with the right Java.
- The servers service needs outbound HTTPS to the three sources; panels without internet fall back to free input and the default image.
- Other games bring their own providers (`steamcmd`, `github-releases` …, ADR 0005); the field type and endpoint stay the same.
