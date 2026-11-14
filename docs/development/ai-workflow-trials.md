# AI workflow trials

Maintainer evidence for the request workflow and the task skills. This file is
not part of the template payload (`docs/development/` never ships).

## Method

The trials ran in a fresh app adopted from `main` at `9642692` (template
`v0.21.0`) with `template/template.rb`, pushed to the public
[`yutna/rafelo-trials`](https://github.com/yutna/rafelo-trials) repository on
2026-11-14. That repository is the only repository outside `rafelo` the
maintainer created or changed.

Each trial ran in a fresh subagent with no earlier conversation. The request
was the one sentence a user would type; the app's own `AGENTS.md`, skills, and
guards were the only instructions. A trial passes when it reaches a merged
pull request with green CI and no human edit, asks only questions the files
cannot answer, edits no guard, and leaves a clean tree.

Paths under engines/billing and spec/requests/billing in this file refer to
the trial app, not this repository.

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

| # | Trial | Issue / PR | Questions | Guard failures | Files outside the task | First push green | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Read page | #11 / #12 | none | Packwerk and graph canaries (spec used a module constant) | none | yes, after the local fix | Pass |
| 2 | Write action | #13 / #14 | none | none | none | yes | Pass |
| 3 | New product module | #9 / #10 | none | RuboCop blank line, kernel spec key collision, drift spec permission | kernel spec fixture, generated graph/lock files | yes, after in-app fixes | Pass after template fix (#386) |
| 4 | Design-system component | #15 / #16 | none | none | none | yes | Pass |
| 5 | Copy change (en/th) | #17 / #18 | none | none | none | yes | Pass |
| 6 | Obvious guard break | #19 / #20 | none | drift spec (new permission missing from the fake upstream catalog) | core grants fixture | no | Pass |
| 7 | Ambiguous request | TBD | TBD | TBD | TBD | TBD | TBD |
| 8 | Person's decision (new library) | TBD | TBD | TBD | TBD | TBD | TBD |

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
    does not depend on engines/billing`. The fix used the grant string
    `"billing:invoice:read"` in the spec, matching the example specs. No
    `package.yml`, guard, or budget changed.
- **Files outside the task:** none. Production changes are inside
  engines/billing`; the generator-required request spec is
  spec/requests/billing/invoices_spec.rb`. A billing-owned fixture was added
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
- **Files outside the task:** none. Changes are confined to engines/billing`,
  its generated outputs, and spec/requests/billing/invoices_spec.rb`.
- **Allowed fixture/manifest changes:** added a synthetic create-response
  fixture and `create` to engines/billing/config/permissions.yml`, then
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
- **Result:** pass after the template defects were fixed. The generator and
  kernel-spec fixes are PR #386; a fresh module run after that fix is the
  re-run evidence. About 21 minutes and 119k input / 9k output tokens.

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

TBD

## Trial 8 — decision for a person

TBD

## Fixes made from the trials

- **PR #386** — `rafelo:module` no longer writes the blank line RuboCop
  rejects, and the kernel `Modules` spec uses the neutral `:ledger` fixture key
  so a generated `billing` module cannot collide with it.
- No trial edited a guard, budget, ratchet, baseline, canary, workflow, or CI
  step.
