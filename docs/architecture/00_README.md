# Rafelo

Rafelo is a blueprint for a Rails application that sits in front of existing
backend APIs as a **Backend for Frontend (BFF)**. Rails owns sessions,
authorization at the edge, page props, i18n, and every upstream call. React
renders the UI through Inertia, styled with Tailwind CSS.

It documents an open-source template. A Rails application template creates
the project, copies in a kernel, example engines, the guards that enforce
these rules, and the AI files an agent works from (`14_working_with_ai.md`),
and installs these files as `docs/architecture/` and `AGENTS.md`.
They describe the architecture, the contracts between layers, the
conventions, and how each rule is enforced.

`Acme` stands for your application namespace; the application template
derives it from the app name. `billing` and `invoices` are example module and
resource names. `engines/example_orders` (a product module) and
`engines/example_customers` (a domain engine) are the example engines the
template ships.

## Principles

1. **One deployable, one contract.** The browser talks only to Rails. Rails
   talks to the upstream APIs. Inertia props are the contract between Rails
   and React.
2. **Thin Rails, honest boundaries.** Rails handles HTTP, sessions,
   authorization at the edge, props, i18n, and integration. Business data and
   business rules stay in the upstream APIs.
3. **Engines with declared, one-way dependencies.** Each product area is a
   Rails engine, Ruby and frontend together. Engines build on the kernel
   (`core` and `design_system`) and on the declared public surfaces of other
   engines. The graph is declared once and has no cycles. The application
   composes the engines (ARCH-04, ARCH-08).
4. **Object-oriented domain, React renders.** React components are functions
   that render plain data. Client-side domain logic lives in small immutable
   TypeScript classes, and hooks are where the two meet.
5. **Tools guard, people decide, AI builds.** Every rule names what enforces
   it. A guard is a tool that fails the build. People decide what tools cannot
   check and approve every loosening of a guard. AI writes code and may assist a
   review, but never counts as a guard (ADR-32).
6. **Built for year three: growth has budgets.** The structure has to hold for
   the codebase you will have in three years, not the one you have in week
   one. Kernel size, how often changes touch the kernel, fan-in on product
   modules, the public surface of domain engines, and module size have
   budgets, and raising one takes an ADR (ARCH-12, ADR-29).

## File map

| File | Purpose |
| --- | --- |
| `00_README.md` | This overview: principles, stack, adoption, and the kernel after adoption |
| `01_architecture.md` | BFF responsibilities, engine kinds, the dependency graph, public surfaces, registry, locales, growth budgets, request flow, layout (ARCH) |
| `02_backend.md` | Controllers, policies, props, named upstreams and their resilience, configuration, migrations (BE) |
| `03_session_security.md` | Session and token pattern, request protection, persisted formats (SEC) |
| `04_contracts.md` | Page envelope, schemas, error catalog, i18n contract (CT) |
| `05_frontend.md` | Layers, the design_system engine, state, charts, Buddhist Era, naming (FE) |
| `06_frontend_oop.md` | How OOP domain code meets functional React (OOP) |
| `07_testing.md` | Test levels, budgets, upstream fakes, parallel and concurrency lanes (TS) |
| `08_generators.md` | Module, domain, page, rename, and move generators; adoption; example engines (GEN) |
| `09_enforcement.md` | Rule → tool → status matrix, guard files, ratchets, and the CI gate |
| `10_decisions.md` | Architecture decision records (ADR) |
| `11_workflow.md` | Issues, pull requests, merge queue, review gates, releases, dependency upgrades (WF) |
| `12_hardening.md` | Failure modes Rafelo is designed to prevent |
| `13_operations.md` | Logs, tracing, error reporting, health, Dev Container, deployment, backups, audit (OPS) |
| `14_working_with_ai.md` | The AI files the template ships (guides, the request workflow, task skills, the design skills pack), how to adapt and validate them; greenfield and brownfield adoption with AI |
| `AGENTS.md` | Starter always-on guide for AI coding agents; adapt it as `14` describes |

