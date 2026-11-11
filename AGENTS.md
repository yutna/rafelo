# Project instructions

Rafelo is an opinionated Ruby on Rails 8.1 BFF template. The application
architecture is intentionally undecided: [docs/architecture.md](docs/architecture.md)
records the generated Rails baseline, not decisions. Do not add layers,
patterns or abstractions until an issue explicitly asks for architecture work.

## Workflow

- Follow [CONTRIBUTING.md](CONTRIBUTING.md): issue first, version milestone,
  short branch, draft pull request, Conventional Commits title, squash merge.
- Run `bin/ci` before pushing. Run `bin/rails test:system` when a change touches
  browser behaviour.
- Keep `VERSION` equal to the milestone without the `v` prefix.
- Never commit `config/master.key` or other secrets. Use
  `bin/rails credentials:edit` locally.
- Keep code, comments, docs, commit messages and pull request titles in English.

## Object-oriented design skills

- The project's own written conventions win over the pack. When they disagree,
  follow the project and say so.
- The `oo-design` skill sizes a task and names the skill that fits. Load it
  before designing a class, module or system, or before a change that moves
  responsibilities between objects.
- Load `oo-ruby` before editing plain Ruby, `oo-javascript` before plain
  JavaScript, and `oo-typescript` before plain TypeScript. When a framework
  builds or wires the objects, such as Rails models and controllers or
  Stimulus controllers, load `oo-working-within-a-framework` instead; the pack
  does not override the framework's conventions.
- Leave throwaway scripts and one-line fixes alone.

## Vendored skills

- `.opencode/skills/oo-*` is copied from
  [yutna/object-oriented-design-skills](https://github.com/yutna/object-oriented-design-skills)
  v0.17.1 (commit `453834912b1b907cdc1064f8e75bb17916dd3318`), MIT.
- The pack's Claude Code `/plugin install` instructions do not apply here; the
  skills are already under `.opencode/skills`.
- Do not edit those files by hand. See [docs/opencode.md](docs/opencode.md) to
  update the snapshot.
