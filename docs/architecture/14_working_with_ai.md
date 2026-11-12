# 14 — Working with AI

This file is a guide, not a rule file. It defines no rules; it cites the rules
in `01`–`13` by ID. It says which AI instruction files the template ships and
an adopter's AI adapts, what goes into each and what must never go in, how to
validate them, and how the answer differs for a new project and an existing
one.

The template ships a working set, so an AI can build on an adopted app from
the first session: the root `AGENTS.md`, an `AGENTS.md` in each kernel and
example engine (the generators write one into
each new engine), a request workflow that takes a plain-language request to a
merged change, one task skill per recipe, and a pinned copy of the
object-oriented design skills pack. They are the adopter's from adoption on:
the adopter's AI adapts them to the project's domain, upstreams, and tools,
and a person approves each change.

## The principle: tools guard, people decide, AI builds (ADR-32)

| Who | Does | Never |
| --- | --- | --- |
| Tools | check every rule that can be checked: linters, cops, Packwerk, dependency-cruiser, strict schemas, budgets, ratchets, and CI, each proven by a canary (TS-07, `09_enforcement.md`) | depend on someone remembering a rule |
| People | decide: ADRs, guard-file changes, budget and baseline raises, migration maps, review-gate severity (WF-04), and approval of AI instruction files | hand a decision to an AI reviewer |
| AI | builds: fills generated slices, writes code, tests, and copy, and drafts instruction files and migration maps | act as a guard, or loosen one to make something pass |

Three consequences follow:

- AI review may assist a person; it never counts as a guard. In
  `09_enforcement.md`, the status "review" means people.
- A rule that only an instruction file states is not enforced. If it matters,
  it gets a tool and a canary; if no tool can check it, a person reviews it.
- Because tools catch rule breaks, instruction files do not need to repeat
  rules. Their job is to get the AI to a green `bin/ci` on the first try, with
  as little context as possible.

## Guard files

`09_enforcement.md` lists the guard files: in short, the lint, architecture,
and RuboCop configurations and custom cops, every `package.yml` (it holds the
`dependencies:` list, ARCH-08), the budgets and ratchets files, the canary
fixtures (TS-07), `config/production_routes.yml` (SEC-12), `script/ci/`,
`config/ci.rb`, and `.github/` with the CI workflows. CODEOWNERS requires a
person's approval for every change to them except the ratchet files, and also
covers `engines/core` and `engines/design_system` (ARCH-12). The ratchet files
have no CODEOWNERS entry: a separate required check runs `script/ci/ratchet`
against the merge base, passes a diff that only lowers counts, and fails a
rise until an owner approves it. No workflow commits to `main`; lower counts
arrive in a pull request. On a GitHub plan without required code-owner
review, `script/ci/guard_approval` enforces the same approval for the other
guard files, and without branch protection all of this rests on convention
(WF-03).

The root `AGENTS.md` carries the matching line in its "Never" list: never
loosen a guard to make something pass; propose the change in the pull request
for a person to approve. Every AI file follows from that line.

## The AI files the template ships

| Artifact | File | Loaded | Contains | Never contains |
| --- | --- | --- | --- | --- |
| Root guide | `AGENTS.md` | every session | what the app is, commands, how to decide, the most-used rule IDs, the "Never" list, where skills and the glossary live, the definition of done | rule text, "make sure" checks, version numbers, anything a tool already reports |
| Engine guide | `AGENTS.md` in each engine | when the AI works in that engine | the engine's kind, its allowed dependencies, its public surface, what is special about it | the root guide repeated, guidance for other kinds |
| Request workflow | `.opencode/skills/deliver-request/SKILL.md`, named in the root guide | whenever the user asks for a change in plain words | the steps from a request to a merged pull request, the task skills it may call, what it asks the user, what it hands to a person | rule text; any step that loosens a guard or decides for a person |
| Task skills | one per recipe (see tool notes) | on demand, when a task matches the skill's description | inputs to collect, the generator command, the files to fill, the rule IDs that apply, the check commands, when it is done | rule text, hand-written steps a generator already does, edits to guard files |
| Design skills | `.opencode/skills/oo-*/`, a pinned copy of the object-oriented design skills pack | on demand, when a task matches a skill's description | general object-oriented design advice: values and entities, invariants, boundaries, failure behaviour, review checklists | project rules; edits by hand (the whole snapshot is replaced to update it) |
| Domain glossary | for example `docs/ai/glossary.md`; written by the adopter's AI, not shipped | on demand, linked from the root guide | business terms, upstream names mapped to BFF names, the engine that owns each concept, words to avoid | rules, schemas, API shapes |