## Rule format

Every rule has an ID, a strength, and the decision it implements:

```text
### ARCH-08 — One declared dependency graph, acyclic, checked twice (MUST · ADR-03)
```

- **MUST** — breaking it is a defect.
- **SHOULD** — follow it unless the pull request states a reason.
- **MAY** — an accepted option.

Each rule is defined once, in its topic file. Other files refer to it by ID.
`npm run docs:check` fails when a file, `AGENTS.md`, or any AI instruction
file cites a rule or ADR ID that does not exist, or a superseded ADR.

Each rule's enforcement has one of four statuses, listed in
`09_enforcement.md`:

- **enforced** — a tool fails the build.
- **tested in kernel** — the kernel (core, design_system, the generators)
  implements the behaviour and its own specs prove it; the example engines
  show it in use. Feature code gets it by going through the kernel, which the
  generators wire in.
- **verify when adopting** — a tool or library can do it, but confirm the
  option name or behaviour against the resolved version before relying on it.
- **review** — people only. AI review may assist but never counts as a guard.

**Precedence when guidance conflicts:** current library documentation for API
details, then an ADR, then a rule, then the project's AI instruction files
(which cite rules and never restate them), then any general advice or AI
skill.

## Stack and exact versions

All versions are exact. They were resolved together for peer-dependency
compatibility on **2026-11-09**. That is the last joint resolution, not a
promise: resolve the whole set again at adoption, pin the result exactly, and
commit both lockfiles. CI installs with `BUNDLE_FROZEN=true` and `npm ci`, so
a lockfile that does not match fails (WF-06). Afterwards, upgrade through a dependency bot, one pull
request per package or per peer group, and give every major upgrade its own
pull request (WF-06).

These packages are deliberately not on their newest release. The table is
generated from the Renovate rules by `npm run docs:generate`, and
`npm run docs:check` fails when it drifts.

<!-- generated:held-back:start -->
| Package | Pinned | Why |
| --- | --- | --- |
| `typescript` | 6.0.3 | `typescript-eslint` 8.72.1 supports TypeScript below 6.1 |
| `eslint`, `@eslint/js` | 9.39.5 | `eslint-plugin-react` and `eslint-plugin-jsx-a11y` do not support ESLint 10 yet |
| `eslint-plugin-unicorn` | 65.0.1 | Version 79 requires ESLint 10.4 or newer |
| `@tanstack/react-table` | 8.21.3 | Version 9 is a new major; migrate in its own pull request |
| `@babel/core` | 7.29.13 | Used only to run React Compiler through `@rolldown/plugin-babel`; Babel 8 support in the compiler plugin is unverified |
<!-- generated:held-back:end -->

### Runtimes

```toml
# mise.toml
[tools]
ruby = "4.0.9"   # must equal .ruby-version and the Dev Container image tag (script/ci/pins)
node = "26.13.0"
npm = "12.2.2"   # Node 26.13.0 bundles npm 11.20.0; without this pin the container runs that one
```

```jsonc
// package.json (excerpt)
{
  "private": true,
  "packageManager": "npm@12.2.2",
  "engines": { "node": "26.13.0", "npm": "12.2.2" },
  // npm only warns on a mismatched "engines" and never reads "packageManager";
  // devEngines with onFail "error" makes npm refuse to run (EBADDEVENGINES)
  "devEngines": {
    "runtime": { "name": "node", "version": "26.13.0", "onFail": "error" },
    "packageManager": { "name": "npm", "version": "12.2.2", "onFail": "error" }
  }
}
```

