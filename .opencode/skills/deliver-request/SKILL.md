---
name: deliver-request
description: Use whenever the user asks for a change to the app in plain words; take the request to a reviewed, merged pull request, or stop with a clear hand-over for the decisions a person owns.
---

# Deliver a request

## 1. Understand

- Restate the outcome in a sentence or two.
- Answer everything the code, the spec, and the upstream documentation can
  answer.
- Ask the user only what they can answer: a business rule, which fields a
  viewer may see, an undocumented upstream endpoint. Ask all questions at
  once, in plain words.

## 2. Plan

- Split the request into deliverable outcomes (WF-01); open one issue per
  outcome.
- Pick the task skills each outcome needs: `add-read-page`,
  `add-write-action`, `add-module`, `expose-public-interface`,
  `add-design-system-component`, `add-copy`; use `migrate-a-feature` in a
  brownfield app when the approved map says so.
- Name the design skills from the root guide that apply to the layers
  involved.
- Tell the user the plan and the decisions you expect to need from a person.

## 3. Build

One issue at a time (WF-02):

1. Branch and open a draft pull request with `Closes #<issue>`.
2. Start from the generator the task skill names; never hand-write what a
   generator writes.
3. Write the test at the cheapest useful level first, then fill the slice.
4. Run `bin/check <engine>` until green, then `bin/ci`.
5. A failing guard goes through `fix-failing-guard`; never edit the guard,
   add a disable, raise a budget, or add a baseline (ADR-32).

## 4. Hand over

- A green pull request that needs no person's decision: mark it ready and
  squash-merge once its required checks pass, through the merge queue or,
  where there is none, under the WF-03 fallback.
- One that needs a person: keep it open and list the decisions at the top of
  its description, prepared but not decided (ADR-32):
  - a guard-file change;
  - a budget, ratchet, or baseline raise;
  - an ADR (a framework-level library needs one, WF-06);
  - a change to an AI instruction file;
  - a real secret (BE-08).
- At the end of a slice, open the review gate with drafted findings; a person
  confirms their severity and closes it (WF-04).

## 5. Report

Tell the user in plain words:

- what changed;
- how to try it;
- what waits for a person, and which pull request or issue holds it.

## Rules that apply

WF-01; WF-02; WF-03; WF-04; WF-06; BE-08; ADR-32; GEN-01; GEN-02.

## Check

- `bin/ci` on every pull request
- `npm run docs:check` when an AI instruction file changed

## Design skills

Load the layer skills the task skills name (`oo-design`, `oo-ruby`,
`oo-typescript`, `oo-working-within-a-framework`) and
`oo-reviewing-object-design` for each diff. A rule or ADR wins over the pack.

## Done when

Every outcome has its issue, each merged pull request links its issue and is
green, no person's decision was made by the AI, and the user has a plain-word
report of what changed and what waits.
