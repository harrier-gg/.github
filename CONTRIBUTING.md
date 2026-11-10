# Contributing to Harrier

Thanks for helping! This guide applies to every repository in the organization (GitHub uses this file as the default when a repository has none).

Issues and discussions may be written in English or German. Code, commits, PR titles and Markdown files are in English (see [ADR 0003](adr/0003-internationalization.md)).

## Workflow: GitHub Flow

- `main` is always releasable. Nobody pushes to `main` directly, maintainers included.
- Every change goes through a **short-lived branch** and a **pull request**.
- PRs are merged **only by squash**; the branch is deleted automatically afterwards.

```
main ──●───────────●───────────●──────  (each dot = one squashed PR)
        \         /             \
         feat/agent-token        fix/handshake-timeout
```

External contributors: fork the repository, create the branch in your fork, and open the PR against `main`.

### Branch names

`<type>/<short-description>`, e.g. `feat/agent-token`, `fix/ws-reconnect`, `docs/install-guide`. Types as for commits (below).

### PR title = commit on main = changelog

Because we squash-merge, the **PR title** becomes the commit message on `main`. release-please turns it into the version bump and the changelog entry, so the title must follow [Conventional Commits](https://www.conventionalcommits.org) (checked by CI):

| Title | Effect on the next release |
|---|---|
| `fix(gateway): handshake timeout` | patch (0.1.0 → 0.1.1) |
| `feat(agent): agent token on connect` | minor (0.1.0 → 0.2.0) |
| `feat!: protocol v2` or `BREAKING CHANGE:` in the body | major (before 1.0: minor) |
| `docs:`, `test:`, `ci:`, `build:`, `refactor:`, `chore:` | no release |

The commits **inside** your branch can be anything; they disappear when squashed.

### PR description = template

Every PR uses the [pull request template](pull_request_template.md). The `pr / template` check verifies that:

- exactly one **Type** is ticked (feature, bug fix, docs, refactor/chore/CI),
- **Summary** and **How was this tested?** are filled in,
- **bug fixes link an issue** ("Closes #123").

## Merge rules

| Rule | Applies to |
|---|---|
| All required checks must pass | **everyone**, admins included; nobody can bypass it |
| At least one approving review from a maintainer | PRs by contributors; a new push dismisses earlier approvals |
| All review conversations resolved | everyone |
| Merging | only maintainers (people with write access) |

Maintainers may merge their own PRs without a second review (the review rule allows that bypass), but never with failing checks.

Workflows of first-time contributors only run after a maintainer approves them in the PR. This protects our CI from abuse; please be patient.

### Required checks

| Repository | Checks |
|---|---|
| backend | `check`: lint, types, tests, build, `openapi.json` up to date |
| web | `check`: lint, translations, API client up to date, build |
| agent | `check`: `cargo fmt`, Clippy, tests, protocol types up to date |
| all | `pr / title` (Conventional Commits), `pr / template` (PR description) |

Run the same checks locally first: `just check`.

## Translations (English + German)

The web panel ships in English and German. English is the source of truth.

1. Add the text to `src/locales/en.json` and use it via `t('your.key')`. Keys are type-checked.
2. Add the German translation to `src/locales/de.json` with the same key and the same `{{placeholders}}`.
3. `npm run i18n:check` fails for stale German keys or mismatching placeholders, and warns about missing German texts. If you do not speak German, leave the key out of `de.json`; the UI falls back to English and a maintainer will translate it.

## Releases

1. After every merge to `main`, release-please maintains a PR "chore(main): release x.y.z" with the changelog.
2. Merging that PR is the release: Git tag, GitHub release, artifacts.
3. Release PRs are opened by the Harrier release bot (a GitHub App), so the normal checks run on them, too.

Dependency updates come from Dependabot once a week as grouped PRs (`chore(deps): …`). All GitHub Actions are pinned to commit SHAs; Dependabot updates the pins.

Release branches (`release/1.x`) only appear once older versions still need fixes.

## Changes across repositories

Contracts between repositories ([ADR 0001](adr/0001-repository-layout.md)) always change in this order:

1. **Source** first: `agent` (protocol) or `backend` (API). Merge the PR and wait for the release.
2. **Consumer** second: `backend` takes over the protocol (`just protocol`), `web` the API (`just api`). Separate PR.
3. Incompatible protocol changes require a new protocol version ([ADR 0002](adr/0002-agent-protocol-versioning.md)).

Locally you can work on both at once, because the repositories sit side by side. They are still merged in this order.

## Architecture decisions

Decisions that reach beyond one repository are recorded as ADRs in this repository (`adr/`).
