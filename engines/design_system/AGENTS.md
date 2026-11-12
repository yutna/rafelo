# Rafelo::DesignSystem

The design-system engine. It is a leaf: it imports nothing from this repository,
not even core, and takes only `Link` and `Deferred` from Inertia.

- It is the only place for the UI libraries, tokens and formatters.
- Its public API is the files outside `internal/`; the committed `api.d.ts`
  will make changes visible once the component set exists.
- It has its own `design_system` i18n namespace.
- Run `bin/check design_system` once the engine has a test suite.
