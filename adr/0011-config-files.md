# 0011: Editing config files

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

M3 started with game settings as form fields (game mode, difficulty, PvP …) that the panel passes to the image as environment variables. Research showed this does not hold up:

- Settings depend on the game version. Since Minecraft 1.21.9, `pvp`, `spawn-monsters`, `allow-nether` and `enable-command-block` are game rules, no longer `server.properties` keys; `PVP=false` was written to the file and ignored by a 26.3 server. Other keys were removed (1.21.2), added (26.2) or changed their default (26.3).
- The image writes a property on every start when its variable is set, so values set by the panel overwrite whatever the owner changed in the file.
- Pterodactyl and PufferPanel only offer installation settings (version, loader, memory) as fields; everything else is edited as a file.

## Decision

- **Template fields are for installation and resources** (version, memory). Game settings stay in the game's own files, which the running version writes, so they always match it.
- **A template lists the files that can be edited**, e.g. `files: [{ path: server.properties }]`. The panel shows a text editor for each of them (admins and owners).
- **The agent reads and writes files on request**, only inside the server's data directory: relative paths without `..`, opened component by component (cap-std), so symlinks never lead outside, even mid-request; regular files up to 128 KiB (one agent message), UTF-8 text. The servers service only asks for paths the template lists; the agent checks containment on its own, so a compromised panel still cannot reach other files.
- **Requests and replies:** the panel sends `readFile` / `writeFile` with a `requestId`; the agent answers with one `fileResult` carrying the same id and the content (read; `null` if the file does not exist yet) or an error. The gateway waits up to 10 s. New message types, so the protocol version stays 1 (ADR 0002); older agents ignore them and the panel reports a timeout.
- Changes apply when the server starts the next time; the panel says so while it runs.
- Game rules (PvP since 1.21.9) are changed with `/gamerule` in the console.

## Consequences

- No list of settings per game version to maintain; a new Minecraft version needs no Harrier update.
- A file does not exist before the first start; the panel says so instead of showing an empty editor.
- Read and write become the base of the file manager (M6), which widens the allowed paths to the whole data directory and adds listing, upload and download.
- Values the image sets on every start (e.g. `rcon.password` for itzg images) are overwritten; the editor cannot change them.