Ruby is pinned by the Dev Container image tag (and its digest);
`script/ci/pins` asserts that `mise.toml`'s `ruby`, `.ruby-version` (read by
the Gemfile), the production `Dockerfile`'s `ARG RUBY_VERSION`, and the image
tag agree, and that `devcontainer.json` names the image digest recorded in
`.devcontainer/image_digest`, the only place CI reads it. The `Dockerfile`
cannot read `.ruby-version` (Rails writes it as `ruby-4.0.9`, a prefix only
Bundler strips), so it pins the same version and the check parses its `ARG`
and `FROM` lines. Node and npm are pinned by `mise.toml` and installed inside
the container from it (not by the Dev Container Node feature, which brings
the bundled npm); `script/ci/pins` also asserts that `mise.toml`,
`packageManager`, `engines`, `devEngines`, and the `Dockerfile`'s Node and npm
agree, with a canary per mismatch (TS-07). PostgreSQL runs as a Dev Container service from an image pinned by
version and digest by each template release, and resolved again at adoption
with the rest of the stack (OPS-09).

### Gems

```ruby
# Gemfile (excerpt)
ruby file: ".ruby-version" # one source for the Ruby version; Bundler strips the "ruby-" prefix Rails writes

gem "rails", "8.1.4.1"
gem "propshaft", "1.3.2"
gem "pg" # exact version pinned by each template release
gem "puma", "8.0.2"

gem "inertia_rails", "3.23.0"
gem "vite_rails", "3.11.1"

gem "pundit", "2.5.2"
gem "aasm", "6.0.0"
gem "faraday", "2.15.1"
# Circuit breaker for the upstreams: the template ships one default library (for example
# semian, circuitbox, or stoplight), wired behind UpstreamClient and pinned by each template
# release; adoption may swap it (ADR-30).

gem "solid_queue", "1.7.2"
gem "solid_cache", "1.0.10"
gem "solid_cable", "4.1.0"
gem "lograge", "0.15.1"
gem "strong_migrations" # exact version pinned by each template release

gem "kamal", "2.12.0", require: false
gem "thruster", "0.1.27", require: false

# Engines: one gem per engine, found by glob, so a new module does not edit this file (ARCH-11)
Dir[File.join(__dir__, "engines/*/*.gemspec")].sort.each do |gemspec|
  gem File.basename(gemspec, ".gemspec"), path: File.dirname(gemspec)
end

group :development, :test do
  gem "packwerk", "3.3.1", require: false
  gem "packwerk-extensions", require: false # exact version pinned by each template release
  gem "parallel_tests" # exact version pinned by each template release
  gem "flay", require: false # exact version pinned by each template release
  gem "rspec-rails", "8.1.0"
  gem "factory_bot_rails", "6.5.1"
  gem "json_schemer", "2.5.0"
  gem "prosopite", "2.5.0"
  gem "i18n-tasks", "1.2.0"
  gem "rubocop-rails-omakase", "1.1.0", require: false
  gem "brakeman", "8.1.0", require: false
  gem "bundler-audit", "0.9.3", require: false
  gem "dotenv-rails", "3.2.0"
end

group :test do
  gem "shoulda-matchers", "8.0.1"
  gem "webmock", "3.34.0"
end
```

### npm packages

