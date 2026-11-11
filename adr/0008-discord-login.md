# 0008: Discord login

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Groups of friends usually meet on Discord. Logging in with Discord saves them a password, and joining via an invitation becomes one click. ADR 0007 already decided that Discord must never create accounts without an invitation.

## Decision

- **OAuth2 authorization code flow**, handled by the identity service as a confidential client: the client secret never leaves the backend (`HARRIER_DISCORD_CLIENT_ID`, `HARRIER_DISCORD_CLIENT_SECRET`). Scopes: `identify email`.
- Discord does not document PKCE for this flow, so the protection against forged or injected logins is a random 256-bit **`state`**, stored server-side for 10 minutes and bound to the browser with an `HttpOnly` cookie. The callback is only accepted if both match, and every `state` works once.
- **Three ways to use it:**
  - **Log in:** only works for users whose account is linked to that Discord account. Otherwise the panel says so; no account is created.
  - **Link:** a logged-in user connects their Discord account (one Discord account per Harrier account).
  - **Join via invitation:** the invitation link offers "Join with Discord"; the account gets name and e-mail from Discord (the e-mail must be verified there) and no password.
- The Discord access token is used once to read the profile and then discarded; we store only the Discord user ID and display name.
- The feature is off until the client ID and secret are configured.
- The Discord API base URL is configurable, so the whole flow can be tested against a local mock.

## Consequences

- Accounts without a password can only log in with Discord; setting a password later is a small follow-up.
- The Discord bot (M5) uses the same Discord application.
