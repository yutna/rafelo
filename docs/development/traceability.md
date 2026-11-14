# Rule and ADR traceability

Maintainer evidence for the final release. Every rule ID in `docs/architecture/01` through `13` and every ADR in `10_decisions.md` has one row: the code a reviewer opens first, the command or spec that proves it, and the status from the enforcement matrix. `09_enforcement.md` remains the full matrix; this table is the release index. It is not part of the template payload.

Status meanings are the four in `09_enforcement.md`: **enforced** (a tool fails the build), **tested in kernel** (the kernel's specs prove it; feature code inherits it), **verify when adopting** (confirm the option against the pinned version), and **review** (people only).

## Rules

### Architecture (`01_architecture.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| ARCH-01 | Rails is the BFF and the Inertia server | `engines/core/app/models/rafelo/core/upstream_client.rb` · `config/upstreams.yml` | `bundle exec rspec spec/core/upstream_client_spec.rb` · `bin/ci` | enforced |
| ARCH-02 | The browser never calls an upstream API | `engines/core/app/models/rafelo/core/upstream_client.rb` · `script/ci/cops/rafelo/faraday_only_in_upstream_client.rb` | `bin/rubocop` · `bin/ci` | enforced |
| ARCH-03 | Rails stores only what the BFF owns | `engines/core/db/migrate` · `engines/*/db/migrate` | `script/ci/deploy_preflight` · `bin/ci` | review (table prefix, `strong_migrations`: enforced) |
| ARCH-04 | Engine kinds and dependency direction | `package.yml` · `script/ci/engine_graph` · `engines/core/lib/generators/rafelo/module/module_generator.rb` | `bin/packwerk validate` · `bin/packwerk check` · `npm run graph:check` | enforced (engine kinds: review) |
| ARCH-05 | Shared code is a public interface | `engines/*/app/public` · `.dependency-cruiser.cjs` | `script/ci/clones` · `bin/packwerk check` | enforced (pair filtering and scope options of flay and jscpd: verify when adopting; ladder choice: review) |
| ARCH-06 | One module registry, declared in each module | `engines/core/app/models/rafelo/core/modules.rb` · `config/initializers/modules.rb` | `bundle exec rspec spec/core/modules_spec.rb` · `spec/requests/dummy_engine_spec.rb` | enforced |
| ARCH-07 | Every application URL carries a configured locale | `engines/core/app/models/rafelo/core/locales.rb` · `engines/core/lib/rafelo/core/locale_middleware.rb` · `config/locales.yml` | `bundle exec rspec spec/core/locale_middleware_spec.rb spec/requests/locale_spec.rb` | enforced |
| ARCH-08 | One declared dependency graph, acyclic, checked twice | `package.yml` · `script/ci/engine_graph` · `.dependency-cruiser.cjs` | `bin/packwerk validate` · `npm run graph:check` · `script/ci/graph_canaries` | enforced |
| ARCH-09 | Public surfaces are enforced | `engines/*/package.yml` · `engines/*/app/public` · `engines/design_system/api.d.ts` | `bin/packwerk check` · `npm run api:check` · `script/ci/packwerk_canary` | enforced (packwerk-extensions option names: verify when adopting; additive change: review) |
| ARCH-10 | Coupling without constants is constrained | `script/ci/cops/rafelo/config_x_only_in_core.rb` · `.dependency-cruiser.cjs` · `engines/core/app/models/rafelo/core/scoped_cache.rb` | `bin/rubocop` · `npm run arch:check` · `bundle exec rspec spec/core/scoped_cache_spec.rb` | enforced (URL-building selectors: verify when adopting; string event names: review) |
| ARCH-11 | Module-owned artifacts live in the module | `engines/*/config/contracts` · `engines/*/config/errors.yml` · `engines/*/config/permissions.yml` · `engines/*/config/ratchets.yml` | `npm run contracts:check` · `npm run errors:check` · `npm run permissions:check` · `script/ci/ratchet` | enforced |
| ARCH-12 | Growth has budgets | `config/budgets.yml` · `script/ci/growth` · `script/ci/fan_in` | `script/ci/growth` · `script/ci/fan_in` · `script/ci/growth_canary` | enforced (touch rate: scheduled metric) |
| ARCH-13 | No host-local state | `engines/core/app/models/rafelo/core/export.rb` · `config/storage.yml` | `bundle exec rspec spec/core/export_spec.rb` · `bin/ci` | review |

### Backend (`02_backend.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| BE-01 | The shape of a controller action | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `engines/core/app/models/rafelo/core/page_context_factory.rb` | `bin/packwerk check` · `bundle exec rspec spec/requests` | enforced (action shape: review) |
| BE-02 | Authorization is verified and denied by default | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `engines/core/app/models/rafelo/core/gateway.rb` | `bundle exec rspec spec/requests/authorization_spec.rb spec/core/gateway_lifecycle_spec.rb` | enforced |
| BE-03 | Permission manifests, keys, and wildcards | `engines/*/config/permissions.yml` · `engines/core/app/models/rafelo/core/permission_set.rb` | `npm run permissions:check` · `bundle exec rspec spec/core/permission_set_spec.rb` | enforced (drift: scheduled) |
| BE-04 | Props objects are pure | `engines/core/app/models/rafelo/core/page_props.rb` · `engines/core/app/models/rafelo/core/urls.rb` | `bin/rubocop` · `bundle exec rspec spec/core/page_props_spec.rb spec/core/page_matchers_spec.rb` | enforced (params and session: review) |
| BE-05 | One HTTP adapter for named upstreams | `engines/core/app/models/rafelo/core/upstream_client.rb` · `engines/core/app/models/rafelo/core/upstream_config.rb` | `bundle exec rspec spec/core/upstream_client_spec.rb spec/upstream/fake_app_spec.rb` | enforced (cops) · tested in kernel (persistent adapter's per-request timeouts: verify when adopting) · tested in kernel (resilience; breaker library behaviour, ADR-30: verify when adopting) |
| BE-06 | Gateways declare their upstream and return value objects | `engines/core/app/models/rafelo/core/gateway.rb` | `bundle exec rspec spec/core/gateway_spec.rb` | tested in kernel (declaration) · review (value objects) |
| BE-07 | Lists are paginated by the upstream | `engines/core/app/models/rafelo/core/list_query.rb` | `bundle exec rspec spec/core/list_query_spec.rb` | enforced |
| BE-08 | One typed configuration boundary | `engines/core/app/models/rafelo/core/upstream_config.rb` · `config/upstreams.yml` · `config/credentials` | `bin/ci` · `script/ci/deploy_preflight` | enforced (Rake task introspection: verify when adopting) |
| BE-09 | `Current` stays at the edge | `engines/core/app/models/rafelo/core/current.rb` · `engines/core/app/controllers/rafelo/core/base_controller.rb` · `script/ci/cops/rafelo/faraday_only_in_upstream_client.rb` | `bin/rubocop` · `bundle exec rspec spec/core/base_controller_spec.rb` | enforced |
| BE-10 | The smallest object that fits | review | review · `bin/ci` | review |
| BE-11 | Jobs are small and idempotent | `engines/core/app/jobs/rafelo/core/base_job.rb` · `engines/core/app/jobs/rafelo/core/*.rb` | `bundle exec rspec spec/core/base_job_spec.rb` | enforced (base class) · review (job bodies) |
| BE-12 | Throttle authentication and writes | `engines/core/app/controllers/concerns/rafelo/core/throttling.rb` · `engines/core/app/controllers/rafelo/core/base_controller.rb` · `config/cache.yml` | `bundle exec rspec spec/core/throttling_spec.rb spec/requests/session_flow_spec.rb` | enforced |
| BE-13 | The shape of a write action | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `engines/core/app/models/rafelo/core/form.rb` · `engines/core/app/models/rafelo/core/idempotency_claim.rb` | `bundle exec rspec engines/core/spec/dummy_engine spec/requests/idempotency_spec.rb` | tested in kernel |
| BE-14 | Incoming keys are snake_case once | `engines/core/app/controllers/rafelo/core/base_controller.rb` | `bundle exec rspec spec/requests` | enforced |
| BE-15 | Writes are idempotent and conflict-aware | `engines/core/app/models/rafelo/core/idempotency_claim.rb` · `engines/core/app/models/rafelo/core/form_token.rb` · `engines/core/app/models/rafelo/core/idempotency_key.rb` | `bundle exec rspec spec/core/idempotency_claim_spec.rb spec/core/form_token_spec.rb spec/core/idempotency_concurrency_spec.rb` | enforced |
| BE-16 | Upstream calls have a budget and a deadline | `engines/core/app/models/rafelo/core/request_deadline.rb` · `engines/core/app/models/rafelo/core/call_budget.rb` · `engines/core/app/models/rafelo/core/executor.rb` | `bundle exec rspec spec/core/executor_spec.rb spec/core/request_deadline_spec.rb spec/core/upstream_client_spec.rb` | enforced (interlock wrap: verify when adopting) |
| BE-17 | Caching never crosses viewers, modules, or releases | `engines/core/app/models/rafelo/core/scoped_cache.rb` · `script/ci/cops/rafelo/cache_only_through_scoped_cache.rb` | `bundle exec rspec spec/core/scoped_cache_spec.rb` · `bin/rubocop` | enforced (scopes and invalidation: review) |
| BE-18 | Downloads stream through core; exports are stored and expire | `engines/core/app/controllers/rafelo/core/download_controller.rb` · `engines/core/app/models/rafelo/core/export.rb` · `engines/core/app/jobs/rafelo/core/export_job.rb` | `bundle exec rspec spec/requests/download_spec.rb spec/core/export_spec.rb` | enforced (export dates: tested in kernel) |
| BE-19 | Jobs that act for a viewer use the viewer's session | `engines/core/app/jobs/rafelo/core/viewer_job.rb` · `engines/core/app/models/rafelo/core/viewer_token_provider.rb` · `engines/core/app/models/rafelo/core/job_token_provider.rb` | `bundle exec rspec spec/core/base_job_spec.rb spec/core/viewer_token_provider_spec.rb` | enforced |
| BE-20 | No upstream call inside a database transaction | `engines/core/app/models/rafelo/core/gateway.rb` · `engines/core/app/models/rafelo/core/upstream_client.rb` | `bundle exec rspec spec/core/upstream_client_spec.rb spec/core/gateway_spec.rb` | enforced (transaction counting: verify when adopting) |
| BE-21 | Connection and timeout arithmetic is checked | `config/deploy.yml` · `config/database.yml` · `config/puma.rb` · `config/queue.yml` · `config/budgets.yml` | `bundle exec rspec spec/core/connections_spec.rb spec/config/deployment_spec.rb` | enforced (Solid Queue async mode: verify when adopting) |
| BE-22 | Migrations are zero-downtime | `db/migrate` · `engines/core/db/migrate` · `config/initializers/strong_migrations.rb` · `script/ci/deploy_preflight` | `script/ci/deploy_preflight` · `bin/ci` | enforced (release sequencing, long migrations: review) |
| BE-23 | Monkey patches live in one place | `config/initializers/patches` · `script/ci/patches` | `script/ci/patches` · `script/ci/patches_canary` | enforced (location: review) |
| BE-24 | Base controller callbacks are declared in one list | `engines/core/app/controllers/rafelo/core/base_controller.rb` | `bundle exec rspec spec/core/base_controller_spec.rb` | tested in kernel (callback introspection on the pinned Rails: verify when adopting) |
| BE-25 | Feature flags are server-side and arrive through `can` | `engines/core/app/models/rafelo/core/flags.rb` · `engines/core/app/models/rafelo/core/capability_map.rb` · `engines/core/app/models/rafelo/core/modules.rb` | `bundle exec rspec spec/core/flags_spec.rb spec/core/capability_map_spec.rb spec/requests/dummy_engine_spec.rb` | tested in kernel (dark modules) · review (flags inside a module) |

### Session and security (`03_session_security.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| SEC-01 | Opaque session cookies | `engines/core/app/models/rafelo/core/session.rb` · `config/initializers/session_store.rb` | `bundle exec rspec spec/requests/session_flow_spec.rb spec/core/session_spec.rb` | enforced |
| SEC-02 | Upstream tokens never leave the server | `engines/core/app/models/rafelo/core/session.rb` · `engines/core/app/models/rafelo/core/log_payload.rb` · `engines/core/app/models/rafelo/core/auth_gateway.rb` | `bundle exec rspec spec/core/log_payload_spec.rb spec/core/session_spec.rb` | enforced |
| SEC-03 | Single-flight refresh without row locks | `engines/core/app/models/rafelo/core/session_refresher.rb` | `bundle exec rspec spec/core/grants_concurrency_spec.rb spec/core/session_refresher_spec.rb` | enforced (encryption of the post-claim write on the pinned Rails: verify when adopting) |
| SEC-04 | What a refresh result means | `engines/core/app/models/rafelo/core/session_refresher.rb` · `engines/core/app/controllers/rafelo/core/base_controller.rb` | `bundle exec rspec spec/requests/authorization_spec.rb spec/requests/grants_refresh_spec.rb` | enforced |
| SEC-05 | Request protection | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `config/initializers/content_security_policy.rb` · `engines/core/app/models/rafelo/core/exceptions_app.rb` | `bundle exec rspec spec/requests/security_headers_spec.rb spec/requests/browser_spec.rb spec/requests/write_flow_spec.rb` | enforced (`?inline` imports: review) |
| SEC-06 | No flag may elevate a real account | `engines/core/app/models/rafelo/core/flags.rb` · `engines/core/app/models/rafelo/core/capability_map.rb` | `bundle exec rspec spec/core/flags_spec.rb` | enforced |
| SEC-07 | Data and supply-chain hygiene | `Dockerfile` · `config/bundler-audit.yml` · `script/ci/deploy_preflight` · `.gitignore` | `bundle exec brakeman` · `bundle exec bundler-audit` · `npm audit --audit-level=high` | enforced (synthetic data: review) |
| SEC-08 | Session lifecycle | `engines/core/app/models/rafelo/core/session.rb` · `engines/core/app/jobs/rafelo/core/session_sweep_job.rb` | `bundle exec rspec spec/core/session_spec.rb spec/core/session_recurring_spec.rb` | enforced (the effect of `fillfactor`: verify when adopting) |
| SEC-09 | Clear client history on sign-out | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `config/initializers/inertia_rails.rb` | `bundle exec rspec spec/requests/session_flow_spec.rb` | enforced |
| SEC-10 | Calls on behalf of a viewer use the viewer's token | `engines/core/app/models/rafelo/core/gateway.rb` · `engines/core/app/models/rafelo/core/viewer_token_provider.rb` | `bundle exec rspec spec/core/gateway_spec.rb spec/requests/authorization_spec.rb` | enforced |
| SEC-11 | Redirect targets are internal | `engines/core/app/models/rafelo/core/return_to.rb` · `script/ci/cops/rafelo/return_to_only_in_value_object.rb` | `bundle exec rspec spec/core/return_to_spec.rb` · `bin/rubocop` | enforced |
| SEC-12 | Development and test routes do not exist in production | `engines/core/app/models/rafelo/core/production_routes.rb` · `config/production_routes.yml` · `script/ci/production_routes` | `script/ci/production_routes` · `script/ci/production_routes_canary` | enforced |
| SEC-13 | Security headers and first-party assets | `config/initializers/security_headers.rb` · `engines/core/app/models/rafelo/core/exceptions_app.rb` | `bundle exec rspec spec/requests/security_headers_spec.rb spec/requests/errors_spec.rb` | enforced (proxy body limit: verify when adopting) |
| SEC-14 | Outbound requests are constrained | `engines/core/app/models/rafelo/core/upstream_client.rb` · `script/ci/cops/rafelo/no_tls_verify_disable.rb` | `bundle exec rspec spec/core/upstream_client_spec.rb` · `bin/rubocop` | enforced |
| SEC-15 | Permission grants stay fresh | `engines/core/app/models/rafelo/core/session_refresher.rb` · `engines/core/app/models/rafelo/core/session.rb` | `bundle exec rspec spec/requests/grants_refresh_spec.rb spec/core/grants_concurrency_spec.rb` | enforced |
| SEC-16 | Persisted formats survive two releases | `lib/tasks/formats.rake` · `engines/core/app/models/rafelo/core/release.rb` · `spec/fixtures/formats` | `RAILS_ENV=test bin/rails formats:check` · `bin/ci` | enforced |

### Contracts (`04_contracts.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| CT-01 | The page envelope | `engines/core/app/frontend/contracts/page_props.schema.ts` · `engines/core/app/models/rafelo/core/page_props.rb` | `npm run contracts:check` · `bin/packwerk check` | enforced |
| CT-02 | Nulls and arrays | `engines/core/app/frontend/contracts/page_props.schema.ts` · `engines/core/app/models/rafelo/core/urls.rb` · `spec/support/page_matchers.rb` | `bundle exec rspec spec/requests` · `npm run typecheck` | enforced |
| CT-03 | Zod is the source of truth | `engines/*/config/contracts` · `script/docs` · `package.json` | `npm run contracts:check` · `npm run contracts:generate` | enforced (`$ref`/`$defs` output stability: verify when adopting) |
| CT-04 | Parse at the page boundary | `app/frontend/lib/page_resolver.tsx` · `app/frontend/pages` | `npm run pages:check` · `npm run typecheck` | enforced |
| CT-05 | How a contract changes | `.github/pull_request_template.md` · `script/ci/title` | `script/ci/title` · `script/ci/title_canary` | review (PR title lint: enforced) |
| CT-06 | Error catalogs are split by owner | `config/errors.yml` · `engines/*/config/errors.yml` · `engines/core/app/models/rafelo/core/error_catalog.rb` | `npm run errors:check` · `bundle exec rspec spec/requests/errors_spec.rb` | enforced |
| CT-07 | Rails translates flash and field errors | `engines/core/app/models/rafelo/core/exceptions_app.rb` · `engines/core/app/controllers/rafelo/core/base_controller.rb` | `bundle exec rspec spec/requests/errors_spec.rb spec/requests/idempotency_spec.rb` | tested in kernel |
| CT-08 | The translation catalog | `config/locales.yml` · `engines/*/config/locales` · `engines/*/app/frontend/locales` | `npm run i18n:check` · `npm run i18n:generate` | enforced |
| CT-09 | Documentation tables are generated | `script/docs` · `config/docs.yml` · `docs/contracts.md` | `npm run docs:check` · `npm run docs:canary` | enforced |
| CT-10 | Props are visible to the viewer | `engines/core/app/frontend/contracts/page_props.schema.ts` · `engines/*/app/frontend/pages/*.schema.ts` | `npm run contracts:check` · `bundle exec rspec spec/requests` | enforced + review |
| CT-11 | Deferred and optional props | `script/ci/page_props` · `engines/core/app/frontend/contracts/page_props.schema.ts` | `script/ci/page_props` · `npm run pages:check` | enforced (deferred-prop cross-check: verify when adopting) |
| CT-12 | Deploys never mix contracts | `engines/core/app/models/rafelo/core/asset_version.rb` · `engines/core/app/models/rafelo/core/release.rb` · `.github/workflows/release.yml` | `bundle exec rspec spec/core/asset_version_spec.rb spec/config/formats_spec.rb` | enforced |
| CT-13 | Shared props have their own budget | `engines/core/app/models/rafelo/core/shared_props.rb` · `config/budgets.yml` | `bundle exec rspec spec/core/shared_props_spec.rb` · `bin/ci` | enforced |

### Frontend (`05_frontend.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| FE-01 | Respect the layers | `app/frontend/pages` · `app/frontend/screens` · `engines/example_orders/app/frontend/containers` · `app/frontend/components` | `npm run typecheck` · `npm run pages:check` | enforced |
| FE-02 | Layouts are persistent and chosen by name | `app/frontend/layouts` · `app/frontend/lib/layout_name.ts` · `app/frontend/lib/page_resolver.tsx` | `npm run typecheck` · `npm test` | enforced |
| FE-03 | One router, no second data layer | `app/frontend/entrypoints/application.tsx` · `config/initializers/inertia_rails.rb` | `npm run typecheck` · `npm test` | enforced |
| FE-04 | Local state goes through two core wrappers | `engines/core/app/frontend/lib/use_ui_state.ts` · `engines/core/app/frontend/lib/use_domain_reducer.ts` | `npm test` · `script/ci/frontend_state_canary` | enforced |
| FE-05 | Imports, files, and names | `package.json` · `.dependency-cruiser.cjs` · `tsconfig.base.json` | `bin/packwerk check` · `npm run arch:check` · `npm run typecheck` | enforced (type-export selector: verify when adopting) |
| FE-06 | Tailwind with the full palette plus semantic tokens | `engines/design_system/app/frontend/theme.css` · `config/initializers/assets.rb` | `script/ci/frontend_boundary` · `npm test` | enforced (design_system's own `tv`: review) |
| FE-07 | Controls come from a domain-free design system | `engines/design_system/app/frontend/button.tsx` · `engines/design_system/app/frontend/text_field.tsx` · `engines/design_system/app/frontend/dialog.tsx` | `npm test` · `npm run typecheck` | enforced |
| FE-08 | Charts use ECharts through one wrapper | `engines/design_system/app/frontend/chart.tsx` · `engines/design_system/app/frontend/data_table.tsx` | `npm test` · `script/ci/frontend_boundary` | enforced (within design_system: review) |
| FE-09 | Test ids are required props | `engines/design_system/app/frontend/button.tsx` · `app/frontend/components` · `engines/*/app/frontend` | `npm test` · `script/ci/test_selectors` | enforced |
| FE-10 | React Compiler, no default memoization | `vite.config.mts` · `app/frontend/entrypoints/application.tsx` | `npm run build` · `bin/ci` | enforced |
| FE-11 | Copy, formats, and Thai typography | `engines/design_system/app/frontend/formatters.ts` · `engines/core/app/models/rafelo/core/date_formatter.rb` | `npm test` · `script/ci/frontend_formatters` | enforced (formatting APIs) · verify when adopting (`jsx-no-literals` options) · review (typography) |
| FE-12 | Keep the stack small | `package.json` · `package-lock.json` · `Gemfile.lock` | `script/ci/bundle_budget` · `npm run build` | enforced (new library approval: review) |
| FE-13 | Page changes are announced and focused | `app/frontend/layouts/page_announcer.tsx` · `app/frontend/layouts/layout_root.tsx` | `npm test` · `npm run e2e` | enforced |
| FE-14 | Locale-aware widgets, calendars, and time zones | `engines/design_system/app/frontend/date_field.tsx` · `engines/design_system/app/frontend/formatters.ts` | `npm test` · `npm run e2e` | enforced |
| FE-15 | Every page has an error boundary | `engines/design_system/app/frontend/error_boundary.tsx` · `app/frontend/layouts` | `npm test` · `npm run e2e` | enforced |
| FE-16 | Loading feels fast and stays small | `engines/design_system/app/frontend/skeleton.tsx` · `engines/design_system/app/frontend/deferred.tsx` · `script/ci/bundle_budget` | `script/ci/bundle_budget` · `npm run build` | enforced |
| FE-17 | Icons go through one map | `engines/design_system/app/frontend/icon.tsx` · `config/initializers/modules.rb` | `npm test` · `bundle exec rspec spec/core/modules_spec.rb` | enforced |
| FE-18 | No raw HTML, no unsafe URLs | `engines/design_system/app/frontend/safe_url.ts` · `engines/design_system/app/frontend/link.tsx` | `npm test` · `bundle exec rspec spec/requests` | enforced |
| FE-19 | Evergreen browsers only | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `config/initializers/content_security_policy.rb` | `bundle exec rspec spec/requests/browser_spec.rb` | enforced |
| FE-20 | Thai shows the Buddhist Era everywhere | `engines/core/app/models/rafelo/core/date_formatter.rb` · `engines/design_system/app/frontend/formatters.ts` | `bundle exec rspec spec/core/date_formatter_spec.rb` · `npm test` | enforced (formatting APIs) · tested in kernel (exports) · review (year arithmetic, flash interpolation) |
| FE-21 | The design system's public API is checked | `engines/design_system/api.d.ts` · `engines/design_system/app/frontend/public/index.ts` | `npm run api:check` | enforced (behaviour change behind an unchanged API: review) |

### Frontend objects (`06_frontend_oop.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| OOP-01 | React code is functional | `app/frontend/screens` · `engines/*/app/frontend/domain` | `npm test` · `npm run typecheck` | enforced |
| OOP-02 | Where classes live | `engines/*/app/frontend/domain` · `engines/*/app/frontend/forms` | `npm run typecheck` · `npm test` | review |
| OOP-03 | Classes are immutable; only invariants throw | `engines/core/app/frontend/domain/domain_error.ts` · `engines/core/app/frontend/lib/assert_plain.ts` | `npm test` · `npm run typecheck` | review (`prefer-readonly`: enforced) |
| OOP-04 | Domain code is framework-free | `engines/core/app/frontend/domain` · `engines/*/app/frontend/domain` | `npm test` · `npm run typecheck` | enforced |
| OOP-05 | Class instances never enter React | `engines/core/app/frontend/lib/assert_plain.ts` | `npm test` · `script/ci/frontend_boundary` | tested in kernel · review |
| OOP-06 | Hooks are the bridge | `engines/core/app/frontend/hooks/use_date_range.ts` · `engines/core/app/frontend/lib/use_ui_state.ts` | `npm test` | review |
| OOP-07 | State changes only through domain methods | `engines/core/app/frontend/lib/use_domain_reducer.ts` · `engines/*/app/frontend/domain` | `npm test` | tested in kernel (freeze) · review (delegation) |
| OOP-08 | The server decides | `engines/core/app/frontend/contracts/page_props.schema.ts` · `engines/core/app/models/rafelo/core/capability_map.rb` | `npm run contracts:check` · `bundle exec rspec` | review |
| OOP-09 | Composition over inheritance | `engines/design_system/app/frontend` · `app/frontend/components` | `npm test` · review | review |
| OOP-10 | Test each side on its own terms | `spec/support` · `engines/*/app/frontend/domain/*.test.ts` | `bundle exec rspec` · `npm test` | verify when adopting (round-trip coverage: review) |

### Testing (`07_testing.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| TS-01 | Choose the cheapest useful level | `spec` · `engines/*/spec` · `e2e` | `bundle exec rspec` · `npm test` · `npm run e2e` | review |
| TS-02 | Every page proves its contract and budgets | `spec/support/page_matchers.rb` · `spec/requests` | `bundle exec rspec spec/requests` | enforced |
| TS-03 | Fake each upstream, check it for drift | `spec/upstream` · `engines/core/spec/fake_upstream_app.rb` | `bundle exec rspec spec/upstream` | enforced |
| TS-04 | Tests select by role and name, or by test id | `engines/design_system/app/frontend/*.test.tsx` · `spec/support/page_matchers.rb` | `npm test` · `bundle exec rspec spec/requests` | enforced |
| TS-05 | No duplicate or skipped assertions | `script/ci/skips` · `script/ci/cops_canary` · `spec/enforcement` | `script/ci/skips` · `script/ci/enforcement_canaries` | enforced (guard-spec quality: review) |
| TS-06 | Generators are tested by running them | `spec/generators` · `script/ci/generator_smoke` | `script/ci/generator_smoke` · `bundle exec rspec spec/generators` | enforced |
| TS-07 | Every custom enforcement rule proves it fires | `script/ci/enforcement_canaries` · `spec/enforcement/fixtures` | `script/ci/enforcement_canaries` | enforced |
| TS-08 | Accessibility is checked automatically | `e2e` · `playwright.config.ts` | `npm run e2e` | enforced |
| TS-09 | The suite runs in parallel within time budgets | `.github/workflows/ci.yml` · `config/ci.rb` · `script/ci/affected` | `bin/ci` · `script/ci/affected` | enforced |
| TS-10 | Concurrency specs run in their own lane | `spec/support/concurrency.rb` · `.github/workflows/ci.yml` | `bin/ci (concurrency lane)` · `bundle exec rspec spec/core/idempotency_concurrency_spec.rb` | enforced (tagging, forced interleaving: review) |
| TS-11 | The design system has visual regression tests | `script/ci/e2e` · `e2e` · `engines/design_system` | `npm run e2e` · `script/ci/e2e --update-snapshots` | enforced (own color tables: review) |

### Generators (`08_generators.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| GEN-01 | `rafelo:module` creates a product module wired through the registry | `engines/core/lib/generators/rafelo/module/module_generator.rb` | `bundle exec rspec spec/generators` · `script/ci/generator_smoke` | enforced (migration-path initializer: verify when adopting) |
| GEN-02 | `rafelo:page` creates a complete, passing slice | `engines/core/lib/generators/rafelo/page/page_generator.rb` | `bundle exec rspec spec/generators` · `script/ci/generator_smoke` | enforced |
| GEN-03 | Templates read contracts instead of copying them | `template/template.rb` · `engines/core/lib/generators` | `script/ci/generator_smoke` · `bin/ci` | enforced (templates reading their sources: review) |
| GEN-04 | CI runs the generators end to end | `script/ci/generator_smoke` · `.github/workflows/ci.yml` | `script/ci/generator_smoke` | enforced |
| GEN-05 | `rafelo:domain` creates a domain engine | `engines/core/lib/generators/rafelo/domain/domain_generator.rb` | `bundle exec rspec spec/generators` | enforced |
| GEN-06 | Modules can be renamed, split, and moved | `engines/core/lib/generators/rafelo/rename_module/rename_module_generator.rb` · `engines/core/lib/generators/rafelo/move_page/move_page_generator.rb` | `bundle exec rspec spec/generators` · `script/ci/generator_smoke` | enforced |
| GEN-07 | Adoption by application template; tracked kernel updates | `template/template.rb` · `bin/kernel_update` · `script/ci/kernel_update` | `script/ci/adoption` · `script/ci/kernel_update` · `script/ci/generator_smoke` | tested in kernel |
| GEN-08 | The example engines are examples | `engines/example_orders` · `engines/example_customers` · `script/ci/example_removal` | `script/ci/example_removal` | enforced (removal: tested in kernel) |
| GEN-09 | Generators are all or nothing | `engines/core/lib/generators/rafelo/base/base_generator.rb` | `bundle exec rspec spec/generators` · `script/ci/generator_smoke` | enforced |

### Workflow (`11_workflow.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| WF-01 | Issues describe one deliverable outcome | `.github/ISSUE_TEMPLATE/implementation.yml` | `.github/ISSUE_TEMPLATE/implementation.yml` | review |
| WF-02 | One issue, one pull request | `.github/pull_request_template.md` · `.github/workflows/pull_request.yml` | `script/ci/title` · `.github/workflows/pull_request.yml` | review |
| WF-03 | Titles, merges, and `main` | `.github/rulesets/main.json` · `script/ci/title` · `script/ci/ratchet` · `script/ci/guard_approval` | `script/ci/title_canary` · `script/ci/ratchet_canary` · `script/ci/guard_approval_canary` | enforced (plan features: verify when adopting; without branch protection: convention) |
| WF-04 | Review gates at the end of a slice | `.github/ISSUE_TEMPLATE/review_gate.yml` | `.github/ISSUE_TEMPLATE/review_gate.yml` | review |
| WF-05 | Releases come from `VERSION` | `VERSION` · `script/ci/release` · `script/ci/release_check` · `.github/workflows/release.yml` | `script/ci/release_check` · `script/ci/release_canary` | enforced (tag ruleset bypass actor, releasing a commit that changes `.github/workflows/`: verify when adopting) |
| WF-06 | Dependencies are exact and upgraded deliberately | `Gemfile` · `package.json` · `.github/dependabot.yml` | `script/ci/actions_pinned` · `script/ci/bundle_budget` | enforced |
| WF-07 | CI and the supply chain are hardened | `.github/workflows` · `script/ci/actions_pinned` · `script/ci/workflow_policy` | `script/ci/actions_pinned` · `script/ci/workflow_policy` | enforced (Renovate config: review) |

### Operations (`13_operations.md`)

| Rule | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| OPS-01 | Structured, safe logs | `engines/core/app/models/rafelo/core/log_payload.rb` · `engines/core/app/models/rafelo/core/request_log.rb` | `bundle exec rspec spec/core/log_payload_spec.rb spec/requests/logging_spec.rb` | enforced |
| OPS-02 | W3C trace context from end to end | `engines/core/lib/rafelo/core/trace_middleware.rb` · `engines/core/app/models/rafelo/core/current.rb` · `engines/core/app/models/rafelo/core/upstream_client.rb` | `bundle exec rspec spec/core/trace_middleware_spec.rb spec/requests/early_error_trace_spec.rb` | enforced |
| OPS-03 | Errors are reported from both sides | `engines/core/app/models/rafelo/core/error_reporter.rb` · `engines/core/app/models/rafelo/core/client_error_report.rb` · `engines/core/app/models/rafelo/core/exceptions_app.rb` | `bundle exec rspec spec/requests/error_reporting_spec.rb spec/requests/client_errors_spec.rb` | enforced |
| OPS-04 | Measure what matters for a BFF | `engines/core/app/models/rafelo/core/metrics.rb` · `engines/core/app/models/rafelo/core/reporting_service.rb` · `app/controllers/core/metrics_controller.rb` | `bundle exec rspec spec/requests/metrics_spec.rb` | review |
| OPS-05 | Liveness never depends on an upstream | `config/routes.rb` · `app/controllers/core/ready_controller.rb` | `bundle exec rspec spec/requests/health_spec.rb spec/requests/health_check_spec.rb` | enforced |
| OPS-06 | Two deployment profiles with Kamal | `config/deploy.yml` · `config/deploy.multi.yml` · `Dockerfile` | `script/ci/deploy_preflight` · `script/ci/deploy_preflight_canary` | enforced (preflight, image build) · review (deploy profile) |
| OPS-07 | Backups and retention | `docs/operations/backup-restore.md` · `engines/core/app/models/rafelo/core/restore_preparation.rb` · `engines/core/app/jobs/rafelo/core/session_sweep_job.rb` | `bundle exec rspec spec/core/restore_preparation_spec.rb spec/config/retention_spec.rb` | review (drill) · enforced (job specs) |
| OPS-08 | Audit the events that matter | `engines/core/app/models/rafelo/core/audit_event.rb` · `engines/core/app/models/rafelo/core/audit_recorder.rb` · `engines/core/app/models/rafelo/core/audit_partitions.rb` | `bundle exec rspec spec/core/audit_spec.rb spec/core/audit_partitions_spec.rb` | enforced (trigger on every partition with the pinned PostgreSQL, structure dump flags: verify when adopting; what the migration role does to audit rows: review) |
| OPS-09 | Development runs in a Dev Container | `.devcontainer` · `mise.toml` · `script/ci/pins` · `.github/workflows/devcontainer.yml` | `script/ci/pins` · `bin/ci` | enforced (vite_ruby host option: verify when adopting) |

## ADRs

| ADR | Title | Code | Evidence | Status |
| --- | --- | --- | --- | --- |
| ADR-01 | Rails is a BFF in front of the upstream APIs | `engines/core/app/models/rafelo/core/upstream_client.rb` · `config/upstreams.yml` | `bundle exec rspec spec/core/upstream_client_spec.rb` · `bin/ci` | accepted |
| ADR-02 | Inertia and React, one router | `app/frontend/entrypoints/application.tsx` · `config/initializers/inertia_rails.rb` | `npm run typecheck` · `npm test` | accepted |
| ADR-03 | Rails engines are module boundaries | `package.yml` · `engines/core/lib/generators/rafelo/module/module_generator.rb` | `bin/packwerk check` · `script/ci/generator_smoke` | accepted |
| ADR-04 | One module registry | `engines/core/app/models/rafelo/core/modules.rb` · `config/initializers/modules.rb` | `bundle exec rspec spec/core/modules_spec.rb` | accepted |
| ADR-05 | Rails conventions first | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `app/controllers/application_controller.rb` | `bin/ci` | accepted |
| ADR-06 | Props are a typed contract | `engines/core/app/frontend/contracts/page_props.schema.ts` · `engines/core/app/models/rafelo/core/page_props.rb` | `npm run contracts:check` | accepted |
| ADR-07 | snake_case in Ruby, camelCase in JSON | `engines/core/app/controllers/rafelo/core/base_controller.rb` · `engines/core/app/models/rafelo/core/page_props.rb` | `bundle exec rspec spec/requests` | accepted |
| ADR-08 | Policies and a server-owned capability map | `engines/core/app/models/rafelo/core/capability_map.rb` · `engines/core/app/policies` | `bundle exec rspec spec/core/capability_map_spec.rb spec/core/base_policy_spec.rb` | accepted |
| ADR-09 | Server-side sessions and a protected edge | `engines/core/app/models/rafelo/core/session.rb` · `config/initializers/session_store.rb` | `bundle exec rspec spec/core/session_spec.rb` | accepted |
| ADR-10 | PostgreSQL and the Solid trio | `config/database.yml` · `config/cache.yml` · `config/queue.yml` · `config/cable.yml` | `bundle exec rspec spec/core/connections_spec.rb spec/config` | accepted |
| ADR-11 | Tailwind CSS and headless primitives | `engines/design_system/app/frontend/theme.css` · `engines/design_system/app/frontend/button.tsx` | `npm test` · `npm run e2e` | accepted |
| ADR-12 | ECharts and TanStack Table behind wrappers | `engines/design_system/app/frontend/chart.tsx` · `engines/design_system/app/frontend/data_table.tsx` | `npm test` · `script/ci/frontend_boundary` | accepted |
| ADR-13 | Frontend layers and persistent layouts | `app/frontend/layouts` · `app/frontend/lib/page_resolver.tsx` | `npm run pages:check` · `npm test` | accepted |
| ADR-14 | Functional React, object-oriented domain | `engines/core/app/frontend/lib/use_domain_reducer.ts` · `engines/core/app/frontend/domain` | `npm test` · `npm run typecheck` | accepted |
| ADR-15 | Local state through two wrappers | `engines/core/app/frontend/lib/use_ui_state.ts` · `engines/core/app/frontend/lib/use_domain_reducer.ts` | `npm test` | accepted |
| ADR-16 | React Compiler | `vite.config.mts` · `package.json` | `npm run build` · `bin/ci` | accepted |
| ADR-17 | Configured locales, English by default | `config/locales.yml` · `engines/core/app/models/rafelo/core/locales.rb` | `npm run i18n:check` · `bundle exec rspec spec/core/locale_middleware_spec.rb` | accepted |
| ADR-18 | Exact versions | `Gemfile.lock` · `package-lock.json` · `.github/dependabot.yml` | `script/ci/actions_pinned` · `script/ci/bundle_budget` | accepted |
| ADR-19 | Small changes and an always-green `main` | `.github/workflows/ci.yml` · `script/ci/ratchet` | `bin/ci` · `script/ci/ratchet` | accepted |
| ADR-20 | Test at the cheapest useful level | `spec` · `engines/*/spec` · `e2e` | `bundle exec rspec` · `npm test` · `npm run e2e` | accepted |
| ADR-21 | The shared frontend kit is split between core and design_system | `engines/core/app/frontend` · `engines/design_system/app/frontend` | `npm test` · `npm run api:check` | accepted |
| ADR-22 | No server-side rendering | `app/frontend/entrypoints/application.tsx` · `config/initializers/inertia_rails.rb` | `npm run e2e` | accepted |
| ADR-23 | Realtime carries signals, not data | `config/cable.yml` · `app/controllers` · `engines/*/app/controllers` | `bin/ci` | accepted |
| ADR-24 | Accessibility target: WCAG 2.2 AA | `engines/design_system/app/frontend` · `e2e` | `npm run e2e` | accepted |
| ADR-25 | Observability on W3C trace context | `engines/core/lib/rafelo/core/trace_middleware.rb` · `engines/core/app/models/rafelo/core/current.rb` | `bundle exec rspec spec/core/trace_middleware_spec.rb` | accepted |
| ADR-26 | Deploy with Kamal in two profiles | `config/deploy.yml` · `config/deploy.multi.yml` · `Dockerfile` | `script/ci/deploy_preflight` | accepted |
| ADR-27 | Copy-in kernel with a tracked version | `template/template.rb` · `bin/kernel_update` · `script/ci/kernel_update` | `script/ci/kernel_update` · `script/ci/adoption` | accepted |
| ADR-28 | Development in a Dev Container | `.devcontainer` · `mise.toml` | `script/ci/pins` · `bin/ci` | accepted |
| ADR-29 | Growth has budgets | `config/budgets.yml` · `script/ci/growth` | `script/ci/growth` · `script/ci/growth_canary` | accepted |
| ADR-30 | Upstream resilience (named upstreams, breakers, bulkheads; a default breaker library) | `engines/core/app/models/rafelo/core/upstream_client.rb` · `engines/core/app/models/rafelo/core/bulkhead.rb` · `engines/core/app/models/rafelo/core/executor.rb` | `bundle exec rspec spec/core/upstream_client_spec.rb spec/core/bulkhead_spec.rb` | accepted |
| ADR-31 | Changes are compatible across two releases (migrations, stored formats, contracts) | `engines/core/app/models/rafelo/core/asset_version.rb` · `lib/tasks/formats.rake` · `engines/*/config/contracts` | `RAILS_ENV=test bin/rails formats:check` · `npm run contracts:check` | accepted |
| ADR-32 | Tools guard, people decide, AI builds | `docs/architecture/14_working_with_ai.md` · `AGENTS.md` · `.opencode/skills` | `npm run docs:check` · `bin/ci` | accepted |