```jsonc
// package.json (excerpt)
{
  "dependencies": {
    "@inertiajs/react": "3.11.0",
    "@internationalized/date": "3.12.4",
    "@tanstack/react-table": "8.21.3",
    "echarts": "6.1.0",
    "i18next": "27.0.1",
    "lucide-react": "1.70.0",
    "react": "19.3.1",
    "react-aria-components": "1.22.1",
    "react-dom": "19.3.1",
    "react-i18next": "18.0.1",
    "tailwind-merge": "3.7.0",
    "tailwind-variants": "4.0.1",
    "zod": "4.6.7"
  },
  "devDependencies": {
    "@axe-core/playwright": "4.14.0",
    "@babel/core": "7.29.13",
    "@eslint-community/eslint-plugin-eslint-comments": "4.8.1",
    "@eslint/js": "9.39.5",
    "@playwright/test": "1.65.0",
    "@rolldown/plugin-babel": "0.3.1",
    "@tailwindcss/vite": "4.3.5",
    "@testing-library/dom": "10.4.2",
    "@testing-library/jest-dom": "7.0.1",
    "@testing-library/react": "16.3.3",
    "@testing-library/user-event": "14.6.8",
    "@types/babel__core": "7.20.5",
    "@types/node": "26.6.6",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@vitejs/plugin-react": "6.3.0",
    "@vitest/coverage-v8": "5.1.0",
    "babel-plugin-react-compiler": "1.0.0",
    "dependency-cruiser": "18.7.2",
    "eslint": "9.39.5",
    "eslint-plugin-better-tailwindcss": "4.10.0",
    "eslint-plugin-jsx-a11y": "6.10.2",
    "eslint-plugin-perfectionist": "5.13.0",
    "eslint-plugin-react": "7.37.5",
    "eslint-plugin-react-hooks": "7.1.1",
    "eslint-plugin-unicorn": "65.0.1",
    "globals": "17.14.0",
    "jsdom": "31.0.0",
    "lefthook": "2.2.2",
    "markdownlint-cli2": "0.24.0",
    "prettier": "3.9.10",
    "prettier-plugin-tailwindcss": "0.8.1",
    "tailwindcss": "4.3.5",
    "tsx": "4.23.15",
    "typescript": "6.0.3",
    "typescript-eslint": "8.72.1",
    "vite": "8.3.7",
    "vite-plugin-ruby": "5.2.6",
    "vitest": "5.1.0"
  },
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest run",
    "typecheck": "tsc -b",
    "lint": "node script/ci/eslint/check_config.mjs && eslint . --cache --max-warnings 0",
    "format:check": "prettier --check --cache .",
    "arch:check": "depcruise --config .dependency-cruiser.cjs app engines",
    // tsx finds the alias paths only through --tsconfig: the root tsconfig.json is a solution file (CT-03)
    "contracts:generate": "tsx --tsconfig tsconfig.tooling.json script/contracts/generate.ts",
    "contracts:check": "tsx --tsconfig tsconfig.tooling.json script/contracts/generate.ts --check",
    "errors:generate": "ruby script/contracts/errors",
    "errors:check": "ruby script/contracts/errors --check",
    "permissions:generate": "ruby script/contracts/permissions",
    "permissions:check": "ruby script/contracts/permissions --check",
    "locales:generate": "ruby script/i18n/locales",
    "locales:check": "ruby script/i18n/locales --check",
    "i18n:generate": "ruby script/i18n/export",
    "i18n:check": "ruby script/i18n/export --check",
    "pages:check": "ruby script/frontend/pages_check",
    "aliases:generate": "ruby script/frontend/aliases",
    "aliases:check": "ruby script/frontend/aliases --check",
    "docs:generate": "tsx --tsconfig tsconfig.tooling.json script/docs/generate.ts",
    "docs:check": "tsx --tsconfig tsconfig.tooling.json script/docs/generate.ts --check",
    "bundle:check": "vite build && ruby script/frontend/bundle_budget",
    "e2e": "E2E_ALL_BROWSERS=1 playwright test",
    "e2e:smoke": "playwright test"
  }
}
```

One more dev dependency, `jscpd` (the TypeScript clone detector, ARCH-05), is
pinned exactly by each template release. This spec names no version for it or
for the gems above shown without one; adoption resolves them again with the
rest of the stack.

### Scripts outside `package.json`

The template ships these as part of the kernel; each one is described next to
the rule it serves.

