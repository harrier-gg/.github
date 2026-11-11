# 0015: File manager

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Owners need to reach the files of a server: upload a world or a plugin, download a log or the world, delete a broken mod, edit a config that no template lists. ADR 0011 added reading and writing listed text files up to 128 KiB over the agent connection; its consequences named the file manager as the next step. Worlds and backups are hundreds of megabytes, far beyond one agent message (256 KiB).

## Decision

- **Small operations stay requests over the agent connection** (ADR 0011): list a directory, read and write text files up to 128 KiB, delete, rename/move, create a directory. The reply `fileResult` gains `entries` for listings. Any path inside the server's data directory is allowed now, not only the template's files; the agent still checks every path itself with cap-std, so nothing outside the directory is reachable.
- **Uploads and downloads get a transfer channel.** The gateway creates a one-time transfer ID and sends `sendFile` or `receiveFile` with it. The agent opens a second WebSocket to `/agent/transfer/<id>` with its agent token, and the gateway relays binary frames between it and the browser's HTTP request or response. No size limit per message, no base64, no round trip per chunk, works behind NAT like the agent itself (ADR 0004), no new dependency in the agent.
  - The ID is valid for one connection within 30 s and only for the node it was sent to.
  - The agent closes the channel normally when done, or with an error and a reason; an upload is written to a temporary file and only renamed into place when complete.
- **Who:** admins and owners (`manageServers`), as for config files. Per-server file rights come with the permission model (PLAN.md).
- **The panel** gets a file view per server: folders, sizes, dates, upload (several files), download, new folder, rename, delete, and the text editor for small files.

## Alternatives

- **Chunks over the agent connection** (base64 in JSON): one round trip per 128 KiB and a third more data; a 1 GB world would take thousands of round trips and block console and stats on the same connection.
- **The agent serves files over HTTP:** the node would need an open port and a certificate, which ADR 0004 avoided on purpose.
- **SFTP:** another port, another account system, and nothing a browser can use.

## Consequences

- Backups (next) reuse the transfer channel for downloading and uploading archives.
- Changing files of a running server is allowed; the game may overwrite them. The panel says so.
- A transfer that breaks off leaves no half-written file in place; the user retries.
