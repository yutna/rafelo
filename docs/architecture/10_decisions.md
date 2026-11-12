# 10 — Decisions

Architecture decision records settle questions where reasonable people (or
general advice) disagree. An ADR outranks a rule; rules cite the ADR they
implement.

**Lifecycle.** The template has not been released, so its ADRs are edited in
place. The lifecycle below applies from adoption on. An ADR is `Accepted` or
`Superseded by ADR-NN`. To change a decision, add a new ADR and mark the old
one superseded in the same pull request, then update every rule that cited it.
`npm run docs:check` fails when a rule, `AGENTS.md`, or an AI instruction file
cites a superseded ADR or an ID that does not exist.

**Template for a new ADR:** context (what forces the choice), decision (one
paragraph), consequences (what gets easier, what gets harder, what we will
watch).

### ADR-01 — Rails is a BFF in front of the upstream APIs

Status: Accepted

Rails owns routing, sessions, edge authorization, props, i18n, and every
upstream call. The upstream APIs own business data and business rules. The
browser never talks to an upstream. Consequence: one origin, no tokens in the
browser, and a single place to shape data for screens. The cost is real and
accepted: two languages with two test and lint stacks; about 12–15 files per
page (controller, policy, gateway, props, schema, page, screen, container,
component, hook, types, request spec, component test), most of them written by
the generators; and one more network hop on every request.

### ADR-02 — Inertia and React, one router

Status: Accepted

Pages are React components served by Rails through Inertia. There is no client
router, no Hotwire, and no client data cache. The client targets current
evergreen browsers only; an older browser gets an upgrade page (FE-19).
Consequence: Rails routes and controllers stay the source of navigation; React
stays a rendering layer.

### ADR-03 — Rails engines are module boundaries

Status: Accepted

Every engine has a kind. `engines/core` is the kernel and
`engines/design_system` the shared UI kit; both depend on nothing in the
repository. A domain engine holds a business concept that several modules
share and exposes only a public surface: no routes, pages, or registry entry.
A product module holds one product area with its routes, pages, and registry
entry. A domain engine depends on core, design_system, and the domain engines
it declares; a product module may also declare the public surfaces of other
product modules. The application is the
composition root: it may depend on every engine, and no engine depends on it.
The `dependencies:` list in each engine's `package.yml` is the one declared
graph. Packwerk proves it acyclic and checks Ruby references against it;
generated dependency-cruiser rules and TypeScript project references check the
frontend against the same lists (ARCH-04, ARCH-08). Anything two engines use
is a public interface chosen by the sharing ladder (ARCH-05); copying between
engines is forbidden. The one exception is in the kernel: core and
design_system depend on nothing, so each implements the safe-URL predicate
(`appPathSchema`, `isSafeUrl`), and one shared hostile-input fixture keeps
the two in step (ARCH-05, FE-18). Consequence: modules can be added, removed, renamed, or
split independently, and sharing is a deliberate, reviewed act instead of a
promotion into core. The cost is a dependency list to maintain and public
surfaces to change additively (ARCH-09).

### ADR-04 — One module registry

Status: Accepted

Each product module declares one registry entry in its own
`engines/<module>/config/module.rb`:
key, engine, path, permission prefixes, legacy paths, navigation, and an
optional `flag:`. Mounting, navigation, and permission prefixes are derived
from the entries, boot validation rejects duplicates, and generators never edit
routes. Path and permission prefixes default from the key but can be set
explicitly, so a module can be renamed or split without breaking bookmarks or
upstream grants (GEN-06). A module with a `flag:` ships dark: until the flag is
on for the viewer it stays out of navigation and its routes answer 404
(BE-25). Consequence: no drift between what is mounted, what is shown, and
what is authorized, and no central file that every module edits.

### ADR-05 — Rails conventions first

Status: Accepted

Use resourceful routes, thin controllers, policies, gateways, value objects,
and props objects. Do not add repositories, use-case layers, or a service per
action by default. Consequence: less ceremony; a new layer needs its own ADR.

### ADR-06 — Props are a typed contract

Status: Accepted

