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

## 2026-11-12 — v0.7.0 — issue #94

**What happened.** The gate found the TypeScript clone detector was a no-op
because every engine TypeScript file was a one-line file below jscpd's minimum
size, growth omitted core constants and domain budgets, fan-in counted every
non-kernel engine as a product module, and the public-interface skill omitted
rule IDs.

**Root cause.** New guards were wired before there was enough engine code to
exercise them, and the growth/fan-in scripts were written against the current
skeleton rather than the engine kinds.

**What changed.** The engine public files are multi-line and the clone scan is
scoped to public/domain/forms/hooks/gateways/policies. Growth checks public
constants and domain-engine surfaces. Fan-in counts only engines with a
registry entry. The skill cites ARCH-05, ARCH-08, ARCH-09 and GEN-05. Graph and
privacy canaries plus clone-pair calibration are carried to #102.

**Spec feedback.** TS-07 should say how a guard behaves when it currently has
no eligible input, and ARCH-12 should say whether an empty product-module set
is a pass. Related IDs: ARCH-05, ARCH-12, TS-07.

## 2026-11-12 — v0.8.0 — issue #109

**What happened.** The v0.8.0 gate needed three audit rounds. Round 1 found the
base controller could not authorize or deny, the home page skipped
`verify_authorized`, `Urls` called non-existent route helpers, props read
`Current` through the policy, locale redirects dropped the path and query, and
the new registry and guard checks were incomplete. Round 2 found the app-route
reservation was dead at boot and would self-reject once routes loaded, the
legal graph canary created an illegal design_system → core edge, the callback
spec did not pin the chain, and the fan-in fixture did not exercise the kernel
exclusion. Round 3 found the round 2 route fix hid a genuine app route by
subtracting every module's first path segment.

**Root cause.** The kernel pieces were built and tested one at a time; some
tests used hand-built doubles that did not match the real Rails route and
callback shapes, and the first graph canary proved only the negative cases.

**What changed.** `pundit_user` and a 403 `auth.forbidden` rescue; `HomePolicy`
and an authorized home page; props policies built with `context.permissions`
and an empty set fallback; mounted-engine `_path` helpers; locale redirects
that preserve path and query; middleware position and exempt-path specs;
route-aware registry validation from the middleware with only module keys
excluded; exact symbol callback-chain pinning; isolated grant-shape specs; a
capability reason that distinguishes a disabled flag from a policy denial;
growth counting indented constants; fan-in ignoring kernel engines; a required
canary-script meta-check; and legal graph counterparts. Permission manifest
compilation is carried to the module-generator milestone as #124.

**Spec feedback.** ARCH-06 should say when the app-route reservation runs,
because Rails loads routes after engine initializers. TS-07 should say whether
a legal graph counterpart may add a temporary dependency to an existing engine
or must use a throwaway engine. BE-02 should say whether a forgotten
`authorize` is `auth.forbidden` or a separate developer-facing error.
Related IDs: ARCH-06, BE-02, TS-07.

## 2026-11-12 — v0.9.0 — issue #135

**What happened.** The v0.9.0 gate needed three audit rounds. Round 1 found the
client never switched i18n, the home copy was hardcoded English, every error was
JSON, and the new contract/i18n checks accepted blank values, missing engine
catalogs, numeric ids and stale generator outputs. Round 2 found the
asset-version spec was only sequential and the partial-reload guard still missed
a multi-line array.

**Root cause.** The first pass proved helpers directly instead of the request
and page path, and the text-based guards modeled a line rather than the
formatted value. The i18n generator also validated a locale after extracting
the namespace, so a blank string returned before the blank check.

**What changed.** The resolver awaits the locale before loading a page; home
copy lives in the catalogs; errors render the shared page for Inertia/HTML;
blank/missing/plural/percent i18n cases fail; the locale enum and string-id
guard are generated; generators are root-aware and stale-safe; boundary guards
scan values and multi-line arrays; missing translations raise; the asset
version has a threaded spec; stale versions get 409; the shared budget is
measured through a request; the design-system namespace loads; and `add-copy`
names its rules. The dummy engine is carried to #146.

**Spec feedback.** CT-03 should say whether generators delete orphan outputs in
generate mode or only fail in check mode. CT-08 should say whether every engine
must ship a catalog even when it has no UI copy. CT-04 should say whether a page
schema that includes `sharedPropsSchema` satisfies the layout parse.
Related IDs: CT-03, CT-04, CT-08.

## 2026-11-12 — v0.10.0 — issue #155

**What happened.** The v0.10.0 gate needed three audit rounds. Round 1 found
absolute paths could reach any host, the response cap ran after full buffering,
a public cache accepted viewer data, a viewer gateway accepted a service
provider, the deadline/bulkhead/executor promises were only configuration, 4xx
opened the breaker, config values were unvalidated and loaded after eager load,
there was no transaction guard, and the connection spec compared the wrong
values. Round 2 found the streaming deadline, retry deadline, bulkhead release
and truncated-body checks still wrong. Round 3 found the truncation check
rejected legitimate HEAD, 304 and compressed responses.

**Root cause.** The first pass wrote primitives and happy-path specs without
proving the unsafe and bodyless cases, and several guard objects were created
per client instead of per upstream.

**What changed.** Path validation, streaming deadline and cap, shared bulkhead,
deadline-aware retries, transaction guard, validated/frozen config, core-owned
`config.x`, production URL requirement, real connection arithmetic, token-kind
checks and bodyless-response handling. The remaining evidence and wiring are
carried to #165; the dummy engine stays in #146.

