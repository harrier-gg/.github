# 0014: Discord bot

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Groups of friends meet on Discord. Starting or waking a server, or checking whether it is up, should work from there, and the group wants to know when a server comes online. Games without wake-on-connect (ADR 0013) can only be woken from outside the game. Accounts can already be linked to Discord (ADR 0008).

## Decision

- **A new service `discord`** in the backend, off until `HARRIER_DISCORD_BOT_TOKEN` is set. It uses the Discord application of the login (ADR 0008) and connects to Discord's gateway **outbound**, so it works behind NAT like the agent; no public URL is needed. Libraries: `@discordjs/core`, `@discordjs/ws`, `@discordjs/rest` (no `discord.js`: the bot needs no cache). No privileged intents.
- **Slash commands**, registered globally on start, with German names and descriptions as localizations:
  - `/status` lists the servers with their status (only visible to the caller),
  - `/start <server>` starts or wakes a server, `/stop <server>` stops it (visible to the channel, so friends see who did it). Server names autocomplete.
- **Who may do what:** the caller's Discord account must be linked to a Harrier account (ADR 0008); the role then decides with the same rules as the panel (`viewServers`, `startStopServers`, ADR 0007). Unlinked users are told to link their account in the panel.
- **Notifications** go to one channel, `HARRIER_DISCORD_CHANNEL_ID`: a server came online (from `starting` to `running`) or crashed for good (no restart pending, ADR 0010). The service follows `agents.event` itself and only reports changes it saw happen, so agent reconnects do not repeat messages.
- **Language:** replies follow the caller's Discord language (German or English), notifications the server's preferred language (`preferred_locale`).
- No database: the service is stateless; it asks identity and servers over NATS.

## Alternatives

- **Interactions over HTTPS (webhook) instead of the gateway:** Discord must reach the panel from the internet, which many homelabs do not allow.
- **`discord.js`:** much larger and caches everything; we only need commands and messages.
- **Choosing the notification channel with a command:** needs storage in the bot; one environment variable is enough for one group. A command can come with a settings page.

## Consequences

- Friends can start, wake and stop servers from Discord with the same rights as in the panel.
- Copying a channel ID needs Discord's developer mode; the README explains it.
- The bot shows player counts only once the panel keeps them outside the console hub.
