# Rafelo::DesignSystem

The design-system engine. It is a leaf: it imports nothing from this repository,
not even core, and takes only `Link` and `Deferred` from Inertia.

- It is the only place for the UI libraries, tokens and formatters (FE-07, FE-08, FE-11).
- Its public API is the files outside `internal/`; the committed `api.d.ts`
  makes changes visible (ARCH-09, FE-21).
- It has its own `design_system` i18n namespace (CT-08).
- Run `bin/check design_system` before `bin/ci`.
