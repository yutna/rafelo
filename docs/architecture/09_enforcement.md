# 09 — Enforcement

A rule that no tool checks will drift. This file maps every rule to what
enforces it and describes the gate that runs those tools. It adds no new
rules. Tools are the guards, people decide, AI builds (ADR-32).

Status:

- **enforced** — a tool fails the build wherever the rule applies, including
  feature code written later.
- **tested in kernel** — the kernel (core, design_system, generators)
  implements the rule and its own specs prove it; the example engines show it
  in use. Kernel specs that need an engine (the write flow, the error
  responder, translated errors, the envelope) run against a committed
  test-only engine, `engines/core/spec/dummy_engine`, which loads only in the
  test environment, belongs to core's Packwerk package, and is never mounted
  outside tests, so they still pass after the example engines are deleted
  (GEN-08, TS-01). Code that uses the kernel inherits the behaviour; no tool
  notices feature code that goes around it, so review covers that gap.
- **verify when adopting** — a tool can do it, but confirm the option name or
  behaviour against the pinned version before relying on it. Once confirmed,
  the row is enforced.
- **review** — checked by people only. An AI reviewer may assist a person; it
  never counts as a guard.

Every custom check marked enforced (a custom cop, an ESLint restriction, a
dependency-cruiser rule, a `script/ci/` check) has a canary fixture (TS-07), so
a broken pattern cannot pass silently. Every guard message names the rule ID
and the fix. Every `script/ci/` check and every generator or check script
(`docs:check`, `contracts:*`, `i18n:*`, `errors:check` included) takes
`--root DIR`, prints how many inputs it checked, and fails on an empty input
set or a failing subprocess, so a wrong glob cannot pass by checking nothing
(TS-07).

## Matrix

### Architecture

| Rule | Enforcement | Status |
| --- | --- | --- |
| ARCH-01 | `Rafelo/FaradayOnlyInUpstreamClient` · upstream base URLs come only from `config/upstreams.yml` (`Rafelo/EnvOnlyInConfig`, `Rafelo/ConfigXOnlyInCore`) | enforced |
| ARCH-02 | `Rafelo/FaradayOnlyInUpstreamClient` · `UpstreamClient.for` accepts only names declared in `config/upstreams.yml` · CSP request spec: `connect-src 'self'` (SEC-05) | enforced |
| ARCH-03 | `Rafelo/EngineTablePrefix`, kernel tables included (`core_sessions`, `core_audit_events`, `core_idempotency_keys`, `core_exports` in `engines/core/db/migrate`; the root `db/migrate` holds no kernel tables) · `strong_migrations` (BE-22) · review of migrations: a new table holds BFF-owned data, never a mirror of upstream entities | review (table prefix, `strong_migrations`: enforced) |
| ARCH-04 | `bin/packwerk validate` and `bin/packwerk check` (`enforce_dependencies: strict`) · generated dependency-cruiser rules: an engine imports only what its `package.yml` declares, no engine imports `app/`, core and design_system import nothing in the repository · `tsc -b` over the generated composite engine projects and their references · a domain engine that carries routes, pages, or a registry entry, or declares a product module: review | enforced (engine kinds: review) |
| ARCH-05 | privacy and public-surface checks (ARCH-09) · clone detector: flay (Ruby) and jscpd (TS/TSX) report cross-engine pairs only (matches inside one engine are ignored), over `domain/`, `forms/`, `hooks/`, `app/public/`, `app/frontend/public/`, gateways, and policies, with a minimum token count set where the two example engines report 0 so generated skeletons never match, against a committed baseline that only shrinks (ratchet) · the one kernel exception, the safe-URL predicate (`isSafeUrl` in design_system, `appPathSchema` in core), is guarded by the shared hostile-input fixture `spec/fixtures/hostile_urls.json` (FE-18); a second copy needs an ADR · which step of the sharing ladder to take: review | enforced (pair filtering and scope options of flay and jscpd: verify when adopting; ladder choice: review) |
| ARCH-06 | registry boot validation: duplicate keys, paths, permission keys (from the modules' `config/permissions.yml`; two modules may declare one prefix, GEN-06), and nav orders raise, and so do reserved keys and paths (locale-shaped, app route names and first segments, kernel error-code prefixes) · navigation links only to an engine's `root` route (core spec: a module without one stays out) · mounting and navigation derived from each module's `config/module.rb` · request spec: `legacy_paths` answer 301 to the old path's target under the module (in a module at `/payments`, `{ "/billing/refunds" => "/refunds" }` sends `/billing/refunds/5` to `/payments/refunds/5`) · a registry `flag:`: the core base controller's `require_module_enabled` (after `load_session`, before `require_viewer`, pinned by the BE-24 order spec) renders the 404 error page while the flag is off, and navigation uses the same predicate (core request spec) · registry icon spec (FE-17) · GEN-04 | enforced |
| ARCH-07 | route constraint, locale list, and the Zod locale enum (`@core/contracts/locales.generated.ts`) generated from `config/locales.yml` (`npm run locales:generate`) and checked for staleness (`npm run locales:check`) · locale middleware request spec · spec that an engine URL helper keeps the locale prefix · middleware spec: inserted after `ActionDispatch::DebugExceptions`, an unavailable locale gets the shared 404 page, each exempt path (`/up`, `/core`, `/rails`, `/cable`, `/.well-known`, Vite, `public/` files) passes through | enforced |
| ARCH-08 | `bin/packwerk validate` proves the declared graph acyclic · `tsc -b` refuses a cycle in the generated references · `bin/packwerk check` and the generated dependency-cruiser rules (type-only imports included) keep actual references inside the declared graph · `no-circular` for file cycles inside an engine · `Rafelo/NoConstantize` and the ESLint `@engines/*` and `import.meta.glob` restrictions close the dynamic-reference gaps · no `package_todo.yml`, no known-violations baseline · canaries: a declared A→B→A cycle, a Ruby cycle, a TS cycle, an undeclared dependency | enforced |
| ARCH-09 | `Rafelo/NoKernelInternals` and the dependency-cruiser rule `kernel-internals-stay-inside` keep other engines out of `internal/` in core and design_system · packwerk-extensions privacy (`enforce_privacy: strict`, `public_path: app/public/`) · generated dependency-cruiser rules: cross-engine imports only into `app/frontend/public/` · `Rafelo/NoConstantize` · ESLint `@engines/*` restriction · canaries: a private-constant reference, a non-public TS import, `@engines/` misuse, a reference into a kernel `internal/` folder from another engine · design_system API file `engines/design_system/api.d.ts` (FE-21) · additive change of other public surfaces: review | enforced (packwerk-extensions option names: verify when adopting; additive change: review) |
| ARCH-10 | reflection: `Rafelo/NoConstantize` · frontend globbing: the ESLint `@engines/*` and `import.meta.glob` restrictions (page resolver only) · `Rafelo/EngineTablePrefix` · `Rafelo/ConfigXOnlyInCore` · `ScopedCache` rejects a `module:` that is not the caller's engine (BE-17) · `i18n:check`: a module uses only its own namespace plus `core` and `design_system` · links are server-built props (CT-02): props objects build every URL with `context.urls.route` (engine key and route name as symbols, BE-04), cross-module links included; `have_resolvable_hrefs` (core matcher, TS-02) asserts that every `href`, `*Href`, and `nav[].path` in props was built by `Urls` for the request, so it resolves; ESLint `no-restricted-syntax` bans template literals and string concatenation that start with `/` followed by a locale or path segment in frontend code outside the page resolver, the formatters, and tests, so TypeScript never builds a URL (FE-18) · event names are constants in the publisher's public surface, so ARCH-09 checks their use; an event named by a string literal: review | enforced (URL-building selectors: verify when adopting; string event names: review) |
| ARCH-11 | spec: root `config/budgets.yml` has no `pages:` key · `errors:check` prefix ownership (CT-06) · contracts, locales, error codes, and permissions generated into each engine · ratchet counts per engine in `engines/<e>/config/ratchets.yml`; root `config/ratchets.yml` holds kernel and app counts and the cross-engine clone baseline only · check that the central fake upstream app holds no module paths (TS-03) · Gemfile loads engines by glob over `engines/*/*.gemspec` | enforced |
| ARCH-12 | `script/ci/growth` checks the growth budgets in `config/budgets.yml` → `growth:`: core files (`max_files` excludes `spec/` and `lib/generators/`) and public exports or constants, design_system public exports, each domain engine's public surface size (`growth.domain_engine.max_public_exports` and `max_public_constants`), files and pages per module · `script/ci/fan_in`: `max_dependents` applies to product modules (many dependents on a product module means extracting a domain engine); core and design_system are ignored, and domain engines are budgeted on public surface size instead of dependents · touch rate: scheduled `script/ci/touch_rate` against `growth.touch_rate.max`, enabled once there are at least three product modules not counting the examples (`growth.touch_rate.min_modules: 3`), opens an issue, a metric and not a merge gate · raising a budget needs an ADR (code owners on `config/budgets.yml`) · ratchet files have no CODEOWNERS entry; the required ratchet check passes a fall and needs an owner's approval for a rise | enforced (touch rate: scheduled metric) |
| ARCH-13 | exports and stored files go through Active Storage (BE-18) · nothing else written to local disk beyond request and job temp files: review | review |

### Backend

| Rule | Enforcement | Status |
| --- | --- | --- |
| BE-01 | `Rafelo/PageContextThroughFactory` · generator template (GEN-02) · the four-step action shape: review | enforced (action shape: review) |
| BE-02 | Pundit `verify_authorized` after every action · `gateway(klass)` refuses before any upstream call unless `pundit_policy_authorized?` (request spec: an action without `authorize` gets 403 and the upstream stub is never requested, also for a download) · policy specs · spec listing every action that skips authentication | enforced |
| BE-03 | each module's `config/permissions.yml` generates constants (under `app/public/`, so a module that declares the dependency can read another's) and TS, checked for staleness by `npm run permissions:check` · `Rafelo/NoPermissionLiterals` · `Rafelo/OwnPermissionPrefixes` · `PermissionSet` spec (wildcards, malformed grants such as `billing`, `billing:invoice`, `*:*`, and `Billing:Invoice:Read` match nothing, a required key that is not three lowercase parts raises, `reads_any?`, grants translated through `config/permission_mapping.yml`) · scheduled permission drift job when the upstream offers a grant catalog | enforced (drift: scheduled) |
| BE-04 | `Rafelo/CurrentAtTheEdge` · `Rafelo/EnvOnlyInConfig` · props specs build props from a `PageContext` and plain values · URLs come from `context.urls`, which records every path it builds; `have_resolvable_hrefs` asserts that every `href`, `*Href`, and `nav[].path` is one of them (TS-02) · `match_policy_capabilities` (TS-02): each capability's `allowed` equals its named policy method over a grant matrix · props spec: a top-level key outside `data`, `meta`, `query`, `pagination`, `can` raises (CT-01) · reading `params` or the session inside a props object: review | enforced (params and session: review) |
| BE-05 | `Rafelo/FaradayOnlyInUpstreamClient` · `Rafelo/NoTlsVerifyDisable` · client specs: retries only for `GET`/`HEAD` or with an idempotency key, failure mapping to catalog codes, one row per status of the BE-05 table (304, 409/412, 410, 413, 429 with `Retry-After`, other 3xx and 4xx) · retries for writes only to an upstream that declares `idempotency_keys: true` · persistent-connection spec: sequential calls open one connection · per-upstream breaker, bulkhead, and retry-budget specs: an open circuit answers `upstream.circuit_open` (503, retryable) · a gateway that passes `Authorization`, `traceparent`, `X-Request-Id`, `Idempotency-Key`, or `If-Match` makes the client raise (SEC-10) · a body over the upstream's `max_response_bytes` maps to `unexpected` (500, reported; SEC-14) | enforced (cops) · tested in kernel (persistent adapter's per-request timeouts: verify when adopting) · tested in kernel (resilience; breaker library behaviour, ADR-30: verify when adopting) |
| BE-06 | the core client refuses a gateway without an `upstream` declaration or with an undeclared name · gateway specs assert value objects are returned | tested in kernel (declaration) · review (value objects) |
| BE-07 | `ListQuery` spec on real `ActionController::Parameters`, never a plain hash: `per_page` clamped, sort and filter keys allow-listed, sort direction `asc` or `desc` (anything else: the default sort), a nested hash, an array on a single-valued filter, and a 10 kB value drop the filter, `filters` that is not a hash is dropped, a non-scalar, zero, or negative `page` or `per_page` becomes its default, a cursor that is not a string is dropped and a long one is bounded · props budget at the maximum page size (TS-02) | enforced |
| BE-08 | `Rafelo/EnvOnlyInConfig` (the built-in `Rails/EnvironmentVariableAccess` may cover the `ENV` half) · `Rafelo/ConfigXOnlyInCore` · `config/upstreams.yml` validated at boot · production secrets only in `config/credentials/production.yml.enc`, `config.require_master_key = true` · the Dockerfile's `assets:precompile` is a dummy boot (`.env.ci.production` sourced, the dummy credentials chosen by `SECRET_KEY_BASE_DUMMY` in `config/application.rb`) · subprocess specs: a production boot with `SECRET_KEY_BASE_DUMMY` outside the Rake tasks `assets:precompile` and `ci:production_routes` raises; a production boot without `RAILS_MASTER_KEY` exits 1 | enforced (Rake task introspection: verify when adopting) |
| BE-09 | `Rafelo/CurrentAtTheEdge`: `Current.` only in controllers, middleware, `LogPayload`, the error subscriber, and `Acme::Core::BaseJob` (at enqueue) · `Current` assigned in a `before_action` (BE-24 order spec) · responder spec: a `/th` error page raised after the around-callbacks unwound shows Thai text and both ids | enforced |
| BE-10 | review | review |
| BE-11 | spec after eager loading: every job class defined under `app/` and `engines/*/app/` inherits `Acme::Core::BaseJob`, which carries the request id and trace id through `serialize`/`deserialize`, never as arguments · job specs: a second run is harmless, side effects follow the commit · review | enforced (base class) · review (job bodies) |
| BE-12 | the core `throttle to:, within:, only:, name:` macro records `(action, name, limit)` and raises on a second limit with the same name on one action · it passes `prepend: true`, and the BE-24 order spec asserts every limit precedes the base callbacks · config spec: the test and production cache stores return an integer from `increment` (never `:null_store`) · body-size middleware spec: `/core/client_errors` and `/core/csp_reports` answer 413 before Rails parses · route-table spec fails when a non-GET action is neither throttled nor allow-listed · request spec for throttled sign-in; the test environment's cache store is `:memory_store` (`rate_limit` takes its store when the class loads), cleared by a global `before` hook (TS-01) | enforced |
| BE-13 | core request specs for the write flow against `engines/core/spec/dummy_engine`: `303` with flash on success, `303` with errors on validation failure and on conflict · core error responder spec · a `422` with one known and one unknown upstream field: both messages present (`errors.base` for the unknown one) and the audit outcome is `failure` · the write audit is recorded by the write path or, for a non-GET that raises, by the error responder: exactly one row per audited request (OPS-08 spec) · generator templates (GEN-02) run by GEN-04 · `example_orders` shows the flow in use · a hand-written action that renders from a write: review | tested in kernel |
| BE-14 | request spec that posts camelCase keys | enforced |
| BE-15 | concurrency spec in the `:concurrency` lane (TS-10): two simultaneous submits with one token make one upstream call; an upstream 503 then a retry with the same token succeeds when the upstream declares `idempotency_keys`; without it, a timeout records `unknown` and a resubmit makes no upstream call · a taken-over attempt's late outcome write updates no row (`attempt` fence) · staleness computed by PostgreSQL · the form token is refused before any claim when blank, badly signed, issued to another session, or older than the row retention (config spec: retention exceeds the absolute session lifetime, OPS-07) · a rejected claim (another viewer, a changed payload digest) makes no upstream call and answers a `303` with `errors.base` and a new token · `Idempotency-Key` is the server-side HMAC, never payload-derived · unique index on `core_idempotency_keys.token` · gateway spec asserts `Idempotency-Key`, and `If-Match` carrying the submitted version · conflict request spec · generated edit page test: the submit after a conflict redirect carries the new version and form token (read from props at submit time, not from `useForm` data) | enforced |
| BE-16 | `Rafelo/ConcurrencyOnlyInExecutor` · `upstream_calls_per_request` budget · client specs for the deadline (open, read, and write timeouts each capped by the time left; a trickling body aborted at the deadline through `on_data`; time left on the monotonic clock), the thread-safe counter · a `401` refreshes, then resends the call once (a `GET` and a write without an idempotency key), outside the retry and page budgets · a second `401` on the resent call revokes the row and answers `auth.expired` · executor spec: a fixed pool sized from config · development waits wrapped in `permit_concurrent_loads` | enforced (interlock wrap: verify when adopting) |
| BE-17 | `Rafelo/CacheOnlyThroughScopedCache` · `ScopedCache` spec: a scope and `module:` are required, the namespace includes the release or an explicit schema version · `rate_limit` (BE-12) writes to the cache store directly, a deliberate exemption from `ScopedCache` · review of scopes and invalidation comments · conditional-request spec: a validator is sent only from a `ScopedCache` entry, and a `304` serves its body | enforced (scopes and invalidation: review) |
| BE-18 | `Rafelo/SendStreamOnlyInDownloads` · request spec: downloading a finished export is a `303` to a short-lived signed URL, after a check that the record belongs to the viewer · a streamed download: the core download controller sets headers and the size limit (`downloads.max_bytes`) · download specs: an upstream `500` or an oversized `Content-Length` before the first byte gives the error page without `Content-Disposition`; an overflow after it aborts the stream and audits `failure` · a download over the per-process cap answers `upstream.unavailable` · export job spec: writes to Active Storage and a `core_exports` record, expires · `Acme::Core::Export` spec: a `Date` comes out as a Buddhist Era year in `th` (FE-20) | enforced (export dates: tested in kernel) |
| BE-19 | job specs: uses the session's token, its token provider re-reads the session row before every upstream call, stops on revocation and absolute expiry, not on idle expiry · a unit of work past `jobs.upstream_deadline_seconds` stops, never the request deadline · a stopped job leaves no `solid_queue_failed_executions` row (`discard_on`) · a job enqueued under `th` formats a Buddhist Era year · spec that viewer jobs never receive the service provider | enforced |
| BE-20 | in the test environment `UpstreamClient` raises when a transaction other than the test wrapper is open, so every spec that reaches a gateway checks the rule | enforced (transaction counting: verify when adopting) |
| BE-21 | config spec reading `config/deploy.yml`, `config/puma.rb`, `config/database.yml` (both database roles, OPS-08), `config/queue.yml`, `config/upstreams.yml`, the executor size, the download cap, and `config/budgets.yml` → `connections:` at the root level (`server_max_connections`, `budget`, `headroom`): per Puma process, pool (Rails 8.1 `max_connections` in `config/database.yml`, read through Active Record) ≥ Puma threads + executor size + download cap (+1 per polling thread if used); total connections = Σ over process kinds (count × pool) for Puma workers, the Solid Queue supervisor, its workers (threads from `config/queue.yml`), its dispatchers, and the scheduler when recurring tasks are configured, plus `headroom` for consoles and migrations, within `budget`, which stays below `server_max_connections`; proxy response timeout > request deadline > every call's read timeout; `sessions.refresh_timeout_seconds` > the read timeout of the upstream that issues the tokens (SEC-03) | enforced (Solid Queue async mode: verify when adopting) |
| BE-22 | `strong_migrations` (pinned by each template release) blocks unsafe operations, including non-concurrent index creation · `script/ci/deploy_preflight` fails when `config/deploy.yml` lists more than one host and `boot.limit` is not `1` (canary: two hosts without `boot`), and when it sets no `deploy_timeout` (canary: a `config/deploy.yml` without it) · expand/contract sequencing across releases, a migration that may outlast `deploy_timeout` run as its own step before the deploy, concurrent-index migrations safe to re-run: review | enforced (release sequencing, long migrations: review) |
| BE-23 | every file in `config/initializers/patches/` has a spec and a guard spec that fails when the patched gem's version changes · a patch outside that folder: review | enforced (location: review) |
| BE-24 | order spec pins the base controller's resolved callback chain, including every prepended `throttle` before the base callbacks, `assign_request_context` as a `before_action`, `allow_browser` with its `unless:` exemption, and `require_module_enabled` after `load_session` and before `require_viewer` | tested in kernel (callback introspection on the pinned Rails: verify when adopting) |
| BE-25 | a dark module (registry `flag:`): `require_module_enabled` renders the 404 error page and navigation leaves the module out while the flag is off (core request spec; ARCH-06) · flags reach the UI only as typed `can` keys with reason `disabled` (CT-01) · a client flag SDK is a new library (FE-12) · request specs for both states of a flag inside a module and server-side evaluation: review | tested in kernel (dark modules) · review (flags inside a module) |