| Script | Purpose |
| --- | --- |
| `bin/ci` | The gate: the same steps locally and in CI (`09_enforcement.md`) |
| `bin/check <engine>` | Fast local loop for one engine: its Packwerk checks, its dependency-cruiser rules, `tsc -b` of its project, both of its Vitest projects, its RSpec, ESLint with cache on its files |
| `bin/kernel_update <version>` | Three-way merge of a new kernel release into your copy (below) |
| `script/ci/affected` | Changed paths → affected engines through the `package.yml` graph, plus their transitive dependents; global inputs (lockfiles, root configs, core, design_system, …) run everything, design_system narrowed by `api.d.ts` (FE-21) |
| `script/ci/engine_graph` | Writes every generated tsconfig file (one per engine, one for `app/frontend`, `tsconfig.tooling.json`, the root solution file) and the dependency-cruiser engine rules from the `package.yml` files; `--check` fails when they are stale (ARCH-08) |
| `script/ci/ratchet` | Counts per engine (`engines/<e>/config/ratchets.yml`) and for the kernel, the app, and the cross-engine clone baseline (`config/ratchets.yml`) against the committed counts; only a rise fails. As a required check against the merge base it passes a fall and requires an owner's approval for a rise; a scheduled job proposes falls in a pull request (`09_enforcement.md`) |
| `script/ci/growth` | Size budgets under `growth:` in `config/budgets.yml` (ARCH-12) |
| `script/ci/fan_in` | Dependents per product module against `max_dependents`; core and design_system are not counted (ARCH-12) |
| `script/ci/touch_rate` | Scheduled, once there are at least 3 product modules, not counting the examples: share of merged pull requests touching the kernel (ARCH-12) |
| `script/ci/guard_approval` | Fails when a guard file other than a ratchet file changed without an approving review from a listed owner, through the GitHub API (WF-03) |
| `script/ci/production_routes` | Boots production as a dummy boot (the committed `.env.ci.production` and dummy credentials, BE-08), walks the route set in-process (`bin/rails ci:production_routes`), and fails on a route that matches neither the committed `config/production_routes.yml` (app, core, and framework routes) nor the module routes derived from the registry, on a route it cannot classify, on a listed route the walk did not find, and on an empty walk (SEC-12) |
| `script/ci/deploy_preflight` | Every `.env.ci.production` key is a clear value in `config/deploy.yml` and `RAILS_MASTER_KEY` the app's only secret; before a deploy, the production credentials hold the same keys as the dummy ones; the final image stage runs as a non-root user; no secret file is tracked; `asset_path` is the Vite output; more than one host boots one at a time; `deploy_timeout` is set (OPS-06, SEC-07, CT-12, BE-22) |
| `script/ci/repo_rules` | Scheduled: the active ruleset for `main` matches `.github/rulesets/main.json`, the tag ruleset matches `.github/rulesets/release_tags.json`, and every required check name matches a job (WF-03, WF-05) |
| `script/ci/actions_pinned` | Parses every workflow and composite action as YAML: every remote `uses:` pinned to a full commit SHA with a version comment, every `docker://` image by digest (WF-07) |
| `script/ci/workflow_policy` | Workflow permissions (top level exactly `contents: read`, `write` only on its allow-list), `timeout-minutes` on every job that runs steps, `ci-ok`'s `needs:`, and no pull request code checked out in a `pull_request_target` or `workflow_run` workflow except the release checkout guarded by its `if:` (WF-03, WF-07, TS-09) |
| `script/ci/release` | The release workflow's one step: a Release exists → end; a tag without a Release → create the Release; otherwise check `VERSION` and create the tag and Release in one API call; `--check` runs the `VERSION` checks on a pull request (WF-05) |
| `script/ci/pins`, `script/ci/generator_smoke`, … | The rest of `script/ci/`, each named in `09_enforcement.md` |

## Adopting Rafelo

### A new application

1. On the host, install Docker (Docker Desktop, OrbStack, or similar) and an
   editor that supports Dev Containers. Nothing else is needed, and no cloud
   service (OPS-09).
