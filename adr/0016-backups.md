# 0016: Backups

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

A broken mod, a griefer or a failed update can ruin a world that friends built for months. Owners need backups that happen without thinking about them, and a way back. Worlds are hundreds of megabytes to gigabytes and live on the node (ADR 0004); the panel may run elsewhere.

## Decision

- **The agent makes backups on the node**: a `tar.gz` of the server's data directory in `<data dir>/.harrier-backups/<server>/`, outside every server directory, so neither the game nor the file manager can change them. Symlinks are not followed and not stored. Fast compression: worlds are mostly compressed already. The template leaves out what the image downloads again (`exclude`; Minecraft: `libraries`, `versions`, caches, the server `*.jar`), which made a fresh world's backup 0.3 MB instead of 120 MB; a restore keeps those entries from the current state.
- **Consistent while running:** the template names console commands for it (`capabilities.backup: { before, ready, after }`; Minecraft: `save-off`, `save-all flush`, wait for "Saved the game", then `save-on`). Stopped and sleeping servers are archived as they are. Without such commands a running server is archived as it is, and the panel says so.
- **The panel keeps the schedule:** per server "every N hours, keep M" (default: every 24 hours, keep 7; 0 hours = only by hand), stored by the servers service, which checks every few minutes which backups are due and asks the agent. Only servers that ran since their last backup are due: otherwise a stopped server would replace older, different backups with copies of the same state (a world griefed and then stopped would lose its last good backup after M days). The agent deletes the oldest archives beyond M after each new one. The list of backups is what the agent has on disk; the panel stores only when the last one finished.
- **Results are events:** a backup takes minutes, so the agent reports `backupResult` (name, size or error) when done instead of answering a request. One backup per server at a time.
- **Restore** only while the server is stopped. The agent first backs up the current state (named so it is not pruned with the schedule's), then unpacks into a new directory and swaps it with the old one only when the archive was complete. Entries that would leave the directory are skipped.
- **Download** uses the transfer channel (ADR 0015). Admins and owners only (`manageServers`).

## Alternatives

- **A `scheduler` service:** one timer in the servers service is enough for this; a service comes when there are many kinds of jobs.
- **Backups kept by the panel or in S3 first:** moving gigabytes off the node for every backup costs time and bandwidth; local first, remote copies (S3) later as an addition.
- **Stopping the server for every backup:** players get kicked; the game's own save commands give a consistent copy while it runs.

## Consequences

- Backups need disk space on the node: about one compressed copy per kept backup. The panel shows the sizes.
- If the panel is down, scheduled backups wait until it is back; the agent never starts one on its own.
- Uploading an archive to restore from it, and copies to S3, come later.
