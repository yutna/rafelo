# AGENTS.md — Rafelo

Read this before writing or reviewing code. Full rules live in
`docs/architecture/`; this file points to them by ID and never restates them.
Each engine has its own `AGENTS.md`: read it before you change that engine.

## What this app is

A Rails BFF in front of named upstream APIs. Rails owns sessions, edge
authorization, page props, i18n, every upstream call, and every URL a page
needs; PostgreSQL holds only what the BFF owns. React renders pages through
Inertia; Tailwind CSS styles them.

Code lives in engines (ARCH-04): the kernel engines `core` (`@core/`) and
`design_system` (`@design_system/`), domain engines for shared concepts, and
product modules with routes and pages. An engine uses only the engines its
`package.yml` declares, and only their public surface (ARCH-08, ARCH-09).
`app/` composes the engines; no engine imports it. `engines/example_*` are
examples to learn from; nothing else depends on them.

## When the user asks for a change

Load the `deliver-request` skill and follow it. The user says what they want in
plain words; you take it to a merged pull request, ask only what the code and
the docs cannot answer, and list anything a person must decide instead of
deciding it (ADR-32).

## Commands

Everything runs inside the Dev Container (OPS-09).

```sh
bin/setup --skip-server      # gems, npm packages, database
bin/dev                      # Rails + Vite
bin/check <engine>           # fast checks for one engine; run after each change
bin/ci                       # the full gate; must pass before a PR is ready
bin/kernel_update <version>  # merge a new kernel release into this app
npm run e2e                  # Playwright

bin/rails generate rafelo:module <name>                  # product module
bin/rails generate rafelo:domain <name>                  # domain engine
bin/rails generate rafelo:page <module> <resource> --actions=index,show,new,edit
bin/rails generate rafelo:rename_module <old> <new>
bin/rails generate rafelo:move_page <from> <to> <resource>
```

Documentation and contracts are generated, not hand-edited:

```sh
npm run docs:check           # rule/ADR IDs, paths, and the envelope table
npm run contracts:check      # page schemas and the shared contract
npm run errors:check         # error catalog
npm run i18n:check           # locale catalogs
```

## How to decide

1. Current library documentation for API details.
2. `10_decisions.md` (ADRs).
3. The topic rule files (`01`–`13`).
4. This file and the project's other AI instruction files (they cite rules,
   never restate them).
5. General advice or skills.

Project decisions win over general advice. If a rule seems wrong, propose an
ADR change; do not work around it.

## The rules you will touch most

| ID | In one line |
| --- | --- |
| ARCH-02 | The browser never calls an upstream; gateways do, through a named client. |
| ARCH-04 | Know the engine kind; never import `app/` (`@/`) from an engine. |
| ARCH-05 | Code two engines use is one engine's public interface; never copy it. |
| ARCH-08 | Depend only on engines declared in `package.yml`; no cycles. |
| ARCH-09 | Use another engine only through `engines/<engine>/app/public/` or `@<engine>/public/` (for core and design_system, anything outside `internal/`). |
| ARCH-10 | No reflection, no other engine's tables, own i18n namespace; links are built by props objects through `context.urls` and arrive in props, never built in TypeScript. |
| ARCH-13 | No state outside PostgreSQL or the Active Storage service. |
| BE-01 | Action = authorize → gateway → props with the factory-built `PageContext` → render. |
| BE-03 | Permission keys are constants generated from `engines/<module>/config/permissions.yml`, never strings. |
| BE-04 | Props objects are pure; never read `Current` inside them. |
| BE-16 | Stay inside the upstream call budget; concurrency only through `Rafelo::Core::Executor`. |
| BE-17 | Cache only through `ScopedCache` with `module:`; viewer data never under a shared key. |
| BE-20 | No upstream call inside a database transaction. |
| BE-22 | Migrations are zero-downtime: expand now, contract in a later release. |
| BE-25 | Feature flags are evaluated on the server and reach the UI through `can`. |
| SEC-02 | Upstream tokens never reach props, logs, URLs, or browser storage. |
| CT-01 | Every page uses the envelope; `definePage` lists the page's `can` keys. |
| CT-08 | Every string exists in every configured locale; no placeholder ships. |
| CT-10 | Props are visible to the viewer; pick fields by allow-list. |
| CT-12 | Contract changes are additive first; old tabs reload via the asset version. |
| FE-01 | page → screen → container → component; each page renders one screen. |
| FE-04 | Local state only through `useDomainReducer` or `useUiState` (design_system widgets excepted). |
| FE-07 | Use design_system controls, never raw `<button>`/`<input>`/`<select>`/`<textarea>`. |
| FE-08 | ECharts and TanStack Table only through design_system wrappers. |
| FE-09 | Every interactive element and state has a `testId`. |
| FE-11 | Format dates, numbers, and money only with `@design_system/formatters`. |
| FE-18 | No `dangerouslySetInnerHTML`; URLs arrive in props, built by Rails, and pass `isSafeUrl` (`@design_system/safe_url`). |
| FE-20 | In `th`, every year shown or typed is Buddhist Era; the wire stays Gregorian; Rails formats dates only with `Rafelo::Core::DateFormatter`. |
| OOP-03 | Throw only for invariants; input from a person is checked by `issues()`. |
| OOP-05 | Class instances never enter props or React state; use `toPlain()`. |
| TS-02 | Every page spec checks schema, SQL and upstream call budgets, props budget at the maximum page size, `have_resolvable_hrefs`, and `match_policy_capabilities`. |
| TS-04 | Tests select by role with an accessible name, or by test id. |
| WF-03 | Conventional Commits PR titles, squash merge, never push to `main`. |

