---
name: fix-failing-guard
description: Use when a guard, linter, cop, boundary check, budget, ratchet, contract check, or canary fails during bin/check or bin/ci.
---

# Fix a failing guard

## Read the failure

- The guard's message names the rule ID and the fix; read the rule it cites
  before changing code.
- Run the narrowest command the message prints to reproduce it.

## Fix the code

1. Change the code the guard points at; never change an expectation to match
   a wrong result.
2. Rerun the narrow command until it passes.
3. Run `bin/check <engine>` for the engine you touched, then `bin/ci`.

## Never

- Edit a guard file: the lint, architecture, and RuboCop configuration and
  custom cops, any `package.yml`, `config/budgets.yml`, a `ratchets.yml`
  count, a canary fixture, `config/production_routes.yml`, `script/ci/`,
  `config/ci.rb`, or `.github/` (09_enforcement.md, ADR-32).
- Add a disable comment, skip, ignore entry, baseline, or a higher budget or
  ratchet count to get green. A skip still needs a linked issue and counts
  against the ratchet (TS-05, FE-10).
- Bypass the check, or mix a guard change into a feature pull request.

## When the guard looks wrong

Stop and write the proposal into the pull request description for a person:
the command, the input, the message, and the fix you expected. If the fix
changes a guard file, put it in its own pull request for a person to approve
(ADR-32); leave the failing check visible.

## Rules that apply

`09_enforcement.md`; ADR-32; TS-07; TS-05; FE-10.

## Check

- the failing check's narrow command
- `bin/check <engine>`
- `bin/ci`

## Design skills

Load `oo-reviewing-object-design` when the fix changes object boundaries.
A rule or ADR wins over the pack.

## Done when

The failing check passes for the reason the rule names, no guard, budget,
baseline, or ratchet was relaxed, `bin/ci` is green, and any suspected guard
bug waits in a proposal for a person.