2. Create the app from Rafelo's application template
   (https://github.com/yutna/rafelo) inside a throwaway container, so
   nothing is installed on the host (GEN-07):

   ```sh
   # on the host: the only command that runs outside the Dev Container
   docker run --rm -it --user "$(id -u):$(id -g)" -e HOME=/tmp \
     -v "$PWD":/work -w /work ruby:<pinned> \
     sh -c 'gem install rails -v <pinned> && rails new <app> -d postgresql --devcontainer --skip-javascript --skip-hotwire --skip-jbuilder --skip-test -m <template>'
   ```

   The template asserts these options. Verify when adopting that Rails 8.1
   accepts this flag set and that the image has git.
3. The `rails new` flags select PostgreSQL and the Dev Container. The template
   derives the namespace from the app name and copies in the kernel
   (`engines/core`, `engines/design_system`, the generators, `script/ci/`,
   `bin/check`, `bin/kernel_update`, `spec/fixtures/hostile_urls.json`), the guards (`09_enforcement.md`), the
   example engines, these files as `docs/architecture/`, and the AI files
   (`AGENTS.md`, the engine guides, `.opencode/skills/`;
   `14_working_with_ai.md`). It writes `KERNEL_VERSION` (GEN-07).
4. Open the repository in its Dev Container, run `bin/setup --skip-server`,
   then `bin/ci`. The untouched template is green.
5. Resolve the stack again (see above), keep the default circuit-breaker
   library or swap it (ADR-30), commit both lockfiles, and keep `bin/ci` green.
6. Learn from the example engines, then generate your own:
   `bin/rails generate rafelo:module <name>` for a product area and
   `bin/rails generate rafelo:domain <name>` for a concept several modules share
   (`08_generators.md`). Delete the example engines once they stop teaching;
   nothing outside `example_*` may depend on them (GEN-08).
7. Assign CODEOWNERS for `engines/core`, `engines/design_system`, and every
   guard file except the ratchet files, which the ratchet check covers
   (ARCH-12), and have your AI adapt the shipped AI files as
   `14_working_with_ai.md` describes.
8. Set up logging, error reporting, backups, and deployment from
   `13_operations.md` before the first real user.

### An existing Rails application

Existing code stays in `app/` and moves into engines one feature at a time.
Engines cannot import `app/`, so the guards, core, and design_system come
first, then one module migrated end to end as the exemplar, then one feature
per pull request. `14_working_with_ai.md` describes the order and how AI
helps without refactoring legacy code outside the feature in hand. A project
that is not a Rails application is a rewrite, and out of scope.

## The kernel after adoption

The template is copied in, not installed as a dependency (ADR-27). After
adoption the kernel (`engines/core`, `engines/design_system`, the generators,
`script/ci/`, `bin/check`, `bin/kernel_update`, and
`spec/fixtures/hostile_urls.json`) belongs to you, security
included.

- `KERNEL_VERSION` records the template release your copy is based on.
- `bin/kernel_update <version>` produces a three-way merge of your copy, the
  base version, and the new version, and leaves conflicts for you to resolve.
  By default it updates core, the generators, `script/ci/`, `bin/check`,
  `bin/kernel_update`, `spec/fixtures/hostile_urls.json` (FE-18), and the
  guard configurations; design_system only
  folder by folder on request (`--include design_system/<folder>`), because
  you restyle it. After the
  merge, `KERNEL_VERSION` names the new release; run `bin/ci` before
  merging the pull request.
- The template's own CI proves the update path on every release: it adopts
  release N-1, updates it to N, and runs `bin/ci`.
- Report a vulnerability in the template through its `SECURITY.md`. Template
  fixes reach your copy through `bin/kernel_update`; keeping your copy secure
  is your responsibility.

## Extension points and out of scope

These are deliberately not part of Rafelo. Each needs an ADR before it
is added.

| Topic | Guidance |
| --- | --- |
| Multi-tenancy | Derive the tenant from the viewer's upstream identity, never from client input. Every cache key and audit record then includes the tenant. |
| Server-side rendering | Not used (ADR-22). |
| Offline / PWA | Out of scope: offline caching conflicts with `no-store` and history clearing (SEC-05, SEC-09). |
| File uploads | Use Active Storage direct uploads, or direct-to-upstream signed uploads when the upstream owns the file. If the BFF must proxy, stream with a size limit and an allow-list of content types. |
| Rich text | Needs an HTML sanitizer inside one design_system component, chosen by ADR (FE-18). |
| Realtime | Optional pattern in `05_frontend.md`, signals only (ADR-23). |
| Events between engines | Not used by default. If added, event names are constants in the publisher's public surface (ARCH-10). |
