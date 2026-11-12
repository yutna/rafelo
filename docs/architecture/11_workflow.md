# 11 — Workflow

A light GitHub workflow for a small team or a single developer working with AI
agents. The goal is small, reviewable changes and a `main` branch that is
always green. It is written for GitHub; adopters on another platform adapt it,
keeping the outcomes and replacing the GitHub features with their platform's
equivalents.

These rules govern the repository of an application adopted from the
template: the template writes their workflow files, ruleset exports, and
`CODEOWNERS` placeholders into the new app (GEN-07). The template repository
keeps its own contribution and release process; its CI runs `bin/ci` over the
template and the adoption run that GEN-07 describes.

## Rules

### WF-01 — Issues describe one deliverable outcome (SHOULD · ADR-19)

An issue states the outcome a user or developer will see, the acceptance
checks, and anything explicitly out of scope. Size is a judgement call, not a
formula:

- aim for a change that can be reviewed in one sitting;
- split when an issue mixes unrelated concerns, not merely because it touches
  several layers (a page usually spans controller, props, schema, and React);
- small chores (a typo, a dependency bump from the bot, a docs fix) do not
  need an issue.

AI agents should not split work into many micro-issues to satisfy this rule.
One coherent outcome per issue is the intent.

### WF-02 — One issue, one pull request (SHOULD · ADR-19)

- Branch from `main` as `<type>/<issue>-<slug>`, for example
  `feat/42-invoice-export`.
- Open a draft pull request early with `Closes #42`. Push small, logical
  commits so progress is visible.
- Mark it ready when acceptance checks pass and `bin/ci` is green.

### WF-03 — Titles, merges, and `main` (MUST · ADR-19)

- The pull request title follows Conventional Commits and becomes the squash
  commit:
  `^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)(\([a-z0-9._/-]+\))?(!)?: [^[:space:]].*$`
  (POSIX classes only, so bash's `=~` reads it the same with glibc and BSD
  regex). Use `!` for a breaking contract change (CT-05).
