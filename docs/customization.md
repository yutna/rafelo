# Customizing the template

The template is a starting point, not a library. Replace the names, metadata
and secrets before the first commit in your new repository.

## Rename the application

The application is called `Rafelo` in code and `rafelo` in configuration.
Change both spellings consistently. The files that currently contain them are:

- `config/application.rb` — the `Rafelo` module
- `config/deploy.yml` — service name, image name, volume and accessory names
- `app/views/layouts/application.html.erb` — page title and application name
- `app/views/pwa/manifest.json.erb` — PWA name and description
- `Dockerfile` — example image and container names
- `README.md` — project name, badges and URLs

After renaming the module, run the test suite and boot the server once:

```sh
bundle exec rspec
bin/dev
```

## Credentials

Create your own credentials file:

```sh
bin/rails credentials:edit
```

Commit `config/credentials.yml.enc` if your team shares it, but never commit
`config/master.key`. For a solo project, keeping the key out of git and
providing it through a password manager or `RAILS_MASTER_KEY` is enough.

## Database

PostgreSQL is the default. The Solid Cache, Queue and Cable tables live in the
primary database through the migrations under `db/migrate/`; they are part of
`db/schema.rb`.

If you do not need one of the Solid components, remove its gem, configuration
file, migrations and deployment environment variable together. Do not leave a
half-configured component behind.

## Deployment

Edit `config/deploy.yml` before the first deploy:

- `service` and `image`
- the `servers.web` host list
- the registry server and credentials
- the persistent volume path
- `RAILS_MASTER_KEY` and any other secrets

See [deployment.md](deployment.md).

## GitHub metadata

The repository carries the shared workflow from
[yutna/oss-kit](https://github.com/yutna/oss-kit). If you fork it for another
account or organization, update:

- `LICENSE` — copyright holder and year
- `.github/ISSUE_TEMPLATE/*.yml` — `assignees`
- `SECURITY.md` and `.github/ISSUE_TEMPLATE/config.yml` — the security advisory URL
- `CODE_OF_CONDUCT.md` — the maintainer contact
- `.github/dependabot.yml` — `assignees`
- `README.md` — badges, description and links

If you keep the workflow, enable the repository settings described in
`docs/conventions.md` in oss-kit: issues on, wiki/projects/discussions off,
squash-only merges, auto-merge, delete branches on merge, Dependabot alerts,
secret scanning, private vulnerability reporting and CodeQL.

## Release version

`VERSION` tracks the template release. Change it only when you prepare a
release, and keep it equal to the milestone without the `v` prefix:

```text
VERSION       -> 0.2.0
milestone     -> v0.2.0
```

The release workflow runs `grep -qx "$VERSION" VERSION` before tagging. If you
do not want that check, remove the `preflight` input from
`.github/workflows/release.yml`.

## Building the BFF layer

The template does not yet include the full BFF kernel, CORS, authentication
or upstream clients. When you add them, keep the layering described in the
[architecture specification](architecture/00_README.md) and add tests for the
boundary. A useful first slice is:

1. `app/controllers/api/v1/` with one read-only endpoint
2. a request test that asserts the JSON shape and status codes
3. a consistent error envelope
4. an upstream client with explicit timeouts
5. CORS and session settings only after the contract is stable