### Root `AGENTS.md`

Start from Rafelo's `AGENTS.md` and adapt it to the project. Keep it
short: it is loaded in every session, so each line costs attention and tokens
on every task, whether the task needs it or not. Aim for a file a person reads
in two minutes; move anything longer into a skill.

```markdown
<!-- AGENTS.md (skeleton) -->
# AGENTS.md — <app name>
## What this app is            <!-- three lines: BFF, its upstreams, engines -->
## Commands                    <!-- setup, bin/dev, bin/check <engine>, bin/ci, generators -->
## How to decide               <!-- library docs, then ADRs, then rules, then skills -->
## Rules you will touch most   <!-- an ID and a few words each; never the rule text -->
## Never                       <!-- includes: never loosen a guard; propose it in the PR -->
## Skills and glossary         <!-- where they live, one line each -->
## Definition of done
```

### Engine `AGENTS.md`, by engine kind

Each engine gets a short file of its own. What it says depends on the kind
(ARCH-04):

| Kind | What its guide covers |
| --- | --- |
| `engines/core` | the kernel: changes are rare and reviewed (CODEOWNERS); growth budgets (ARCH-12); public changes are additive first (ARCH-09); only domain-free code belongs here (ARCH-05) |
| `engines/design_system` | a leaf that imports nothing from the repository and only `Link` and `Deferred` from Inertia (FE-03); the only place for the UI libraries (FE-07, FE-08); the committed API file `api.d.ts` (FE-21); visual baselines (TS-11); its own i18n namespace |
| domain engine | public surface only, no routes or pages (GEN-05); which engines depend on it; its upstream |
| product module | its registry entry (ARCH-06), its upstreams, the domain engines it declares, the exemplar module to imitate |

The template ships the guides for `core`, `design_system`, and the example
engines, and `rafelo:module` and `rafelo:domain` write a starter guide into
each new engine (GEN-01, GEN-05). Every product module's guide looks alike, and
so does every domain engine's; once you have adapted one, update your copy of
the generator templates (the kernel is yours after adoption, GEN-07) so new
engines start from it.

### Task skills

The template ships one skill per recurring task in
`.opencode/skills/<name>/SKILL.md`. Adapt them, and add a skill when real pull
requests repeat a task the set does not cover. Each starts from the tool that
does the mechanical part and names the design skills that apply to its steps:

| Skill | Starts from |
| --- | --- |
| Add a read page (`add-read-page`) | `rafelo:page <module> <resource>` for a new resource; an existing resource gets the action by hand (GEN-02, BE-01) |
| Add a write action (`add-write-action`) | `rafelo:page <module> <resource> --actions=new,edit` for a new resource; an existing resource gets the action by hand (GEN-02, BE-13, BE-15) |
| Add a module (`add-module`) | `rafelo:module <name>` (GEN-01) or `rafelo:domain <name>` (GEN-05) |
| Expose a public interface (`expose-public-interface`) | the sharing ladder (ARCH-05), public surfaces (ARCH-09), a declared dependency (ARCH-08) |
| Add a design_system component (`add-design-system-component`) | FE-07, FE-09, FE-21, TS-11 |
| Add copy (`add-copy`) | the engine's locale files, every configured locale (CT-08) |
| Fix a failing guard (`fix-failing-guard`) | the guard's own message, which names the rule ID and the fix |
| Migrate a feature, brownfield (`migrate-a-feature`) | the approved migration map |

"Fix a failing guard" matters most. It says: read the message, fix the code,
run the check again. It never edits the guard, adds a disable comment, raises
a budget, or adds to a baseline. When the guard looks wrong, the AI stops and
writes the proposal into the pull request description for a person.

```markdown
<!-- .opencode/skills/add-read-page/SKILL.md (skeleton) -->
---
name: add-read-page
description: Use when adding a read-only page (index or show) to an existing product module.
---
# Add a read page
## Inputs to collect    <!-- module, resource, upstream endpoint, fields the viewer may see -->
## Generate             <!-- the exact rafelo:page command -->
## Fill in              <!-- the files left after generation, in order -->
## Rules that apply     <!-- IDs only -->
## Check                <!-- bin/check <engine>, then bin/ci -->
## Done when
```

### The request workflow

The user says what they want in plain words; the AI does the rest. The root
guide tells the agent to load `deliver-request` for every request to change
the app, and the skill runs these steps:

1. **Understand.** Restate the outcome in a sentence or two. Answer everything
   the code, the spec, and the upstream documentation can answer; ask the user
   only what they cannot (a business rule, which fields a viewer may see, an
   undocumented upstream endpoint), all questions at once.
2. **Plan.** Split the request into deliverable outcomes (WF-01), pick the task
   skills each needs, and open one issue per outcome.
3. **Build**, one issue at a time (WF-02): branch, draft pull request, the
   task skill and the design skills it names, generators first, tests first,
   `bin/check <engine>` until green, then `bin/ci`. A failing guard goes
   through `fix-failing-guard`.
4. **Hand over.** A green pull request that needs no decision from a person is
   marked ready and squash-merged once its required checks pass, through the
   merge queue or, where there is none, under the WF-03 fallback. One that needs a person stays open with those
   decisions listed at the top of its description: a guard change, a budget or
   ratchet raise, an ADR (a framework-level library needs one, WF-06), a
   change to an AI file, or a real secret (BE-08). The AI prepares them and
   never makes them (ADR-32). At the end of a slice it
   opens the review gate with drafted findings for a person (WF-04).
5. **Report** to the user in plain words: what changed, how to try it, and
   what waits for a person.

### Design skills

The pack (`yutna/object-oriented-design-skills`, MIT) is copied in unmodified
at one release; the template's third-party notices record its license,
release, and commit. It is general advice, level 5 in "How to decide": a rule
or an ADR wins over it, and an AI that finds them disagreeing follows the rule
and says so. The root guide maps the template's layers to the pack's entry
points:

| Work | Load |
| --- | --- |
| Designing a class or a module, or moving responsibilities between objects | `oo-design`, which sizes the task and names the skill that fits |
| Plain Ruby objects (value objects a gateway returns, props objects) | `oo-ruby` |
| TypeScript classes in `domain/` and `forms/` (OOP-01 to OOP-10) | `oo-typescript` |
| What Rails or React builds and wires (controllers, models, jobs, components, hooks) | `oo-working-within-a-framework`; the framework's conventions and the FE rules win |
| Reviewing a diff | `oo-reviewing-object-design`; it assists a person and never counts as a guard (ADR-32) |

`bin/kernel_update` never touches the AI files or the pack. A template release
lists the AI files it changed, so an adopter can merge them by hand, and
replacing the pack snapshot is an ordinary pull request.

### Domain glossary

The AI drafts it from the upstream API documentation and the team's
vocabulary; a person who knows the business corrects it. It names each
business term once, maps upstream names to the names the BFF uses (including
the resource names in permission keys), says which engine owns each concept,
and lists synonyms to avoid so a concept does not get a second name.

## What never goes into an AI file

- **Rule text.** Cite the ID (`BE-13`); never copy what the rule says. A copy
  drifts when the rule changes; an ID does not, and `docs:check` fails when an
  AI file cites an ID that does not exist or a superseded ADR.
- **"Make sure X."** If X can be checked, a tool checks it and names the rule
  in its message. If it cannot, a person reviews it. An instruction that says
  "make sure" is a guard nobody runs.
- **Anything that loosens a guard:** disable comments, budget raises,
  baseline additions, configuration edits, skipped `bin/ci` steps.
- **Facts that live elsewhere:** version numbers (`00_README.md`), copies of
  generated files or schemas, secrets, real personal data.
- **Long always-on text.** Detail belongs in skills, which load only when a
  task needs them.

## What the template provides to make AI efficient

- **Generators first** (GEN-01, GEN-02, GEN-05, GEN-06). A generated slice is
  green before any logic is written; the AI fills it in instead of
  scaffolding by hand.
- **`bin/check <engine>`**, the fast loop for one engine; `bin/ci` stays the
  gate (TS-09).
- **Guard messages that name the rule ID and the fix**, so a failure tells the
  AI which rule broke and what to change.
- **Canaries** (TS-07): every guard is proven to fire, so green means checked.
- **The example engines** (GEN-08): complete code to imitate until the
  project's own exemplar module exists.
- **`docs:check`**, which validates the rule and ADR IDs cited in `AGENTS.md`
  and every AI instruction file.
- **Generated contracts and catalogs** (CT-03, CT-06, CT-08): the AI edits one
  source and regenerates the rest.

## How to have AI adapt and validate them