- Squash merge only, through the merge queue. Delete the branch after merge.
- `main` is protected: no direct pushes, no force pushes, required status
  checks, resolved conversations, code-owner review (so a change to a guard
  file needs a person's approval, `09_enforcement.md`), and a required merge
  queue.
- That protection is a repository ruleset whose export is committed
  (`.github/rulesets/main.json`), because a setting nobody watches drifts. A
  scheduled `script/ci/repo_rules` reads the active rules for `main`
  (`GET /repos/{owner}/{repo}/rules/branches/main`, which the read-only
  workflow token may call; classic branch protection needs an admin token)
  and opens an issue when they differ from the file or when a required check
  name matches no job. It also reads a recorded payload (`--payload FILE`)
  for its canaries (TS-07).
  Ruleset bypass actors are visible only to admins, so the bypass list stays
  a review item. Verify ruleset availability on the plan when adopting.
- The CI workflow ends in one aggregator job, `ci-ok`, whose `needs:` lists
  every other job and which runs `if: always()`. It fails unless each needed
  result is `success`, or `skipped` for a job whose own `if:` declares that
  skip (visual regression, generator smoke, a per-engine suite that the
  affected set leaves out). GitHub reports a skipped job as passing, so a plain
  `needs:` aggregator that is skipped after a failure would pass, and job
  names produced by a matrix or a condition cannot be required. The only
  required check names are `ci-ok` and the three jobs of the pull request
  workflow below: `title` (the title lint), `ratchet` (the ratchet check), and
  `guard_approval` (`script/ci/guard_approval`). A canary workflow fixture
  has a job missing from `ci-ok`'s `needs:`, and `script/ci/workflow_policy`
  (WF-07), which reads the workflows, fails on it (TS-07).
- The title lint, the ratchet check, and `script/ci/guard_approval` run in
  their own workflow, `.github/workflows/pull_request.yml`, because they must
  run again on events that change no code: `pull_request` with the `edited`
  type (a corrected title is linted again; the default types `opened`,
  `synchronize`, and `reopened` never include it) and `pull_request_review`
  with `submitted` and `dismissed` (an owner's approval given or withdrawn).
  Such an event re-runs these three cheap jobs, never CI. The workflow also
  runs on `merge_group`, and never on `push`. Its jobs run on
  `ubuntu-latest`, not in the Dev Container image. The ratchet check and
  `script/ci/guard_approval` read the reviews through the GitHub API, so
  their jobs widen the token to `pull-requests: read` (WF-07); each also
  reads a recorded list of reviews (`--reviews FILE`) for its canaries
  (TS-07). Verify when adopting that branch protection reads the newest run
  of a check name on the head commit.
- No workflow pushes to `main`. Ratchet counts fall without a person, through
  pull requests: CI compares the current counts with the committed ones and
  fails only on a rise, and a scheduled job opens a pull request that lowers
  the committed counts. The ratchet files have no CODEOWNERS entry; a
  separate required check runs `script/ci/ratchet` against the merge base,
  passes a diff that only lowers numbers, and fails a rise until an owner
  approves it (GitHub API, like `script/ci/guard_approval`;
  `09_enforcement.md`).
- The merge queue tests each pull request on top of the `main` it will land
  on, so two pull requests that pass alone but break together never reach
  `main`. CI runs on `merge_group` as well as `pull_request`, and every
  required check reports on both. A `merge_group` payload carries no pull
  request (only `head_ref`, `head_sha`, and `base_sha`), and a required check
  that never reports fails the queue entry. So checks that read pull request
  data pass on `merge_group` with a log line: the title lint and
  `script/ci/guard_approval` already ran on the pull request. The ratchet
  check compares counts against the queue's base and, for a rise, reads the
  approvals of the pull request numbered in `merge_group.head_ref` (verify
  the ref format when adopting).
- CI also runs on `push` to `main`, so the commit that lands has a CI run of
  its own, and "`main` is green" is a result the release workflow can read
  (WF-05). That run checks again the tree the merge queue already tested. The
  checks that read pull request data live in the pull request workflow, which
  does not run on `push`, and `ci-ok` decides the CI run's conclusion the same
  way on all three events.
- `script/ci/affected` computes the affected engines against the merge base,
  not against the branch's own history, so a queued pull request runs the
  checks its combined change needs. On `push` the base is the push's `before`
  commit.

```yaml
# .github/workflows/ci.yml (excerpt)
name: CI # the release workflow names it in workflow_run (WF-05)
on:
  pull_request: # default types; a title edit or a review re-runs only pull_request.yml
  merge_group:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  image: # the one place CI learns the image: .devcontainer/image_digest (OPS-09)
    runs-on: ubuntu-latest
    timeout-minutes: 2
    outputs:
      ref: ${{ steps.read.outputs.ref }}
    steps:
      - uses: actions/checkout@<full commit SHA> # version in this comment (WF-07)
      - id: read
        run: echo "ref=$(cat .devcontainer/image_digest)" >> "$GITHUB_OUTPUT" # <registry>/<app>-dev@sha256:…
  affected:
    needs: image
    runs-on: ubuntu-latest
    container: ${{ needs.image.outputs.ref }} # the prebuilt Dev Container image; no digest in workflow YAML
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@<full commit SHA> # version in this comment (WF-07)
        with:
          fetch-depth: 0
      - run: script/ci/affected --base "$(git merge-base "$BASE_SHA" HEAD)"
        env:
          BASE_SHA: ${{ github.event.merge_group.base_sha || github.event.pull_request.base.sha || github.event.before }}
```

Verify the `merge_group` event fields against the current GitHub
documentation when adopting.

```yaml
# .github/workflows/pull_request.yml (excerpt)
name: Pull request
on:
  pull_request:
    types: [opened, edited, synchronize, reopened] # edited: a corrected title is linted again
  pull_request_review:
    types: [submitted, dismissed] # an approval given or withdrawn re-runs the approval checks
  merge_group:

permissions:
  contents: read

jobs:
  title: # required check; a merge_group payload has no pull request, so it passes with a log line
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - env:
          EVENT: ${{ github.event_name }}
          TITLE: ${{ github.event.pull_request.title }} # through env, never interpolated into the script
        run: |
          if [ "$EVENT" = merge_group ]; then echo "title: linted on the pull request"; exit 0; fi
          pattern='^(feat|fix|docs|chore|refactor|test|ci|build|perf|style|revert)(\([a-z0-9._/-]+\))?(!)?: [^[:space:]].*$'
          [[ "$TITLE" =~ $pattern ]] || { echo "WF-03: the title is not a Conventional Commit: $pattern" >&2; exit 1; }
  # ratchet and guard_approval, the other two required checks: script/ci/ratchet against the merge
  # base and script/ci/guard_approval, each on ubuntu-latest with timeout-minutes, and each widened
  # to permissions: { pull-requests: read } to read the reviews through the GitHub API (WF-07).
```

A required merge queue needs a repository owned by an organization (public,
or private on GitHub Enterprise Cloud), and required code-owner review needs a
paid plan for private repositories (verify the current plans when adopting). Where the
repository lacks them, the fallback is explicit: branch protection requires branches
to be up to date before merging, plus the required `ci-ok` check and the three
`pull_request.yml` checks. The title lint and the ratchet check stay as
above, and `script/ci/guard_approval` fails when a guard file other than a
ratchet file changed without an approving review from an owner listed in
CODEOWNERS (it reads the reviews through the GitHub API).

On a plan without branch protection for private repositories (verify when
adopting), nothing can be required. The guarantees then fall back to required
CI status where the platform offers it, and otherwise to convention:
`ci-ok`, `title`, `ratchet`, and `guard_approval` still run, and
people merge only when they are green. The outcomes of this rule (an
always-green `main`, a person's approval on every guard change) need branch
protection to be real.

### WF-04 — Review gates at the end of a slice (SHOULD · ADR-19)

When a feature slice is done, open a review-gate issue and review the slice as
a whole: bugs, edge cases, security, performance, accessibility, and
documentation.

| Severity | Meaning | Action |
| --- | --- | --- |
| P0 | security hole, data loss, broken core flow, red CI | fix before merge or release |
| P1 | user-facing bug, missing acceptance check, missing test for a critical edge | fix before closing the gate |
| P2 | polish, rare edge case, non-critical performance | backlog issue |
| P3 | refactor or idea | backlog issue |

At most two rounds: round one reviews the slice, round two verifies fixes and
regressions only. Scope is frozen once review starts. If P0 or P1 findings
remain after round two, stop, record the risk, and split the work. Style
questions are settled by formatters and linters, not review comments. An AI
reviewer may draft findings; a person confirms their severity and closes the
gate (ADR-32).

### WF-05 — Releases come from `VERSION` (MUST · ADR-19)

- `VERSION` holds the release being prepared: one line holding
  `MAJOR.MINOR.PATCH` and nothing else
  (`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`; no `v`, no
  pre-release or build suffix, one trailing newline allowed). Only the
  release pull request (`chore: release vX.Y.Z`) changes it; between release
  pull requests it names the latest release, which is already tagged and
  released.
- The release pull request sets `VERSION`, runs `bin/rails formats:dump`, and
  commits its output: synthetic rows for every versioned stored format
  (idempotency outcomes, one job per class defined under `app/` and
  `engines/*/app/` through its `serialize`, sessions)
  in `spec/fixtures/formats/v<VERSION>/`, with folders older than N-2 pruned.
  The SEC-16 compatibility spec loads the previous tag's folder. A release
  that changes the session format incompatibly may revoke all sessions instead
  of reading the old format (SEC-16).
- The release workflow starts from `workflow_run`: it runs whenever the CI
  workflow completes, and acts only when that run's event is `push`, its
  branch is `main`, its repository is this one, and its conclusion is
  `success`. "`main` is green" is therefore the CI result of the exact commit
  it releases, read from the event rather than from commit statuses. The
  event and repository conditions matter: a pull request from a fork's branch
  named `main` also completes CI with `head_branch` `main`.
- It checks out `workflow_run.head_sha` with `persist-credentials: false`
  (the job pushes nothing with git) and reads `VERSION`. Then, in this order:
  - a GitHub Release for `v<VERSION>` exists
    (`GET /repos/{owner}/{repo}/releases/tags/v<VERSION>` answers `200`): the
    push carried no release, and the workflow ends with a log line; that is
    the outcome on almost every push;
  - the tag `v<VERSION>` exists without a Release (for example a Release
    deleted by hand): it creates the Release for that tag and never moves the
    tag;
  - otherwise it fails if `VERSION` breaks the format above or is not higher
    than the highest `v*` tag (another release may have landed since the
    pull request's check), if any locale placeholder (`[<locale>] …`, CT-08)
    remains, or if `spec/fixtures/formats/v<VERSION>/` is missing. Else it
    creates the tag and the Release in one Releases API call
    (`POST /repos/{owner}/{repo}/releases` with `tag_name` `v<VERSION>`,
    `target_commitish` the checked-out SHA, and `generate_release_notes`,
    whose notes list the merged pull request titles, which are the squash
    commit titles). GitHub creates the tag from `target_commitish` in the same
    call, so no run leaves a tag without its Release, and a failed call
    leaves nothing to clean up.

  It commits nothing. A release that failed or was cancelled is attempted
  again by the next green push to `main`, which carries the fix. GitHub's
  documentation asks for permission to modify workflows when the tagged
  commit adds or changes files under `.github/workflows/`; verify when
  adopting that the release job's token can release such a commit.
- Because an existing Release now means "nothing to release", the mistake
  that check used to catch moves to the pull request: CI fails a pull
  request that changes `VERSION` unless the new value has the format above,
  `v<VERSION>` does not exist yet, and it is higher than the highest `v*`
  tag. That check is `script/ci/release --check`, which `bin/ci` runs when
  `VERSION` changed (`09_enforcement.md`): the release step's own `VERSION`
  checks run against the local tags without the API, so the two cannot
  disagree; its canaries are fixture `VERSION` files and tag lists (TS-07).
- Only the release workflow creates `v*` tags. A tag ruleset on
  `refs/tags/v*` restricts their creation, update, and deletion, and its
  export is committed next to the branch ruleset
  (`.github/rulesets/release_tags.json`) for `script/ci/repo_rules` to
  compare. Verify when adopting which bypass actor the release job's token
  matches, and whether the read-only token can read tag rulesets. If the
  bypass can only name GitHub Actions as a whole, the `contents: write`
  allow-list of `script/ci/workflow_policy` (WF-07) is what keeps other
  workflows from tagging.

```yaml
# .github/workflows/release.yml (excerpt)
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

permissions:
  contents: read

concurrency:
  group: release # two quick pushes never tag at once
  cancel-in-progress: false

jobs:
  release:
    # A green CI run of a push to main in this repository; a fork's pull request from a
    # branch named main also reports head_branch "main" (WF-05).
    if: >-
      github.event.workflow_run.conclusion == 'success' &&
      github.event.workflow_run.event == 'push' &&
      github.event.workflow_run.head_repository.full_name == github.repository
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: write # the tag and the GitHub Release (allow-listed in script/ci/workflow_policy, WF-07)
    steps:
      - uses: actions/checkout@<full commit SHA> # version in this comment (WF-07)
        with:
          ref: ${{ github.event.workflow_run.head_sha }} # the one allowed PR-free checkout of a workflow_run (WF-07)
          fetch-depth: 0 # tags: whether v<VERSION> exists, and the highest v* tag
          persist-credentials: false # nothing is pushed with git; the Releases API creates the tag
      - run: script/ci/release # Release exists: end · tag only: add its Release · else check, then one API call
        env:
          GH_TOKEN: ${{ github.token }}
          RELEASE_SHA: ${{ github.event.workflow_run.head_sha }}
```

`workflow_run` starts only from a workflow file on the default branch, and a
run from a pull request never reaches the release job's steps. The fields the
excerpt reads (`conclusion`, `event`, `head_branch`, `head_sha`,
`head_repository.full_name`) are those of GitHub's workflow run object, which
the event carries as `workflow_run` (checked against the REST API's workflow
run object on 2026-11-12).

### WF-06 — Dependencies are exact and upgraded deliberately (MUST · ADR-18)

- Pin exact versions (see `00_README.md`); commit `Gemfile.lock` and
  `package-lock.json`. CI installs with `npm ci`, and with `bundle install`
  under `BUNDLE_FROZEN=true`.
- Renovate opens one pull request per package, except for peer sets, which
  only work at matching versions and move together in one grouped pull
  request:

  | Group | Packages |
  | --- | --- |
  | TypeScript | `typescript`, `typescript-eslint` |
  | Vite | `vite`, `@vitejs/plugin-react`, `vite-plugin-ruby`, `@rolldown/plugin-babel` |
  | React | `react`, `react-dom`, `@types/react`, `@types/react-dom`, `eslint-plugin-react-hooks` |
  | Vitest | `vitest`, `@vitest/coverage-v8` |
  | Tailwind CSS | `tailwindcss`, `@tailwindcss/vite`, `prettier-plugin-tailwindcss` |
  | ESLint | `eslint`, `@eslint/js` |

- `script/ci/pins` checks:
  - npm: every version string in `package.json`'s `dependencies`,
    `devDependencies`, `optionalDependencies`, and `overrides` is one exact
    version (`1.2.3`, a pre-release allowed). A range (`^`, `~`, `>=`, `1.x`,
    `*`), a dist-tag (`latest`), a URL or git reference, a `file:` path, and
    an `npm:` alias fail;
  - gems: it evaluates the `Gemfile` and every engine gemspec through
    Bundler, never by text pattern. Every gem except the engines (path gems)
    is pinned to one exact version in the `Gemfile`; a gem from `git:` or
    `github:` also needs `ref:` with a full 40-character commit SHA (a branch
    or a tag fails). An engine gemspec depends only on other engines and on
    gems the `Gemfile` pins, and states no version constraint of its own, so
    the `Gemfile` is the one place a gem's version lives;
  - peer sets: each is grouped in the Renovate configuration (a peer-set
    member outside its group fails);
  - tools: the Ruby versions in `mise.toml`, `.ruby-version` (read by the
    Gemfile), and the production Dockerfile's `ARG RUBY_VERSION` agree with
    the tag of the Dev Container image, which pins Ruby; every Node and npm
    pin (`packageManager`, `engines`, `devEngines`, the Dockerfile) equals
    the version in `mise.toml`, their one source; and `devcontainer.json`
    names the digest in `.devcontainer/image_digest`, which CI reads at run
    time (OPS-09).

  Its canaries are listed in TS-07.
- Packages held back on purpose are Renovate rules with a description of why.
  The "held back" table in `00_README.md` is generated from those rules and
  checked by `docs:check`.
- Nothing auto-merges. A major upgrade is its own pull request with a note on
  what changed.
- A pull request that changes only lockfiles (for example Renovate's lockfile
  maintenance) runs a reduced lane: install (`BUNDLE_FROZEN=true`, `npm ci`),
  typecheck, and the browser smoke suite, plus the dependency audits SEC-07
  requires for any lockfile change. `script/ci/affected` selects that lane; a
  lockfile change together with anything else runs everything.
- A new dependency needs an issue that states why; a new framework-level
  library needs an ADR.

```json5
// renovate.json5 (excerpt)
{
  minimumReleaseAge: "3 days",
  automerge: false,
  lockFileMaintenance: { enabled: true },
  packageRules: [
    { groupName: "typescript", matchPackageNames: ["typescript", "typescript-eslint"] },
    { groupName: "vite", matchPackageNames: ["vite", "@vitejs/plugin-react", "vite-plugin-ruby", "@rolldown/plugin-babel"] },
    { groupName: "react", matchPackageNames: ["react", "react-dom", "@types/react", "@types/react-dom", "eslint-plugin-react-hooks"] },
    { groupName: "vitest", matchPackageNames: ["vitest", "@vitest/coverage-v8"] },
    { groupName: "tailwindcss", matchPackageNames: ["tailwindcss", "@tailwindcss/vite", "prettier-plugin-tailwindcss"] },
    { groupName: "eslint", matchPackageNames: ["eslint", "@eslint/js"] },
  ],
}
```

### WF-07 — CI and the supply chain are hardened (MUST · ADR-18, ADR-19)

- The dependency bot waits a few days after a release before proposing it
  (Renovate `minimumReleaseAge`), so a compromised version has time to be
  noticed and pulled.
- Every GitHub Actions `uses:` is pinned to a full commit SHA with the version
  in a comment; the bot updates the SHAs. `script/ci/actions_pinned` parses
  every workflow under `.github/workflows/` (`*.yml` and `*.yaml`) and every
  composite action under `.github/actions/` (`action.yml`, `action.yaml`) as
  YAML, never by line pattern, and checks step-level `uses:`, job-level
  `uses:` (reusable workflows), and the steps of composite actions. A remote
  reference needs `@` and 40 hexadecimal characters plus a version comment on
  its line (`# v4.2.2`); a `docker://` image needs an `@sha256:` digest; a
  local `./` reference needs neither. Its canaries, one per form, are listed
  in TS-07.
- Every workflow sets `permissions:` at the top to exactly `contents: read`.
  A job MAY widen it with a mapping of GitHub's permission scopes to `read`,
  `write`, or `none` (never `read-all`, `write-all`, an unknown scope, or an
  expression); a `write` value is allowed only for a job
  that `script/ci/workflow_policy`'s allow-list names with that scope (for
  example the release job's `contents: write`, WF-05). Every job that runs
  steps declares `timeout-minutes` (TS-09); a job that calls a reusable
  workflow cannot (actionlint 1.7.12 rejects the key there), and the called
  workflow's jobs carry it. `script/ci/workflow_policy` checks all of this
  from the parsed YAML, together with `ci-ok`'s `needs:` (WF-03). Its
  canaries are listed in TS-07.
- Never check out pull request code in a `pull_request_target` or
  `workflow_run` workflow: such a run holds the base repository's token and
  secrets. `script/ci/workflow_policy` fails when a workflow with either
  trigger has a checkout step with a `ref:` or `repository:` input, or a
  `run:` step that fetches or checks out a pull request (`pull/`,
  `gh pr checkout`). The one exception is the release job (WF-05): it checks
  out `github.event.workflow_run.head_sha`, which the check accepts only in a
  job whose `if:` requires both `github.event.workflow_run.event == 'push'`
  and `github.event.workflow_run.head_repository.full_name == github.repository`,
  so the commit is one that `main` of this repository already holds. The
  canaries are listed in TS-07.
- Deployment secrets live in protected environments.
- Lockfiles are authoritative: `npm ci`, and `bundle install` with
  `BUNDLE_FROZEN=true`, fail on any mismatch. There are two exceptions, both
  jobs that run a generator, which changes `Gemfile.lock`: the generator
  smoke test, which sets `BUNDLE_FROZEN=false` inside its script (GEN-04),
  and the production image build, which runs `rafelo:module` before it builds
  (OPS-06).
- SEC-07 sets the audit policy: when Brakeman and the dependency audits
  block a pull request, and the daily job that opens issues for new
  advisories. No audit is ever disabled.

## Pull request checklist

```markdown
- [ ] Linked issue, or a chore that does not need one (WF-01)
- [ ] Tests at the right level (TS-01), page budgets at the maximum page size (TS-02), and axe clean (TS-08)
- [ ] Generated files regenerated (`contracts:generate`, `errors:generate`, `permissions:generate`, `locales:generate`, `i18n:generate`, `aliases:generate`, `docs:generate`, `script/ci/engine_graph`)
- [ ] Copy present in every configured locale; any `[<locale>]` placeholder left is translated before the release (CT-08, WF-05)
- [ ] Contract changes are additive, or the title carries `!` (CT-05, CT-12)
- [ ] Migrations and stored formats work while the previous release still runs (BE-22, SEC-16)
- [ ] Code shared across engines goes through a public surface and a declared dependency (ARCH-05, ARCH-09)
- [ ] No guard loosened; any guard-file change is named in the description for a person to approve
- [ ] No secrets, tokens, or real personal data
- [ ] Docs or ADRs updated when behaviour or a decision changed
- [ ] `bin/ci` green
```
