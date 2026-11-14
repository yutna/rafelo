# Acme

A Rails BFF built from the Rafelo application template.

The full rules live in [`docs/architecture/`](docs/architecture/). Start with
[`AGENTS.md`](AGENTS.md) before changing code, then run:

```sh
bin/setup --skip-server
bin/ci
```

Create your own credentials before deploying:

```sh
bin/rails credentials:edit
```

Report a vulnerability privately through the repository's security advisories,
never in a public issue.
