---
name: migrate-a-feature
description: Use when moving one legacy Rails feature from app/ into an engine in a brownfield adoption, following the approved migration map.
---

# Migrate a feature

## Inputs to collect

- The approved migration-map entry: the feature, its source in `app/`, the
  target engine, what it needs first, and its order.
- The target engine's kind and allowed dependencies, and the exemplar module
  or example engine to imitate.
- The feature's routes, pages, upstream calls, permissions, copy, and tests in
  the legacy code.

## Before you start

- The map must already be approved by a person; a missing or changed entry
  becomes a map proposal, not a decision (ADR-32).
- One feature per pull request (WF-02). Do not refactor legacy code outside
  the feature being moved.
- Dependencies move first: expose them through `expose-public-interface`, or
  extract a domain engine with `rafelo:domain` (ARCH-05).

## Move

1. Generate the target slice: `rafelo:page` for pages and actions, and
   `rafelo:module` or `rafelo:domain` for a new engine (GEN-01, GEN-02,
   GEN-05). Do not hand-scaffold what a generator writes.
2. Move the feature code into the generated files; replace private reaches
   with the owning engine's public surface and declare only real dependencies
   (ARCH-08, ARCH-09).
3. Move the routes, registry entry, permissions, copy, contracts, fixtures,
   and specs with the code; keep behaviour identical to the legacy feature.
4. Regenerate what the move changed: `npm run contracts:generate`,
   `npm run permissions:generate`, `npm run i18n:generate`,
   `npm run aliases:generate`, `npm run graph:generate`.
5. Delete the legacy code in the same pull request and lower the
   `legacy_lint_paths` ratchet count; a fall needs no approval (WF-03).
6. Keep every guard: a failing boundary, budget, or ratchet goes through
   `fix-failing-guard`; never add the old path back or raise a count.

## Decisions a person owns

Record these at the top of the pull request; prepare them, never decide them
(ADR-32):

- a new engine, or a dependency the map did not approve;
- a budget, ratchet, or baseline raise;
- an ADR (a framework-level library needs one, WF-06);
- a guard-file change, including removing a legacy path from the lint
  configurations;
- a real secret (BE-08), or a business rule the legacy code leaves unclear.

## Rules that apply

ARCH-05; ARCH-08; ARCH-09; ARCH-10; GEN-01; GEN-02; GEN-05; WF-02; WF-03;
WF-06; CT-08; TS-01; BE-22; ADR-32.

## Check

- `bin/check <engine>`
- `bin/packwerk check`
- `npm run graph:check`
- `bin/ci`

## Design skills

Load `oo-design` before choosing what moves together, and
`oo-working-with-legacy-code` before touching the legacy feature. Load
`oo-ruby` for Ruby value and props objects, `oo-typescript` for `domain/` and
`forms/` classes, and `oo-working-within-a-framework` for the Rails and React
code the move touches. Load `oo-reviewing-object-design` when reviewing the
diff. A rule or ADR wins over the pack.

## Done when

The feature works from its engine, the legacy copy is gone, no engine reaches
private code, the graph is acyclic and current, every test moved or is
replaced at the cheapest useful level, the ratchet only fell, and `bin/ci` is
green.
