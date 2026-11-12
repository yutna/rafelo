# 12 — Hardening

Architectures like this one tend to fail in the same few ways: conventions
drift away from the code that is supposed to follow them, the same fact is
stored in several places, and rules that nothing checks quietly stop being
true. Each row below names a failure mode, the rule that prevents it, and what
enforces that rule. Rule text lives in the topic files; this table only points
to it. Rows 58 onward cover what appears at scale: many engines, several
hosts, deploys that overlap two releases, and AI agents writing much of the
code. Rows 108 to 126 mostly cover ways the enforcement mechanisms themselves
can fail. Rows 127 onward come from the first implementation of Rafelo:
failures it actually hit or narrowly missed.

| # | Failure mode | Prevented by | Enforced by |
| --- | --- | --- | --- |
| 1 | Generators fall behind the contract or routing, so every new module starts broken while their text-only specs stay green | ARCH-06, GEN-01, GEN-03, GEN-04, TS-06 | generator smoke on triggering pull requests and nightly |
| 2 | A rule, `AGENTS.md`, or an AI instruction file keeps citing a decision that was later reversed, or an ID that does not exist | CT-09, ADR lifecycle in `10_decisions.md` | `npm run docs:check` |
| 3 | Documentation describes a different props envelope from the schema | CT-09 | generated doc sections + `--check` |
| 4 | Mounting, navigation, and permissions are declared in separate places and diverge | ARCH-06 | registry entry in each module's `engines/<module>/config/module.rb`; routes and navigation derived from it; boot validation |
| 5 | The app shell is rendered at different layers on different pages, or a module page cannot pick a frame without importing app code | FE-02 | layouts chosen by name + dependency-cruiser `only-resolver-picks-layouts` + generated engine rules |
| 6 | A page skips the screen layer and grows into a god component | FE-01 | dependency-cruiser `pages-render-screens` |
| 7 | A demo or debug flag silently elevates real accounts | SEC-06 | boot guard + spec |
| 8 | A rule cannot be checked mechanically, so a lint message points at a helper nobody wrote | FE-04 | `useDomainReducer` and `useUiState` exist in `@core/lib`, reject primitives by type, and are the only files outside design_system allowed React's state hooks |
| 9 | Two overlapping permission maps disagree | CT-01 (`can` only, typed keys) | `definePage` strict `can` + page schemas |
| 10 | Props objects read request globals and become hard to test | BE-04, BE-09 | `Rafelo/CurrentAtTheEdge` |
| 11 | A list is fetched whole and filtered or paged in memory | BE-07 | `ListQuery` + props budget at the maximum page size |
| 12 | Every spec invents its own query and size limits | TS-02 | `config/budgets.yml` defaults + per-engine page overrides (count ratcheted) |
| 13 | camelCase keys are typed by hand and drift from the schema | ADR-07 | `prop_transformer` + schema validation |
| 14 | `VERSION`, tags, and releases disagree after a cancelled release | WF-05 | release workflow checks + one Releases API call (a tag without a Release gets its Release) + the next green push to `main` retries + `VERSION` check on the release pull request |
| 15 | Single-flight token refresh holds a row lock or an open transaction across the upstream refresh, so a slow upstream stalls every request for that session | SEC-03, BE-20 | one conditional claim on `refresh_version` + concurrency spec + `UpstreamClient` transaction guard in tests |
| 16 | A misspelled Tailwind class produces no CSS and no error | FE-06 | `better-tailwindcss/no-unknown-classes` with `entryPoint` |
| 17 | Raw HTML controls bypass accessibility wiring and test ids | FE-07 | `react/forbid-elements` outside design_system |
| 18 | Class instances leak into React state and break re-rendering or serialization | OOP-05 | plain-data assertion in both state wrappers + hook tests |
| 19 | Upstream responses change shape and nobody notices until production | TS-03 | scheduled drift job per named upstream |
| 20 | Untranslated copy ships because one locale lags | CT-08, GEN-02 | parity check + visible `[<locale>]` placeholders + release check (WF-05) |
| 21 | A dependency range resolves to an untested version, or one package of a peer set moves alone | WF-06 | `script/ci/pins` (exact npm values; git gems by full SHA; gemspecs without constraints) + lockfiles + Renovate peer groups |
| 22 | An engine imports the app's code or reaches past its declared dependencies, so the dependency direction silently inverts | ARCH-04, ARCH-08 | generated dependency-cruiser engine rules + `bin/packwerk check` |
| 23 | An architecture or lint rule has a wrong pattern and checks nothing while CI stays green | TS-07 | canary fixtures |
| 24 | A tab left open across a deploy feeds new props to old JavaScript | CT-12 | Inertia asset version checked on GET visits |
| 25 | After sign-out, the back button restores earlier pages from client history | SEC-09 | history encryption + clearing |
| 26 | A privileged service token fetches data on a viewer's behalf and bypasses upstream checks | SEC-10 | service-token allow-list spec per upstream |
| 27 | A session token survives sign-in or never expires | SEC-08 | session lifecycle specs |
| 28 | `return_to` sends users to another site | SEC-11 | `ReturnTo` spec + `Rafelo/ReturnToOnlyInValueObject` |
| 29 | Fake upstream or test sign-in routes ship to production | SEC-12 | `script/ci/production_routes` as a dummy boot (`.env.ci.production`, dummy credentials) |
| 30 | Viewer-specific data is cached under a shared key and shown to someone else | BE-17 | `ScopedCache` + `Rafelo/CacheOnlyThroughScopedCache` |
| 31 | One page calls the upstream once per row and becomes slow under load | BE-16 | upstream call budget + deadline |
| 32 | User input steers an upstream request to another host | SEC-14 | client specs + `Rafelo/FaradayOnlyInUpstreamClient` + `Rafelo/NoTlsVerifyDisable` |
| 33 | Props expose fields the viewer should not see | CT-10 | strict schemas (a prop outside the schema fails its request spec) + review |
| 34 | A double click or retry creates two upstream records; a stale edit overwrites a newer one | BE-15 | idempotency key + `resource.conflict` |
| 35 | camelCase params arrive where snake_case is expected and strong parameters drop them | BE-14 | request spec |
| 36 | Screen-reader users get no signal that the page changed, hear the previous page's title, or land in a `bare` page with no page announcer | FE-13 | layout tests (every layout) + announcement test + axe |
| 37 | A page crashes to a blank screen and nobody hears about it | FE-15, OPS-03 | resolver test + client error endpoint |
| 38 | `Current` is empty inside concurrent upstream calls | BE-16, BE-09 | bounded executor receives context explicitly + `Rafelo/ConcurrencyOnlyInExecutor` + concurrency spec |
| 39 | An upstream outage makes the health check fail and the proxy restarts healthy Rails | OPS-05 | `/up` spec |
| 40 | The app outgrows one host without anyone deciding to, or adding hosts needs code changes | OPS-06, ARCH-13, ADR-26 | two deploy profiles + no host-local state + connection-pool and latency metrics (OPS-04) |
| 41 | A failed or conflicting write renders a page from a POST and the form state is lost | BE-13 | core write-flow specs against `engines/core/spec/dummy_engine` + generator templates run by GEN-04 |
| 42 | Two simultaneous submits both pass a cache check and create two upstream records | BE-15 | unique token claim + concurrency spec |
| 43 | A background job has no viewer token and quietly falls back to the service token | BE-19, SEC-10 | job specs |
| 44 | Rails' own session survives sign-in, or redirect errors overflow the session cookie | SEC-08 | `reset_session` specs + cookie-size spec |
| 45 | Grants revoked upstream stay active in Rails until the next sign-in | SEC-15 | grant freshness specs |
| 46 | HTML or a `javascript:` URL from data executes in the page | FE-18 | `react/no-danger` + `isSafeUrl` |
| 47 | A loose CSP allows inline scripts, or a strict one breaks development | SEC-05 | CSP header specs + a per-request nonce (`SecureRandom.base64(16)`, never the session id), also on the tags Vite injects in development: `vite_client_tag` and `vite_typescript_tag` with `nonce: true`, `vite_react_refresh_tag` by itself, and `<meta property="csp-nonce" nonce>` for Vite's client · `createInertiaApp({ nonce })` for the progress bar |
| 48 | URL helpers in mounted engines drop the locale prefix, or `default_url_options` turns it into `?locale=` | ARCH-07 | URL helper spec (engine and `main_app` helpers under `/th`) |
| 49 | A cursor-paginated upstream is forced into page numbers with an invented total | BE-07, CT-01 | pagination union in the schema |
| 50 | Clock differences let a token expire in the middle of a call | SEC-03 | early-expiry margin spec |
| 51 | Behind a proxy every request shares one IP, so rate limits and audit records are wrong | OPS-06 | trusted proxy configuration |
| 52 | Threads running upstream calls leak database connections or miscount the budget | BE-16, BE-21 | bounded executor + thread-safe counter spec + connection arithmetic spec |
| 53 | A sibling subdomain overwrites the session cookie | SEC-01 | `__Host-` cookie spec |
| 54 | Oversized request bodies tie up the app | SEC-13 | proxy body limit |
| 55 | An upstream failure leaves an idempotency claim pending and blocks every retry | BE-15 | claim states + retry spec |
| 56 | Monitors or crash reports are blocked by authentication, or a new endpoint quietly skips it | BE-02 | explicit skip list spec |
| 57 | A token refresh on a page request makes the upstream budget fail at random | BE-16, TS-02 | refreshes and the resend after them counted separately |
| 58 | A kernel engine becomes the hub that nearly every pull request touches, so affected-only CI rarely narrows | ARCH-12, ARCH-05 | scheduled `script/ci/touch_rate` (from three product modules on, not counting the examples) opens an issue above the budget + core and design_system size budgets + code owners |
| 59 | Two engines come to depend on each other, directly or through a third, or files inside one engine import each other in a loop | ARCH-08 | `bin/packwerk validate` + `tsc -b` references + `bin/packwerk check` + generated dependency-cruiser rules + `no-circular` + cycle canaries |
| 60 | An engine references another engine's private constants or files, so its internals become an unplanned interface | ARCH-09 | packwerk-extensions privacy + generated public-surface rules + `Rafelo/NoKernelInternals` and `kernel-internals-stay-inside` for kernel `internal/` folders + canaries |
| 61 | A dynamic lookup (`constantize`, `const_get`, a string `class_name:`, `@engines/`, `import.meta.glob`) hides a dependency from both graph checks | ARCH-10, ARCH-08 | `Rafelo/NoConstantize` + ESLint restrictions that allow only the page resolver |
| 62 | Engines couple through channels no constant check sees: a shared table, `config.x`, a cache key, another module's translation keys, a hard-coded URL, an event name | ARCH-10 | `Rafelo/EngineTablePrefix` + `Rafelo/ConfigXOnlyInCore` + `ScopedCache` `module:` + `i18n:check` + URLs built by Rails through `context.urls` and sent in props, with an ESLint ban on building them in TypeScript and `have_resolvable_hrefs`, which asserts that every `href`, `*Href`, and `nav[].path` was built by `Urls` |
| 63 | Code is copied between engines to avoid declaring a dependency | ARCH-05 | flay and jscpd on cross-engine pairs in `domain/`, `forms/`, `hooks/`, public surfaces, gateways, and policies, against a baseline that only shrinks (ratchet) |
| 64 | Renaming or splitting a module would break bookmarks and upstream grants, so nobody does it and the module keeps growing | GEN-06, ARCH-06, ARCH-12 | `rafelo:rename_module` and `rafelo:move_page` in GEN-04 + registry `path:`, `permission_prefixes:`, `legacy_paths:` + module size budget |
| 65 | A product module collects so many dependents that it becomes a second core, or a domain engine's public surface keeps growing | ARCH-12 | `script/ci/fan_in` (`max_dependents` on product modules) + domain-engine public-surface budget in `script/ci/growth` |
| 66 | Every feature pull request edits the same central files (error catalog, page budgets, contract schemas, upstream fixtures, registry, Gemfile), so they conflict and run everything | ARCH-11 | artifacts live in each engine + spec that root `config/budgets.yml` has no `pages:` + `errors:check` prefix ownership + fake-upstream check + Gemfile glob |
| 67 | A shared-prop change rewrites every page's JSON Schema | CT-03 | shared props emitted once to `config/contracts/_shared.json` and referenced with `$ref` + `contracts:check` |
| 68 | Affected-only CI runs everything on most pull requests, or skips an engine it should have run | ARCH-08, ARCH-12, FE-21 | `script/ci/affected` over the declared graph with an explicit global-input list + mapping canaries + design_system API file (`engines/design_system/api.d.ts`) |
| 69 | Running one engine's specs boots the whole app, and boot time grows with every module | TS-09 | `boot_seconds` budget (`bin/rails runner nil`) + bootsnap |
| 70 | The suite slows until people and agents stop running it before pushing | TS-09 | `parallel_tests` + `timeout-minutes` per job that runs steps + `bin/check <engine>` |
| 71 | A slow upstream holds every Puma thread, and retries amplify the incident into an outage of unrelated pages | BE-05, BE-16, ADR-30 | per-upstream circuit breaker, bulkhead, and retry budget + `upstream.circuit_open` + client specs |
| 72 | Puma threads, executor threads, and Solid Queue's forked supervisor, workers, and dispatchers (and the scheduler when recurring tasks are configured) exhaust the database pool or PostgreSQL `max_connections` across hosts, or timeouts fire in the wrong order | BE-21 | connection and timeout arithmetic config spec, summed over every process kind against `config/budgets.yml` → `connections:` |
| 73 | A transaction stays open while the code waits on an upstream, holding locks and a connection | BE-20 | `UpstreamClient` raises in tests when a transaction is open |
| 74 | A migration locks a busy table, or drops a column the old container still reads during a deploy | BE-22, ADR-31 | `strong_migrations` + expand/contract review |
| 75 | Audit, session, and idempotency tables grow without bound, and delete-based retention bloats them and slows the purge | OPS-07, OPS-08, SEC-08 | month-partitioned audit table (`core_audit_events`) with partition drops + batched purges + job specs |
| 76 | Audit rows are edited or deleted after the fact, or the application's own database role disables the trigger first | OPS-08 | database trigger + spec + runtime role with only `INSERT` and `SELECT` on audit tables (the migration role owns them) |
| 77 | A session row or cached value written by one release cannot be read by the other release running beside it | SEC-16, BE-17, ADR-31 | `format_version` + compatibility spec with the previous release's `spec/fixtures/formats/` folder + the release or an explicit schema version in the cache namespace |
| 78 | Permission strings are typed by hand and drift from the manifest, so a typo denies silently | BE-03 | generated permission constants + `Rafelo/NoPermissionLiterals` + `Rafelo/OwnPermissionPrefixes` |
| 79 | The upstream renames a grant, and the BFF silently denies or allows | BE-03 | one mapping file (`config/permission_mapping.yml`) + scheduled permission drift job |
| 80 | A second upstream arrives and forces special cases into budgets, tokens, fixtures, and drift checks | BE-05, BE-06, BE-08, TS-03, ADR-30 | `config/upstreams.yml` + `UpstreamClient.for` + allow-lists, fixtures, and drift jobs keyed per upstream |
| 81 | Suppressions, skips, budget overrides, and clone entries accumulate one "just this once" at a time | FE-10, TS-05, TS-02, ARCH-05 | `script/ci/ratchet` over the root and per-engine ratchet files; a raise needs an owner's approval |
| 82 | A gem upgrade silently breaks a monkey patch hidden somewhere in the code | BE-23 | patches only in `config/initializers/patches/` + guard spec on the patched gem's version |
| 83 | A new advisory turns every pull request red on the same day, so someone disables the audit | SEC-07 | audits block only lockfile changes + daily advisory job with a fix deadline + audit steps as guard files |
| 84 | An open `meta` record carries fields that no schema checks | CT-01, CT-10 | strict default `meta` + canary |
| 85 | The props budget passes on a three-item fixture while a full page overflows it | TS-02, BE-07 | `be_within_props_budget` requires `perPage` at the `ListQuery` maximum and that many items + `pages:check --matchers` |
| 86 | Shared props grow with every module and inflate every response | CT-13 | shared-props byte budget |
| 87 | A shared chunk grows the initial download of every page while entry and page-chunk budgets stay green | FE-16 | smallest-page initial-bytes budget from Vite's manifest + lazy wrapper test |
| 88 | During a deploy an open tab requests a lazy chunk the new container no longer serves, and navigation fails with a 404 | CT-12, OPS-06 | Kamal asset bridging (`asset_path: /rails/public/vite`, not the generated `/rails/public/assets`; `deploy_preflight`) |
| 89 | One unfinished module blocks everyone's release, because the application is a single deployable | BE-25, ARCH-06 | server-side flags delivered through `can` with reason `disabled` + a registry `flag:` that ships a whole module dark |
| 90 | Every design_system change runs the whole suite and waits on one owner, so the design system becomes a bottleneck | FE-21, ARCH-12 | an unchanged API file narrows CI to design_system's tests and the affected modules' Vitest component tests + design_system export budget; the remaining gap is a behaviour change behind an unchanged API, which skips RSpec and Playwright and is caught only by component tests, visual regression (TS-11), and review |
| 91 | A design_system change breaks screens in modules nobody looked at | TS-11, FE-21 | visual regression of the component catalog page + API file |
| 92 | A Thai viewer types a Gregorian year, and a date 543 years in the past is submitted | FE-20 | min and max on every date field + date field tests (2026 refused, 2569 submits 2026) |
| 93 | A chart axis, flash message, or export shows a Gregorian year to a Thai viewer | FE-20 | ESLint bans (`Intl` formatters and `toLocale*String` everywhere; `getFullYear`, `getUTCFullYear`, `getMonth`, `getDate` in presentation code, while `domain/` and `forms/` may compute with dates but never format them; `@internationalized/date` only in design_system) and `Rafelo/DateFormatterOnly` (`strftime`, `I18n.l` and `l(`, `to_fs`, `to_formatted_s`) confine formatting to `@design_system/formatters` and `Acme::Core::DateFormatter` + exports through `Acme::Core::Export`, whose spec asserts a Buddhist Era year in `th` + `th` chart and export tests, the real guard; year arithmetic and `.to_s` or `.year` in flash interpolation: review |
| 94 | Adding or removing a locale means editing literals across routes, schemas, and specs | ARCH-07, CT-08 | `config/locales.yml` + generated route constraint and locale enum |
| 95 | An adopter's kernel copy drifts from the template until fixes can no longer be applied | GEN-07, ADR-27 | `KERNEL_VERSION` + `bin/kernel_update` three-way merge + template CI (N-1 to N) |
| 96 | The example engines stay in production because other code came to depend on them | GEN-08 | dependency-cruiser `nothing-depends-on-example-engines` + `script/ci/engine_graph` + canary + template CI that deletes them |
| 97 | Development, CI, and production environments drift apart ("works on my machine") | OPS-09, ADR-28 | prebuilt Dev Container image used by CI and `devcontainer.json` by digest + Ruby pinned by the image tag and digest, Node and npm by `mise.toml` (not the Dev Container Node feature) + `script/ci/pins` asserts that `mise.toml`'s Ruby, `.ruby-version` (read by the Gemfile), the production Dockerfile's `ARG RUBY_VERSION`, and the image tag agree, and that `devcontainer.json` names the digest in `.devcontainer/image_digest`, the only place CI reads it + PostgreSQL pinned by digest |
| 98 | Two pull requests that pass alone break `main` together, or a merge queue that runs everything serialises every merge | WF-03, ADR-19 | merge queue with CI on `merge_group` + affected engines computed against the merge base (without a merge queue: "require branches to be up to date" + the required `ci-ok` check and the three `pull_request.yml` checks) |
| 99 | Concurrency specs flake under parallel, transactional runs and get retried until green | TS-10 | `:concurrency` tag + serial lane with truncation + no retries |
| 100 | A new write action ships without throttling | BE-12 | throttle macro + route-table spec |
| 101 | Adding a member to the page context breaks every place that builds one | BE-01 | core factory + `Rafelo/PageContextThroughFactory` |
| 102 | Base controller callbacks pile up in an order nobody chose | BE-24 | one callback list + order spec |
| 103 | A domain object throws on a person's input during render, and the error boundary replaces the page | OOP-03 | `issues()` for input, `throw` only for invariants (review) |
| 104 | A class loses or changes data on its way into React and back | OOP-10 | round-trip test per boundary class |
| 105 | An export written to one host's disk cannot be downloaded from another host | ARCH-13, BE-18 | exports in Active Storage + 303 to a signed URL + `Rafelo/SendStreamOnlyInDownloads` |
| 106 | Touching the session row on every request bloats the table and defeats HOT updates | SEC-08 | throttled `last_seen_at` + no index on the sliding idle expiry + `core_sessions` table `fillfactor` 70 (verify) |
| 107 | An AI agent, or a hurried person, loosens a lint rule, budget, or baseline to get a green build, and an AI review approves it | ADR-32 | code owners and human approval on guard files (`script/ci/guard_approval` where the plan has no required code-owner review; `script/ci/ratchet` for ratchet raises) + the `AGENTS.md` "Never" list |
| 108 | A referenced TypeScript project is not composite or does not emit, so `tsc -b` fails with TS6310, or a hand-edited tsconfig drifts from the declared graph | ARCH-08 | `script/ci/engine_graph` writes every generated tsconfig file (composite engine projects emitting declarations only into `tmp/tsc/<engine>`, an `app/frontend` project and `tsconfig.tooling.json` that reference every engine, a root solution file) + `--check` + `tsc -b` in `bin/check` and `bin/ci`; `npm run aliases:generate` writes the alias `paths` in `tsconfig.base.json` + `aliases:check` |
| 109 | TypeScript builds URLs by hand (a locale prefix, a module path), so a renamed route, a moved module, or a new locale leaves links that 404 while every type checks | ARCH-10, ARCH-07, FE-18, CT-02 | props objects build every URL through `context.urls` (BE-04) and send it in props + ESLint ban on template literals and concatenation that start with `/` and a segment (verify the selectors) + `have_resolvable_hrefs` in every page's request spec (`pages:check`): every `href`, `*Href`, and `nav[].path` must be a path `Urls` built for the request + `z.string().refine(isSafeUrl)` |
| 110 | A session column named `lock_version` silently turns on Active Record's optimistic locking, so the winner's save after a refresh claim raises | SEC-03 | the column is `refresh_version` + the SEC-03 spec saves the winner's tokens with a normal save after the claim |
| 111 | Each monthly audit partition rewrites `structure.sql`, so unrelated pull requests conflict and the dump differs between machines | OPS-08, ARCH-03 | audit partitions excluded from the dump (`--exclude-table=core_audit_events_*`, verify) + partitions ensured on boot in development and test and by the scheduled job in production + product modules rarely own tables |
| 112 | An audit insert for a month without a partition fails, and the write it records fails with it | OPS-08 | DEFAULT partition as a backstop, with an alert when a row lands there + partitions ensured ahead of time |
| 113 | Every CI job builds the Dev Container from its definition, so CI is slow and jobs can run on images that differ from each other and from development | OPS-09, ADR-28 | image prebuilt on `.devcontainer/**` changes (`.devcontainer/image_digest` ignored) and pushed by digest + the digest recorded only in `.devcontainer/image_digest`: a first CI job reads it and the other `ci.yml` jobs, except the production image build (Docker on the runner), run in `container: ${{ needs.image.outputs.ref }}`, so workflow YAML never contains it + `devcontainer.json` references the same digest, checked by `script/ci/pins` + the digest file `.devcontainer/image_digest` is a global input of `script/ci/affected` |
| 114 | A ratchet fall fails CI until someone commits the lower number, or a lowered ceiling waits on a code owner, so people learn to work around the ratchet | FE-10, TS-05, TS-02, ARCH-05 | only a rise fails + a scheduled job opens a pull request that lowers the counts (CI never pushes to `main`) + ratchet files have no CODEOWNERS entry, and the required ratchet check passes a diff that only lowers numbers without an owner |
| 115 | Deleting the example engines deletes the specs that proved the kernel's write flow, error responder, translated errors, and envelope | BE-13, CT-07, GEN-08 | kernel specs against `engines/core/spec/dummy_engine` + template CI that deletes the example engines and runs `bin/ci` |
| 116 | On a GitHub plan without a required merge queue or code-owner review, guard files merge without an owner and two green pull requests break `main` together | WF-03, ADR-32 | "require branches to be up to date" + the required `ci-ok` check and the three `pull_request.yml` checks, `script/ci/guard_approval` (GitHub API) among them; without branch protection nothing can be required, and the outcome rests on required CI status where available, otherwise on convention plus `script/ci/guard_approval` |
| 117 | Throttle specs pass because the test environment's cache is a null store and nothing is ever counted | BE-12 | `config.cache_store = :memory_store` in `config/environments/test.rb` (`rate_limit` takes its store when the class loads) + a global `before` hook that clears it |
| 118 | `React.useState` through a namespace or default import slips past the state-hook import ban | FE-04 | ESLint `no-restricted-properties` outside the two wrappers and design_system |
| 119 | The clone detector reports generated skeletons and repetition inside one engine, the baseline fills with noise, and nobody reads it | ARCH-05 | cross-engine pairs only + scoped folders + a minimum token count set where the example engines report 0 |
| 120 | Compatibility fixtures are written by hand, so a stored format nobody remembered is never read across releases | SEC-16, ADR-31 | `bin/rails formats:dump` in the release pull request writes every versioned format to `spec/fixtures/formats/v<VERSION>/`, committed there + the release workflow fails while that folder is missing + the compatibility spec loads the previous tag's folder |
| 121 | The production route check cannot boot without production secrets, so it is skipped or run with real ones | SEC-12, BE-08 | dummy boot: committed `.env.ci.production` and dummy credentials; a setting without a value raises at boot |
| 122 | A dark module is hidden from navigation, but its routes still answer anyone who knows the URL | ARCH-06, BE-25 | `require_module_enabled` in the base controller's callback list + order spec (BE-24) + core request spec |
| 123 | Engine migrations are copied into the app, drift from the engine's copy, and lose the engine their table prefix is checked against | ARCH-03, ARCH-10, GEN-01 | the engine's `db/migrate` appended to the app's migration paths (verify) + `Rafelo/EngineTablePrefix` reads the engine from the file path |
| 124 | Numbers and money are formatted by hand (`toFixed`, `Intl.NumberFormat`) and drift from the locale's rules | FE-11 | ESLint bans outside `@design_system/formatters` |
| 125 | A workflow commits generated changes (lower ratchet counts, format fixtures) straight to `main`, past the required checks and review | WF-03, WF-05, SEC-16, ADR-19 | no workflow pushes to `main`: a scheduled job opens a pull request for ratchet falls, the release pull request commits the `formats:dump` output, and the release workflow only checks and tags |
| 126 | A props object links into another module through that module's constants, so a link creates a dependency or a cycle, or a renamed route leaves a dead link | BE-04, ARCH-10, CT-02 | `context.urls.route` with the engine key and route name as symbols + `have_resolvable_hrefs` in every page's request spec: every `href`, `*Href`, and `nav[].path` was built by `Urls`, and a route helper raises on an unknown route name |
| 127 | An error raised outside an action (router 404, missing parameter, forgery failure) shows Rails' static English page without ids, `no-store`, or a CSP | CT-06, BE-13 | core exceptions app + its specs under `/th` for HTML, Inertia, and JSON |
| 128 | The error page loses the locale and the ids, because `rescue_from` runs after around-callbacks unwind | BE-09, BE-24 | `Current` assigned in a `before_action` + order spec + responder spec |
| 129 | CSRF specs pass because the test environment turns forgery protection off | SEC-05 | `:csrf` shared context + canary |
| 130 | A throttle runs after the session loads and a refresh fires, or a store returning `nil` silently disables every limit | BE-12 | `prepend: true` + order spec + cache store config spec |
| 131 | A forged `Host` header lands in redirect locations | SEC-13 | `config.hosts` + production config spec |
| 132 | A `..`, `.`, or empty segment, or a leading `/`, sends a gateway call to another resource or drops the base path | SEC-14 | client path specs |
| 133 | An oversized or failing download looks complete to the viewer | SEC-14, BE-18 | first-chunk status and size checks + download specs |
| 134 | A timed-out write is retried or taken over against an upstream that does not deduplicate, and happens twice | BE-15 | `idempotency_keys` declaration + `unknown` outcome + `attempt` fence + TS-10 specs |
| 135 | `can` offers an action that the policy refuses, or the reverse | BE-04 | `match_policy_capabilities` |
| 136 | A permission matcher written from the wildcard table over-grants on a short or malformed grant | BE-03 | `PermissionSet` spec with malformed grants |
| 137 | A concurrent grant re-fetch overwrites a grants-stale mark | SEC-15 | `grants_generation` + TS-10 spec |
| 138 | After a forced refresh, the losing requests retry with the dead token and end the session | SEC-03 | losers wait for `refreshing_since` to clear + TS-10 spec |
| 139 | A point-in-time restore brings back revoked sessions | OPS-07 | sessions emptied on restore + drill assertion |
| 140 | Logged viewer ids are reversed by hashing candidate ids | OPS-01 | keyed HMAC + log payload spec |
| 141 | The route check parses `bin/rails routes` text and silently skips mounts, redirects, and multi-verb routes | SEC-12 | in-process route walk with an allow-list + canaries |
| 142 | Rails i18n syntax reaches i18next untransformed (`%{name}` shown literally, plurals missing) | CT-08 | export transform + per-category parity + canaries |
| 143 | A locale switch shows the old locale's copy because the new namespace never loaded | CT-08 | resolver awaits namespaces per locale + resolver test |
| 144 | Money shows a thousand times off because the browser's currency digits differ from ISO 4217 | CT-02 | exponent on the wire + formatter test |
| 145 | Charts lose hover and scale colors because ECharts cannot parse Tailwind's `oklch()` tokens | FE-08 | oklch-to-hex converter + wrapper test |
| 146 | Tests run without React Compiler and miss compiler-only behaviour | FE-10 | shared `reactPlugins()` + render-count test |
| 147 | Back, forward, and same-component visits are never announced, or an announcement is lost because its live region was just inserted | FE-13 | `navigate` listener + one page announcer in the layout root + layout and announcement tests |
| 148 | A failed submit or a pagination boundary drops focus to the page body | FE-13, FE-16 | `isPending` and `aria-disabled` + focus tests |
| 149 | Every visit remounts the page and drops typed input because the resolver returns a new wrapper | FE-15 | resolver identity test |
| 150 | Shell widgets format with the browser's locale because the locale provider wraps only the page | FE-14 | provider in the layout root + layout test |
| 151 | A required check skipped after a failure reports success, or a merge-queue entry waits for a check that needs pull request data | WF-03 | `ci-ok` aggregator + `merge_group` short-circuit of the checks that read pull request data + canary |
| 152 | Branch protection is turned off or a required check is renamed, and nothing notices | WF-03 | committed ruleset + scheduled `script/ci/repo_rules` + canary |
| 153 | The production image first fails at deploy (path gems before `bundle install`, a new config key) | OPS-06, BE-08 | image build on pull requests |
| 154 | A secret is missing at deploy, a secret file is tracked, or the image runs as root | OPS-06, SEC-07 | `script/ci/deploy_preflight` + canaries |
| 155 | A docs check that requires a file extension never checks `script/ci/*`, and a rule ships without a canary because the canary table is hand-written | CT-09, TS-07 | path existence check + rule-name meta-check |
| 156 | npm differs between the container, CI, and the image | WF-06, OPS-09 | npm in `mise.toml` + `devEngines` + `script/ci/pins` |
| 157 | Vite inlines a small asset as `data:` and the CSP blocks it | SEC-05 | `assetsInlineLimit: 0` + bundle check + smoke suite on CSP violations |
| 158 | A generator fails halfway and leaves a half-wired engine that the next run refuses | GEN-09 | failure-injection generator specs |
| 159 | design_system reads page props or starts visits, so its components depend on the page they sit in | FE-03 | `designSystemInertia` allow-list (`Link`, `Deferred`) + canary |
| 160 | A server runs on the committed dummy credentials, or production lacks a credential the dummy file lists and fails only after the deploy starts | BE-08, OPS-06 | dummy branch only under `SECRET_KEY_BASE_DUMMY` + boot guard for the two Rake tasks + `RAILS_MASTER_KEY` precedence + `deploy_preflight` (one `env.secret`, key-path comparison before a deploy) |
| 161 | A release is tagged from a commit no CI run passed, because a squash commit on `main` carries no check runs | WF-05 | CI on `push` to `main` + release workflow started by that run's successful `workflow_run` |
| 162 | A second host boots while the first migrates and fails with `ConcurrentMigrationError` | BE-22, OPS-06 | `boot: limit: 1` + `deploy_preflight` + canary |
| 163 | Inertia sends a notice twice (as a shared prop and as its page-level flash), and Back or Forward shows an old notice again because props stay in history | CT-07, FE-13 | page-level flash only (no `flash` prop; the strict envelope rejects one) + flash status test (notice, a page without one, Back: empty) |
| 164 | A typo or a duplicate key in a YAML catalog or locale file passes, because YAML keeps the last of two equal keys and a misspelled field reads as missing | CT-06, CT-08 | `errors:check` entry validation + node-tree duplicate checks in `errors:check` and `i18n:check` + canaries |
| 165 | Bare `tsx` reads the solution tsconfig, which has no `paths`, so every schema that imports `@core/` or `@design_system/` fails to load in `contracts:generate` | CT-03 | `tsx --tsconfig tsconfig.tooling.json` in every script + canary |
| 166 | A generated file outlives its source (a moved page's JSON Schema, a dropped locale's export) and is read as current | CT-03, CT-08, FE-10 | generators delete outputs they no longer produce + `--check` fails on an output with no source |
| 167 | `docs:check` reads a heading inside a fenced example as a definition, or a rule has no matrix row or two | CT-09 | heading parse outside fences + exactly one 09 row per rule + status vocabulary + canaries |
| 168 | A page's props carry a key outside the envelope and shadow a shared prop such as `auth` | CT-01 | core raises when a props hash's top-level keys are not exactly the envelope's + core request specs |
| 169 | A boot-time migration runs past Kamal's 30-second `deploy_timeout`: the new container is stopped, and a concurrent-index migration leaves an INVALID index | BE-22, OPS-06 | `deploy_timeout` set (`deploy_preflight` + canary) + long migrations as their own step, re-runnable (review) |
| 170 | A form token outlives its idempotency row, so a resubmit after the purge calls the upstream again | BE-15, OPS-07 | signed token with its issue time + claim refuses tokens older than the retention + config spec (retention above the absolute session lifetime) |
| 171 | A write without an idempotency key that got a `401` is never resent after the refresh, or the resend eats the retry budget | BE-16, SEC-04 | one resend after a successful refresh, outside the retry and page budgets + client specs + a second `401` revokes |
| 172 | A forged or malformed `traceparent` is logged, echoed on the error page, and sent upstream | OPS-02 | strict W3C parsing + hostile-header request spec |
| 173 | Active Job writes job arguments, ids and values included, to production logs | OPS-01 | `log_arguments = false` + spec over every job class |
| 174 | A write that raises leaves no audit row, or one request writes two | OPS-08, BE-13 | one recorder (write path + error responder) with a request-scoped marker + per-outcome spec |
| 175 | The SQL budget counts the spec's setup, query-cache hits, or `BEGIN` and `COMMIT`, so it measures the wrong thing or fails at random | OPS-01, TS-02 | `within_budgets` counts only its block + one core SQL subscriber shared with the log + spec + canary |
| 176 | A huge upstream body is buffered whole before any size check | BE-05, SEC-14 | `max_response_bytes` checked in `on_data` + chunking-fake spec |
| 177 | A canary passes on a parse error, an ignored file, or a different rule's report | TS-07 | findings exit status + the rule named in machine-readable output + `enforcement_canaries`' own canaries |
| 178 | A check passes because it read no files (a wrong glob, an empty root) | TS-07 | count printed + fails on zero + empty-root canary per check |
| 179 | `pages:check` finds a matcher name in a comment, so a page whose specs never call the matchers passes | TS-02 | matchers record page keys at run time + `pages:check --matchers` + canary |
| 180 | A guard or concurrency spec still passes with the guard removed | TS-05, TS-10 | guard specs reach the guarded path and assert its outcome + forced interleaving (barrier + latch) (review) |
| 181 | A negative log assertion needs two values on one line, so a line that leaks one of them passes | TS-05, OPS-01 | per-value absence assertions over the whole output + key allow-list per JSON line |
| 182 | A test keeps its own color contrast table, which drifts from the tokens | TS-11 | contrast only through axe's `color-contrast` (review) |
| 183 | An old browser gets an unstyled English `406` page, because the CSP blocks its inline style | FE-19, SEC-05 | core's `unsupported_browser` template with a nonce'd style, translated + request spec (CSP, nonce, `/th`) |
| 184 | `tailwind-merge` drops a color class next to a custom non-color token | FE-06 | one `extendTailwindMerge` instance listing every custom token + design_system test |
| 185 | The production route allow-list is derived from the routes it checks, so a stray route allows itself | SEC-12 | committed `config/production_routes.yml` + module routes from the registry + canaries |
| 186 | A person creates, moves, or deletes a `v*` tag by hand | WF-05 | tag ruleset on `refs/tags/v*` + `repo_rules` comparison with `.github/rulesets/release_tags.json` |
| 187 | One `uses:` form slips past the pin check (a job-level `uses:`, a `.yaml` workflow, a composite action, a `docker://` image) | WF-07 | YAML-parsing `actions_pinned` + one canary per form |
| 188 | A job gets write scopes it does not need, or runs without a timeout | WF-07, TS-09 | `script/ci/workflow_policy` + canaries |
| 189 | A `pull_request_target` or `workflow_run` workflow checks out pull request code with the base repository's token | WF-07 | `script/ci/workflow_policy` + canaries |
| 190 | A title edit or a review never re-runs the title lint or the approval checks, so the pull request stays blocked or passes on stale data | WF-03 | `pull_request.yml` on `edited` and on `pull_request_review` (`submitted`, `dismissed`) |
| 191 | The application template fails for the commit being released, or leaves `acme` in the adopter's app | GEN-07 | template CI adopts `HEAD` under a two-word name + leftover-`acme` check |
| 192 | An app named like a kernel engine or an existing constant collides with Rafelo's namespaces | GEN-07 | reserved-name refusal + template specs |
| 193 | A session passed to a log line or a props hash by mistake carries its tokens | SEC-02 | `serializable_hash` without token columns + model spec |
| 194 | CSP Report-Only is left on in production | SEC-05 | typed `csp.report_only` defaulting to `false` + production-config spec |
