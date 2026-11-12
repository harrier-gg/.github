# 0019: Integration settings

- **Status:** Accepted
- **Date:** 2026-11-12

## Context

Every Harrier installation needs its own credentials for external services: a Discord application for the login (its redirect URL contains the panel's address) and the bot, and a CurseForge API key (keys must stay secret, so an open-source project cannot ship one). Until now they were environment variables in `.env` on the server, which means a shell and a restart for every change. Owners should be able to set them in the panel.

## Decision

- **An "Integrations" page for the owner** (new permission `manageInstance`, owner only): Discord login (client ID and secret, with the redirect URL to copy), Discord bot (token and notification channel, with its status and invite link), CurseForge (API key). Each section says where to get the values.
- **The identity service stores them** in its database. Secrets are encrypted with AES-256-GCM using `HARRIER_APP_KEY` (32 random bytes, base64; the installer creates it, M8). Without the key the page can show values from the environment but cannot save secrets.
- **Secrets never leave the backend in plain text towards a browser:** the page shows only "set" or "not set" and can replace or remove them. Other services ask identity over NATS (`settings.get`), which stays inside the backend's network.
- **Environment variables still win**, so automated setups keep working; the page shows such values as "from the environment" and does not let them be changed.
- **Changes apply without a restart:** identity announces `settings.changed`; the Discord service reconnects the bot, the login uses the new values at once.

## Alternatives

- **Environment variables only:** needs a shell and a restart for every change; hard for the homelab owners Harrier is for.
- **Each service stores its own settings:** three places for one page; identity already owns instance-wide data such as the owner account.
- **Plain-text secrets in the database:** a database dump or backup would leak the bot token and API keys.

## Consequences

- Losing `HARRIER_APP_KEY` makes stored secrets unreadable; they have to be entered again.
- New integrations (S3 for backups, Steam login) are more keys on the same page.
