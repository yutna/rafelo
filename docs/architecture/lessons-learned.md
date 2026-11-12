# Lessons learned

This file records what surprised the implementer, the root cause, the change
made, and any feedback on the specification. It cites rule IDs; it never
defines a rule.

## 2026-11-12 — v0.3.0 — issue #14

**What happened.** The gist's `AGENTS.md` was imported verbatim, but promoting
it to the root guide immediately would have instructed agents to run
`bin/check`, `bin/kernel_update`, the `rafelo:*` generators and npm scripts
that do not exist yet.

**Root cause.** `14_working_with_ai.md` describes the finished template, while
the conversion starts from a stock Rails baseline. A guide for the finished
state is not safe as an always-on guide during the build.

**What changed.** The gist guide remains the read-only copy at
`docs/architecture/AGENTS.md`. The root `AGENTS.md` is a truthful build-phase
guide that points at the spec and records which commands are still planned. It
is finalised in `v0.20.0` and audited against `14_working_with_ai.md` in
`v0.22.0`.

**Spec feedback.** `14_working_with_ai.md` and `AGENTS.md` describe the shipped
root guide as if the template already exists. Proposed wording: "During
template development, the root guide may be a staged guide; the shipped guide
must be finalised before GEN-07 lands." Related IDs: CT-09, WF-01, WF-02.

## 2026-11-12 — v0.3.0 — issue #14

**What happened.** The specification's topic files cite paths under
`engines/core/`, `engines/design_system/`, `script/ci/`, `bin/` and `.github/`
that the build has not created yet. A full `docs:check` path audit cannot be
green on the imported copies today.

**Root cause.** CT-09 applies a finished-repository path check to topic files
that are also the plan for building the finished repository.

**What changed.** The full `docs:check` path audit is scheduled for `v0.20.0`,
after the kernel, generators and application template paths exist. The spec
copies are never edited to satisfy the check. ID and ADR validation is applied
to AI files as they land.

**Spec feedback.** CT-09 should say whether the template's own pre-release
repository may stage docs path checks until the referenced kernel paths exist.
Related IDs: CT-09, GEN-07.

## 2026-11-12 — v0.3.0 — issue #14

**What happened.** The specification does not name a repository path for the
application template's payload tree.

**Root cause.** GEN-07 describes what `rails new -m` writes into an adopted
app, but the template repository also needs a source directory to copy and
render without mixing payload with its own `.github/` workflows.

**What changed.** The template will use `template/` as the payload source.
The repository's own `.github/` keeps its oss-kit callers and required checks.

**Spec feedback.** GEN-07 could name the recommended payload directory and
state that the template repository's own `.github/` is not the payload.
Related ID: GEN-07.

## 2026-11-12 — v0.3.0 — issue #15

**What happened.** The round 1 gate audit found two S2 findings: the published
provenance recipe counted the maintainer lessons file as a specification file,
and the implementation issue form did not require Evidence.

**Root cause.** The verification recipe used a directory glob after a
non-spec file joined the directory, and the form made four of five required
fields required. Neither finding touched the spec copies.

**What changed.** The recipe now names and excludes `lessons-learned.md`; the
Evidence field is required. Round 2 passed with only the two intended files in
the diff. The root guide's final rule-ID table and no-version-number cleanup
remain a non-blocking S3 item for `v0.20.0`/`v0.22.0`, tracked in Backlog.

**Spec feedback.** CT-09 verification recipes should say which files are
specification copies. WF-01 should say Evidence is required when an issue
claims rule IDs. Related IDs: CT-09, WF-01.

## 2026-11-12 — v0.4.0 — issue #32

**What happened.** The gate audit applied WF-06's Renovate and peer-group rules
to the template repository's own oss-kit Dependabot setup, then found that the
new exact Gemfile pin broke the production Docker build because `.ruby-version`
was copied too late. The Dev Container also used floating feature tags.

**Root cause.** The milestone description claimed the whole of WF-06 even
though owner decision 2 makes the WF rules govern the adopted app, not the
template repository's own process. The Gemfile and Dockerfile changed in
separate pull requests, so CI did not build the production image and missed
the regression.

**What changed.** Dependabot now updates one package per pull request; the
adopted-app Renovate payload is deferred to the template milestone. Every gem
is exact-pinned and Ruby comes from `.ruby-version`. Dev Container features are
exact-versioned. The production Dockerfile copies `.ruby-version` before
`bundle install`. The milestone description now says WF-06 runtime-pin
checkpoint.

**Spec feedback.** WF-06 should state explicitly whether it governs the
template repository's own dependency bot or only the adopted app. OPS-09 should
say that Dev Container feature tags need exact versions, not just the base and
database images. Related IDs: WF-06, OPS-09.

## 2026-11-12 — v0.5.0 — issue #50

**What happened.** The gate audit found the production image no longer built:
the frontend moved to Vite, but the Dockerfile had no Node/npm and the
repository had no `bin/vite`. It also found Kamal's `asset_path` still pointed
at Propshaft.

**Root cause.** The baseline conversion split frontend wiring from the
production image. `bin/ci` runs `npm run build` on the host, so it did not
exercise `assets:precompile` inside the image, and no CI job built the image.

**What changed.** The image now copies pinned Node/npm from the official Node
image, runs `npm ci`, includes `bin/vite`, excludes development and test gems,
and removes `node_modules` after precompile. CI builds the production image.
Kamal asset bridging points at `/rails/public/vite`. The image builds, boots,
and serves `/up`, `/` and its Vite assets.

**Spec feedback.** ARCH-01 and OPS-06 should state that the production image
build is part of the baseline gate, not only the later operations milestone,
because the frontend build can break it. Related IDs: ARCH-01, OPS-06.

## 2026-11-12 — v0.6.0 — issue #65

**What happened.** The gate needed three audit rounds. The first found that the
skip check only scanned fixtures, the pin/action/workflow checks were text
scans that ordinary YAML or Gemfile forms could bypass, and canary coverage was
too shallow. The second found regressions in duplicate action comments, a
guarded release checkout, path gems and quoted YAML keys.

**Root cause.** Guards that read text instead of the parsed source, and a
canary harness that only asserted one substring per guard. The initial
milestone also claimed the checks without running them against the real tree.

**What changed.** The skip check runs on the real RSpec and frontend tests.
Pins evaluate the Gemfile and gemspecs through Bundler. Actions are parsed from
YAML, comments are checked per line, and the workflow policy checks parsed
triggers, every checkout/run step and a job/scope allow-list. The canary
harness now checks 18 cases, including full pins. Release metadata and lessons
remain part of the gate.

**Spec feedback.** TS-07 should say a guard with several sub-rules needs a
canary for each sub-rule, not one fixture per script. WF-07 should allow the
semantically equivalent double-quoted guarded-release `if:` form. Related IDs:
TS-05, TS-07, WF-06, WF-07.