**Spec feedback.** BE-05 should say which responses may omit a body when
checking `Content-Length`. BE-16 should say whether a gateway owns one client
for its lifetime. BE-21 should name the Puma thread source explicitly.
Related IDs: BE-05, BE-16, BE-21.

## 2026-11-13 — v0.11.0 — issue #186

**What happened.** The v0.11.0 gate needed four audit rounds. Round 1 found the
signed-in page crashed, the sign-in form had no CSRF token, refresh and dead
sessions were not handled, the CSP nonce was empty, production cookie deletion
was insecure, grants never went stale, and dark modules were still reachable.
Round 2 found a 401 refresh returned 200, production host authorization was
off, and mounted-engine gating read an engine-relative path. Round 3 found the
takeover fence logged the successor out; round 4 passed.

**Root cause.** The first pass tested happy paths and a unit-shaped path that
production never produces, and treated "clear the session" as one outcome for
both a dead session and a lost refresh race.

**What changed.** Rotation and clear-history, a real CSRF token, single-flight
refresh with a version fence and one token/grant write, idle/expired cookie
cleanup, per-request CSP nonces, `form-action 'self'`, production SSL/hosts/`/up`,
`Modules.for_path` over the original full path, and a lost race that returns the
successor token instead of revoking the session. Remaining evidence and SEC-15
generation fencing are carried in #185.

**Spec feedback.** SEC-03 should say whether a refresh writes tokens only or
tokens and grants together. SEC-15 should name the 403 staleness mark and its
concurrency test. SEC-13 should name the exact `/up` and host-authorization
expectations. Related IDs: SEC-01, SEC-03, SEC-05, SEC-06, SEC-09, SEC-13, SEC-15.

## 2026-11-13 — v0.12.0 — issue #220

**What happened.** The v0.12.0 gate needed three audit rounds. Round 1 found two concurrent first claims could both write, real upstream 422/409 never reached the 303 form flow, no audit trail existed, a signed export URL reached the log, the download producer lost `Current`, and several matcher/format/migration checks were shape-only. Round 2 confirmed the write races and audit fixed but found the followed Active Storage request still logged the signed URL. Round 3 passed after exports streamed through core.

**Root cause.** The first pass tested hand-built error objects instead of the real client, treated a shape check as proof of a matcher, generated "previous release" fixtures with the new code, and left concurrency specs that could pass with the fence removed.

**What changed.** First-claim fencing, real 422/409/503 request specs, an append-only `core_audits` table and recorder, a streamed export path with no signed URL, `Current` in the download producer, a bounded queue, computed field codes, and an outside-folder patch canary. Remaining matcher, fixture, migration and concurrency depth is carried in #219.

**Spec feedback.** TS-02 should define each matcher's exact inputs and failure output. SEC-16 should say where the previous release's fixtures come from and how a tag folder is bootstrapped. BE-18 should choose between a signed redirect and log-safe streaming. Related IDs: BE-13, BE-15, BE-18, BE-23, SEC-16, TS-02, TS-10.

## 2026-11-13 — v0.13.0 — issue #238

**What happened.** The v0.13.0 gate needed two audit rounds. Round 1 found every page rendered two layouts, the required locale/time-zone provider was missing, and date input either threw from `fromPlain` or accepted impossible dates such as `2026-02-31`. Round 2 passed after the fixes and round-trip tests.

**Root cause.** The resolver both rendered a layout and assigned it to Inertia, which applies layouts itself; the locale work stopped at a `lang` attribute; and the form sent person input through a factory designed for invariants.

**What changed.** One layout assignment, an `I18nProvider` with calendar/time zone, non-throwing date issues for invalid and impossible dates, a validating `DateField`, copied plain input/output, and round-trip tests for every boundary class. The remaining matcher, compiler-proof, URL-guard, bundle and date-field depth is carried in #219.

**Spec feedback.** FE-02 should say whether the resolver or Inertia applies the layout. FE-14 should name the provider contract. OOP-03 should name the invalid-date codes and the boundary copy rule. Related IDs: FE-02; FE-14; OOP-03; OOP-05; OOP-10.

## 2026-11-13 — v0.14.0 — issue #249

**What happened.** The v0.14.0 gate needed three audit rounds. Round 1 found the announcer focused on first load and announced the wrong text, the flash region was inserted with its message, the error boundary was app-local and reported to a missing route, the chart crashed from missing ECharts components, controls were native HTML, and new copy was hardcoded. Round 2 found the announcer compared the already-updated path, so no navigation was ever announced, and Dialog was hand-rolled. Round 3 passed.

**Root cause.** The first pass checked presence rather than the event contract, and the e2e screenshot test waited for a button before the lazy chart had a chance to crash.

**What changed.** A path-ref announcer with history/query/hash rules, an always-mounted flash region, a design-system boundary with reset/retry/ids/CSRF reporting, modular pie-chart ECharts, React Aria controls and modal, localized en/th copy, and a test-env e2e run against built assets. Remaining catalog, declaration, lint and guard depth is carried in #219.

**Spec feedback.** FE-13 should name the Inertia event ordering and the initial/history semantics. FE-15 should name the reporter contract and last-resort boundary. TS-11 should say which assets and locale screenshots the baseline covers. Related IDs: FE-07; FE-08; FE-13; FE-15; TS-08; TS-11.
