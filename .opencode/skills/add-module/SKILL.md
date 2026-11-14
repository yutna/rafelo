---
name: add-module
description: Use when creating a new product module or domain engine, or when deciding which generator starts a new bounded context.
---

# Add a module

## Inputs to collect

- The engine name, its kind (product module or domain engine), and the concept
  it owns.
- The upstreams it calls, the engines it may depend on, and the navigation
  label/icon for a product module.
- The permission prefixes and the domain concepts it exposes publicly.

## Generate

Product module:

```sh
bin/rails generate rafelo:module <name> --icon <icon>
```

Domain engine:

```sh
bin/rails generate rafelo:domain <name>
```

The generator writes the engine, guide, `package.yml`, locale files, public
surface, frontend directories, and specs, and regenerates the graph, aliases,
contracts, and catalogs. A product module also gets routes, the registry entry,
permissions, errors, budgets, ratchets, its contract folder, and `db/migrate/`.

## Fill in

- `engines/<name>/package.yml`: declare only the engines this one uses; a new
  dependency is a guard change to name in the pull request.
- `engines/<name>/config/module.rb` for a product module; a domain engine
  exposes its concept through `engines/<name>/app/public/` and
  `engines/<name>/app/frontend/public/`. Keep routes and pages out of domain
  engines.
- `engines/<name>/AGENTS.md`: the engine's kind, allowed dependencies, public
  surface, and what is special about it.
- A product module's `engines/<name>/config/locales/*.yml`,
  `engines/<name>/config/permissions.yml`,
  `engines/<name>/config/errors.yml`,
  `engines/<name>/config/budgets.yml`,
  `engines/<name>/config/ratchets.yml`, and `engines/<name>/db/migrate/`; a
  domain engine keeps the locale copy it exposes and adds only the config files
  it needs.
- The public Ruby and TypeScript files under `engines/<name>/app/public/` and
  `engines/<name>/app/frontend/public/`; never copy code from another engine.
- The smoke/request specs and any upstream fixture the module needs.

## Rules that apply

GEN-01; GEN-05; ARCH-03; ARCH-04; ARCH-06; ARCH-08; ARCH-09; ARCH-10; ARCH-12;
BE-03; BE-10; CT-08; WF-06.

## Check

- `bin/packwerk validate`
- `bin/packwerk check`
- `script/ci/engine_graph --check`
- `npm run aliases:check`
- `bin/ci`

## Design skills

Load `oo-design` before choosing the engine boundary and `oo-ruby` for the
Ruby surface; load `oo-typescript` for the public TypeScript classes and
`oo-working-within-a-framework` for the Rails engine wiring. Load
`oo-reviewing-object-design` when reviewing the diff. A rule or ADR wins over
the pack.

## Done when

The engine has one clear responsibility, declares only its real dependencies,
exposes a small public surface, has its guide and copy, the generated graph and
aliases are current, and `bin/ci` is green.
