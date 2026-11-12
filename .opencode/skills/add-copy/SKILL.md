---
name: add-copy
description: Use when adding or changing a user-facing string, when a page needs copy in every configured locale, or when a translation key must be generated for the frontend.
---

# Add copy

## Inputs

- The owning engine (`core`, `design_system`, app, or a product module) and its namespace.
- The key under that namespace and the English copy.
- The value for every other configured locale, translated or a visible `[<locale>]` placeholder.

## Build

1. Add the English string to `engines/<engine>/config/locales/en.yml` under `<engine>:`; for app pages use `config/locales/en.yml` under `app:`.
2. Add the same key to every other configured locale file. Do not leave a blank value; use a visible placeholder until a translator fills it.
3. Run `npm run i18n:generate` and commit the generated JSON.
4. Read the string in the page with the i18n resolver; never hardcode user-facing English.

## Check

- `npm run i18n:check`
- `npm run typecheck`
- `bin/ci`

## Design skills

Load `oo-design` before changing a props or page object. Load `oo-typescript` for TypeScript page code and `oo-working-within-a-framework` for React components. Load `oo-reviewing-object-design` when reviewing the diff. A rule or ADR wins over the pack.

## Done when

Every configured locale has the key, the generated JSON is current, the page reads the string through i18n, and `bin/ci` is green.
