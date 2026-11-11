# 0006: Users, login and sessions

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

Until now the panel has no users: REST API and live consoles are only protected by listening on localhost and by origin checks. Harrier is meant for groups of friends, so it needs accounts, a first owner, invitations, roles and later a Discord login.

The plan originally named Better Auth. Better Auth wants to own HTTP routes and its own database tables in the process that serves them. In Harrier only the gateway speaks HTTP, and each service owns its data and offers it via NATS (ADR 0001). The first features we need (password login, sessions, invitations, roles, one OAuth provider) are small enough to build directly and keep fully understood.

## Decision

- **A new `identity` service owns users and sessions** (Postgres schema `identity`) and is reachable via NATS only. The gateway offers the HTTP endpoints (`/api/v1/auth/*`) and sets the cookie.
- **First owner via a one-time setup link.** While no user exists, the identity service creates a random setup token on start and logs a link (`<public URL>/setup?token=…`). Only that link can create the first account, which gets the role `owner`. Creating it is atomic: it fails if any user exists. Afterwards accounts only come from invitations (next step of M2).
- **Passwords:** `scrypt` from Node's standard library (N=2^15, r=8, p=3, 16-byte salt; OWASP-recommended parameters), stored as `scrypt$N$r$p$salt$hash`, compared in constant time. Minimum length 10 characters.
- **Sessions:** a random 256-bit token in an `HttpOnly`, `SameSite=Lax` cookie (`Secure` when the panel runs on HTTPS). The database stores only its SHA-256. Sessions last 30 days and are extended when used. Logout deletes the session.
- **Every API route requires a session** except health, meta and the auth endpoints themselves. The live console checks the session on the WebSocket upgrade, in addition to the same-origin check. Agents keep authenticating with their node token (ADR 0004).
- **Brute force:** failed logins are limited per e-mail address (10 per 15 minutes); errors never reveal whether an e-mail address exists.
- **Roles:** `owner`, `admin`, `member` are stored per user now; what each role may do is decided together with invitations (next step of M2).
- **Discord login** follows as an OAuth provider in the identity service (authorization code flow with PKCE), linked to existing users.

## Consequences

- Panel and consoles are protected; the gateway may listen on other interfaces once HTTPS is set up (installer, M8).
- We own the security-relevant code. It stays small, covered by tests, and uses only standard library cryptography.
- Passkeys and two-factor authentication come later with dedicated libraries (e.g. `@simplewebauthn/server`, `otpauth`), not with a framework.