Every page uses the same envelope. Zod schemas are the source of truth,
exported to strict JSON Schema (no properties outside the schema) and
validated in Rails request specs. Each page declares its capability keys, so
`can` is typed, and `meta` is strict. Shared props are emitted once and
referenced from every page schema. Page schemas, error codes, and translations
live in the engine that owns them; errors and translations are catalog
contracts too. Consequence: shape changes and leaked fields are caught in CI
on both sides, and a change in one module does not rewrite another module's
contract.

### ADR-07 — snake_case in Ruby, camelCase in JSON

Status: Accepted

Props objects use snake_case symbol keys. One `prop_transformer` converts keys
to camelCase at the Inertia boundary. Data values never become object keys.
Consequence: idiomatic code on both sides and no hand-written key strings.

### ADR-08 — Policies and a server-owned capability map

Status: Accepted

Pundit policies decide access with permission keys that each module declares
in its `engines/<module>/config/permissions.yml`, compiled into constants.
One `PermissionSet` matches them against the viewer's upstream grants,
translated through one mapping file (`config/permission_mapping.yml`), the
only place upstream grant
names appear. Pages receive a single `can` map with `allowed` and `reason`;
server-side feature flags arrive through it with reason `disabled` (BE-25).
The client never derives access. No flag elevates a real account.
Consequence: one authorization model, testable in isolation, and an upstream
grant rename changes one file.

### ADR-09 — Server-side sessions and a protected edge

Status: Accepted

The browser holds two session cookies, both httpOnly: one opaque cookie for
the server-side session, and Rails' own cookie-store session, which never
holds identity (SEC-01, SEC-08). Upstream tokens are encrypted in the session
store and refreshed single-flight on the server.
Every request is protected at the Rails edge: CSRF, a strict CSP, `no-store`
on authenticated pages, and throttling on sign-in and writes. Secrets and real
personal data never enter code, logs, fixtures, or tickets. Consequence: no
token theft through XSS-readable storage and one place to audit request
security; Rails carries the session complexity.

### ADR-10 — PostgreSQL and the Solid trio

Status: Accepted

PostgreSQL in every environment (development runs it in the Dev Container,
ADR-28), with Solid Queue, Solid Cache, and Solid Cable. The database stores
only BFF-owned data (ARCH-03), and no state lives outside PostgreSQL or the
Active Storage service beyond request and job temp files (ARCH-13). The Solid
trio shares the primary database by default: fewer connection pools to size
(BE-21) and one database to back up. Split queue, cache, or cable into their
own databases when
measured queue or cache load on the primary (OPS-04) starts to affect request
latency. Consequence: real transactions and row locks, which are never held
across an upstream call (BE-20, SEC-03); several app hosts can share one
database (ADR-26). In exchange: a database server to operate, connection
arithmetic to check, zero-downtime migrations (BE-22), and write patterns that
respect vacuum (SEC-08, OPS-08).

### ADR-11 — Tailwind CSS and headless primitives

Status: Accepted

Styling is Tailwind v4 with the full palette plus semantic tokens, defined in
the design_system engine. Variants use `tailwind-variants`; class merging uses
`tailwind-merge`. Accessible complex widgets are built on React Aria
Components. All three libraries are imported only inside
`engines/design_system`. No styled component kit and no CSS-in-JS.
Consequence: one styling language, a strict CSP, accessibility from proven
primitives, and library upgrades in one engine.

### ADR-12 — ECharts and TanStack Table behind wrappers

Status: Accepted

Charts use ECharts and complex grids use TanStack Table, each only inside a
design_system wrapper that owns lifecycle, states, theming, test ids, and time
axes formatted by `@design_system/formatters`. The wrappers load lazily, so a
page without a chart does not download one. The wrappers, like every
design_system export, form a public API that is reported and checked in CI
(FE-21) and covered by visual regression tests (TS-11). Consequence: features
stay declarative, libraries can be upgraded in one place, and a design_system
change shows its reach before it merges.

### ADR-13 — Frontend layers and persistent layouts

Status: Accepted

Pages parse props and render one screen; screens arrange; containers connect
hooks; components present. Layouts are Inertia persistent layouts assigned by
the app's resolver. Files are `snake_case`. Imports go through aliases:
`@core/`, `@design_system/`, `@<engine>/` (another engine only through
`@<engine>/public/`), and `@/` for app code; `@engines/` appears only in the
page resolver. Types, schemas, and constants have their own file suffixes.
Each page loads as its own chunk through the resolver, and the bundles have
size budgets (FE-16). Consequence: predictable files, and a dependency graph a
tool can check.

