# Contributing

Thanks for your interest. This project has a single maintainer, so the
process is small and the same for every change.

## How a change gets in

1. **Issue first.** Open or find an issue that describes the change. Use the
   _Implementation change_ form for planned work; it asks for the outcome,
   acceptance checks, spec rule IDs, out-of-scope work and evidence. The
   maintainer triages it into a milestone.
2. **Branch** from `main` as `<type>/<issue>-<slug>`, for example
   `feat/12-login`.
3. **Open a draft pull request early.** CI runs on drafts too. Mark it
   _Ready for review_ when the work is done.
4. **Title the pull request in [Conventional Commits](https://www.conventionalcommits.org/)
   form:** `<type>(<scope>)!: <summary>`, where type is one of `feat`, `fix`,
   `docs`, `chore`, `refactor`, `test`, `ci`, `build`, `perf`, `style`,
   `revert`. The scope is optional and lower-case; `!` marks a breaking change.
   The title becomes the commit on `main`.
5. **Link the issue** with `Closes #N` in the description. The pull request
   takes the issue's milestone, and it can only be merged while it is in a
   version milestone (`vX.Y.Z`).
6. **CI must pass**: the `ci-ok` and `pr-check / check` checks. This
   repository does not add required checks, approvals, or a merge queue.
7. **Squash merge only.** The branch is deleted after the merge.

## Pull request checks

This repository runs `ci.yml` (`bin/ci` over the template, the GEN-07 adoption
run, and the N-1 to N update) and the oss-kit `pr-check` and `issue-check`
callers. The template ships its own `pull_request.yml` (title, ratchet,
guard_approval) to adopters under `template/.github/workflows/`; this
repository does not apply that ruleset or require those checks. Name every
guard-file change in the pull request for the owner's review.

A release is made when its version milestone is complete: the release pull
request sets `VERSION` and the formats fixture, and closing the milestone runs
the oss-kit release caller (see [Releases](#releases)). The release notes on
GitHub are the changelog.

## Local development

Open the repository in the Dev Container under `.devcontainer/`. It pins the
Rails base image, Ruby, Node, npm and PostgreSQL. The post-create command
installs the tools from `mise.toml` and prepares the application. Ports 3000
(Rails) and 3036 (Vite) are forwarded. PostgreSQL is reachable as
`postgres:5432` on the Dev Container network and is not published to the host.

For a host-based setup, install Docker and mise, then run:

```sh
mise install
bin/setup --skip-server
bin/dev
bin/ci
```

`bin/setup` installs gems and npm packages, prepares PostgreSQL and clears
logs and tmp. `bin/dev` starts Rails and Vite at <http://localhost:3000>.
`bin/ci` runs the local checks: style, security scans, the Vite build, RSpec
and seeds.

Verify the exact runtime pins with:

```sh
mise exec -- ruby --version
mise exec -- node --version
mise exec -- npm --version
docker compose -f .devcontainer/compose.yaml config
```

Playwright browsers are installed by the Dev Container post-create hook once
`@playwright/test` is part of `package.json`.

The template ships `config/credentials/production.yml.enc` with placeholder
values and the committed dummy credentials used by the dummy boots. Re-encrypt
the production file with your own secrets and key before deploying; never
commit the key. Create local credentials with `bin/rails credentials:edit`
when an integration needs them.

## Releases

`VERSION` holds the release being prepared, for example `0.20.0`. The release
pull request sets it, runs `bin/rails formats:dump`, and commits
`spec/fixtures/formats/v<VERSION>/`. CI fails a pull request that leaves the
format invalid, uses a tag that already exists, or does not raise the version
above the highest `v*` tag (`script/ci/release --check`).

Closing the version milestone at 100% runs the oss-kit release caller
(`.github/workflows/release.yml`): it preflights `VERSION` and the formats
fixture, tags the default branch, and creates the GitHub Release with
generated notes (`.github/release.yml`). Closing a milestone with open items
reopens it and fails. The release pull request must merge before the milestone
closes; closing the milestone again after the release does nothing.
