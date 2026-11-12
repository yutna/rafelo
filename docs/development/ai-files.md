# AI file payload

This is the plan for the AI instruction files the Rafelo application template
ships to adopters. It implements [14_working_with_ai.md](../architecture/14_working_with_ai.md)
and keeps maintainer-only material out of the payload.

## What ships

| Artifact | Path | Loaded | Milestone |
| --- | --- | --- | --- |
| Root guide | `AGENTS.md` | every OpenCode session | present; finalised in `v0.20.0` |
| Spec copy | `docs/architecture/` | when the agent needs a rule or an ADR | `v0.3.0` |
| Core engine guide | `engines/core/AGENTS.md` | when changing the kernel | `v0.7.0` |
| Design system guide | `engines/design_system/AGENTS.md` | when changing the UI kit | `v0.7.0` |
| Example engine guides | `engines/example_*/AGENTS.md` | when learning from an example | `v0.17.0` |
| Generator engine guides | rendered by `rafelo:module` and `rafelo:domain` | when changing a generated engine | `v0.15.0` |
| Design skills pack | `.opencode/skills/oo-*` | on demand | present, pinned `v0.17.1` |
| Request workflow | `.opencode/skills/deliver-request/SKILL.md` | when the user asks for a change | `v0.14.0` |
| Task skills | `.opencode/skills/<name>/SKILL.md` | on demand | see below |
| Docs registry | `config/docs.yml` | `docs:check` | `v0.20.0` |
| Domain glossary | adopter-created, for example `docs/ai/glossary.md` | on demand | never shipped |

The root guide is the only always-on file. Engine guides are not loaded by
OpenCode automatically; the root guide tells the agent to read an engine's
`AGENTS.md` before changing that engine.

## What never ships

- `docs/development/`: the implementation protocol, spec provenance, this
  plan, workflow trials, and release-maintainer notes.
- `docs/architecture/lessons-learned.md`: maintainer and reviewer evidence.
- Any secret, credential, token, or real personal data.

The application template copies the spec under `docs/architecture/`, but not
the maintainer-only files in `docs/development/`.

## Task skills and when they ship

Each task skill ships with the generator or guard it starts from. It names
inputs, the generator command, files to fill, applicable rule IDs, check
commands, and the pack skills for its steps. It does not restate rule text.

| Skill | Starts from | Ships |
| --- | --- | --- |
| `fix-failing-guard` | the guard's own message and fix | `v0.6.0` |
| `expose-public-interface` | the ARCH-05 sharing ladder | `v0.7.0` |
| `add-copy` | the engine locale files | `v0.9.0` |
| `add-design-system-component` | FE-07, FE-09, FE-21, TS-11 | `v0.14.0` |
| `deliver-request` | the first task skills | `v0.14.0` |
| `add-module` | `rafelo:module` and `rafelo:domain` | `v0.15.0` |
| `add-read-page` | `rafelo:page` | `v0.16.0` |
| `add-write-action` | `rafelo:page --actions=new,edit` | `v0.16.0` |
| `migrate-a-feature` | an approved brownfield migration map | `v0.20.0` |

`deliver-request` takes a plain-language request to a merged pull request. It
opens one issue per deliverable outcome, uses the task skills, stops for the
decisions the spec reserves for a person, and reports what changed.

## Layer-to-skill map

| Work | Load |
| --- | --- |
| Designing a class or module, or moving responsibilities | `oo-design` |
| Plain Ruby objects, value objects, props objects, gateways | `oo-ruby` |
| TypeScript classes in `domain/` and `forms/` | `oo-typescript` |
| Rails or React code the framework builds and wires | `oo-working-within-a-framework` |
| Reviewing a diff | `oo-reviewing-object-design` |

A rule or ADR wins over the pack. If they disagree, follow the rule and record
the disagreement in
[lessons-learned.md](../architecture/lessons-learned.md). A framework's own
conventions win for framework-built code.

## Root guide timeline

The gist's `AGENTS.md` is preserved verbatim at
[docs/architecture/AGENTS.md](../architecture/AGENTS.md). The root guide is
staged while the commands and layers it describes do not exist yet. It becomes
the adopter guide when the application template is wired (`v0.20.0`) and is
audited against `14_working_with_ai.md` and the built code in `v0.22.0`.

This staging avoids two failures: an agent told to run commands that do not
exist, and `docs:check` failing on paths that a later milestone creates. The
reading is recorded as spec feedback in lessons learned.

## Maintenance

- A new AI file is added to `config/docs.yml` so `docs:check` validates the
  rule and ADR IDs it cites.
- A change to a task skill is a normal pull request; a person approves changes
  to shipped AI files.
- The vendored pack is replaced as a snapshot, never edited by hand. See
  [docs/opencode.md](../opencode.md).
- The final skills audit reads every `SKILL.md`, checks the layer-to-skill map,
  and records every pack-versus-rule conflict in lessons learned.