### ADR-14 — Functional React, object-oriented domain

Status: Accepted

React code is functions. Client-side domain logic is immutable TypeScript
classes in `domain/` and `forms/`, and state changes only through their
methods. A class throws `DomainError` only for an invariant violation (a
programmer error); input from a person is validated by methods that return
`issues()`, because hooks rebuild objects during render and a throw would
replace the page with the error boundary. Hooks are the only meeting point,
and only plain data enters React; every class that crosses has a round-trip
test. The error boundary is the single class component. Consequence: business
logic is unit-testable without React, and React state stays plain.

### ADR-15 — Local state through two wrappers

Status: Accepted

Local state goes through two core wrappers built on React's own hooks:
`useDomainReducer(reducer, initialPlain)` for state with business transitions,
where the reducer delegates to domain objects
(`X.fromPlain(state).method().toPlain()`), and `useUiState({ open: false })`
for presentation-only state, always an object and never a primitive. In
development both assert plain data and deep-freeze it, because React does
not freeze state and an edit in place would otherwise pass unnoticed.
`useState`, `useReducer`, `useActionState`, and `useOptimistic` appear only
inside those two files, except that
design_system widgets may use React's state hooks for their own presentation
state (FE-04). Forms and
server-backed optimism belong to Inertia's `useForm` and router; a purely local
optimistic change uses `useDomainReducer` with an explicit rollback event.
Consequence: one state style, transitions owned by domain objects, and no
state library beyond React itself.

### ADR-16 — React Compiler

Status: Accepted

The build uses React Compiler. Manual memoization needs a measured reason.
Consequence: simpler components; compiler upgrades get an integration check.

### ADR-17 — Configured locales, English by default

Status: Accepted

Locales are configured once, in `config/locales.yml`. The default
configuration is `available: [en, th]` with `default: en`. Rails' available
locales, the route constraint, the Zod locale enum, parity checks, and
generator placeholders are all derived from that file. Every user-facing
string exists in every configured locale; English is the default and fallback
unless configured otherwise. URLs carry the locale. Rails YAML is the source of
truth, exported per engine as i18next namespaces. When `th` is enabled, every
year a viewer sees or types is a Buddhist Era year, with the calendar set
explicitly instead of left to a runtime default; this is a MUST (FE-20). The
wire stays Gregorian ISO 8601 (CT-02). Consequence: no untranslated screens,
locale-stable URLs, a new locale is a configuration change, and a Thai viewer
never meets a Gregorian year.

### ADR-18 — Exact versions

Status: Accepted

Ruby, Node, npm, gems, and npm packages are pinned to exact versions, with
lockfiles committed. The versions in `00_README.md` were resolved together on
one date and are resolved again at adoption. Upgrades arrive through Renovate:
one pull request per package, except peer sets that must move together, which
`packageRules` groups and `script/ci/pins` checks. Majors arrive separately,
and nothing auto-merges. Consequence: reproducible builds; upgrades are
deliberate work, and a peer set never lands half-upgraded.

### ADR-19 — Small changes and an always-green `main`

Status: Accepted

Work arrives as small, reviewable pull requests tied to one outcome, squash
merged through a merge queue into a protected `main`. The queue runs CI on the
merged result (`merge_group`), with affected engines computed against the
merge base, so two changes that pass alone cannot break `main` together. A
required merge queue needs an organization-owned repository (public, or
private on GitHub Enterprise Cloud; verify when adopting); without one, branch protection requires branches to
be up to date, the `ci-ok` check, and the three `pull_request.yml` checks,
which gives the same guarantee at the cost of more rebasing (WF-03). On a plan
without branch protection for private repositories (verify when adopting),
nothing can be required: the guarantees fall back to required CI status where
the platform offers it and otherwise to convention plus
`script/ci/guard_approval`. This decision's outcomes need branch protection to
be real. No workflow pushes to `main`; generated changes such as lower ratchet
counts arrive as pull requests.
Slices end with a bounded review gate, and releases are cut from `VERSION`:
CI runs again on the push to `main`, and its success starts the release
workflow (WF-05).
Consequence: history reads as a list of outcomes, and `main` is always
releasable.

