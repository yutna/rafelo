---
name: add-design-system-component
description: Use when adding or changing a reusable design_system component, its API, its tests, or its visual baseline.
---

# Add a design_system component

## Inputs to collect

- The component's job, its props, its states (empty, loading, error, disabled),
  and the pages or modules that will use it.
- The accessibility contract: role, accessible name, keyboard behavior, and
  focus handling.
- The copy keys it needs in every configured locale and the visual baseline
  it changes.

## Build

- Add the component under
  `engines/design_system/app/frontend/components/<name>/`; design_system is a
  leaf that imports nothing from the repository and only `Link` and
  `Deferred` from Inertia.
- Export it through the public surface and update
  `engines/design_system/api.d.ts` with `npm run api:generate` if the
  repository generates it; never hand-edit a generated file.
- Use only design_system controls and wrappers; no raw `<button>`, `<input>`,
  `<select>`, or `<textarea>` in a page.
- Add the component test with role/accessible-name or test-id selectors, and
  the visual baseline under the design_system fixtures.
- Add copy in every configured locale; keep the design_system i18n namespace.
- Keep ECharts and TanStack Table behind the design_system wrappers.

## Rules that apply

FE-03; FE-07; FE-08; FE-09; FE-11; FE-21; TS-11; CT-08; ARCH-09.

## Check

- `bin/check design_system`
- `npm run api:check`
- `npm test`
- `bin/ci`

## Design skills

Load `oo-design` before shaping the component API and `oo-typescript` for the
component's framework-free classes; load `oo-working-within-a-framework` for
React behavior and `oo-reviewing-object-design` when reviewing the diff. A
rule or ADR wins over the pack.

## Done when

The component has a small documented API, every state and accessible name is
covered by tests, the visual baseline is current, copy exists in every
configured locale, and `bin/ci` is green.
