# Rafelo

[![ci](https://github.com/yutna/rafelo/actions/workflows/ci.yml/badge.svg)](https://github.com/yutna/rafelo/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/yutna/rafelo?sort=semver)](https://github.com/yutna/rafelo/releases/latest)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Opinionated Ruby on Rails BFF template tailored for modern frontend applications.

Rafelo is a Rails 8.1 application baseline for building a
backend-for-frontend (BFF): Rails owns HTTP, sessions, props and integration;
React renders pages through Inertia; PostgreSQL and the Solid trio hold the
data the BFF owns.

The template conversion is in progress. This release is the tested baseline:
PostgreSQL, Inertia + React + Vite + Tailwind, and RSpec. The architecture
specification lives in [docs/architecture/](docs/architecture/).

## Use this template

This repository is a GitHub template. Create a new repository from it:

```sh
gh repo create my-app --template yutna/rafelo --public
```

Then clone your new repository and follow [Development environment](#development-environment).
Read [docs/customization.md](docs/customization.md) before the first commit:
the application name, credentials, deployment settings and community files
are all meant to be replaced.

## What is included

- Rails 8.1 with Inertia, React, Vite and Tailwind CSS
- PostgreSQL 18.6 in development, test and production
- Solid Cache, Solid Queue and Solid Cable in the primary database
- Active Job, Action Cable and Active Storage (with libvips variants)
- Kamal 2, Thruster and a production Dockerfile
- RSpec, FactoryBot, WebMock, Brakeman, bundler-audit, npm audit, and
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

Ruby, Node and npm are pinned by `mise.toml`; do not install a different
version by hand. The Dev Container installs the pinned versions and PostgreSQL
for you.

## Development environment

Development runs in the Dev Container definition under `.devcontainer/`. It
uses a prebuilt image published to GitHub Container Registry and pinned by
digest in `.devcontainer/image_digest`: the Ruby 4.0.9 base, Node 26.13.0 and
npm 12.2.2 from `mise.toml`, the Playwright browsers, and the PostgreSQL
client. PostgreSQL 18.6 runs as a service pinned by digest. The same image is
what CI runs, so a local pass and a CI pass use the same tools.

Forwarded ports:

| Port | Purpose |
| ---: | --- |
| 3000 | Rails |
| 3036 | Vite |

PostgreSQL is reachable from the app as `postgres:5432` on the Dev Container
network. It is not published to the host.

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

Open <http://localhost:3000/> for the Inertia home page and
<http://localhost:3000/up> for the health check used by load balancers and
uptime monitors.

Verify the pins from the repository root:

```sh
mise exec -- ruby --version
mise exec -- node --version
mise exec -- npm --version
docker compose -f .devcontainer/compose.yaml config
```

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
bundle exec rspec
bin/ci                  # the local CI suite
```

`bin/ci` runs setup, RuboCop, the security audits, the Vite build, RSpec and
the seed check. Browser tests are added with the Playwright milestone.

## AI-assisted development

The repository includes a project-local OpenCode V2 setup and a vendored copy
of the [object-oriented design skills](https://github.com/yutna/object-oriented-design-skills).
The agent instructions live in [AGENTS.md](AGENTS.md); usage, provenance and
update steps are in [docs/opencode.md](docs/opencode.md). The setup is optional:
the Rails application does not depend on OpenCode.

## Deployment

The production image uses the included Dockerfile, Thruster and PostgreSQL.
Kamal configuration lives in `config/deploy.yml`. See
[docs/deployment.md](docs/deployment.md) for the full checklist, including
`RAILS_MASTER_KEY`, the `/up` health check and backups.

## Project structure

```text
app/controllers     request handling; BFF controllers and sessions
app/frontend        Inertia entrypoint, pages, styles and client code
app/models          BFF-owned persistence
config/             environments, routes, deployment and Solid* settings
db/                 schema, migrations, seeds and Solid* tables
docs/               architecture specification, customization and operations
.opencode/          OpenCode config and vendored design skills
spec/               RSpec request and unit tests
AGENTS.md           project instructions loaded by OpenCode
```

## Documentation

- [Architecture specification](docs/architecture/00_README.md)
- [Customizing the template](docs/customization.md)
- [Deployment](docs/deployment.md)
- [OpenCode setup](docs/opencode.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Support](SUPPORT.md)

## Roadmap

The remaining work follows the architecture specification:

- the core kernel, contracts, sessions and authorization
- the design system and object-oriented frontend domain
- generators, example engines and operations
- the application template and adoption proof

## Versioning and releases

`VERSION` holds the release being prepared. The repository uses SemVer and
`vX.Y.Z` milestones. The release pull request sets `VERSION`; after it merges,
the first green CI push to `main` creates the tag and GitHub Release, and
GitHub Releases are the changelog. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the day-to-day flow.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md)
first.

## License

[MIT](LICENSE)