### ADR-20 — Test at the cheapest useful level

Status: Accepted

Each behaviour is proven once, at the cheapest level that can prove it:
request specs for pages, plain specs for objects, Vitest for domain and UI
units, Playwright only for critical journeys. Every page checks its contract
and budgets at its maximum size. Browser-facing tests select by role with an
accessible name, or by test id. The suite runs in parallel within time
budgets; concurrency specs run in their own serial lane and are never retried;
the design system has visual regression tests. Consequence: a fast, stable
suite in which a failure points at one layer.

### ADR-21 — The shared frontend kit is split between core and design_system

Status: Accepted

Two kernel engines hold what every module needs. `engines/core` (`@core/`)
holds the contracts (envelope, shared props, `definePage`, the
generated locale enum), `lib/` (the two state wrappers, `assertPlain`,
`deepFreeze`, and i18n helpers that do not format), and domain-free value
objects such as `Money` and `DateRange`. `engines/design_system` (`@design_system/`, never
abbreviated) holds tokens and theme, components, the chart and data-table
wrappers, the icon map, the error boundary, and the formatters for dates,
numbers, and money. design_system is a leaf: it depends on nothing in the
repository, not even core, takes only `Link` and `Deferred` from Inertia, and
has its own i18n namespace. The price is one duplicated predicate: the
safe-URL check exists in both kernel engines, the one copy ARCH-05 allows. Translations are
exported per engine, never into core; i18next is initialised in the app's
entrypoint. The app holds the entrypoint, resolver, layouts, and app-level
pages. Consequence: the frontend dependency direction matches the Ruby one and
a tool proves it; UI work and kernel work have separate owners and checks
(FE-21, TS-11). Both kernel engines are inputs that run everything in CI
(design_system narrowed by `api.d.ts`, FE-21), so their growth is budgeted
(ADR-29).

### ADR-22 — No server-side rendering

Status: Accepted

Pages render in the browser from the page object Rails embeds in the initial
HTML. Inertia SSR would add a Node runtime to deploy and operate, and internal
applications gain little from it. The server-rendered layout still carries
what must exist before hydration, such as the idle-lock shield. Consequence:
one runtime in production. Revisit if the `js_initial_gzip_kb` budget (FE-16)
cannot be met.

### ADR-23 — Realtime carries signals, not data

Status: Accepted

Solid Cable is available but off by default. When used, the server broadcasts
only change signals, and the client reloads the affected props through Inertia,
so every piece of data still passes through a controller and its policy.
Consequence: no second authorization path over websockets.

### ADR-24 — Accessibility target: WCAG 2.2 AA

Status: Accepted

The application targets WCAG 2.2 level AA. Accessible primitives come from
React Aria, page changes are announced and focused, and axe runs in the browser
smoke suite. Consequence: accessibility regressions fail CI instead of
surfacing in audits.

### ADR-25 — Observability on W3C trace context

Status: Accepted

Every request carries a W3C `traceparent` from the browser edge through Rails
to the upstream, and every log line, error report, and error page carries the
trace id. Logs are structured and allow-listed. Consequence: one id answers
"which side failed?", and logs are safe to ship.

### ADR-26 — Deploy with Kamal in two profiles

Status: Accepted

Production runs one Docker image, built from a production Dockerfile separate
from the Dev Container, with Kamal and Thruster. There are two profiles.
Single host (the default): PostgreSQL as a Kamal accessory on a volume, or a
managed service. Multi-host: several app hosts behind a load balancer, managed
PostgreSQL, and an S3-compatible Active Storage service. Moving between them
needs no code change, because no state lives outside PostgreSQL or the
Active Storage service (ARCH-13). With more than one host, Kamal boots them
one at a time, so the migration that the first host runs at boot finishes
before the next host boots (BE-22). Kamal
asset bridging keeps old Vite chunks available, so open tabs survive a deploy
(CT-12). Production secrets are Rails encrypted credentials, committed
encrypted; Kamal delivers only their key, `RAILS_MASTER_KEY` (BE-08, OPS-06). Old and new containers run side by side during a deploy, so
migrations and stored formats stay compatible across two releases (ADR-31).
Consequence: a small, cheap deployment to start, and a planned path to more
hosts when one is no longer enough (OPS-06).

### ADR-27 — Copy-in kernel with a tracked version

