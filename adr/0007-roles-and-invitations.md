# 0007: Roles and invitations

- **Status:** Accepted
- **Date:** 2026-11-11

## Context

ADR 0006 introduced accounts with the roles `owner`, `admin` and `member`, but left open what each role may do and how friends get an account. Harrier is for groups of friends: most people only want to play and maybe wake a server up; a few manage everything.

## Decision

### Roles

| Action | member | admin | owner |
|---|---|---|---|
| See servers, their status and console output | ✓ | ✓ | ✓ |
| Start and stop servers | ✓ | ✓ | ✓ |
| Send console commands | – | ✓ | ✓ |
| Create servers, see nodes and agents | – | ✓ | ✓ |
| Invite members, revoke invitations, remove members | – | ✓ | ✓ |
| Invite admins, change roles, remove admins | – | – | ✓ |

- Starting and stopping is allowed for members on purpose: a friend can wake the server up without asking someone.
- Console commands are admin-only because they are powerful (`op`, `stop`, `ban`).
- There is exactly one owner. The owner cannot be removed or demoted (transferring ownership comes later).
- Roles are checked in the gateway for HTTP routes and the console, and **again in the identity service** for user management. The identity service loads the acting user's role from its own database instead of trusting the role sent along.
- Per-server permissions ("Anna may only use the survival server") come later, once someone needs them.

### Invitations

- An admin or the owner creates an invitation for a role (`member`, or `admin` by the owner only). It is a link `<public URL>/invite?token=…` with a random 256-bit token; only its SHA-256 is stored.
- Invitations are **single-use** and expire after **7 days**. They can be revoked while unused.
- The link is shared by any means (chat, Discord). Opening it lets the person choose name, e-mail and password; the account gets the invitation's role and is logged in right away.
- Accepting is atomic: the invitation is marked as used in the same transaction that creates the account, so a link cannot create two accounts.

## Consequences

- Friends join without e-mail infrastructure; an e-mail invitation can be added later on top of the same links.
- Leaked links are limited by single use, expiry and revocation.
- The Discord login (next step) will link Discord accounts to existing users or accept invitations, but never create accounts without an invitation.