1. **Inputs.** Give the AI the Rafelo spec (`00`–`14`) and the ADRs, the
   generators' output, the example engines or your exemplar module, the
   upstream API documentation, and the team's conventions.
2. **Approval.** The AI drafts; a person reviews and approves each file in a
   normal pull request, checking that it cites IDs instead of restating
   rules. Putting the AI files under CODEOWNERS as well keeps that approval
   path.
3. **Trial requests in a fresh session.** A session with no history sees
   only what the files give it. Pick a few representative requests, for
   example a read page, a write action, a new module, exposing a public
   interface, a request that tempts the AI to loosen a guard, one that needs a
   question, and one that needs a person's decision. Write each as the one
   sentence a user would type, with a fact sheet for the questions it may
   ask, run it through the request workflow in a fresh session, and measure:
   - **first-time-green CI:** the first push passes `bin/ci` with no human
     edit;
   - the questions asked, and whether the files could have answered them;
   - whether a request that needs a person ends handed over, not decided;
   - each guard failure along the way, and whether it was fixed in the code
     rather than in the guard;
   - files touched outside the task;
   - time and tokens spent.

   The template's maintainers run the same trials before a release that
   changes an AI file or a generator.
4. **Fix the file, not the guard.** When a trial fails, change the instruction
   file or the generator, then run the trial again in a new fresh session.
5. **Keep them current.** Update the files when an ADR or a rule changes
   (`docs:check` catches removed IDs and superseded ADRs; a changed meaning
   needs a person), when a generator changes, and when real pull requests
   repeat the same mistake. Track first-time-green on real AI pull requests
   over time.

## Greenfield and brownfield

### A new project

1. Adopt with the application template (GEN-07). `bin/ci` is green with the
   example engines in place.
2. Generate the first module and build it end to end, imitating
   `example_orders`.
3. Have the AI adapt the shipped files to the project, pointing at that module
   as the exemplar instead of the example engines, and validate them with
   trial tasks.
4. Delete the example engines (GEN-08).

### An existing Rails application

- Existing code stays in `app/` and moves into engines feature by feature.
  Engines cannot import `app/` (ARCH-04), so a feature moves together with
  what it needs, or what it needs moves first: into the owning engine's public
  surface, a domain engine, core, or design_system (ARCH-05).
- The dependency guards apply from the first engine (ARCH-08). Code-level lint
  rules are scoped by path: they apply in full under `engines/`, and the ESLint
  and RuboCop configurations list the legacy paths in `app/`. The ratchet
  counts them (`legacy_lint_paths`), so the list only shrinks.
- The order:
  1. the guards, core, and design_system;
  2. the first module, migrated end to end and reviewed by a person as the
     exemplar;
  3. a migration map the AI drafts (features, target engines, what each
     needs, the order) and a person approves;
  4. one feature per pull request (WF-02), using the migrate-a-feature skill.
- The AI never refactors legacy code outside the feature it is migrating.
- A project that is not a Rails application is a rewrite, not a migration,
  and out of scope here.

## Tool notes

- Rafelo's AI files target OpenCode. OpenCode reads the root `AGENTS.md` at
  startup and discovers skills in `.opencode/skills/<name>/SKILL.md`, each with
  a `name` and a `description` in its front matter; the description decides
  when the skill loads. OpenCode does not load an engine's `AGENTS.md` on its
  own, so the root guide tells the agent to read it before changing that
  engine; an `instructions` glob in the OpenCode configuration would put every
  engine guide into every session instead. Verify the loading behaviour
  against the current OpenCode documentation when adopting.
- Many other coding agents read `AGENTS.md` too; how they load nested files
  differs by tool, so check its documentation when adopting.
- A team on Claude Code adds a `CLAUDE.md` containing the line `@AGENTS.md`,
  so there is one source (a nested `CLAUDE.md` can import an engine's
  `AGENTS.md` the same way), and points `.claude/skills` at
  `.opencode/skills` (for example a symlink), so there is one copy of each
  skill. Verify against the current Claude Code documentation.
- A tool that reads neither folder gets one line in the root guide pointing it
  to `.opencode/skills/`. Keep one copy of each skill.
- `docs:check` finds `AGENTS.md` and `CLAUDE.md` at any depth. The template's
  `config/docs.yml` lists the request workflow and the shipped task skills,
  and nothing under
  `.opencode/skills/oo-*`: the pack is third-party advice that cites no rule
  IDs.
  Add every other place your AI files live (a new skill, the glossary) to that
  list (CT-09), so cited IDs are checked everywhere.