Status: Accepted

An open-source template can ship its kernel as a dependency the adopter cannot
change, or as code the adopter owns and must keep current. Business
applications need to change the kernel, and they cannot wait for a template
release to fix a problem in their own copy.

Adoption runs a Rails application template; the `rails new` flags select
PostgreSQL and the Dev Container (`rails new <app> -d postgresql
--devcontainer ... -m <template>`, GEN-07). The template derives the namespace
from the app name and writes `KERNEL_VERSION`. From then on the kernel (core,
design_system, the generators, `script/ci`, `bin/check`, `bin/kernel_update`,
and `spec/fixtures/hostile_urls.json`) belongs to the adopter, security included.
`bin/kernel_update <version>` produces a three-way merge of the adopter's
copy, the base version, and the new version, and leaves conflicts to resolve.
By default it updates core, the generators, `script/ci`, `bin/check`,
`bin/kernel_update`, `spec/fixtures/hostile_urls.json`, and the guard
configurations; design_system is updated
only per folder on request (`--include design_system/<folder>`), because
adopters restyle it. The template's own CI adopts the commit under test under
a two-word app name and runs `bin/ci`, failing on any leftover `acme`; it also
adopts release N-1, updates to N, and runs `bin/ci`.
`SECURITY.md` explains how to report a vulnerability in the template.

Consequence: adopters can change anything, and kernel updates are reviewable
merges instead of version bumps. In exchange the adopter owns every kernel
line, including pulling security fixes from new template releases.

### ADR-28 — Development in a Dev Container

Status: Accepted

Ruby, Node, and PostgreSQL versions drift between machines and away from CI,
and a local PostgreSQL makes setup heavier for every new developer and AI
agent.

