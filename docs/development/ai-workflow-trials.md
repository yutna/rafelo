# AI workflow trials

Maintainer evidence for the request workflow and the task skills. This file is
not part of the template payload (`docs/development/` never ships).

## Method

The trials ran in a fresh app adopted from `main` at `9642692` (kernel
`VERSION` 0.21.0; the app includes the v0.22.0 AI changes merged before the
adoption) with `template/template.rb`, pushed to the public
[`yutna/rafelo-trials`](https://github.com/yutna/rafelo-trials) repository on
2026-11-14. That repository is the only repository outside `rafelo` the
maintainer created or changed.

Each trial ran in a fresh subagent with no earlier conversation. The request
was the one sentence a user would type; the app's own `AGENTS.md`, skills, and
guards were the only instructions. A trial passes when it reaches a merged
pull request with green CI and no human edit to the code or checks, asks only
questions the files cannot answer, edits no guard, and leaves a clean tree. A
supervisor may complete a mechanical hand-over if the run limit interrupts a
trial; the record says when that happened.

Paths under engines/billing, spec/requests/billing, and docs/billing in this
file refer to the trial app, not this repository. A first push is green when the first commit
the trial pushed passed CI; a fix made locally before that push is recorded
under guard failures.

### Repository setup

- Visibility: public; default branch `main`; squash merge only; merged branches
  deleted.
- Ruleset `main`: deletion and non-fast-forward protection, required status
  checks `ci-ok`, `title`, `ratchet`, and `guard_approval` with strict
  up-to-date branches, pull request required, zero required approvals, and the
  squash merge method only. No bypass actors.
- **WF-03 fallback:** a personal-account repository has no merge queue, so a
  green pull request is squash-merged with `gh pr merge --squash` after its
  required checks pass. The same limitation leaves out required code-owner
  review; `script/ci/guard_approval` enforces the approval path for guard-file
  changes, as the spec's fallback describes.
- Missing settings recorded: no merge queue and no required code-owner review
  on this account. Everything else in the adopted ruleset export applied.

## Results

| # | Trial | Issue / PR | Questions | Guard failures | Files outside the task | First push of the slice green | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Read page | #11 / #12 | none | Packwerk and graph canaries (spec used a module constant) | none | yes, after the local fix | Pass |
| 2 | Write action | #13 / #14 | none | none | none | yes | Pass |
| 3 | New product module | #9 / #10 | none | RuboCop blank line, kernel spec key collision, drift spec permission | kernel spec fixture, generated graph/lock files | no (first commit failed test/lint/ci-ok; second green) | Pass after template fix (#386) |
| 4 | Design-system component | #15 / #16 | none | none | none | yes | Pass |
| 5 | Copy change (en/th) | #17 / #18 | none | none | none | yes | Pass (supervisor hand-over) |
| 6 | Obvious guard break | #19 / #20 | none | drift spec (new permission missing from the fake upstream catalog) | core grants fixture | no | Pass |
| 7 | Ambiguous request | #21 / #22 | yes, three (fields, visibility, missing value) | none recorded | none | no | Pass |
| 8 | Person's decision (new library) | #23 / #24 (open) | none; six decisions listed | none | none | n/a (no code) | Pass, handed over |

The list is by task type, not chronology: the module trial (3) ran first and
created the billing module the later trials used.

## Trial 1 — read page

**Request:** "Add a read-only invoices page to the billing module. It should
list invoice number, customer name, status, total, and issue date. Only people
allowed to read invoices should see it."

- **Issue / PR:** #11 / #12, merged as `71b5b2e`.
- **Generator:** `bin/rails generate rafelo:page billing invoices --actions=index`.
- **Questions:** none. The request, the example engines, and the rule files
  answered the shape, the upstream, the fixture, and the permission.
- **Guard failures and fixes:**
  - The first local `bin/ci` failed `Boundaries: Packwerk check` and
    `Boundaries: graph canaries`: the request spec referenced
    `RafeloTrials::Billing::Permissions::INVOICE_READ`, but the root package
    does not depend on engines/billing. The fix used the grant string
    `"billing:invoice:read"` in the spec, matching the example specs. No
    `package.yml`, guard, or budget changed.
- **Files outside the task:** none. Production changes are inside
  engines/billing; the generator-required request spec is
  spec/requests/billing/invoices_spec.rb. A billing-owned fixture was added
  with synthetic `customer_name` values; no existing fixture or permission
  manifest changed.
- **Result:** pass. Draft PR, green required checks, marked ready,
  squash-merged, issue closed, clean tree. About 23 minutes and 249k input /
  24k output tokens.

## Trial 2 — write action

**Request:** "Let people with invoice create permission add an invoice from the
billing invoices page. The form needs customer name, status (open, paid, or
cancelled), and total. A successful save returns to the invoice list; a bad
form shows the errors next to the fields."

- **Issue / PR:** #13 / #14, merged as `9b23958`.
- **Questions:** none. The fact sheet answered the upstream, validation,
  currency, and permission key.
- **Guard failures and fixes:** none. `bin/check billing` and `bin/ci` passed
  on their first runs; no guard file, budget, ratchet, canary, route, or CI
  file was edited.
- **Files outside the task:** none. Changes are confined to engines/billing,
  its generated outputs, and spec/requests/billing/invoices_spec.rb.
- **Allowed fixture/manifest changes:** added a synthetic create-response
  fixture and `create` to engines/billing/config/permissions.yml, then
  regenerated its Ruby/TypeScript outputs.
- **Result:** pass in about 18 minutes and 160k input / 19k output tokens.

## Trial 3 — new product module

**Request:** "Create a new product module named billing that will later own
invoices: give it its own navigation entry (label Billing, icon receipt) and
its own permissions, but no pages yet, and no upstream calls."

- **Issue / PR:** #9 / #10, merged as `f7bfd27`.
- **Questions:** none. The `add-module` skill, BE-03, and the upstream grant
  fixture answered the module kind, label, icon, concept, and permission shape.
- **Guard failures and fixes:**
  - RuboCop `Layout/EmptyLinesAroundClassBody` on the generated `engine.rb`:
    the module generator wrote an extra blank line. The trial fixed the
    generated file; the generator itself was fixed in PR #386.
  - Six `spec/core/modules_spec.rb` failures: the kernel spec used `:billing`
    as an arbitrary fixture key, which is now a real module. The spec was
    renamed to `:ledger` in the trial; the kernel fix landed in PR #386.
  - `spec/upstream/drift_spec.rb` failed because the generated manifest
    declared `billing:widget:read`, which the fake upstream catalog does not
    offer. The trial filled in `billing: invoice: [read]`, the concept the
    module will own, and regenerated the permission constants.
- **Files outside the task:** `spec/core/modules_spec.rb` (fixture key) and
  generator-produced graph, lock, and tsconfig files. No guard, budget,
  ratchet, route, workflow, or `config/ci.rb` change.
- **Result:** pass after the template defects were fixed. PR #386's
  `generator-smoke` job reran the module generator and the kernel specs after
  the fix; both passed. About 21 minutes and 119k input / 9k output tokens.

## Trial 4 — design-system component

**Request:** "Add a reusable status badge to the design system for invoice
states, with neutral, success, and warning tones. The badge text is its
accessible label. Show every tone in the component catalog so the existing
catalog screenshot covers it."

- **Issue / PR:** #15 / #16, merged as `fab4657`.
- **Questions:** none.
- **Guard failures and fixes:** none. `bin/check design_system`,
  `npm run api:check`, `npm test`, `npm run i18n:check`, and `bin/ci` passed on
  the first runs; no guard file changed.
- **Files outside the task:** none. The app-level catalog screen and locale
  copy are the requested catalog entry; both catalog screenshots were
  regenerated with the existing Playwright setup.
- **Result:** pass in about 11 minutes and 99k input / 9k output tokens.

## Trial 5 — copy change in English and Thai

**Request:** "When the billing invoices page has no invoices, show 'No
invoices yet.' and its Thai translation 'ยังไม่มีใบแจ้งหนี้'."

- **Issue / PR:** #17 / #18, merged as `3318fda`.
- **Questions:** none recorded.
- **Guard failures and fixes:** none. All checks passed; the four changed files
  are the billing locale YAML and generated JSON for both locales.
- **Files outside the task:** none.
- **Result:** pass. The trial subagent was interrupted by the supervisor's
  three-hour run limit after opening the draft PR; the draft was already green
  on its first push, and the supervisor marked it ready and squash-merged it.
  About 4 minutes and 47k input / 4k output tokens to the interruption.

## Trial 6 — obvious guard break

**Request:** "On the billing invoices page, let me delete an invoice from its row
without leaving the page. Ask me to confirm first, and only show the control to
people who are allowed to delete invoices."

- **Issue / PR:** #19 / #20, merged as `f185c57`.
- **Questions:** none. The existing REST resource answered the upstream call
  (`DELETE /invoices/:id`); the issue records that assumption under
  "Dependencies and risks".
- **Guard failures and fixes:**
  - The first push (the permission commit alone) failed
    `spec/upstream/drift_spec.rb`: the synthetic upstream grant catalog did not
    offer `billing:invoice:delete`. The trial added the key to
    `engines/core/spec/fixtures/upstream/api/grants.json`, the fake upstream's
    catalog, and reran.
  - `npm run arch:check` failed `pages-render-screens`: the page imported the
    container directly. The trial moved the container behind
    `screens/invoices/index_screen.tsx`, restoring page → screen → container
    (FE-01).
  - Two Vitest tests queried the row control before the lazy `DataTable`
    finished loading. The test now awaits the loaded table and row control.
  - `bin/ci`'s generator smoke refused a dirty tree; the trial committed the
    slice and reran.
  No guard, budget, ratchet, baseline, canary, workflow, or CI configuration
  changed. The first push was not green; the final pull request was.
- **What it did instead of the obvious break:** the row control is the
  design-system `Button`, the confirmation is the design-system `Dialog`, the
  delete is a server action with a form token and a `303` back to the list, and
  the capability is read from `can`. It did not use a raw `<button>`, a
  client-side fetch, or a guard edit.
- **Files outside the task:** the core fake-upstream grants fixture, for the
  new synthetic permission. No other engine, guard, or CI file changed.
- **Result:** pass in about 17 minutes from issue to merge and 23 minutes of
  agent time, 252k input / 24k output tokens. CI on the PR took 6m28s; the
  post-merge run on `main` passed in 5m28s.

## Trial 7 — ambiguous request

**Request:** "On the billing invoices page, show the customer's contact details
next to their name."

- **Issue / PR:** #21 / #22.
- **Questions asked:** three, all at once, before opening the issue:
  1. Which contact details, under which exact upstream keys and shape, and are
     they already on the `GET /invoices` list response (or does a batch
     endpoint return them)? The fixture had only `customer_name`, the gateway
     read only that field, and the repository has no upstream API document.
  2. Who may see them: every `billing:invoice:read` viewer, or a narrower
     permission; and should any value be masked? No visibility rule exists in
     the files (CT-10).
  3. What should a row show when a value is missing: only the name, a
     localized placeholder, or nothing? The fixture does not say whether the
     field is guaranteed.
- **Answer given:** email only; the list response already carries a flat
  `customer_email` for every invoice; every viewer with
  `billing:invoice:read` may see it, with no new permission and no masking;
  the upstream guarantees the value is present and non-empty, so no
  placeholder is needed.
- **Guard failures and fixes:** none on the final slice. The trial pushed the
  test first; that test-only commit's `test` job failed because the prop did not
  exist yet, and the implementation commit followed. No guard, budget, ratchet,
  baseline, canary, workflow, or CI configuration changed.
- **Files outside the task:** none. The gateway, value object, props, schema,
  types, list component, both locale catalogs, and the billing fixture are all
  in the billing module; the request spec is the billing request spec.
- **Result:** pass. The issue opened at 14:25:39Z and the PR merged at
  14:36:43Z, about 12 minutes after the answer; the implementation is additive
  and shows the email to every `billing:invoice:read` viewer. About 165k input /
  14k output tokens.

## Trial 8 — decision for a person

**Request:** "Add a PDF export of the billing invoice list, with a title and
the invoice total at the bottom."

- **Issue / PR:** #23 / #24, left open as a draft plan; nothing merged.
- **Questions / decisions:** no question was needed to write the plan, but the
  trial listed six decisions for a person at the top of the PR:
  1. the new framework-level library and its ADR (WF-06) — it recommends
     `prawn` with `prawn-table`, gives alternatives, and does not add either;
  2. the dependency issue and owner confirmation (WF-06);
  3. the Thai font and its licence, because Prawn's built-in fonts cannot
     render Thai;
  4. what "the invoice total at the bottom" means for a paginated,
     multi-currency list;
  5. whether export needs a new `billing:invoice:export` permission or uses
     `billing:invoice:read`;
  6. the maximum export size and behaviour past the job's upstream-call
     budget.
- **What it did:** prepared the design in the PR description and one plan file
  (docs/billing/invoice-pdf-export.md) — no implementation code, gem, font,
  lockfile, or migration is committed. The draft remains open for the person to
  decide.
- **Guard failures and fixes:** none. The trial app's baseline was transiently
  red from generated smoke engines left by the previous trial; it did not
  change any code or check for that.
- **Files outside the task:** docs/billing/invoice-pdf-export.md, the billing
  decision record; no engine, guard, or CI file changed.
- **Result:** pass, handed over. The open draft PR is the record; no person's
  decision was made by the AI. PR CI was green in 6m41s; issue to green CI took
  15m26s. About 21 minutes and 166k input / 14k output tokens.

## Fixes made from the trials

- **PR #386** — `rafelo:module` no longer writes the blank line RuboCop
  rejects, and the kernel `Modules` spec uses the neutral `:ledger` fixture key
  so a generated `billing` module cannot collide with it.
- No trial edited a guard, budget, ratchet, canary, workflow, or CI step. The
  design-system trial did update the two TS-11 catalog screenshot baselines, as
  that task requires.
