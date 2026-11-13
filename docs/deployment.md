# Deployment

The template ships two Kamal profiles that run the same production image and
code (OPS-06):

| Profile | File | PostgreSQL | Active Storage | Solid Queue |
| --- | --- | --- | --- | --- |
| Single host (default) | `config/deploy.yml` | Kamal accessory on a named volume, or a managed service | Disk on the `rafelo_storage` volume, or S3-compatible | In the web Puma process |
| Multi host | `config/deploy.multi.yml` | Managed service shared by every host | S3-compatible | Separate `job` role (`bin/jobs`) |

Nothing else is host-local (ARCH-13). Request and job scratch files live in
the container's temporary directories; data lives in PostgreSQL or Active
Storage.

## Docker

The production image is separate from the Dev Container (OPS-09). It runs
Thruster in front of Puma, exposes port 80, and its final stage runs as a
non-root user.

Build and run it locally:

```sh
docker build -t rafelo .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=rafelo \
  -e DB_NAME=rafelo_production \
  -e RAFELO_API_BASE_URL=http://host.docker.internal:4000 \
  -e RAILS_HOSTS=localhost \
  --name rafelo \
  rafelo
```

The image build sources `.env.ci.production` and uses the committed dummy
credentials with `SECRET_KEY_BASE_DUMMY=1`; it never needs the production key
(BE-08, SEC-12). CI builds the image without pushing it after a throwaway
`rafelo:module` changes the lockfile, on the pull requests that can break the
build and nightly (OPS-06).

## Secrets and configuration

`RAILS_MASTER_KEY` is the app's only `env.secret`. It decrypts
`config/credentials/production.yml.enc`, which holds every production secret:

- `secret_key_base`;
- `active_record_encryption.primary_key`, `deterministic_key`, and
  `key_derivation_salt`;
- `database.password` and `database.migration_password` (the runtime and
  migration roles, OPS-08);
- `aws.access_key_id` and `aws.secret_access_key` for the S3-compatible
  Active Storage service.

Everything else is a clear value in the profile's `env.clear`: upstream base
URLs, hosts, database host/name/users, pool sizes, and the Active Storage
service. A missing credential fails boot, not the first sign-in. Create or
edit the production credentials with the production key:

```sh
RAILS_MASTER_KEY=<the key> bin/rails credentials:edit --environment production
```

Put the key in `.kamal/secrets` through a password manager or the deploy
environment; never commit it. The single-host PostgreSQL accessory also reads
`POSTGRES_PASSWORD` from `.kamal/secrets`.

Create the runtime and migration database roles before the first deploy (the
accessory creates only the runtime `rafelo` role), and put their passwords in
the `database` credentials above. The entrypoint runs `db:prepare` as the
migration role while the old release still serves (BE-22); the web server and
the job role then connect as the runtime role.

## Single host

1. Edit `config/deploy.yml`: the host, registry, `RAILS_HOSTS`, upstream base
   URL, and the PostgreSQL accessory host.
2. Provide `RAILS_MASTER_KEY` and `POSTGRES_PASSWORD` to `.kamal/secrets`.
3. Deploy:

```sh
bin/kamal setup
bin/kamal deploy
```

The PostgreSQL accessory image is pinned by version and digest at the Dev
Container's major version. A major upgrade is planned work (dump and restore,
or `pg_upgrade`), never a tag bump. The web Puma process runs Solid Queue's
supervisor because `SOLID_QUEUE_IN_PUMA` is set.

Useful aliases are defined in the profile:

```sh
bin/kamal console
bin/kamal logs
bin/kamal dbc
```

## Multi host

1. Edit `config/deploy.multi.yml`: the web and job hosts, the load balancer,
   the managed PostgreSQL host, the S3-compatible bucket and region, and
   `RAILS_HOSTS`.
2. Point every host and the load balancer at the managed services.
3. Deploy the profile explicitly:

```sh
bin/kamal -c config/deploy.multi.yml setup
bin/kamal -c config/deploy.multi.yml deploy
bin/kamal -c config/deploy.multi.yml rollback
```

`boot.limit: 1` boots one host at a time, so only the first host's
`db:prepare` runs while the old release still serves (BE-22). The job role
runs `bin/jobs`; the web role has no `SOLID_QUEUE_IN_PUMA` because any value,
including `"false"`, turns the Puma plugin on. Recheck the BE-21 connection
arithmetic after adding hosts, job containers, or a second database.

In front of publicly addressed load balancers, add the balancer's addresses to
`config.action_dispatch.trusted_proxies`; never trust a client-supplied
`X-Forwarded-For` beyond known proxies.

## Preflight

`script/ci/deploy_preflight` runs in `bin/ci` and through the Kamal hook
`.kamal/hooks/pre-deploy` before every deploy, redeploy, and rollback. It
checks both profiles: `deploy_timeout`, `boot.limit`, `asset_path`, the app's
only secret, every `.env.ci.production` key in `env.clear`, the non-root final
image stage, no tracked secret file, the pinned PostgreSQL accessory, and the
multi-host job/S3/no-host-volume shape. When a production key is available it
also compares the production and dummy credential key paths, printing paths
and never values; CI skips that comparison because it never holds the key.

## Health checks and data

- Point the load balancer or uptime monitor at `/up`; it checks no upstream
  (OPS-05). `/core/ready` adds a PostgreSQL query.
- PostgreSQL holds the BFF data, cache, queue, and cable tables. Back it up
  off the host before taking traffic, and run the monthly restore drill in
  [operations/backup-restore.md](operations/backup-restore.md) (OPS-07).
- Assets are bridged from `/rails/public/vite`, so a tab still running the
  previous release can fetch its chunks during and just after a deploy.

## Release flow

Releases are created from version milestones, not from tag pushes:

1. Update `VERSION` in a pull request and merge it.
2. Move any unfinished work out of the `vX.Y.Z` milestone.
3. Close the milestone. The release workflow tags the default branch and
   creates the GitHub Release with generated notes.

`release-tags` protects `v*` tags from deletion or updates. If you need to fix
a bad tag, disable that ruleset temporarily, fix the tag, and re-enable it.

## Security checklist

- Keep `config/master.key` out of git.
- Set `config.force_ssl = true` and `config.assume_ssl = true` when TLS
  terminates at a proxy.
- Configure `config.hosts` for the production host.
- Keep Dependabot alerts, security updates, secret scanning and CodeQL
  enabled.
- Review the generated CSP before enabling it in production.