Development runs in a Dev Container. The host needs only Docker (Docker
Desktop, OrbStack, or similar) and an editor that supports Dev Containers; no
cloud service is required. The base is Rails' generated devcontainer plus
Node, Playwright browsers, and PostgreSQL as a service. Ruby is pinned by the
Dev Container image tag and digest, Node and npm by `mise.toml`.
`script/ci/pins` asserts that `mise.toml`'s Ruby, `.ruby-version` (read by
the Gemfile), the production Dockerfile's `ARG RUBY_VERSION`, and the image
tag agree; the PostgreSQL image is pinned by version and digest. The
image is prebuilt when `.devcontainer/` changes (other than
`.devcontainer/image_digest`) and pushed to the registry by digest, recorded
only in `.devcontainer/image_digest`: a first CI job reads it and the other
`ci.yml` jobs, except the production image build (Docker on the runner), run in that image, so workflow YAML
never contains the digest, and `devcontainer.json` references the same digest,
which
`script/ci/pins` checks against the file. On Windows,
Docker Desktop runs on WSL2 and the repository lives in the WSL2 filesystem or
a container volume, not on `C:\`; `.gitattributes` forces `eol=lf`. The
production image is a separate Dockerfile (ADR-26).

Consequence: one environment for every developer, agent, and CI job. The cost
is Docker on every machine and file-system performance to watch on some hosts.

### ADR-29 — Growth has budgets

Status: Accepted

In modular codebases the shared package tends to become the hub: code is
promoted into it because two modules needed it, most changes touch it, and
affected-only CI stops narrowing because everything depends on it. A domain
engine can become a second hub the same way, by letting its public surface
grow; a product module that many others depend on holds a domain concept that
never got its own engine; and a module can grow until nobody can own it.

`config/budgets.yml` → `growth:` limits core (files, not counting `spec/` and
`lib/generators/`, and public exports or constants), design_system (public
exports), each domain engine (public surface size: exports and constants),
each module (files and pages), and each product module's dependents
(`max_dependents`, default 5). Fan-in ignores core and design_system, which
every engine depends on by design, and domain engines, whose purpose is to be
shared; their size budgets hold them down instead. Exceeding a budget fails
CI; the fix is a split (`rafelo:module`, then `rafelo:move_page`), an extracted
domain engine (the usual answer to many dependents on a product module), or an
ADR. The share of merged pull requests over 30 days that touch core or
design_system (`growth.touch_rate.max`, default 0.15) is a metric, not a gate:
once there are at least three product modules besides the examples
(`growth.touch_rate.min_modules: 3`), a scheduled job opens an issue when it
is exceeded; with fewer, nearly every change touches the kernel and the number
means nothing. Raising any growth budget needs an ADR. Core, design_system,
and `config/budgets.yml` have code owners (ADR-32).

Consequence: the kernel stays small enough for affected CI to narrow, and
growth becomes a visible decision. The cost is occasional splitting work, and
an ADR whenever a budget truly has to rise.

### ADR-30 — Upstream resilience (named upstreams, breakers, bulkheads; a default breaker library)

Status: Accepted

A BFF is I/O-bound. When one upstream slows down, every Puma thread waits on
it, retries multiply its load, and the incident spreads to pages that never
needed that upstream. Most applications also gain a second upstream sooner or
later.

Upstreams are named in `config/upstreams.yml`; `Acme::Core::UpstreamClient.for(:api)`
builds the client, and each gateway declares `upstream :api`. Budgets, the
service-token allow-list, fixtures, and drift checks are keyed per upstream.
Each upstream has a circuit breaker, a concurrency limit (bulkhead), and a
retry budget; an open circuit fails fast as `upstream.circuit_open` (503,
retryable). Concurrent calls run only on core's bounded executor. The
template ships one default breaker library (for example semian, circuitbox, or
stoplight), chosen when the template is built, wired behind `UpstreamClient`,
and pinned by each template release. At adoption the stack is resolved again
and the adopter may swap the library; the library in use is recorded in this
ADR, and its behaviour verified against the pinned version.

Consequence: a slow upstream degrades its own pages instead of the whole
application, and a second upstream is configuration instead of special cases.
The cost is one more library and per-upstream limits to tune from the metrics
in OPS-04.

### ADR-31 — Changes are compatible across two releases (migrations, stored formats, contracts)

Status: Accepted

During a deploy the old and new containers run side by side against one
database, and open tabs keep running the old JavaScript.

Every change that crosses a release boundary stays compatible with the
previous release. Migrations expand first and contract in a later release;
`strong_migrations` blocks unsafe operations, and indexes are created
concurrently (BE-22). Persisted formats carry a version, and readers accept
the current and the previous one; each release pull request commits fixture
rows of every versioned format, and the next release's compatibility spec
reads them. A
release MAY revoke all sessions instead of reading an old session format,
which only forces sign-in (SEC-16). Cache namespaces include the release or
an explicit schema version (BE-17). Contracts and engine public surfaces
change additively first (CT-05, ARCH-09); the asset version reloads a stale
tab on its next GET visit, and asset bridging keeps old chunks available
(CT-12).

Consequence: deploys need no maintenance window and never strand a running
container or an open tab. The cost is that a removal or a rename takes two
releases.

### ADR-32 — Tools guard, people decide, AI builds

Status: Accepted

AI agents write much of the code. They are fast, confident, and make the
mistakes a hurried person makes, including loosening a check to get a green
build. An AI reviewer shares the blind spots of an AI author.

Every rule names what enforces it (`09_enforcement.md`): a tool that fails the
build, a kernel spec, a check to verify at adoption, or review by people. AI
builds, and may assist a reviewer, but an AI review never counts as a guard.
Guard files (ESLint, dependency-cruiser, Packwerk, and RuboCop configuration
and custom cops, every `package.yml` dependency change, budgets, ratchets,
canary fixtures, `config/production_routes.yml`, `script/ci/`, `config/ci.rb`,
and `.github/` with the CI workflows) need a person's approval: through
code owners, or, for a ratchet, through `script/ci/ratchet`, which lets a fall
pass and requires an owner's approval for a rise. Where the GitHub plan offers
no required code-owner review (verify when adopting), `script/ci/guard_approval`
fails when a guard file changed without an approving review from a listed
owner. An agent never loosens a guard to make something pass; it proposes the
change in the pull request for a person to decide. Guard messages name the
rule ID and the fix. The template ships the AI files an agent works from
(root and engine guides, a request workflow, one task skill per recipe, and
a pinned copy of the object-oriented design skills pack); the adopter's AI adapts them and a person
approves each change (`14_working_with_ai.md`), and `docs:check` validates the
IDs they cite.

Consequence: the speed of AI without delegating judgement. The cost is that
every rule must be expressible as a check, or be labelled review honestly.
