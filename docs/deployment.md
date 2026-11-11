# Deployment

The template ships a production Dockerfile, Thruster and a Kamal
configuration. SQLite is used in production, so the storage volume is part of
the deployment contract.

## Docker

Build and run the image locally:

```sh
docker build -t rafelo .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  --name rafelo \
  rafelo
```

The container runs Thruster in front of Puma and exposes port 80. The health
check is `GET /up`.

## Kamal

1. Edit `config/deploy.yml`:
   - `service` and `image`
   - the `servers.web` host list
   - the registry server and credentials
   - the persistent volume
2. Make `config/master.key` available, or set `RAILS_MASTER_KEY` through your
   password manager. `.kamal/secrets` reads `config/master.key` by default.
3. Deploy:

```sh
bin/kamal setup
bin/kamal deploy
```

Useful aliases are defined in `config/deploy.yml`:

```sh
bin/kamal console
bin/kamal logs
bin/kamal dbc
```

## Environment variables

| Variable | Purpose |
|---|---|
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |
| `RAILS_LOG_LEVEL` | Log verbosity, default `info` |
| `SOLID_QUEUE_IN_PUMA` | Run the job supervisor inside Puma |
| `WEB_CONCURRENCY` | Puma worker count |
| `JOB_CONCURRENCY` | Solid Queue worker count |

Add application-specific variables to `config/deploy.yml` under `env.clear`
or `env.secret`. Do not put raw credentials in `.kamal/secrets`; read them
from a password manager or the environment.

## Health checks and data

- Point the load balancer or uptime monitor at `/up`.
- The SQLite database, cache, queue and cable files live under `storage/`.
  Keep that directory on the persistent volume and back it up.
- If you move to multiple web hosts, move the database and Solid components to
  a shared database first.

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
