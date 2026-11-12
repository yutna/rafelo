# Project instructions

Rafelo is a Rails 8.1 BFF template. It is being converted in place from the
stock Rails baseline into the architecture specified under
[docs/architecture](docs/architecture/). The implementation is in progress:
the specification is authoritative, while the repository may not yet contain
every command or layer it describes.

Read [00_README.md](docs/architecture/00_README.md) and the topic files for the
work you are doing before changing code. When guidance conflicts, follow the
precedence in `00_README.md`: library documentation, then ADRs, then rules,
then AI instructions, then general advice and skills.

During template development, also read
[implementation-protocol.md](docs/development/implementation-protocol.md).
That file is maintainer-only and is not copied into an adopted application.

## Workflow

- Follow [CONTRIBUTING.md](CONTRIBUTING.md): issue first, version milestone,
  short branch, draft pull request, Conventional Commits title, squash merge.
- Work on one issue and one pull request at a time. Rebuild state from GitHub
  before starting the next issue.
- Open the pull request as a draft at once and keep its status checklist
  current.
- Run `bin/ci` before marking a pull request ready. Until `bin/check` exists,
  use the current repository checks.
- Keep `VERSION` equal to the milestone without the `v` prefix.
- Keep code, comments, docs, commit messages and pull request titles in
  English.

## Current commands

```sh
bin/setup --skip-server
bin/dev
bin/ci
bundle exec rspec
```

The specification's commands (`bin/check`, `bin/kernel_update`, the `rafelo:*`
generators, `npm` scripts and Playwright) are added by the milestone that owns
them. Do not invoke a command that is not in the repository yet; do not add a
stub to make an instruction true.

## Never

- Edit the read-only specification copies under `docs/architecture/` or push
  to their gist.
- Edit the vendored `.opencode/skills/oo-*` pack by hand.
- Change repository settings, rulesets, labels, branch protection, required
  checks, or the template flag.
- Loosen, skip or disable a guard, budget, ratchet or check to get green.
  Propose the change in the pull request for a person to decide.
- Commit secrets, `config/master.key`, credentials keys, tokens, or real
  personal data.
- Add a dependency without an issue, or a framework-level library without an
  ADR.
- Work outside the current milestone's scope.

## Object-oriented design skills

- The project's own written conventions and the spec win over the pack. When
  they disagree, follow the project and record the disagreement.
- Load `oo-design` before designing a class, module or system, or before a
  change that moves responsibilities between objects.
- Load `oo-ruby` for plain Ruby objects and `oo-typescript` for TypeScript
  classes in `domain/` and `forms/`.
- Load `oo-working-within-a-framework` for objects Rails or React builds and
  wires; framework conventions win.
- Load `oo-reviewing-object-design` when reviewing a diff. It assists a person
  and never counts as a guard.
- Leave throwaway scripts and one-line fixes alone.

The full AI file plan, including the layer-to-skill map and the milestone for
each task skill, is in
[ai-files.md](docs/development/ai-files.md).

## Definition of done

- The issue's acceptance checks pass.
- Every rule ID named in the pull request has code and a test, canary or guard
  as evidence.
- Generated files are regenerated; no guard was loosened.
- Docs and lessons learned are updated when behaviour or a decision changed.
- `bin/ci` is green and the pull request is linked to its issue.
