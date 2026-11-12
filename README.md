# Rafelo

[![ci](https://github.com/yutna/rafelo/actions/workflows/ci.yml/badge.svg)](https://github.com/yutna/rafelo/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/yutna/rafelo?sort=semver)](https://github.com/yutna/rafelo/releases/latest)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Opinionated Ruby on Rails BFF template tailored for modern frontend applications.

Rafelo is a Rails 8.1 application baseline for building a
backend-for-frontend (BFF): a server that renders Hotwire pages where that is
useful, exposes JSON endpoints for a separate frontend, and already has the
operational pieces (jobs, cache, cable, Docker, Kamal) wired together.

The application code is intentionally still close to the Rails baseline while
the template conversion proceeds. This release is the tested baseline plus the
same GitHub workflow used by the rest of
[yutna](https://github.com/yutna)'s public repositories. The architecture
specification lives in [docs/architecture/](docs/architecture/).

## Use this template

This repository is a GitHub template. Create a new repository from it:

```sh
gh repo create my-app --template yutna/rafelo --public
```

Then clone your new repository and follow [Getting started](#getting-started).
Read [docs/customization.md](docs/customization.md) before the first commit:
the application name, credentials, deployment settings and community files
are all meant to be replaced.

## What is included

- Rails 8.1 with Propshaft, Importmap, Hotwire (Turbo + Stimulus) and Jbuilder
- SQLite for development and test, with separate SQLite databases for
  Solid Cache, Solid Queue and Solid Cable in production
- Active Job, Action Cable and Active Storage (with libvips variants)
- Kamal 2, Thruster and a production Dockerfile
- Minitest and Capybara, Brakeman, bundler-audit, importmap audit, and
  RuboCop with rails-omakase
- GitHub Actions CI with a single required `ci-ok` gate, plus the shared
  `pr-check`, `issue-check` and `release` callers from
  [yutna/oss-kit](https://github.com/yutna/oss-kit)
- Community files and issue/pull request templates
- A project-local OpenCode setup with the object-oriented design skills

## Requirements

- Docker with Dev Container support
- [mise](https://mise.jdx.dev/) for a host-based setup
- libvips (for Active Storage variants)
- SQLite 3.8 or newer for the current baseline

Ruby, Node and npm are pinned by `mise.toml`; do not install a different
version by hand. The Dev Container installs the pinned versions and PostgreSQL
for you.

## Development environment

Development runs in the Dev Container definition under `.devcontainer/`. It
uses the Rails Dev Container image pinned by tag and digest, installs Ruby
4.0.9, Node 26.13.0 and npm 12.2.2 from `mise.toml`, and starts PostgreSQL
18.6 as a service pinned by digest. The post-create command installs the
pinned tools and prepares the application.

Forwarded ports:

| Port | Purpose |
| ---: | --- |
| 3000 | Rails |
| 3036 | Vite |
| 5432 | PostgreSQL |

Open the repository in the Dev Container, then run:

```sh
bin/dev
```

For a host-based setup, install Docker and mise, then run:

```sh
mise install
bin/setup --skip-server
bin/dev
```

Open <http://localhost:3000/up>. The template has no application-specific
routes yet; `/up` is the health check used by load balancers and uptime
monitors.

Verify the pins from the repository root:

```sh
mise exec -- ruby --version
mise exec -- node --version
mise exec -- npm --version
docker compose -f .devcontainer/compose.yaml config
```

Playwright browsers are installed by the post-create hook once
`@playwright/test` is part of `package.json`.

## Credentials

The template intentionally does not ship `config/credentials.yml.enc`. Every
clone creates its own key and encrypted file:

```sh
bin/rails credentials:edit
```

This creates `config/master.key` (ignored by git) and
`config/credentials.yml.enc`. Never commit `config/master.key`. For
production, provide the key as `RAILS_MASTER_KEY`; see
[docs/deployment.md](docs/deployment.md).

## Testing

```sh
bin/rails test
bin/rails test:system   # requires Chrome
bin/ci                  # the local CI suite
```

`bin/ci` runs setup, RuboCop, the security scans, the test suite and the seed
check. System tests are commented out there by default; run them explicitly
when a change touches browser behaviour.

## AI-assisted development

The repository includes a project-local OpenCode V2 setup and a vendored copy
of the [object-oriented design skills](https://github.com/yutna/object-oriented-design-skills).
The agent instructions live in [AGENTS.md](AGENTS.md); usage, provenance and
update steps are in [docs/opencode.md](docs/opencode.md). The setup is optional:
the Rails application does not depend on OpenCode.

## Deployment

The production image uses the included Dockerfile, Thruster and a persistent
SQLite volume. Kamal configuration lives in `config/deploy.yml`. See
[docs/deployment.md](docs/deployment.md) for the full checklist, including
`RAILS_MASTER_KEY`, the `/up` health check and backups.

## Project structure

```text
app/controllers     request handling; add the BFF/API namespace here
app/models          persistence and domain models
app/views           Hotwire pages, mailers and PWA files
app/javascript      Stimulus controllers and Importmap entrypoints
config/             environments, routes, deployment and Solid* settings
db/                 schema, seeds and Solid* database schemas
docs/               architecture, customization, deployment and OpenCode notes
.opencode/          OpenCode config and vendored design skills
test/               Minitest, integration and system tests
AGENTS.md           project instructions loaded by OpenCode
```

## Documentation

- [Architecture](docs/architecture.md)
- [Customizing the template](docs/customization.md)
- [Deployment](docs/deployment.md)
- [OpenCode setup](docs/opencode.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Support](SUPPORT.md)

## Roadmap

These are intentionally out of scope for v0.1.0 and are the next layers to
build on the baseline:

- an API namespace, JSON error format and request/response tests
- CORS, session/cookie strategy and CSRF handling for a separate frontend
- authentication and authorization
- upstream service clients with timeout, retry and circuit-breaker conventions
- OpenAPI or contract tests
- an example frontend integration

## Versioning and releases

`VERSION` tracks the template release. The repository uses SemVer and
`vX.Y.Z` milestones; closing a complete milestone creates the tag and GitHub
Release, and GitHub Releases are the changelog. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the day-to-day flow.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md)
first.

## License

[MIT](LICENSE)