## Never

- Loosen a guard to make something pass: ESLint, RuboCop and custom cops,
  dependency-cruiser, Packwerk, a `package.yml` `dependencies:` list,
  `config/budgets.yml`, any `ratchets.yml` count, canary fixtures,
  `config/production_routes.yml`, `script/ci/`, `config/ci.rb`, `.github/` (CI
  workflows included). Propose the change in the pull request; a person
  approves it (for a ratchet count, an owner approves a rise through the
  ratchet check; a fall needs no approval).
- Copy code from another engine, or reach its private code by any route
  (ARCH-05, ARCH-09, ARCH-10).
- Read or print `.env`, `config/master.key`, `config/credentials/production.key`,
  the decrypted production credentials (`bin/rails credentials:show
  --environment production`), or tokens. Put secrets or real personal data in
  code, tests, fixtures, logs, or issues; a new secret goes into the dummy
  credentials with a dummy value, and a person adds the real one (BE-08).
- Disable Brakeman, an audit, or a CI step. A disable comment needs a reason
  (FE-10), a skip a linked issue (TS-05); both count against the ratchet.
- Add a dependency without an issue, or a framework-level library without an
  ADR (WF-06).
- Edit generated files (contracts, `*.generated.ts`, locale JSON, generated
  tsconfig files, `engines/design_system/api.d.ts`). Regenerate them.
- Use the service token for a viewer (SEC-10); render a page from a POST,
  PATCH, or DELETE (BE-13); use a cache for idempotency (BE-15); log
  parameters, props, headers, or upstream bodies (OPS-01).

## Skills and layers

The request workflow and task skills live in `.opencode/skills/` and load
when a task matches. Each starts from a generator, the guard's own message, or
the approved map, and names the rule IDs that apply; never hand-write what a
generator writes. The template currently ships:

- `deliver-request`: the workflow from a plain-language request to a merged
  change (WF-01, WF-02, WF-03, WF-04).
- `add-copy`: add a string in every configured locale (CT-08).
- `add-design-system-component`: add a reusable UI control with its API,
  tests, and visual baseline (FE-07, FE-09, FE-21, TS-11).
- `add-module`: start a product module or domain engine from the generator
  and keep the declared graph acyclic (GEN-01, GEN-05).
- `add-read-page`: add an index or show slice from `rafelo:page` (GEN-02).
- `add-write-action`: add a new/edit write slice with validation, idempotency,
  and 303/error behavior (GEN-02, BE-13, BE-15).
- `expose-public-interface`: the ARCH-05 ladder when another engine needs the
  code; a new `dependencies:` entry is a guard change, so say so in the pull
  request (ARCH-08, ARCH-09).
- `fix-failing-guard`: read the guard's message, fix the code, rerun the
  check; a suspected guard bug is a proposal for a person (ADR-32).
- `migrate-a-feature`: move one legacy feature from the approved migration
  map, one feature per pull request (WF-02).

Design skills (`.opencode/skills/oo-*`, a pinned copy of the object-oriented
design skills pack; never edit it):

| Work | Load |
| --- | --- |
| Designing a class or module, or moving responsibilities | `oo-design` |
| Plain Ruby objects (value objects, props objects) | `oo-ruby` |
| TypeScript classes in `domain/` and `forms/` (OOP-01–OOP-10) | `oo-typescript` |
| What Rails or React builds and wires | `oo-working-within-a-framework` |
| Reviewing a diff | `oo-reviewing-object-design` |

A rule or an ADR wins over the pack.

## Definition of done

- Behaviour is covered at the cheapest useful level (TS-01).
- Generated files are regenerated and committed; every new string exists in
  every configured locale (CT-08).
- No new N+1 query or per-row upstream call; budgets hold, no ratchet rises,
  axe is clean.
- No guard file changed without a person's approval recorded in the PR (a
  ratchet count that only falls needs none).
- Docs or ADRs are updated when behaviour or a decision changed.
- `bin/ci` is green and the pull request is linked to its issue.
