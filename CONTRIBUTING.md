# Contributing

Thanks for your interest. This project has a single maintainer, so the
process is small and the same for every change.

## How a change gets in

1. **Issue first.** Open or find an issue that describes the change. Use the
   *Implementation change* form for planned work; it asks for the outcome,
   acceptance checks, spec rule IDs, out-of-scope work and evidence. The
   maintainer triages it into a milestone.
2. **Branch** from `main` as `<type>/<issue>-<slug>`, for example
   `feat/12-login`.
3. **Open a draft pull request early.** CI runs on drafts too. Mark it
   *Ready for review* when the work is done.
4. **Title the pull request in [Conventional Commits](https://www.conventionalcommits.org/)
   form:** `<type>(<scope>)!: <summary>`, where type is one of `feat`, `fix`,
   `docs`, `chore`, `refactor`, `test`, `ci`, `build`, `perf`, `style`,
   `revert`. The scope is optional and lower-case; `!` marks a breaking change.
   The title becomes the commit on `main`.
5. **Link the issue** with `Closes #N` in the description. The pull request
   takes the issue's milestone, and it can only be merged while it is in a
   version milestone (`vX.Y.Z`).
6. **CI must pass**: the `ci-ok` and `pr-check / check` checks.
7. **Squash merge only.** The branch is deleted after the merge.

A release is made when its version milestone is complete: closing the
milestone creates the GitHub Release with generated notes. The release notes
on GitHub are the changelog.

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

Create local credentials with `bin/rails credentials:edit` when an
integration needs them. The template does not ship an encrypted credentials
file, so every clone starts with its own key.

## Releases

`VERSION` tracks the template release. Before closing a version milestone,
update `VERSION` to the version without the `v` prefix, for example `0.2.0`.
The release workflow checks it before tagging.