### Session and security

| Rule | Enforcement | Status |
| --- | --- | --- |
| SEC-01 | request specs: cookie flags, the `__Host-` name in production, digest-only storage, sign-out order · production-config spec: the cookie deletion header carries `Secure` and `Path=/` | enforced |
| SEC-02 | auth spec asserts token values are absent from props and log output · `filter_parameters` spec · session model spec: `as_json` on a session with every token set carries none of their values and no cookie digest | enforced |
| SEC-03 | concurrency spec in the `:concurrency` lane: two threads refresh one session, one upstream refresh call · the claim is one conditional `UPDATE` on `refresh_version`/`refreshing_since`, with no transaction open across the refresh (BE-20 guard) · the winner's token write is a normal save, and a spec reads the raw columns after it and finds ciphertext · the losing request waits until `refreshing_since` is `NULL` and compares the access token (a new one is used, a revoked session answers `auth.expired`, the same one or a timeout fails retryable); a spec with two `401`s on a locally valid token makes one refresh call and keeps the session · staleness compared with PostgreSQL's `now()` · early-expiry margin spec | enforced (encryption of the post-claim write on the pinned Rails: verify when adopting) |
| SEC-04 | auth request specs for 401, 429, and 5xx refresh outcomes · after a successful refresh the call is resent once (BE-16) · mid-action specs for an Inertia `GET` and a write, each for a refresh `401` and for a second `401` on the resent call: the row is revoked, the cookie deleted, and the answer is a `303` to the locale's sign-in page · a dead session under `/th` lands on `/th/sign_in` | enforced |
| SEC-05 | request specs: `Cache-Control: no-store` (also on 403 and 503 error pages, set by a `before_action`), CSP directives (nonce for scripts and styles, no `'unsafe-inline'`, `connect-src 'self'`), and two requests of one session get different nonces · in development, Vite's injected scripts and styles get the request nonce (`vite_client_tag` and `vite_typescript_tag "application.tsx"` with `nonce: true`, `vite_react_refresh_tag` by itself; preload links carry a literal `nonce="true"` and are not asserted; the layout renders `<meta property="csp-nonce" nonce>` for Vite's client; no `'unsafe-inline'` in any environment, development included) · `createInertiaApp({ nonce })` gives the progress bar's style the nonce · the `:csrf` shared context turns forgery protection on, with a canary (`POST` without a token gets `422`, TS-07); the Playwright server runs with protection on · `/core/csp_reports` skips forgery protection, the only endpoint that does: a spec in the `:csrf` context accepts a report without a token; its spec also covers the allow-listed line, byte cap, and rate limit · CSP readiness: the Playwright smoke job runs under Report-Only and fails when `/core/csp_reports` received a report, and staging shows no new directive and origin pair for a stated period · `assetsInlineLimit: 0`, the bundle check fails on `url(data:` (canary), the smoke suite fails on a `securitypolicyviolation` event · no `?inline` imports: review · production-config spec: `Content-Security-Policy` and no `Content-Security-Policy-Report-Only` while the typed `csp.report_only` (default `false`) is absent, the reverse when it is `true` · the `406` page carries the CSP header and its `<style>` the header's nonce (FE-19) · Brakeman | enforced (`?inline` imports: review) |
| SEC-06 | boot guard spec | enforced |
| SEC-07 | Brakeman blocks every pull request · bundler-audit and `npm audit --audit-level=high` block every pull request that changes a lockfile · a daily scheduled job opens an issue with a fix deadline for new advisories · audit steps are guard files · `.gitignore` (`/.env*`, then only `!/.env.ci.production`) · `script/ci/deploy_preflight` fails on a tracked secret file; the allow-list is `.env.ci.production` and `config/credentials/dummy.key` (canaries: a tracked `.env.local`, a tracked `config/credentials/production.key`) · synthetic data only: review | enforced (synthetic data: review) |
| SEC-08 | session specs: rotation and `reset_session` on sign-in and sign-out, a second sign-in by the same viewer keeps the first session, idle expiry at both edges of the touch interval, absolute expiry, throttled `last_seen_at` · cookie-size spec for the largest form · batched purge job spec · index choice (none on the sliding idle expiry) and the `core_sessions` table's `fillfactor` 70, which keeps HOT updates possible: review | enforced (the effect of `fillfactor`: verify when adopting) |
| SEC-09 | request spec: an authenticated page carries `encryptHistory: true` · sign-out spec: `reset_session`, then a `303` whose following Inertia page carries `clearHistory: true` once | enforced |
| SEC-10 | spec with the allow-list of gateways that may use the service token, per named upstream · `UpstreamClient` raises when a gateway passes `Authorization` (BE-05) | enforced |
| SEC-11 | `Rafelo/ReturnToOnlyInValueObject`: `return_to` read from params only inside `ReturnTo` · `ReturnTo` spec with hostile inputs (`//host`, `https://host`, no leading slash, a locale that is not configured, `//` inside the path, `\`, dot and encoded-dot segments, control characters, checked raw and once decoded) and every configured locale prefix | enforced |
| SEC-12 | `script/ci/production_routes` walks the production route set in-process (`bin/rails ci:production_routes`), descending into mounted engines, as a dummy boot with the committed `.env.ci.production` and dummy credentials (dummy values; a setting without a value raises at boot by design, so those two files are the list of keys) and fails on a walked route that matches neither the committed `config/production_routes.yml` (the app's, core's, and the framework's routes; a guard file) nor the module routes derived from the registry, never from the route set under check; on a route it cannot classify (Rack app, `Proc`, stray redirect, multi-verb); on a listed route the walk did not find; and on an empty walk; it prints its counts and reads a recorded walk (`--routes FILE`) · canaries (TS-07): a development route outside `Rails.env.local?`, a mounted fake app, a stray redirect, a `via: [:get, :post]` route, a listed route missing from the walk, an empty walk | enforced |
| SEC-13 | production config spec for `force_ssl` and `config.hosts` (an unknown host gets `403`, `/up` still answers) · header specs (`frame-ancestors`, `base-uri`, `form-action`, `object-src`, `Permissions-Policy` from core's middleware, never `config.permissions_policy`, which sends `Feature-Policy` in Rails 8.1.4.1; also on an error page and a router `404`) · proxy body limit | enforced (proxy body limit: verify when adopting) |
| SEC-14 | `Rafelo/FaradayOnlyInUpstreamClient` · `Rafelo/NoTlsVerifyDisable` · client specs: no redirect followed, response size checked against the upstream's `max_response_bytes`, by `Content-Length` on the first chunk and the running total after (chunking fake: crossed in the third chunk, no fourth handed over), escaped path segments, one row per refused path class (a leading `/`, `//`, a scheme, `?`, `#`, `\`, and a control character raise; `..`, `.`, and an empty segment answer `404` with no request made), a kept base path | enforced |
| SEC-15 | session specs: grants re-fetched on refresh and when stale · an upstream `403` marks grants stale by bumping `grants_generation`, and a concurrency spec (TS-10) proves a re-fetch started before the mark does not clear it | enforced |
| SEC-16 | in the release pull request that bumps `VERSION` (WF-05), `bin/rails formats:dump` writes synthetic rows for every versioned format (idempotency outcomes, one job per class defined under `app/` and `engines/*/app/` through `serialize`, sessions) to `spec/fixtures/formats/v<VERSION>/` and prunes folders older than N-2, and that pull request commits the result; the release workflow fails while that folder is missing and commits nothing · the compatibility spec loads the previous tag's folder · readers of job arguments and idempotency outcomes accept the current and the previous format · session rows carry `format_version`; on an incompatible session format a release MAY revoke all sessions instead of reading the old one (it only forces sign-in, OPS-07) | enforced |

### Contracts

| Rule | Enforcement | Status |
| --- | --- | --- |
| CT-01 | `definePage` builds `can` as a strict object from the page's declared keys, and `meta` as an empty strict object by default · `contracts:check` · `match_page_schema` in request specs (offset and cursor pagination) · `tsc` · `trace` is an always-prop: a partial reload that omits it still carries the ids of its own response (CT-01 spec) · core raises when a props hash's top-level keys are not exactly `data`, `meta`, `query`, `pagination`, `can` (core request specs: a missing page key, an extra key, a shared key such as `auth`) · request specs on the inertia_rails settings: a first HTML visit renders the page in `<script data-page="app" type="application/json">` with the request nonce and no `data-page` attribute, a page without errors carries `errors: {}`, keys inside arrays arrive camelCase | enforced |
| CT-02 | page schemas (`null`, arrays of objects with `id`, ISO 8601, money as `{ minor, currency, exponent }` with the exponent from core's ISO 4217 table, ids as strings, URLs through `z.string().refine(isSafeUrl)`) · `match_page_schema` · `have_resolvable_hrefs` (core matcher, TS-02): every `href`, `*Href`, and `nav[].path` in props, `app.localeHrefs` included, is a path `Urls` built for the request, so it resolves · shared URLs typed with `appPathSchema` · `contracts:check` fails on an `id` or `*Id` property that is not a string (canary) · formatter test over IQD, LAK, MMK, and HUF reads `exponent`, never `Intl` · core request spec: `?page=2` marks exactly its own module `nav[].current` | enforced |
| CT-03 | `contracts:check`: per-engine JSON Schemas under `engines/<m>/config/contracts/` and `config/contracts/_shared.json` are current · Zod 4 output mode emits `additionalProperties: false`, and a canary proves an extra prop fails a request spec · shared props referenced with `$ref` · `contracts:generate` fails on a `pages/**/*.schema.ts` without `pageSchema` or whose top-level keys are not the envelope's (canaries) · generators delete outputs they no longer produce and `--check` fails on an output without a source (canary: the JSON Schema of a deleted page) · tsx scripts run with `--tsconfig tsconfig.tooling.json`; `aliases:check` fails on a `package.json` script that runs `tsx` without it (canary) | enforced (`$ref`/`$defs` output stability: verify when adopting) |
| CT-04 | `pages:check`: every page has a `.schema.ts` (the dummy engine under `engines/core/spec/` is left out, TS-01) · page template parses once · layouts parse `sharedPropsSchema` · ESLint: `usePage` from `@inertiajs/react` (named, aliased, or namespace import) reported everywhere except `app/frontend/layouts/**` and the page resolver (canaries) · `tsc` | enforced |
| CT-05 | PR title lint accepts `!`; marking a breaking change: review | review (PR title lint: enforced) |
| CT-06 | `errors:check`: kernel codes only in root `config/errors.yml`, codes prefixed `<module>.` only in that module's `config/errors.yml`, generated TS per engine current · `errors:check` validates each entry: code shape, integer `status` 400–599, non-empty `i18n_key`, boolean `retryable`, no other key; a code defined twice within one file, found through the YAML node tree (canaries) · spec: every raised code exists in a catalog · exceptions app specs (`show_exceptions: :all`): a router 404, a missing parameter, a forgery failure, and a raised `StandardError`, under `/th`, for HTML, Inertia, and JSON, assert the Thai message, both ids, `no-store`, and the CSP | enforced |
| CT-07 | core request specs against `engines/core/spec/dummy_engine` assert translated `errors` and page-level `flash` in every configured locale · write flow: the GET after the `303` carries the page-level `notice` and no `flash` prop, and the GET after that carries no flash · the strict envelope rejects a `flash` prop · a `422` with an unknown upstream field fills `errors.base` · generator templates (GEN-02) run by GEN-04 · the example engines show it in use | tested in kernel |
| CT-08 | `i18n:check`: per-engine i18next namespaces current, namespace ownership · `i18n-tasks missing` and `unused` · parity across configured locales, per plural category · `i18n:check`: one top-level key per locale file, matching its file name; no duplicate key within a mapping (YAML node tree); parity fails on a `nil` or blank value (canaries) · `i18n:generate` deletes a dropped locale's JSON, and `--check` fails on it · `i18n:generate` transforms `%{x}` to `{{x}}` and plural hashes to `_one`/`_other` keys, and fails on `{{`, `$t(`, `%<x>s` (canaries) · `raise_on_missing_translations = :strict` in development and test, and a spec resolves every catalog `i18n_key` and field-error code with `fallback: false` · resolver test: a module page first rendered in `en` shows `th` text after a visit in `th` · the release workflow (WF-05) fails while any `[<locale>]` placeholder remains | enforced |
| CT-09 | `docs:check`: generated tables current; rule and ADR IDs cited in the docs, `AGENTS.md`, and AI instruction files exist and are not superseded; named repository paths exist, extensionless `script/ci/*` included: every path in AI instruction files, and in topic files a path under `engines/<name>/` only for the kernel engines (`core`, `design_system`), since other engine names there are illustrative; placeholders, globs, and paths git ignores (`git check-ignore`) are exempt (canaries: a missing extensionless `script/ci/` path and a missing kernel path fail; a git-ignored path and an illustrative engine path in a topic file pass) · definitions parsed only from headings outside fenced code; rule heading format and ADR `Status:` line checked; fails on an ID defined twice, a rule without exactly one matrix row, a row for an undefined ID, a status cell outside the four statuses, and zero definitions (canaries) | enforced |
| CT-10 | strict schemas: a prop outside the schema fails its request spec; strict default `meta` · a field inside the schema that the viewer should not see: review | enforced + review |
| CT-11 | `pages:check` cross-checks optional schema keys against deferred props and fails on a multi-word deferred, optional, merge, or once prop name, or `only`/`except` key (canaries) | enforced (deferred-prop cross-check: verify when adopting) |
| CT-12 | config spec: `config.version` calls `Acme::Core::AssetVersion`, never `ViteRuby.digest` directly · threaded `AssetVersion` spec: `reset!`, stub `ViteRuby.digest` with a slow fake that raises when entered twice at once, assert one computation (fails without the lock) · spec helpers send `X-Inertia-Version` on GET visits · request spec with a stale version: a `POST` is processed and answers `303`, and the `GET` after it gets `409` with `X-Inertia-Location` · Kamal asset bridging keeps old chunks during a deploy: `asset_path` is `/rails/public/vite` (OPS-06 preflight) | enforced |
| CT-13 | `shared_props_bytes` in `config/budgets.yml`, asserted by one request spec for a viewer whose grants show every registered module | enforced |
| ADR-07 (camelCase boundary) | inertia_rails `prop_transformer = ->(props:) { props.deep_transform_keys { _1.to_s.camelize(:lower) } }` (CT-01), which also converts hashes inside arrays · incoming keys through `params.deep_transform_keys!(&:underscore)` (BE-14) · schema validation catches misses | enforced |

### Frontend

| Rule | Enforcement | Status |
| --- | --- | --- |
| FE-01 | dependency-cruiser `pages-render-screens` and `components-stay-presentational` (canaries) · `pages:check` | enforced |
| FE-02 | dependency-cruiser `only-resolver-picks-layouts` (canary) · generated engine rules: no engine imports `app/` · every layout returns the shared `LayoutRoot` (layout test: an app → auth → app sequence keeps its node) | enforced |
| FE-03 | ESLint `no-restricted-imports` for client routers, data caches, and stores · in design_system and its icon map, `designSystemInertia`: `Link` and `Deferred` from `@inertiajs/react`, nothing else from `@inertiajs/` (canary: `router`, `usePage`, a namespace import, and `@inertiajs/core` in a design_system component) | enforced |
| FE-04 | ESLint: `useState`, `useReducer`, `useActionState`, and `useOptimistic` only in `use_domain_reducer.ts`, `use_ui_state.ts`, and design_system widgets, as named imports (`no-restricted-imports`) and as `React.useState` and the like through a namespace or default import of `react` (`no-restricted-properties`) · `tsc` (`useUiState` rejects primitives) · wrapper tests for the development plain-data assertion and deep freeze · core's `assertPlain` test: one row per kind OOP-05 refuses, the path in the message, a cycle ends | enforced |
| FE-05 | ESLint: `../` imports, `unicorn/filename-case`, `perfectionist/sort-imports`, `no-restricted-syntax` `typeExports` for exported types in `.tsx` files only (canary: one in a `.tsx` file, the same in a `.ts` file not reported) · TypeScript and Vite aliases generated from the engine list (`npm run aliases:check`) | enforced (type-export selector: verify when adopting) |
| FE-06 | `better-tailwindcss/no-unknown-classes` (4.10.0; reports "Unknown class detected") with `entryPoint` set to the v4 CSS entry that imports the design_system theme by relative path (canary: a misspelled class) · `prettier-plugin-tailwindcss` with `tailwindStylesheet` on the same entry (`format:check` fails when it cannot resolve the theme) · `@apply` only in design_system CSS (`script/ci/apply_check`) · design_system test: each custom non-color theme token merged with a semantic color of the same prefix keeps both (one `extendTailwindMerge` instance) · design_system components build variants with design_system's own `tv` (`@design_system/internal/tailwind`) | enforced (design_system's own `tv`: review) |
| FE-07 | ESLint `react/forbid-elements` outside `engines/design_system` (eslint-plugin-react 7.37.5 reports `button`, `input`, `select`, `textarea`; canary at an engine page path) | enforced |
| FE-08 | ESLint: `echarts`, `@tanstack/react-table`, `react-aria-components`, `@internationalized/date`, `tailwind-variants`, `tailwind-merge` only inside `engines/design_system` · wrapper tests (`AriaComponent` registered, aria on with the translated description, container never `aria-hidden`, "show as table" toggle) · browser test: `role="img"` and a translated `aria-label` on a `th` chart · test that the chart and table wrappers load through `React.lazy` · `th` chart axis test (FE-20) · wrapper test: `init` once, `setOption` with `notMerge: true`, every theme color non-empty and parseable · oklch-to-hex converter unit test against known Tailwind values · DataTable tests: `getRowId` row test ids, `aria-sort` from the `sort` prop | enforced (within design_system: review) |
| FE-09 | `tsc` (required `testId` prop) · design_system tests | enforced |
| FE-10 | `react-hooks` recommended rules · `@eslint-community/eslint-comments/require-description` · React Compiler via `@rolldown/plugin-babel` + `reactCompilerPreset` · Vitest compiles with the same `reactPlugins()`, proven by a render-count test · ratchets on `eslint-disable` and `"use no memo"`; design_system's count starts at one, the `react-hooks/incompatible-library` disable on `useReactTable` | enforced |
| FE-11 | ESLint `react/jsx-no-literals` in feature folders · i18n checks · formatting only in `@design_system/formatters`: ESLint bans `Intl.NumberFormat`, `Intl.RelativeTimeFormat`, and `toFixed` (the usual hand-formatting of money) outside it, alongside FE-20's date bans · review of typography | enforced (formatting APIs) · verify when adopting (`jsx-no-literals` options) · review (typography) |
| FE-12 | ESLint `no-restricted-imports` for styled kits, CSS-in-JS, data caches, and stores · a new dependency needs an issue, and a new framework-level library an ADR (WF-06): review | enforced (new library approval: review) |
| FE-13 | layout tests: every layout (`app`, `auth`, `bare`) renders the skip link (the first Tab focuses it; activating it focuses `<main>`) and `<main>`, and the one page announcer (`sr-only`) lives in the shared layout root, present from the first render, the same node across app → auth → app · announcement test: the first page of a full load is neither announced nor focused; after a visit the announcer holds the first `h1` in `<main>` while `document.title` still holds the old title; announced on `navigate` for invoice 1 → 2, back, and a create → show redirect, not for a filter · flash status test: a page with a notice, then one without, then Back: the container is empty after both (CT-07) · `Pagination` test: a `<nav>` with a translated label and a polite status ("Page 2 of 5") present from the first render, the status text after a page change · focus after a failed submit lands on the first invalid field or the error summary (design-system form test, each generated form's component test) · Playwright check in TS-08 | enforced |
| FE-14 | layout test: a shell widget reads `th-TH-u-ca-buddhist` when `app.locale` is `th` · `I18nProvider` and formatter tests per configured locale, with explicit calendars · time zone tests · date field test submits Gregorian ISO | enforced |
| FE-15 | resolver test: a throwing page renders the error state (`role="alert"`, focus on its title: `document.activeElement`) with the ids from `trace` and reports it · reset test: invoice 1 crashes, a visit to invoice 2 renders invoice 2 (reset key `page.url`) · retry clears the error and renders the page again · resolver identity test: one name resolved twice returns the same component · a throwing shell renders the root boundary's error state and reports it · entrypoint test: an `unhandledrejection` and a `window` `error` event each send one report; a non-`Error` reason sends the fixed message, never the reason (OPS-03) | enforced |
| FE-16 | bundle budgets from Vite's manifest, following `imports` recursively and never `dynamicImports`: the entry (`js_entry_gzip_kb`), each page (its own chunk plus the static imports the entry does not load, `js_page_chunk_gzip_kb`), the smallest page's initial bytes (`js_initial_gzip_kb`), and each lazy chunk (`js_lazy_chunk_gzip_kb`) (canaries: a page over budget through its static imports, a lazy chunk over budget) · lazy wrapper test · `Pagination` test: focus stays on a control after moving to the last page | enforced |
| FE-17 | ESLint: `lucide-react` only in `@design_system/icon` · registry icon spec | enforced |
| FE-18 | ESLint `react/no-danger` · every URL in props validated by `z.string().refine(isSafeUrl)` in its page schema · `isSafeUrl` and `appPathSchema` tests read one shared fixture of hostile inputs by path, `spec/fixtures/hostile_urls.json`, shipped with the kernel (`javascript:`, `data:`, `//host`, `/\host`, a tab, a control character, surrounding whitespace) · TypeScript never builds URLs (ARCH-10's ESLint rule); links are server-built props (CT-02), proven by `have_resolvable_hrefs` · Brakeman | enforced |
| FE-19 | `allow_browser versions: :modern, block: :render_unsupported_browser, unless: :browser_check_exempt?` in the base controller · request spec with an old user agent: a page gets `406` from core's `unsupported_browser` template (`Cache-Control: no-store`, which `render_unsupported_browser` sets itself; the CSP header's `style-src` nonce equals the `<style>` element's, no `<script>`, no `style` attribute; under `/th`, Thai text and `lang="th"`), `/core/client_errors`, `/core/csp_reports`, and `/core/ready` answer normally | enforced |
| FE-20 | ESLint: `Intl.DateTimeFormat`, `toLocaleString`, `toLocaleDateString`, and `toLocaleTimeString` only in `@design_system/formatters`; `getFullYear`, `getUTCFullYear`, `getMonth`, and `getDate` banned in presentation code (pages, screens, containers, components, hooks, layouts) and everywhere else outside the formatters, `domain/`, and `forms/` (their tests included), which may compute with dates but never format them (OOP-04); `@internationalized/date` only in design_system (FE-08) · `Rafelo/DateFormatterOnly`: `strftime`, `I18n.l` and `l(`, `to_fs`, and `to_formatted_s` only in `Acme::Core::DateFormatter` (a cop has no types, so it flags the calls, not dates) · exports through `Acme::Core::Export`, whose spec feeds a `Date` and asserts a Buddhist Era year in `th` · tests, the real guard: a `th` chart shows 2569; a `th` date field typed 2569 submits 2026-…; typed 2026 is refused; a `th` export contains 2569 · `DateFormatter` spec matches ICU's +543 rule · year arithmetic that no banned API sees, and `.to_s`, `.year`, or plain interpolation of a date in flash code: review | enforced (formatting APIs) · tested in kernel (exports) · review (year arithmetic, flash interpolation) |
| FE-21 | CI concatenates and sorts design_system's declaration output from `tsc -b`, leaving out `internal/**` and `**/*.test.d.ts`, into `engines/design_system/api.d.ts` and fails when it differs from the committed file · an unchanged file narrows the run to design_system's tests plus the Vitest component tests of the affected modules, skipping RSpec and Playwright; a changed file runs everything · visual regression on every design_system change (TS-11) · design_system export budget (ARCH-12) · a behaviour change behind an unchanged API: review (see `12_hardening.md`) | enforced (behaviour change behind an unchanged API: review) |

### Object-oriented domain

| Rule | Enforcement | Status |
| --- | --- | --- |
| OOP-01 | ESLint `no-restricted-syntax` `classComponents`: a class extending `Component` or `PureComponent` only in design_system's `error_boundary/error_boundary.tsx` (canary: one outside it reported, that file not) | enforced |
| OOP-02 | review | review |
| OOP-03 | `@typescript-eslint/prefer-readonly` · `throw DomainError` only for invariants, `issues()` for input: review · an invariant never asks the runtime (`Intl.supportedValuesOf`, the browser's ICU data, the clock): review | review (`prefer-readonly`: enforced) |
| OOP-04 | dependency-cruiser `domain-is-framework-free` (canary): no React, Inertia, i18next, Tailwind helpers, or `engines/design_system` | enforced |
| OOP-05 | both state wrappers assert plain data (core's `assertPlain`: one row per refused kind, the path in the message) and deep-freeze it in development · hook tests apply `assertPlain` to the view-model, never to its dispatchers · props, context values, and form data: review | tested in kernel · review |
| OOP-06 | review | review |
| OOP-07 | both state wrappers deep-freeze state in development (FE-04), so a reducer that edits state in place throws in development and in hook tests · delegation to domain methods: review | tested in kernel (freeze) · review (delegation) |
| OOP-08 | typed `can` (CT-01) · review | review |
| OOP-09 | review | review |
| OOP-10 | each engine's `<engine>:node` Vitest project runs every `*.test.ts` outside `hooks/`, the `domain/` and `forms/` tests included, in the `node` environment (the `<engine>` project runs `*.test.tsx` and `hooks/**/*.test.ts` in jsdom; the app's `app` and `app:node` split the same way) · a round-trip test `fromPlain(x.toPlain())` for every boundary class: review | verify when adopting (round-trip coverage: review) |

### Testing

| Rule | Enforcement | Status |
| --- | --- | --- |
| TS-01 | review | review |
| TS-02 | the `be_within_props_budget` matcher fails unless `pagination.perPage` equals the `ListQuery` maximum and the list holds that many items · `have_resolvable_hrefs` (core matcher): every `href`, `*Href`, and `nav[].path` in props is a path `Urls` built for the request · each matcher records the page key it checked in `tmp/page_matchers/` (`bin/ci` empties it before RSpec); after RSpec, `pages:check --matchers` fails when a page of a covered engine, or of the app, has no recorded call of `match_page_schema`, `within_budgets`, `be_within_props_budget`, `have_resolvable_hrefs`, and (with `can` keys) `match_policy_capabilities`; it never searches spec text (canary: the matchers named only in a comment); a page whose `definePage` takes `paginated: false` (schema `pagination: z.null()`) is exempt from the maximum-page-size rule · `within_budgets` counts only inside its block and raises without one; SQL as OPS-01 counts it (canary: over budget inside the block; setup outside it and a query-cache hit not counted) · `be_within_props_budget` canary: one byte over at the maximum page size · `match_page_schema` raises on an empty, `.`, or `..` key segment and lists each failing JSON pointer · Prosopite raises on N+1 (canary) · page overrides only in `engines/<m>/config/budgets.yml`, their count ratcheted | enforced |
| TS-03 | `WebMock.disable_net_connect!` · one fake Rack app per named upstream, fixtures per engine · check that the central fake app holds no module paths · scheduled drift job per upstream | enforced |
| TS-04 | ESLint `no-restricted-syntax` in the root and engine `e2e/` folders and in test files, by regex over member and bare calls: no Testing Library text query in any variant (`get`/`query`/`find`, `All`; `Text`, `LabelText`, `PlaceholderText`, `DisplayValue`, `Title`, `AltText`), no Playwright `getByText`/`getByLabel`/`getByPlaceholder`/`getByAltText`/`getByTitle`, no `locator` or `querySelector`; `*ByRole` only with a `name` from the i18n helper · canaries prove each selector at real test paths (TS-07) | enforced |
| TS-05 | `Rafelo/SkipNeedsIssue` for RSpec and the same restriction in ESLint for Vitest and Playwright (the local rule `rafelo/skip-needs-issue` in `script/ci/eslint/rafelo.mjs`, registered in the test-file blocks: `no-restricted-syntax` cannot read the comment on the line): every skip form TS-05 lists carries `#<number>` or an issue URL on the same line · `prosopite: false` and `Prosopite.pause` outside `spec/enforcement/` are skip forms · one canary per form · skip count ratcheted · a guard spec fails without its guard, parsers of untrusted input have one row per refused class, absence assertions check each forbidden value alone over the whole output and log lines' keys against the OPS-01 allow-list: review | enforced (guard-spec quality: review) |
| TS-06 | `script/ci/generator_smoke` on pull requests touching generator templates, core contract helpers, registry code, or routing · nightly | enforced |
| TS-07 | `script/ci/enforcement_canaries`, which first lists rule names from their sources (dependency-cruiser, `Rafelo/*` cops, ESLint `--print-config` with the local `rafelo/*` rules, `script/ci/*`) and fails on a name without a fixture · a canary passes only on the tool's findings exit status (ESLint and RuboCop 1, never 2) and machine-readable output that names the expected rule; a crash, a configuration or parse error, an ignored file, and a run that inspected no file fail it (canaries for each) · canaries run the repository's own configuration at real paths (throwaway engines under `engines/`, removed in an `EXIT` trap), never a copied rule; every graph canary has a legal counterpart that must not be reported · every `script/ci/` check and generator or check script takes `--root DIR`, prints its count, and fails on an empty root (canary per check) | enforced |
| TS-08 | Playwright smoke with `@axe-core/playwright` | enforced |
| TS-09 | `parallel_tests` with per-process databases (`TEST_ENV_NUMBER`) · `timeout-minutes` on every CI job that runs steps (`script/ci/workflow_policy`, WF-07) · `boot_seconds` budget measured by `bin/rails runner nil` · bootsnap on | enforced |
| TS-10 | a CI lane runs `:concurrency` specs serially, non-transactional with truncation, without retries · tagging a new concurrency spec, and each spec forcing its race (a barrier, the first thread held inside the critical section by a latch): review | enforced (tagging, forced interleaving: review) |
| TS-11 | Playwright screenshots of the design_system component catalog, an app page drawn only in development and test with a schema like any page, in the `design_system` Playwright project (Chromium only), on every design_system change · a person approves baseline updates · contrast only through axe's `color-contrast` rule on the catalog page (axe-core 4.14.0 parses `oklch()`); no test keeps its own color table: review | enforced (own color tables: review) |

### Generators

| Rule | Enforcement | Status |
| --- | --- | --- |
| GEN-01 | GEN-04 · generator spec: reserved names (`core`, `design_system`, `app`, `engines`, the `example_` prefix, locale-shaped keys, app route names, kernel error-code prefixes) are refused; the new `package.yml` declares core and design_system with strict dependency and privacy enforcement · the engine template's initializer appends its `db/migrate` path to the app's migration paths, so migrations stay in `engines/<e>/db/migrate`, where `Rafelo/EngineTablePrefix` reads the engine from the file path | enforced (migration-path initializer: verify when adopting) |
| GEN-02 | GEN-04 · generator spec: an uncountable resource and an existing resource are refused; the first `index` page adds the engine's `root` route | enforced |
| GEN-03 | GEN-04 · templates read the namespace, locale list, and envelope from their sources: review | enforced (templates reading their sources: review) |
| GEN-04 | `script/ci/generator_smoke` in a CI job of its own whose `if:` declares the skip (sets `BUNDLE_FROZEN=false` itself, like the production image build, OPS-06; refuses a dirty or untracked tree and restores the tree in an `EXIT` trap) on triggering pull requests and nightly | enforced |
| GEN-05 | GEN-04 runs `rafelo:domain` and checks the new domain engine | enforced |
| GEN-06 | GEN-04 runs `rafelo:rename_module` and `rafelo:move_page` · request spec: old paths redirect through `legacy_paths`, each old prefix mapped to its path under the module (`/billing/refunds/5` to `/payments/refunds/5`), permission prefixes unchanged | enforced |
| GEN-07 | the template's CI adopts the commit under test (`git archive HEAD`, `rails new` under a two-word name such as `smoke_shop`, `bin/setup --skip-server`, `bin/ci`) and fails on any `acme` left in a tracked path or file, in any letter case; it also adopts release N-1, runs `bin/kernel_update` to N, and runs `bin/ci` · template specs: each reserved app name (`Core`, `DesignSystem`, `Rafelo`, `Engines`, `App`, `ExampleOrders`, `ExampleCustomers`, an existing constant) is refused before anything is written · the application template ends with an initial commit · `bin/kernel_update` updates core, the generators, `script/ci`, `bin/check`, `bin/kernel_update`, `spec/fixtures/hostile_urls.json`, and the guard configurations by default, and design_system only per folder on request (`--include design_system/<folder>`) · adoption writes `KERNEL_VERSION` | tested in kernel |
| GEN-08 | dependency-cruiser `nothing-depends-on-example-engines` · `script/ci/engine_graph` refuses an `example_*` dependency outside `example_*` · canary · the template's CI deletes both example engines and runs `bin/ci` | enforced (removal: tested in kernel) |
| GEN-09 | generator spec per post-write step that GEN-09 lists, in its order: an injected failure leaves a clean `git status` and names the step | enforced |

### Workflow

| Rule | Enforcement | Status |
| --- | --- | --- |
| WF-01 | issue template (outcome, acceptance checks, out of scope) | review |
| WF-02 | pull request template · required status checks | review |
| WF-03 | branch protection as a committed ruleset export, with scheduled `script/ci/repo_rules` drift detection (read-only token; canary: a payload missing a required check) · `ci-ok` aggregator (`if: always()`, each result `success` or a declared skip; `script/ci/workflow_policy` fails on a job missing from its `needs:`, canary) · the only required check names are `ci-ok`, `title`, `ratchet`, and `guard_approval` (the last three are the jobs of `.github/workflows/pull_request.yml`: title lint, ratchet check, guard approval), which runs on `pull_request` (types including `edited`), `pull_request_review` (`submitted`, `dismissed`), and `merge_group`, never on `push`; on `merge_group` the title lint and `guard_approval` pass with a log line · PR title lint (POSIX regex) · required status checks · merge queue: CI runs on `merge_group`, affected engines computed against the merge base · CI also runs on `push` to `main`, against the push's `before` commit (WF-05) · ratchet files: the required ratchet check passes a fall and needs an owner's approval for a rise (GitHub API) · `ratchet` and `guard_approval` read reviews with `pull-requests: read`, or a recorded list (`--reviews FILE`) in their canaries · where the GitHub plan offers no required merge queue or code-owner review: "require branches to be up to date" plus the four required checks, and `script/ci/guard_approval` fails when a guard file changed without an approving review from a listed owner (GitHub API) · where the plan offers no branch protection for private repositories: required CI status where the platform offers it, otherwise convention plus `script/ci/guard_approval` | enforced (plan features: verify when adopting; without branch protection: convention) |
| WF-04 | review-gate issue template | review |
| WF-05 | `VERSION` holds the release being prepared, strictly `MAJOR.MINOR.PATCH`; only the release pull request sets it, together with the `bin/rails formats:dump` output (SEC-16) · CI fails a pull request that changes `VERSION` unless it has that format, `v<VERSION>` does not exist, and it is higher than the highest `v*` tag (`script/ci/release --check`, canaries) · the release workflow starts from `workflow_run` of CI and acts only on a successful run of a `push` to `main` in this repository; it checks out that run's `head_sha` with `persist-credentials: false`; `script/ci/release`: a Release for `v<VERSION>` exists → a log line; the tag exists without a Release → it creates the Release and never moves the tag; otherwise it fails on a bad format, a version not above the highest `v*` tag, a remaining locale placeholder, or a missing `spec/fixtures/formats/v<VERSION>/`, then creates the tag and the Release in one Releases API call; it commits nothing · the tag ruleset on `refs/tags/v*` is exported to `.github/rulesets/release_tags.json` and compared by `script/ci/repo_rules` | enforced (tag ruleset bypass actor, releasing a commit that changes `.github/workflows/`: verify when adopting) |
| WF-06 | `.npmrc` `save-exact=true` · `script/ci/pins`: every `dependencies`, `devDependencies`, `optionalDependencies`, and `overrides` value in `package.json` is one exact version (a range, a dist-tag, a URL or git reference, `file:`, and an `npm:` alias fail), the `Gemfile` and every engine gemspec are read through Bundler (every non-path gem pinned in the `Gemfile`, a `git:`/`github:` gem with a full-SHA `ref:`, a gemspec depends only on engines and `Gemfile`-pinned gems and states no constraint), Renovate `packageRules` peer groups present, `mise.toml`'s Ruby, `.ruby-version`, the `Dockerfile`'s `ARG RUBY_VERSION`, and the Dev Container image tag agree, every Node and npm pin (`packageManager`, `engines`, `devEngines` with `onFail: "error"`, the `Dockerfile`) equals `mise.toml`'s, and `devcontainer.json` names the digest in `.devcontainer/image_digest` (canaries: a `^` range, a dist-tag, an `npm:` alias, a gem on a git branch, a gemspec with its own constraint) · `npm ci` · `BUNDLE_FROZEN=true` · lockfile-only lane · `docs:check` generates the held-back table from Renovate rules | enforced |
| WF-07 | `script/ci/actions_pinned` parses every workflow (`*.yml`, `*.yaml`) and composite action as YAML: step- and job-level `uses:` pinned to a full commit SHA with a version comment, a `docker://` image by `@sha256:` digest (canaries, one per form) · `script/ci/workflow_policy`: top-level `permissions` exactly `contents: read`, job permissions a mapping of known scopes, `write` only where its allow-list names the job and scope, `timeout-minutes` on every job that runs steps, `ci-ok`'s `needs:` complete, no pull request code checked out in a `pull_request_target` or `workflow_run` workflow except the release checkout guarded by its `if:` (canaries: a missing top-level block, a top-level `contents: write`, `write-all` on a job, a `write` scope outside the allow-list, a job without `timeout-minutes`, a `pull_request_target` checkout of the head SHA, the release checkout without the `push` condition) · Renovate config review | enforced (Renovate config: review) |

### Operations

| Rule | Enforcement | Status |
| --- | --- | --- |
| OPS-01 | log payload spec: each JSON line's keys, and each metric's tags (OPS-04), compared with the allow-list; the viewer id is a keyed HMAC, neither the raw id nor its bare SHA-256 · core's one SQL subscriber, shared with the budget matcher (TS-02), skips `SCHEMA`, `TRANSACTION`, and cached events (spec: one query twice under the query cache inside a transaction counts 1) · Lograge on in every environment with `keep_original_rails_log = false` (log spec: a token-like parameter and a query string reach no output) · `log_arguments?` false for every job class after eager loading | enforced |
| OPS-02 | request spec: a valid incoming `traceparent` keeps its trace id in logs and upstream calls, each call with a new parent id and only the sampled bit · hostile headers (uppercase hex, version `ff`, all-zero trace id, all-zero parent id, a short field, a trailing field on version `00`) each start a new trace and appear in no log line · a request without a valid `traceparent`, a throttled one included, shows one trace id in its error page and its log line: core's Rack middleware parses `traceparent` or starts a trace before the throttle and stores the trace id in the request env, where `Current`, the error responder, the exceptions app, and the log payload read it · job spec: a job carries the request's trace id (BE-11) | enforced |
| OPS-03 | client error endpoint spec: CSRF, rate limit (an IP limit and a session limit with distinct names; requests from fresh sessions on one IP still hit the IP cap), size limit (a Rack middleware, before Rails parses), the path kept without its query string, request id and trace id kept only in their formats, a forged `release` stored as `unknown` · scrubber spec: one row per class (`Bearer`, JWT, email, a 32+ base64url run, in the message, stack, path, and page name) and one per cut (message 1,000, stack 4,000) · reporter tests: token read from the `XSRF-TOKEN` cookie at send time, a non-ok response is reported once, a 50 KB message gives a body under the endpoint's cap, `keepalive: true`, a `window` `error` event sends one report, a non-`Error` rejection sends the fixed message without a stack · browser test: a report sent after sign-in is accepted | enforced |
| OPS-04 | review of dashboards and alerts (connection-pool waits, dead-tuple ratio, circuit-breaker state and open count per upstream) | review |
| OPS-05 | specs: `/up` and `/core/ready` make no upstream call (WebMock); `/core/ready` fails when PostgreSQL is unavailable | enforced |
| OPS-06 | `script/ci/deploy_preflight` (`bin/ci` step 14, and the Kamal hook `.kamal/hooks/pre-deploy` before every deploy): every `.env.ci.production` key is in `config/deploy.yml`'s `env.clear`, the app's only `env.secret` is `RAILS_MASTER_KEY` and neither `SECRET_KEY_BASE` nor `SECRET_KEY_BASE_DUMMY` appears, the final stage's effective `USER` is not root, no tracked secret file, more than one host needs `boot.limit: 1`, `deploy_timeout` is set (canaries, TS-07) · before a deploy, where the production key is available, the production and dummy credentials have the same key paths (values never printed; skipped in CI, which never holds the key) · PR image build after `rafelo:module` on Dockerfile, `.dockerignore`, `Gemfile`, gemspec, lockfile, `.env.ci.production`, and dummy credentials changes, and nightly · review of the deploy profile · `deploy_preflight` also fails unless `config/deploy.yml`'s `asset_path` is the Vite output directory, `/rails/public/vite` (canary: the generated `/rails/public/assets`) | enforced (preflight, image build) · review (deploy profile) |
| OPS-07 | scheduled restore drill of point-in-time recovery, which asserts `core_sessions` is empty after the restore · batched purge and partition-drop job specs | review (drill) · enforced (job specs) |
| OPS-08 | audit event specs (`core_audit_events`, partitioned by month) · one recorder, every outcome: a core request spec drives success, `422`, conflict, `403`, an upstream `503`, and a raise in a callback and asserts exactly one row each; none for the session-less endpoints and for a `GET` that fails · IP truncation helper spec: IPv4 /24, IPv6 /48, IPv4-mapped through `native`, `nil` when unparsable · user-agent family helper spec: an unknown, empty, and oversized header map to `other` · spec proves the database trigger rejects `UPDATE` and `DELETE` on audit rows · two database roles: a migration role owns the tables, and the runtime role has only `INSERT` and `SELECT` on audit tables, so the application's own role cannot disable the trigger (BE-21's spec reads both from `database.yml`) · a DEFAULT partition catches rows that match no monthly partition and an alert fires instead of the insert failing · upcoming partitions are ensured on boot in development and test and by the scheduled job in production · partition retention job spec · audit partitions are excluded from `structure.sql` (structure dump flags `--exclude-table=core_audit_events_*`) · what the migration role does to audit rows: review | enforced (trigger on every partition with the pinned PostgreSQL, structure dump flags: verify when adopting; what the migration role does to audit rows: review) |
| OPS-09 | a workflow on changes under `.devcontainer/**` other than `.devcontainer/image_digest`, which it writes itself, builds the Dev Container image and pushes it to the registry by digest; the digest lives only in `.devcontainer/image_digest`: a first CI job outputs it and every other `ci.yml` job except the production image build runs in `container: ${{ needs.image.outputs.ref }}`, so workflow YAML never contains it; `devcontainer.json` references the same digest; the digest file is a global input of `script/ci/affected` · Ruby pinned by the image tag and digest, Node and npm by `mise.toml`; `script/ci/pins` asserts that `mise.toml`'s Ruby, `.ruby-version` (read by the Gemfile through `ruby file:`), the production Dockerfile's `ARG RUBY_VERSION`, and the image tag agree, and that `devcontainer.json` names the digest in `.devcontainer/image_digest` · PostgreSQL image pinned by version and digest · `.gitattributes` forces `eol=lf` · Vite listens on 0.0.0.0 inside the container | enforced (vite_ruby host option: verify when adopting) |

## Custom cops

Boundaries in Ruby are checked by custom RuboCop cops, and in TypeScript by
ESLint rules. A cop reads the syntax tree, so comments, strings, and formatting
cannot fool it the way they fool a text search. The cops live in
`script/ci/cops/` (a guard file), each has a canary (TS-07), and each message
names the rule ID and the fix.

| Cop | Flags | Allowed only in | Rule |
| --- | --- | --- | --- |
| `Rafelo/FaradayOnlyInUpstreamClient` | `Faraday` | `Acme::Core::UpstreamClient` | ARCH-01, ARCH-02, BE-05, SEC-14 |
| `Rafelo/NoTlsVerifyDisable` | `verify: false`, `VERIFY_NONE` | nowhere | BE-05, SEC-14 |
| `Rafelo/EnvOnlyInConfig` | `ENV[...]`, `ENV.fetch`, `Rails.application.credentials` | `config/` | ARCH-01, BE-04, BE-08 |
| `Rafelo/CurrentAtTheEdge` | `Current.` | controllers, middleware, `Acme::Core::LogPayload` (OPS-01), the `Rails.error` subscriber (OPS-03), `Acme::Core::BaseJob` at enqueue (BE-11) | BE-04, BE-09 |
| `Rafelo/CacheOnlyThroughScopedCache` | `Rails.cache` | `Acme::Core::ScopedCache` (`rate_limit` writes to the cache store itself, a deliberate exemption, BE-12); specs (`spec/`, `engines/*/spec/`), which clear the store and call `increment` (TS-01, BE-12) | BE-17 |
| `Rafelo/ConcurrencyOnlyInExecutor` | `Concurrent::` | `Acme::Core::Executor`; specs (`spec/`, `engines/*/spec/`), which force races with a `Concurrent::CyclicBarrier` (TS-10) | BE-16 |
| `Rafelo/SendStreamOnlyInDownloads` | `send_stream` | core's download controller | BE-18 |
| `Rafelo/PageContextThroughFactory` | `PageContext.new`, `PageContext[...]` | `engines/core` | BE-01 |
| `Rafelo/NoPermissionLiterals` | a string literal passed to `allows?` or `capabilities` | nowhere; use the generated constants | BE-03 |
| `Rafelo/OwnPermissionPrefixes` | a required key outside the module's declared `permission_prefixes` | nowhere | BE-03 |
| `Rafelo/DateFormatterOnly` | `strftime`, `I18n.l` and `l(`, `to_fs`, `to_formatted_s`; a cop has no types, so it flags these calls wherever they appear, and exports format dates through `Acme::Core::Export` | `Acme::Core::DateFormatter` | FE-20 |
| `Rafelo/NoConstantize` | `constantize`, `safe_constantize`, `const_get`, a string `class_name:` | the core module registry | ARCH-10, ARCH-08, ARCH-09 |
| `Rafelo/EngineTablePrefix` | a table created in `engines/<e>/db/migrate` without the `<e>_` prefix (core's tables are `core_*`); the engine is read from the file path | nowhere, except a prefix recorded as `metadata.legacy_table_prefix` in `package.yml` (GEN-06) | ARCH-03, ARCH-10 |
| `Rafelo/ConfigXOnlyInCore` | reading or writing `config.x` | `engines/core` | ARCH-01, ARCH-10, BE-08 |
| `Rafelo/ReturnToOnlyInValueObject` | `return_to` read from params | `Acme::Core::ReturnTo` | SEC-11 |
| `Rafelo/SkipNeedsIssue` | `skip`, `pending`, `xit`, `xspecify`, `xexample`, `xdescribe`, `xcontext`, and `:skip`/`skip:`/`pending:` metadata, and outside `spec/enforcement/` also `prosopite: false` metadata and `Prosopite.pause`, without `#<number>` or an issue URL on the same line (`# 5 seconds` does not count) | nowhere | TS-05 |
| `Rafelo/NoKernelInternals` | `Acme::Core::Internal`, `Acme::DesignSystem::Internal` | the kernel engine that owns it | ARCH-09 |

Outside Ruby, `@apply` is allowed only in design_system CSS (FE-06):
`script/ci/apply_check` fails on an `@apply` in a CSS file outside
`engines/design_system/`. The template ships it; an adopter may replace it with
stylelint's `at-rule-disallowed-list` scoped by path.

```ruby
# script/ci/cops/rafelo/no_constantize.rb
module RuboCop
  module Cop
    module Rafelo
      class NoConstantize < Base
        MSG = "A dynamic constant lookup hides a dependency from Packwerk (ARCH-10). " \
              "Reference the constant through the owning engine's app/public/ and declare the dependency."
        RESTRICT_ON_SEND = %i[constantize safe_constantize const_get].freeze

        def_node_matcher :string_class_name?, "(pair (sym :class_name) (str _))"

        def on_send(node) = add_offense(node.loc.selector)

        def on_pair(node)
          add_offense(node) if string_class_name?(node)
        end
      end
    end
  end
end
```

```yaml
# .rubocop.yml (excerpt)
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

require:
  - ./script/ci/cops/rafelo

AllCops:
  Exclude: ["spec/enforcement/fixtures/**/*"] # the canaries read each fixture under a real file name (TS-07)

Rafelo/NoConstantize:
  Include: ["engines/**/*.rb"]
  Exclude: ["engines/core/**/modules.rb"] # the one allow-listed place

Rafelo/CacheOnlyThroughScopedCache: # specs clear the cache store and call increment (TS-01, BE-12)
  Exclude: ["engines/core/**/scoped_cache.rb", "spec/**/*", "engines/*/spec/**/*"]

Rafelo/ConcurrencyOnlyInExecutor: # specs force races with Concurrent:: primitives (TS-10)
  Exclude: ["engines/core/**/executor.rb", "spec/**/*", "engines/*/spec/**/*"]

Rafelo/EnvOnlyInConfig:
  Exclude: ["config/**/*"]

Rafelo/EngineTablePrefix:
  Include: ["engines/*/db/migrate/**/*.rb"] # the engine name comes from the file path (GEN-01)
```

## Configuration excerpts

### ESLint

```js
// eslint.config.mjs (excerpt)
import rafelo from "./script/ci/eslint/rafelo.mjs"; // local rules (TS-05), listed by the TS-07 meta-check

const DESIGN_SYSTEM = "engines/design_system/app/frontend";
const ICON_MAP = `${DESIGN_SYSTEM}/icon/**`;
const FORMATTERS = `${DESIGN_SYSTEM}/formatters.ts`;
const ERROR_BOUNDARY = `${DESIGN_SYSTEM}/error_boundary/error_boundary.tsx`; // the one class component (OOP-01)
const PAGE_RESOLVER = "app/frontend/lib/page_resolver.tsx";
const LAYOUTS = "app/frontend/layouts/**";
// domain/ and forms/ may compute with dates but never format them (FE-20, OOP-04).
const DOMAIN_CODE = ["**/app/frontend/domain/**", "**/app/frontend/forms/**"];
const TESTS = ["e2e/**/*.ts", "engines/*/e2e/**/*.ts", "**/*.test.{ts,tsx}"];
const DOMAIN_TESTS = ["**/app/frontend/domain/**/*.test.ts", "**/app/frontend/forms/**/*.test.ts"];
const STATE_WRAPPERS = [
  "engines/core/app/frontend/lib/use_domain_reducer.ts",
  "engines/core/app/frontend/lib/use_ui_state.ts",
];
const STATE_HOOKS = ["useState", "useReducer", "useActionState", "useOptimistic"];
const STATE_HOOKS_MESSAGE = "Use useDomainReducer or useUiState from @core/lib (FE-04).";
const URL_MESSAGE = "Do not build URLs in TypeScript; use the href Rails sends in props (ARCH-10).";
const USE_PAGE_MESSAGE =
  "Pages parse their props and pass them down; only layouts and the page resolver call usePage (CT-04).";
const SELECTOR_MESSAGE = "Select by role with an accessible name, or by test id (TS-04).";
const TYPE_EXPORT_MESSAGE = "A .tsx file exports no types; move them to a *.types.ts file (FE-05).";
const CLASS_COMPONENT_MESSAGE =
  "React code is functional; the design_system error boundary is the one class component (OOP-01).";
const DS_INERTIA_MESSAGE =
  "design_system takes only Link and Deferred from Inertia; visits, page props, and forms belong to the engines (FE-03).";
// Testing Library text queries in every variant (get/query/find, All), Playwright's text
// locators, CSS locators, and querySelector. An exact-name list misses findByText and queryByText.
const TEXT_QUERY =
  "/^((get|query|find)(All)?By(Text|LabelText|PlaceholderText|DisplayValue|Title|AltText)|getBy(Label|Placeholder)|locator|querySelector(All)?)$/";
const ROLE_QUERY = "/^(get|query|find)(All)?ByRole$/";

const IMPORTS = {
  base: {
    patterns: [
      { group: ["../*"], message: "Use an alias or ./ (FE-05)." },
      { group: ["react-router*", "@tanstack/react-query", "redux", "zustand", "styled-components", "@emotion/*"],
        message: "Inertia is the router and the data layer; style through the design system (FE-03, FE-12)." },
    ],
  },
  stateHooks: {
    paths: [{ name: "react", importNames: STATE_HOOKS, message: STATE_HOOKS_MESSAGE }],
  },
  // Raw page props: only layouts and the page resolver read them (CT-04).
  usePage: {
    paths: [{ name: "@inertiajs/react", importNames: ["usePage"], message: USE_PAGE_MESSAGE }],
  },
  engines: {
    patterns: [{ group: ["@engines/*"],
      message: "Only the page resolver uses @engines/; use @core/, @design_system/, or @<engine>/public/ (ARCH-10)." }],
  },
  designSystemLibraries: {
    patterns: [{
      group: ["react-aria-components", "@internationalized/date", "tailwind-variants", "tailwind-merge",
        "echarts", "echarts/*", "@tanstack/react-table"],
      message: "Use the @design_system/ component, wrapper, or formatter (FE-07, FE-08, FE-20)." }],
  },
  icons: {
    patterns: [{ group: ["lucide-react"], message: "Use @design_system/icon (FE-17)." }],
  },
  // design_system renders Inertia's Link and Deferred and nothing else of Inertia (FE-03).
  designSystemInertia: {
    paths: [{ name: "@inertiajs/react", allowImportNames: ["Link", "Deferred"], message: DS_INERTIA_MESSAGE }],
    patterns: [{ group: ["@inertiajs/*", "!@inertiajs/react"], message: DS_INERTIA_MESSAGE }],
  },
};

const PROPERTIES = {
  // React.useState and the like, through `import React from "react"` or `import * as React from "react"`.
  stateHooks: STATE_HOOKS.map((property) => ({ object: "React", property, message: STATE_HOOKS_MESSAGE })),
};

const SYNTAX = {
  formatting: [
    { selector: "MemberExpression[object.name='Intl'][property.name=/^(DateTimeFormat|NumberFormat|RelativeTimeFormat)$/]",
      message: "Format dates, numbers, and money with @design_system/formatters (FE-11, FE-20)." },
    { selector: "CallExpression[callee.property.name=/^toLocale(Date|Time)?String$/]",
      message: "Format with @design_system/formatters (FE-11, FE-20)." },
    // A syntax rule cannot tell money from other numbers, so toFixed is banned outright;
    // formatting any number for display belongs to the formatters (FE-11).
    { selector: "CallExpression[callee.property.name='toFixed']",
      message: "Format numbers and money with @design_system/formatters (FE-11)." },
  ],
  // Presentation code reads no calendar fields; domain/ and forms/ may compute with them (FE-20).
  dateGetters: [
    { selector: "CallExpression[callee.property.name=/^(getFullYear|getUTCFullYear|getMonth|getDate)$/]",
      message: "Show calendar dates through @design_system/formatters; a Thai year is a Buddhist Era year (FE-20)." },
  ],
  glob: [
    { selector: "MemberExpression[object.type='MetaProperty'][property.name='glob']",
      message: "Only the page resolver uses import.meta.glob (ARCH-10)." },
  ],
  urlBuilding: [
    // A template literal or `+` concatenation that starts with "/" and a locale or path segment
    // builds a URL (\x2F is "/"). ESLint 9.39.5 reports both; canary: `/${app.locale}/sign_in` (FE-18).
    { selector: "TemplateLiteral[quasis.0.value.raw=/^\\x2F(\\w|$)/]", message: URL_MESSAGE },
    { selector: "BinaryExpression[operator='+'][left.type='Literal'][left.value=/^\\x2F(\\w|$)/]", message: URL_MESSAGE },
  ],
  // Exported type aliases and interfaces, and type-only exports and re-exports. Used in .tsx files
  // only: *.types.ts, *.schema.ts, and generated .ts files export types (FE-05).
  typeExports: [
    { selector: ":matches(ExportNamedDeclaration, ExportAllDeclaration, ExportSpecifier)[exportKind='type']",
      message: TYPE_EXPORT_MESSAGE },
    { selector: "ExportDefaultDeclaration > TSInterfaceDeclaration", message: TYPE_EXPORT_MESSAGE },
  ],
  // Component, PureComponent, React.Component, React.PureComponent (OOP-01).
  classComponents: [
    { selector: ":matches(ClassDeclaration, ClassExpression)[superClass.name=/^(Pure)?Component$/]",
      message: CLASS_COMPONENT_MESSAGE },
    { selector: ":matches(ClassDeclaration, ClassExpression)[superClass.property.name=/^(Pure)?Component$/]",
      message: CLASS_COMPONENT_MESSAGE },
  ],
  selectors: [
    // A member call (screen.findByText, page.getByLabel) and a bare call destructured from render().
    { selector: `CallExpression[callee.property.name=${TEXT_QUERY}]`, message: SELECTOR_MESSAGE },
    { selector: `CallExpression[callee.name=${TEXT_QUERY}]`, message: SELECTOR_MESSAGE },
    { selector: `CallExpression[callee.property.name=${ROLE_QUERY}] Property[key.name='name'] > Literal`,
      message: "Take the accessible name from the i18n helper, not a literal (TS-04)." },
    { selector: `CallExpression[callee.name=${ROLE_QUERY}] Property[key.name='name'] > Literal`,
      message: "Take the accessible name from the i18n helper, not a literal (TS-04)." },
  ],
};

// Flat config replaces a rule per matching block instead of merging its
// options, so every block restates the full list minus its own exemption.
const restrictImports = (...keys) => ["error", {
  paths: keys.flatMap((key) => IMPORTS[key].paths ?? []),
  patterns: keys.flatMap((key) => IMPORTS[key].patterns ?? []),
}];
const restrictProperties = (...keys) => ["error", ...keys.flatMap((key) => PROPERTIES[key])];
const restrictSyntax = (...keys) => ["error", ...keys.flatMap((key) => SYNTAX[key])];

export default [
  // Canary fixtures break rules on purpose; the canaries lint them at real paths (TS-07).
  { ignores: ["spec/enforcement/fixtures/**"] },
  // ...base, typescript-eslint, react, react-hooks, jsx-a11y, unicorn, perfectionist
  {
    files: ["**/*.{ts,tsx}"],
    // Type-aware rules only through projectService; script/ci/eslint/check_config.mjs fails on `parserOptions.project`.
    languageOptions: { parserOptions: { projectService: true } },
    rules: {
      "no-restricted-imports": restrictImports(
        "base", "stateHooks", "usePage", "engines", "designSystemLibraries", "icons"),
      "no-restricted-properties": restrictProperties("stateHooks"),
      "no-restricted-syntax": restrictSyntax("formatting", "dateGetters", "glob", "urlBuilding", "classComponents"),
      "@eslint-community/eslint-comments/require-description": "error",
      "react/no-danger": "error",
    },
  },
  {
    files: ["**/*.tsx"],
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting", "dateGetters", "glob", "urlBuilding", "typeExports", "classComponents"),
    },
  },
  {
    files: [`${DESIGN_SYSTEM}/**`],
    ignores: [ICON_MAP],
    // design_system widgets may hold their own presentation state (FE-04)
    rules: {
      "no-restricted-imports": restrictImports("base", "engines", "icons", "designSystemInertia"),
      "no-restricted-properties": "off",
    },
  },
  {
    files: [ICON_MAP],
    rules: {
      "no-restricted-imports": restrictImports("base", "engines", "designSystemInertia"),
      "no-restricted-properties": "off",
    },
  },
  {
    files: STATE_WRAPPERS,
    rules: {
      "no-restricted-imports": restrictImports("base", "usePage", "engines", "designSystemLibraries", "icons"),
      "no-restricted-properties": "off",
    },
  },
  {
    files: [LAYOUTS],
    rules: {
      "no-restricted-imports": restrictImports("base", "stateHooks", "engines", "designSystemLibraries", "icons"),
    },
  },
  {
    files: [PAGE_RESOLVER],
    rules: {
      "no-restricted-imports": restrictImports("base", "stateHooks", "designSystemLibraries", "icons"),
      // its glob keys are file paths, not URLs
      "no-restricted-syntax": restrictSyntax("formatting", "dateGetters", "typeExports", "classComponents"),
    },
  },
  {
    files: DOMAIN_CODE,
    rules: { "no-restricted-syntax": restrictSyntax("formatting", "glob", "urlBuilding", "classComponents") },
  },
  // formats strings, builds no URLs
  { files: [FORMATTERS], rules: { "no-restricted-syntax": restrictSyntax("glob", "classComponents") } },
  {
    files: [ERROR_BOUNDARY], // React still needs a class for an error boundary (OOP-01, FE-15)
    rules: { "no-restricted-syntax": restrictSyntax("formatting", "dateGetters", "glob", "urlBuilding", "typeExports") },
  },
  {
    files: ["**/*.tsx"],
    ignores: [`${DESIGN_SYSTEM}/**`],
    rules: {
      "react/forbid-elements": ["error", { forbid: [
        { element: "button", message: "Use Button from @design_system/ (FE-07)." },
        { element: "input", message: "Use a design_system field (FE-07)." },
        { element: "select", message: "Use a design_system select (FE-07)." },
        { element: "textarea", message: "Use a design_system text area (FE-07)." },
      ] }],
    },
  },
  // Keep the test blocks last: a later block that sets no-restricted-syntax for a folder would
  // replace the selector rules for the tests in it. The canaries check the resolved config
  // of real test files (TS-07).
  {
    files: TESTS,
    plugins: { rafelo },
    rules: {
      "no-restricted-syntax": restrictSyntax("formatting", "dateGetters", "glob", "classComponents", "selectors"),
      "rafelo/skip-needs-issue": "error", // a skip carries #<number> or an issue URL on its line (TS-05)
    },
  },
  {
    files: ["**/*.test.tsx"],
    rules: {
      "no-restricted-syntax": restrictSyntax(
        "formatting", "dateGetters", "glob", "typeExports", "classComponents", "selectors"),
    },
  },
  {
    files: DOMAIN_TESTS, // they compute with dates like the code they test (FE-20)
    rules: { "no-restricted-syntax": restrictSyntax("formatting", "glob", "classComponents", "selectors") },
  },
];
```

The exemptions are exact files plus the design_system folder and
`app/frontend/layouts/`. The two state
wrappers and design_system widgets may use React's state hooks, whether
imported by name or reached as `React.useState`. Test files inherit their
folder's state-hook setting (the test blocks set no `no-restricted-properties`),
so a design_system test may call `React.useState` and an engine test may not.
The page resolver may use
`@engines/` and `import.meta.glob`, and its glob keys look like paths, so the
URL rule does not apply there. The formatters may use the `Intl` formatters,
`toLocale*String`, the date getters, and `toFixed`, and are outside the URL
rule too: it applies in frontend code outside the page resolver, the
formatters, and tests. `domain/` and `forms/`, their tests included,
may use the date getters to compute, never the formatting APIs (FE-20,
OOP-04); presentation code (pages, screens, containers, components, hooks,
layouts), its tests, and every other folder may use neither. A `.tsx` file
exports no types (`typeExports`, FE-05), while `*.types.ts`, schema, and
generated `.ts` files may; a class extending `Component` or `PureComponent`
is reported everywhere except design_system's
`error_boundary/error_boundary.tsx` (`classComponents`, OOP-01). With ESLint
9.39.5 and typescript-eslint 8.72.1, `typeExports` reports `export type`,
`export interface`, `export default interface`, `export type { … } from`,
`export { type … }`, and `export type *` in a `.tsx` file, a `.tsx` test
included, and none of them in a `.ts` file; `classComponents` reports
`Component`, `React.Component`, `PureComponent`, and a class expression,
also in another file of the `error_boundary/` folder. Only design_system may
import the UI libraries and `@internationalized/date` (`lucide-react` only in
its icon map). The reverse holds for Inertia: every folder outside
design_system may import it, and design_system, its icon map included, takes
only `Link` and `Deferred` (`designSystemInertia`, FE-03). With ESLint 9.39.5
that allow-list reports `router`, `usePage`, `useForm`, a default import, a
namespace import, a re-export of `WhenVisible`, and an `@inertiajs/core`
import in a design_system file, and leaves `Link`, `Deferred`, and
`Link as InertiaLink` alone; in an engine page the same imports are not
reported, except `usePage`. Raw page props are read only in
`app/frontend/layouts/` and the page resolver (`usePage` key, CT-04): with
ESLint 9.39.5 a named, aliased, or namespace import of `usePage` is reported in
an engine page, hook, or state wrapper and allowed in those two places; a
namespace import of `@inertiajs/react` is therefore reported outside them too.
Tests and browser specs navigate by URL, so they may build one;
every other restriction still applies to them. They alone run the local rule
`rafelo/skip-needs-issue` (plugin `rafelo` in `script/ci/eslint/rafelo.mjs`,
TS-05). ESLint ignores `spec/enforcement/fixtures/`; the canaries lint each
fixture at a real path through `--stdin-filename` and never edit the
configuration (TS-07).

The URL rule exists because links are server-built props (CT-02, ARCH-10):
props objects build every URL a page needs through `context.urls` (BE-04), a
list row carries its `href`, and action URLs sit in `data` or `meta` under a
key ending in `Href`, offered only where `can` allows. Page schemas validate
each one with `z.string().refine(isSafeUrl)` (FE-18), and every page's request
spec calls `have_resolvable_hrefs` (TS-02), which asserts that every `href`,
`*Href`, and `nav[].path` is a path `Urls` built for the request. Canary
fixtures under `spec/enforcement/fixtures/` break each restriction once, so a
typo in a path here fails CI instead of silently exempting everything.

### dependency-cruiser, generated from `package.yml`

The engine rules are not written by hand. `script/ci/engine_graph` reads the
`dependencies:` of every `engines/*/package.yml` (ARCH-08) and writes the
dependency-cruiser engine rules and every generated tsconfig file (one per
engine, one for `app/frontend`, `tsconfig.tooling.json`, and the root solution
file), so `bin/packwerk check`, dependency-cruiser, and `tsc -b` all check the
same declared graph. `--check` compares instead of writing and fails on drift;
it also fails when any `package_todo.yml` exists.

```ruby
# script/ci/engine_graph (sketch)
require "json"
require "yaml"

# Whole frontend tree except internal/ is their surface: @core/..., @design_system/...
# (internal/ is closed by the kernel-internals-stay-inside rule).
KERNEL = %w[core design_system].freeze

graph = Dir["engines/*/package.yml"].sort.to_h do |file|
  [File.basename(File.dirname(file)),
   YAML.load_file(file).fetch("dependencies", []).map { |dep| File.basename(dep) }]
end

graph.each do |engine, deps|
  next if engine.start_with?("example_") || deps.none? { _1.start_with?("example_") }

  abort "#{engine}: nothing outside example_* may depend on an example engine (GEN-08)"
end

def surface(engine)
  KERNEL.include?(engine) ? "^engines/#{engine}/app/frontend/" : "^engines/#{engine}/app/frontend/public/"
end

rules = graph.map do |engine, deps|
  {
    name: deps.empty? ? "#{engine}-imports-nothing-in-the-repository" : "#{engine}-imports-declared-surfaces-only",
    severity: "error",
    from: { path: "^engines/#{engine}/" },
    to: { path: "^(app|engines)/", pathNot: ["^engines/#{engine}/", *deps.map { surface(_1) }] },
  }
end

File.write(".dependency-cruiser.engines.generated.json", "#{JSON.pretty_generate(rules)}\n")

# The same graph writes every generated tsconfig file: one composite project per engine, one for
# app/frontend, one for the tooling (e2e/, scripts, root configs, engine Vitest configs; never the canary
# fixtures), and the root solution file. The alias paths in tsconfig.base.json come from `npm run aliases:generate`.
def project(name, root:, sources:, references:)
  {
    extends: "#{root}tsconfig.base.json",
    compilerOptions: {
      composite: true, declaration: true, emitDeclarationOnly: true,
      outDir: "#{root}tmp/tsc/#{name}", tsBuildInfoFile: "#{root}tmp/tsc/#{name}.tsbuildinfo",
    },
    include: sources,
    references: references,
  }
end

every_engine = ->(root) { graph.keys.map { |engine| { path: "#{root}engines/#{engine}" } } }

graph.each do |engine, deps|
  sources = ["app/frontend/**/*"]
  sources << "spec/dummy_engine/app/frontend/**/*" if engine == "core" # the test-only dummy engine (TS-01)
  config = project(engine, root: "../../", sources: sources, references: deps.map { |dep| { path: "../#{dep}" } })
  File.write("engines/#{engine}/tsconfig.json", "#{JSON.pretty_generate(config)}\n")
end

app = project("app", root: "../../", sources: ["**/*"], references: every_engine.("../../"))
File.write("app/frontend/tsconfig.json", "#{JSON.pretty_generate(app)}\n")

tooling = project("tooling", root: "./", references: every_engine.("./"), sources: %w[
  e2e/**/* engines/*/e2e/**/* script/**/*.ts playwright.config.ts vite.config.mts vitest.config.mts
  engines/*/vitest.config.mts config/frontend_aliases.mts config/frontend_react.mts
])
File.write("tsconfig.tooling.json", "#{JSON.pretty_generate(tooling)}\n")

solution = { files: [], references: [*every_engine.(""), { path: "app/frontend" }, { path: "tsconfig.tooling.json" }] }
File.write("tsconfig.json", "#{JSON.pretty_generate(solution)}\n")
```

For the example engines the dependency-cruiser rules read:

```jsonc
// .dependency-cruiser.engines.generated.json (excerpt; generated, do not edit)
[
  { "name": "core-imports-nothing-in-the-repository", "severity": "error",
    "from": { "path": "^engines/core/" },
    "to": { "path": "^(app|engines)/", "pathNot": ["^engines/core/"] } },
  { "name": "design_system-imports-nothing-in-the-repository", "severity": "error",
    "from": { "path": "^engines/design_system/" },
    "to": { "path": "^(app|engines)/", "pathNot": ["^engines/design_system/"] } },
  { "name": "example_customers-imports-declared-surfaces-only", "severity": "error",
    "from": { "path": "^engines/example_customers/" },
    "to": { "path": "^(app|engines)/", "pathNot": [
      "^engines/example_customers/", "^engines/core/app/frontend/", "^engines/design_system/app/frontend/"] } },
  { "name": "example_orders-imports-declared-surfaces-only", "severity": "error",
    "from": { "path": "^engines/example_orders/" },
    "to": { "path": "^(app|engines)/", "pathNot": [
      "^engines/example_orders/", "^engines/core/app/frontend/", "^engines/design_system/app/frontend/",
      "^engines/example_customers/app/frontend/public/"] } }
]
```

One rule per engine covers three facts at once: no engine imports `app/`, an
engine imports another engine only when its `package.yml` declares it, and
only into that engine's `public/` folder. Core and design_system are surfaces
as a whole, except their `internal/` folders, which the hand-written
`kernel-internals-stay-inside` rule below closes to everything outside the
kernel (ARCH-09). There is no known-violations baseline for these rules.

`tsc -b` refuses a reference to a project that is not `composite` or that does
not emit (TS6306, TS6310; a shared `noEmit: true` triggers the second). Each
engine project therefore emits declarations only, into `tmp/tsc/<engine>`,
with its build info in `tmp/tsc/<engine>.tsbuildinfo`; CI caches `tmp/tsc/`.
`app/frontend/tsconfig.json` is built the same way (into `tmp/tsc/app`) and
references every engine, because the composition root may use them all.
`tsconfig.tooling.json` (into `tmp/tsc/tooling`) covers the TypeScript outside
every `app/frontend/`: the root `e2e/`, `engines/*/e2e/`, `script/**/*.ts`,
`playwright.config.ts`, `vite.config.mts`, `vitest.config.mts`, each
engine's `engines/*/vitest.config.mts` (which takes `reactPlugins()` from
`config/frontend_react.mts`), `config/frontend_aliases.mts`, and
`config/frontend_react.mts`; it also references every engine. The
canary fixtures in `spec/enforcement/fixtures/` are excluded: they break
rules on purpose. The canaries run each tool with the repository's real
configuration, unchanged, and put each fixture at a real path; they never
edit the configuration or copy a rule (TS-07). Core's project includes the dummy engine's
`spec/dummy_engine/app/frontend/` (TS-01). The root `tsconfig.json` is a
solution file (`files: []`) that only lists the references, the tooling
project included. The alias `paths` live in the shared `tsconfig.base.json`,
which every project extends and dependency-cruiser reads; `npm run
aliases:generate` writes them, and Vite's `engineAliases` and `engineFsAllow`
in `config/frontend_aliases.mts`, and `npm run aliases:check` fails when
either file is stale (FE-05). Nobody edits a generated file by hand.

```jsonc
// engines/example_orders/tsconfig.json (generated, do not edit)
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "composite": true,
    "declaration": true,
    "emitDeclarationOnly": true,
    "outDir": "../../tmp/tsc/example_orders",                    // tmp/tsc/example_orders
    "tsBuildInfoFile": "../../tmp/tsc/example_orders.tsbuildinfo"
  },
  "include": ["app/frontend/**/*"],
  "references": [{ "path": "../core" }, { "path": "../design_system" }, { "path": "../example_customers" }]
}
```

```js
// .dependency-cruiser.cjs (excerpt)
const engineRules = require("./.dependency-cruiser.engines.generated.json");

const FRONTEND = "(^|/)app/frontend/";

module.exports = {
  forbidden: [
    ...engineRules, // ARCH-04, ARCH-08, ARCH-09: regenerate, never edit
    { name: "kernel-internals-stay-inside", severity: "error", // ARCH-09
      from: { pathNot: "^engines/(core|design_system)/" },
      to: { path: "^engines/(core|design_system)/app/frontend/internal/" } },
    { name: "no-circular", severity: "error", from: {}, to: { circular: true } },
    { name: "nothing-depends-on-example-engines", severity: "error",
      from: { path: "^(app|engines)/", pathNot: "^engines/example_" },
      to: { path: "^engines/example_" } },
    { name: "domain-is-framework-free", severity: "error",
      from: { path: `${FRONTEND}(domain|forms)/` },
      to: { path: [
        "node_modules/(react|react-dom|@inertiajs|i18next|react-i18next|tailwind-variants|tailwind-merge|react-aria-components|echarts|lucide-react)/",
        "^engines/design_system/",
        `${FRONTEND}(components|containers|screens|pages|hooks|layouts)/`,
      ] } },
    { name: "pages-render-screens", severity: "error",
      from: { path: `${FRONTEND}pages/` },
      to: { path: `${FRONTEND}(containers|components|hooks|domain|forms)/` } },
    { name: "only-resolver-picks-layouts", severity: "error",
      from: { path: `${FRONTEND}(pages|screens|containers|components)/` },
      to: { path: "^app/frontend/layouts/" } },
    { name: "components-stay-presentational", severity: "error",
      from: { path: `${FRONTEND}components/` },
      to: { path: `${FRONTEND}(containers|hooks|screens|pages)/` } },
  ],
  options: {
    // Without tsConfig, alias imports (@core/, @design_system/, @<engine>/, @/) do not
    // resolve and every path rule above silently matches nothing. The aliases live in the
    // shared tsconfig.base.json; the root tsconfig.json is a solution file with no paths.
    tsConfig: { fileName: "tsconfig.base.json" },
    tsPreCompilationDeps: true, // `import type` counts as a dependency (ARCH-08)
    doNotFollow: { path: "node_modules" },
    exclude: { path: "spec/enforcement/fixtures" }, // canaries put fixtures at real paths, never edit this (TS-07)
  },
};
```

### Packwerk

Each engine's `package.yml` is the single source of its dependencies. The
module generator writes it; a person approves every change to it (guard
files).

```yaml
# engines/example_orders/package.yml
enforce_dependencies: strict
enforce_privacy: strict   # packwerk-extensions privacy checker
public_path: app/public/
dependencies:
  - engines/core
  - engines/design_system
  - engines/example_customers
```

```yaml
# packwerk.yml
include:
  - "**/*.{rb,rake,erb}"
exclude:
  - "{bin,node_modules,script,tmp,vendor}/**/*"
  - "spec/enforcement/fixtures/**/*"
require:
  - packwerk-extensions
cache: true
```

`bin/packwerk validate` proves the declared graph acyclic (Packwerk's
dependency validator checks for cycles). `bin/packwerk check` checks every
constant reference against the declarations and, through packwerk-extensions,
against each engine's `app/public/`. Strict mode means a violation is never
parked: `bin/packwerk update-todo` is not used, and `script/ci/engine_graph
--check` fails while any `package_todo.yml` exists. The root package (the
application) may depend on every engine; no engine declares it, so a reference
from an engine to `app/` fails. Verify the packwerk-extensions `require` name
and option names when adopting.

### Canaries (TS-07)

`script/ci/enforcement_canaries` runs each tool on fixtures under
`spec/enforcement/fixtures/` and fails unless every expected rule reports.
Path-scoped rules are also proven where the code lives (TS-07): ESLint
fixtures are linted with `--stdin-filename` set to a real path in the folder
the rule targets, and `eslint --print-config` on one real file per scoped
folder asserts that the resolved rule still holds every expected entry.
A canary passes only when the tool exits with its findings status (ESLint
and RuboCop exit 1; their exit 2 is a crash or a configuration error) and
its machine-readable output names the expected rule, so a crash, a parse
error, an ignored file, or a run that inspected no file fails it. Every
`script/ci/` check and every generator or check script also runs on an empty
`--root` and must fail there with a count of 0. TS-07 lists the fixtures. In short: every graph check (declared and actual
cycles, undeclared dependencies, private constants, non-public imports,
references into a kernel `internal/` folder, `@engines/` misuse,
example-engine dependencies), every hand-written dependency-cruiser rule
(`domain-is-framework-free`, `pages-render-screens`,
`only-resolver-picks-layouts`, `components-stay-presentational`,
`nothing-depends-on-example-engines`), every custom cop, every
ESLint restriction and local rule above, a prop outside a page schema, a hand-written
`href` that `Urls` did not build (`have_resolvable_hrefs`), a global
`project: true` (`script/ci/eslint/check_config.mjs`), the changed-path
mappings of `script/ci/affected`, and every `script/ci/` check.

## The fast loop: `bin/check <engine>`

`bin/check example_orders` runs the checks for one engine in seconds to
minutes, for a person or an AI agent iterating on it. It does not replace
`bin/ci`, which stays the gate.

```sh
# bin/check (sketch)
set -euo pipefail
engine="${1:?usage: bin/check <engine>}"
dir="engines/${engine}"

bin/packwerk validate
bin/packwerk check "${dir}"
npx depcruise --config .dependency-cruiser.cjs "${dir}"
npx tsc -b "${dir}"
npx vitest run --project "${engine}" --project "${engine}:node" # jsdom: *.test.tsx, hooks; node: other *.test.ts
bundle exec rspec "${dir}/spec"
npx eslint --cache --cache-location "tmp/cache/eslint/${engine}/" --max-warnings 0 "${dir}"
```

## Affected engines: `script/ci/affected`

`script/ci/affected` maps the changed paths of a pull request to engines
through the `package.yml` graph, then adds every transitive dependent. CI runs
the per-engine steps of `bin/ci` for that set only. In the merge queue the
diff is taken against the merge base (WF-03).

Global inputs run everything, and so does any changed path that is in no
list below and outside `engines/<e>/`: a new root file runs everything until
it is added to a list (canary). The lists are explicit:

```ruby
# script/ci/affected (excerpt)
GLOBAL_INPUTS = %w[
  Gemfile Gemfile.lock package.json package-lock.json .npmrc mise.toml .ruby-version package.yml
  eslint.config.mjs packwerk.yml .rubocop.yml .dependency-cruiser.cjs
  vite.config.mts vitest.config.mts config/frontend_react.mts playwright.config.ts .env.ci.production
  Dockerfile .dockerignore renovate.json5 VERSION KERNEL_VERSION .gitattributes .gitignore
  config/application.rb config/credentials/ config/environments/ config/initializers/ config/routes.rb
  config/database.yml config/puma.rb config/queue.yml config/deploy.yml config/ci.rb
  config/errors.yml config/budgets.yml config/ratchets.yml config/locales.yml
  config/upstreams.yml config/permission_mapping.yml config/contracts/_shared.json
  bin/ db/ spec/enforcement/ spec/fixtures/formats/ spec/fixtures/hostile_urls.json
  .devcontainer/image_digest .devcontainer/
  .github/ script/ tsconfig.base.json
  engines/core/ engines/design_system/
].freeze

# The application only; a global input above takes precedence (config/contracts/_shared.json, spec/enforcement/).
APP_ONLY = %w[app/ e2e/ spec/ config/locales/ config/contracts/].freeze

# No engine and not the app: documentation and AI instruction files (14_working_with_ai.md).
ENGINE_FREE = %w[AGENTS.md CLAUDE.md docs/ .opencode/ .claude/].freeze

# Derived from the package.yml files and the engine list; they select nothing themselves, because
# script/ci/engine_graph --check and npm run aliases:check prove they match their sources.
# tsconfig.base.json is global instead: besides the generated alias paths it holds hand-written
# compiler options that apply to every project.
DERIVED = %w[
  tsconfig.json tsconfig.tooling.json config/frontend_aliases.mts
  .dependency-cruiser.engines.generated.json
].freeze
```

- A dependency change selects engines from the `package.yml` diff: the engine
  whose `dependencies:` list changed, plus its transitive dependents. The
  derived files that change with it (`DERIVED`) add nothing, so adding a
  dependency to one module does not run every engine.
- The digest file of the prebuilt Dev Container image,
  `.devcontainer/image_digest` (OPS-09), is listed by name as well as under
  `.devcontainer/`, so it stays a global input even if the folder entry
  changes: a first CI job reads it, and every other `ci.yml` job except the
  production image build runs in the image it names.
- A change to an `APP_ONLY` path (outside the global inputs) affects the
  application only: app-level specs, the page resolver, and the Playwright
  smoke. No engine depends on the app.
- A change only to `ENGINE_FREE` paths selects no engine; the steps of
  `bin/ci` that always run, `docs:check` among them, still check it.
- `db/` holds `structure.sql` (OPS-08), which every engine's specs load,
  `spec/fixtures/formats/` feeds the compatibility spec over every job class
  defined under `app/` and `engines/*/app/` (SEC-16), and the kernel's `isSafeUrl` and `appPathSchema` tests read
  `spec/fixtures/hostile_urls.json` (FE-18), so all three are global.
- `engines/design_system` is a global input, with one narrowing: when a pull
  request leaves the committed API file `engines/design_system/api.d.ts`
  unchanged (FE-21; a `bin/ci` step proves the committed file is current),
  the run covers design_system's own tests plus the Vitest component tests of
  the affected modules, and skips RSpec and Playwright; the visual regression
  suite (TS-11) runs as on every design_system change. A changed API file
  runs everything.
- A pull request that changes only lockfiles runs a reduced lane (WF-06):
  install with `BUNDLE_FROZEN=true` and `npm ci`, the dependency audits
  (SEC-07), `tsc -b`, and the smoke suite. A lockfile changed together with
  anything else runs everything, and the nightly run covers every engine
  regardless.
- Canary fixtures pair changed-path lists with the engine sets they must
  produce, including a change in a domain engine's public surface reaching its
  dependents, an app-only change, a documentation-only change that
  selects no engine, and a root path in no list, which runs everything.

## The gate: `bin/ci`

Rails 8.1's `config/ci.rb` runs the same steps locally and in CI. Steps marked
*affected* run for the engines `script/ci/affected` returns; the nightly run
passes every engine.

1. Setup (`bin/setup --skip-server`).
2. Declared graph: `script/ci/engine_graph --check` (dependency-cruiser engine
   rules and every generated `tsconfig.json`), `bin/packwerk validate`,
   `bin/packwerk check`.
3. RuboCop with the `Rafelo/*` cops; `script/ci/apply_check` (FE-06).
4. Clone detector: flay and jscpd on cross-engine pairs in the scoped folders,
   against the baseline (ARCH-05).
5. Ratchets (`script/ci/ratchet`: a count above its ceiling fails) and
   growth budgets: `script/ci/growth` (core and design_system size,
   domain-engine public surfaces, module files and pages) and
   `script/ci/fan_in` (product modules) (ARCH-12).
6. `script/ci/pins` (including `mise.toml`'s Ruby, `.ruby-version`, and the
   Dev Container image tag, which must agree, and the image digest in
   `devcontainer.json`, which must equal `.devcontainer/image_digest`),
   `script/ci/actions_pinned`, `script/ci/workflow_policy` (WF-07).
7. `script/ci/enforcement_canaries` (TS-07).
8. Generated files and catalogs: `contracts:check`, `errors:check`,
   `pages:check`, `aliases:check`, `permissions:check`, `locales:check`,
   `docs:check`, `i18n:check`,
   `i18n-tasks missing`, `i18n-tasks unused`.
9. Lint, *affected*, with caches: `script/ci/eslint/check_config.mjs` (which
   `npm run lint` also runs first) runs `eslint --print-config` on one `.ts`
   file and fails when `parserOptions.project` is set; then ESLint on the
   affected engines with `--cache` and `--max-warnings 0`, Prettier (`--check --cache`),
   dependency-cruiser.
10. `tsc -b` over the generated composite projects (declaration output and
    `.tsbuildinfo` files in `tmp/tsc/`, cached between runs); then the
    design_system API file is regenerated from `tmp/tsc/design_system`
    (without `internal/**` and `**/*.test.d.ts`) and compared with the
    committed `engines/design_system/api.d.ts` (FE-21).
11. Tests in parallel, *affected*: Vitest projects (`<engine>` in jsdom for
    `*.test.tsx` and `hooks/**/*.test.ts`, `<engine>:node` for every other
    `*.test.ts`; `app` and `app:node` the same way for the app); RSpec through
    `parallel_tests` with a database per process (`bin/ci` empties
    `tmp/page_matchers/` before RSpec; after it, `pages:check --matchers`,
    TS-02); the `boot_seconds` budget (TS-09).
12. Concurrency lane: `:concurrency` specs serially, with truncation, never
    retried (TS-10).
13. `script/ci/generator_smoke` (GEN-04), in CI a job of its own whose `if:`
    skips it unless a pull request touches generator templates, core contract
    helpers, registry code, or routing; the nightly run always runs it.
14. Security and release checks: Brakeman; bundler-audit and
    `npm audit --audit-level=high` when a lockfile changed;
    `script/ci/production_routes` as a dummy boot (SEC-12, BE-08);
    `script/ci/deploy_preflight` (OPS-06), which the Kamal hook
    `.kamal/hooks/pre-deploy` also runs before every deploy;
    `script/ci/release --check` when `VERSION` changed (WF-05).
15. Vite build and bundle budgets: entry, each page with its static imports,
    the smallest page's initial bytes, and each lazy chunk (FE-16).

Separate CI jobs run the Playwright smoke per engine project with axe (TS-08)
under a Report-Only CSP, failing when `/core/csp_reports` received a report
(SEC-05), and, on design_system changes, the visual regression suite (TS-11).
The PR title lint, the ratchet-file comparison (Ratchets), and
`script/ci/guard_approval` (WF-03, Guard files) are required checks of their
own, the jobs `title`, `ratchet`, and `guard_approval` of
`.github/workflows/pull_request.yml`, which re-runs them, never CI, when a
title is edited and when a review is submitted or dismissed; `ratchet` and
`guard_approval` read the reviews with `pull-requests: read` (WF-07), or a
recorded list (`--reviews FILE`), which their canaries use. The CI workflow,
`.github/workflows/ci.yml`, triggers on `pull_request`, `merge_group`, and
`push` to `main` (WF-03, WF-05). Its jobs run in the prebuilt Dev Container
image, whose digest the first job (`image`) reads from
`.devcontainer/image_digest` (OPS-09), and install with `BUNDLE_FROZEN=true`
and `npm ci` (WF-06). The image reader itself runs directly on the runner, as
do the two jobs that need Docker there: the production image build (OPS-06)
and, in its own workflow, the Dev Container image build (OPS-09). Generator
smoke and the production image build run `rafelo:module`, which changes
`Gemfile.lock`, so they are the two that set `BUNDLE_FROZEN=false` (GEN-04,
OPS-06). The `pull_request.yml` jobs
and the release job run on `ubuntu-latest`. Every job that runs steps
declares `timeout-minutes` (TS-09). `ci.yml` ends in the `ci-ok` aggregator
(WF-03). No CI job pushes to `main`.

`lefthook` runs RuboCop, ESLint, and Prettier on staged files before each
commit. It is a convenience; `bin/ci` is the gate.

## Ratchets

Some counts rise only with an owner's approval, and every fall becomes the new
ceiling. `script/ci/ratchet` counts each item and compares it with the
committed counts. Only a rise fails; a fall never fails a pull request. CI
never commits a lower count and never pushes to `main`. A pull request may
lower the counts it earned itself (`script/ci/ratchet --update` writes them);
otherwise a scheduled job runs `--update` on `main` and opens a pull request
that lowers them. A gain cannot be quietly spent later, and nobody has to
remember to lower a number.

Counts live where the code they count lives (ARCH-11). Each product module
and domain engine keeps its own in `engines/<e>/config/ratchets.yml`:
`eslint-disable`, `rubocop:disable`, `"use no memo"`, skips, page budget
overrides, `legacy_table_prefixes`, and `legacy_constants`. The root
`config/ratchets.yml` holds the clone baseline, whose entries are pairs across
two engines by nature, and the counts for core, design_system, and the app,
including `legacy_lint_paths`: the legacy `app/` paths of a brownfield
adoption, which `eslint.config.mjs` and `.rubocop.yml` list because the
code-level rules do not yet apply to them in full (14_working_with_ai.md), so
that list only shrinks. The kernel's counts sit at the root because code owners cover
`engines/core/` and `engines/design_system/`, and the ratchet files stay
outside CODEOWNERS (below).

```yaml
# config/ratchets.yml (kernel and app counts, and the cross-engine clone baseline; a rise needs an owner, a fall is the new ceiling)
eslint_disable: 1          # FE-10: core, design_system, and app/
rubocop_disable: 0
use_no_memo: 0             # FE-10
skipped_tests: 0           # TS-05
clone_baseline_entries: 0  # ARCH-05: every entry is a pair across two engines
legacy_lint_paths: 0       # brownfield only: legacy app/ paths listed in eslint.config.mjs and .rubocop.yml
```

```yaml
# engines/example_orders/config/ratchets.yml (this engine's counts; a rise needs an owner, a fall is the new ceiling)
eslint_disable: 2          # FE-10
rubocop_disable: 1
use_no_memo: 1             # FE-10
skipped_tests: 0           # TS-05
page_budget_overrides: 1   # TS-02: pages: entries in this engine's config/budgets.yml
legacy_table_prefixes: 0   # GEN-06: metadata.legacy_table_prefix in this engine's package.yml
legacy_constants: 0        # GEN-06: aliases in config/initializers/legacy_constants.rb that point into this engine
```

The ratchet files decide what green means, so a rise needs a person, but a
fall should not wait for one. GitHub's required code-owner review cannot
exempt a diff that only lowers numbers, so the ratchet files have no
CODEOWNERS entry. Instead, a separate required check runs `script/ci/ratchet`
against the merge base on every pull request: a diff that only lowers counts
passes; a diff that raises one fails unless an owner listed in CODEOWNERS
approved the pull request (read through the GitHub API with
`pull-requests: read`, as `script/ci/guard_approval` does, which skips the
ratchet files; both read a recorded list of reviews instead with
`--reviews FILE`, which their canaries use). The scheduled
job's pull request therefore merges without an owner. Open it with a GitHub
App token: a pull request opened with a workflow's own `GITHUB_TOKEN` does not
trigger CI (verify when adopting).

Locale placeholders are not ratcheted: the release workflow (WF-05) fails
while any placeholder remains, which enforces zero where it matters.

## Lint and build performance

- ESLint and Prettier run per affected engine with `--cache`; the cache
  directory is kept between CI runs per engine.
- Type-aware typescript-eslint rules run only through `projectService`, on
  affected projects. `script/ci/eslint/check_config.mjs`, which `npm run lint`
  runs before ESLint, fails when `parserOptions.project` is set (canary: a
  global `project: true`), which would type-check the whole repository on
  every lint run.
- `tsc -b` builds through project references generated from the declared
  graph. Each engine is a composite project that emits declarations only into
  `tmp/tsc/<engine>`, next to its `.tsbuildinfo`; CI caches `tmp/tsc/`
  between runs, so an unchanged engine is not type-checked again.
- RuboCop and Packwerk keep their caches between runs.
- Running one engine's specs still boots the whole application, so boot time
  has its own budget (`boot_seconds`, measured by `bin/rails runner nil`, with
  bootsnap on).

## Scheduled jobs

Scheduled jobs never block a merge and never push to `main`. Each opens an
issue when it finds something, except the ratchet job, which opens a pull
request.

| Job | When | What it does | Rule |
| --- | --- | --- | --- |
| Full run | nightly | `bin/ci` over every engine, including `script/ci/generator_smoke` | TS-06, GEN-04 |
| Cross-browser end to end | nightly | Playwright projects per engine on Chromium, Firefox, and WebKit | TS-04, TS-08 |
| Upstream drift | scheduled | per named upstream: staging responses against the committed fixtures | TS-03 |
| Permission drift | scheduled | module permission manifests and `config/permission_mapping.yml` against the upstream's grant catalog, when it offers one | BE-03 |
| Touch rate | scheduled, once there are at least three product modules not counting the examples (`growth.touch_rate.min_modules: 3`) | `script/ci/touch_rate` over `git log`: share of merged pull requests in 30 days touching `engines/core` or `engines/design_system` | ARCH-12 |
| Ratchet falls | scheduled | `script/ci/ratchet --update` on `main`; when any count fell, opens a pull request that lowers the committed counts, which passes the ratchet check without an owner | FE-10, TS-05, TS-02, ARCH-05, GEN-06 |
| Advisories | daily | bundler-audit and `npm audit` on `main`; a new advisory opens an issue with a fix deadline | SEC-07 |
| Repository rules drift | scheduled | `script/ci/repo_rules` with the read-only workflow token: the active rules for `main` against `.github/rulesets/main.json` and the `refs/tags/v*` ruleset against `.github/rulesets/release_tags.json`; also a required check name that matches no job | WF-03, WF-05 |
| Production image build | nightly | builds the production image, without pushing it, after `rafelo:module` has created a throwaway module | OPS-06 |

## The template's own CI

The template repository also proves what an adopter relies on:

- it adopts the commit under test: `git archive HEAD`, `rails new` with the
  application template from that archive under a two-word app name that is
  not `acme` (for example `smoke_shop`), `bin/setup --skip-server`, and
  `bin/ci` in the new app; it fails when any tracked path or file still
  contains `acme` in any letter case (GEN-07);
- it adopts the previous release (N-1) with the application template, updates
  it to the current one with `bin/kernel_update`, and runs `bin/ci` (GEN-07);
- it deletes `engines/example_orders` and `engines/example_customers` and runs
  `bin/ci`, proving they are removable (GEN-08); the kernel's own specs keep
  passing because they run against `engines/core/spec/dummy_engine`, not the
  example engines.

## Guard files

Guard files decide what green means, so changing one needs a person's
approval (ADR-32): through CODEOWNERS, or, for the ratchet files, through the
required ratchet check, which passes a fall and needs an owner's approval for
a rise (Ratchets). An AI agent never loosens a guard to make something pass;
it proposes the change in the pull request and a person decides.

| Guard | Files |
| --- | --- |
| Lint and dependency rules | `eslint.config.mjs`, `.dependency-cruiser.cjs`, `packwerk.yml`, `.rubocop.yml`, `script/ci/cops/`, `script/ci/eslint/` |
| The declared graph | every `package.yml` (each `dependencies:` change) |
| Budgets and ratchets | `config/budgets.yml` (CODEOWNERS); `config/ratchets.yml` and `engines/*/config/ratchets.yml` (no CODEOWNERS entry; a rise needs an owner through the ratchet check, see Ratchets) |
| Canaries | `spec/enforcement/` |
| Production routes | `config/production_routes.yml` (the routes no registry entry declares, SEC-12) |
| CI | `script/ci/`, `config/ci.rb`, `.github/` |

Code owners also cover `engines/core/` and `engines/design_system/`
(ARCH-12); they are kernel code, not guard files.

```text
# .github/CODEOWNERS (excerpt)
# The ratchet files have no line: script/ci/ratchet passes falls and requires an owner's approval for raises.
/engines/core/               @acme/architecture
/engines/design_system/      @acme/design-system
/package.yml                 @acme/architecture
/engines/*/package.yml       @acme/architecture
/eslint.config.mjs           @acme/architecture
/.dependency-cruiser.cjs     @acme/architecture
/packwerk.yml                @acme/architecture
/.rubocop.yml                @acme/architecture
/config/budgets.yml          @acme/architecture
/config/ci.rb                @acme/architecture
/config/production_routes.yml @acme/architecture
/spec/enforcement/           @acme/architecture
/script/ci/                  @acme/architecture
/.github/                    @acme/architecture
```

Branch protection requires a code owner's review. The generated files
(`.dependency-cruiser.engines.generated.json` and every generated
`tsconfig.json`) need no owner of their own: they are derived from the
`package.yml` files, and `script/ci/engine_graph --check` fails when they
drift.

What GitHub can require depends on the plan (verify the current plans when
adopting):

- **Branch protection with a required merge queue and required code-owner
  review.** The full arrangement above.
- **Branch protection without a required merge queue or code-owner review**
  (a merge queue needs an organization-owned repository; for private
  repositories code-owner review depends on the plan). The fallback
  is explicit: branch protection turns on "require branches to be up to date"
  and requires the `ci-ok` check and the three `pull_request.yml` checks
  (`title`, `ratchet`, `guard_approval`). `script/ci/guard_approval` fails
  when a guard file other than a ratchet file changed without an approving
  review from an owner listed in CODEOWNERS (GitHub API), and the ratchet
  check works as before. The approval rule then holds.
- **No branch protection for private repositories.** Nothing can be required.
  The guarantees fall back to required CI status where the platform offers it
  and otherwise to convention: `ci-ok`, `title`, `ratchet`, and
  `guard_approval` still run and report, and people merge only when all of
  them are green.

The outcomes Rafelo promises, an always-green `main` and a person's
approval on every guard change, are real only with branch protection
(WF-03, ADR-19).
