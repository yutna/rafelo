# Architecture

Rafelo is a Rails application that is meant to sit between a frontend and one
or more upstream services. That position is usually called a
backend-for-frontend (BFF): the frontend talks to one origin, and the BFF owns
the browser-facing contract, session handling and the translation to internal
APIs.

## Current baseline

The v0.1.0 baseline is deliberately close to a stock Rails 8.1 application:

- Rails handles routing, controllers, views and Active Record.
- Propshaft serves assets, Importmap provides JavaScript without a Node build,
  and Hotwire (Turbo + Stimulus) handles page navigation and small interactions.
- Jbuilder is available for JSON responses.
- Active Job uses Solid Queue in production; Solid Cache and Solid Cable cover
  caching and Action Cable.
- SQLite is the default database. Production uses separate SQLite databases
  for the primary data, cache, queue and cable stores.
- Active Storage is configured with local storage and libvips variants.
- `/up` is the health check endpoint.

There is no API namespace, authentication layer or upstream client yet. Those
are the next pieces, not hidden features of this release.

## Request flow

```text
browser / frontend
        |
        v
Rails router (config/routes.rb)
        |
        v
controller (app/controllers)
        |
        +--> view / Turbo response (app/views)
        |
        +--> JSON response (Jbuilder or render json:)
        |
        +--> service / upstream client (planned)
                    |
                    v
             internal services
```

For a same-origin Hotwire application, a controller usually renders a view.
For a separate frontend, the BFF exposes a JSON namespace and the frontend
sends requests to it. Both styles can coexist.

## Where BFF code should go

When the first feature is added, keep the boundary explicit:

- `app/controllers/api/` for JSON endpoints
- `app/controllers/concerns/` for shared authentication and error handling
- `app/services/` for use cases that coordinate several models or upstreams
- `app/clients/` for upstream HTTP clients and their timeout/retry policy
- `app/serializers/` or Jbuilder templates for response shaping
- `test/integration/` for request-level contracts, `test/services/` and
  `test/clients/` for the layers below

The BFF should not leak upstream payloads directly to the frontend. Shape the
response at the boundary and keep a stable error format.

## Frontend integration options

1. **Same-origin Hotwire** — Rails renders pages and Turbo updates them. This
   is the nearest path and needs no CORS.
2. **Separate SPA** — the frontend calls a JSON namespace. Decide early whether
   the session is a same-site cookie or a token, then configure CORS, CSRF and
   cookie settings together.
3. **Hybrid** — Hotwire for account and admin pages, JSON for the product
   surface. Keep one authentication mechanism rather than two.

## Operational pieces

- **Jobs:** Solid Queue. Start a worker with `bin/jobs` or run the supervisor
  inside Puma (`SOLID_QUEUE_IN_PUMA=true`).
- **Cache:** Solid Cache. Configured in `config/cache.yml`.
- **Cable:** Solid Cable. Configured in `config/cable.yml`.
- **Storage:** local Active Storage in `storage/`. Change
  `config/storage.yml` before deploying multiple hosts.
- **Health:** `GET /up` returns 200 when the application boots.

## Planned layers

The roadmap in the README lists the next work: API namespace and error
format, CORS/session strategy, authentication and authorization, upstream
clients, contract tests and an example frontend. Add each layer with tests and
a short note here so the boundary stays understandable.
