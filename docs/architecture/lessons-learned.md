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

## 2026-11-13 — v0.15.0 — issue #260

**What happened.** The v0.15.0 gate found a generated module that did not boot, a post-write step that ignored failures, no rollback outside the engine folder, broken TypeScript/errors checks, hardcoded locales/namespace, a locale-shaped name accepted, and an invalid permission manifest. Round 2 passed after the generated engine was loaded from `config/module.rb`, the post-write steps raised and restored root files, and the domain/module skeletons were completed.

**Root cause.** Generator specs stubbed post-write and never booted a real engine; the registry entry lived in an engine initializer that ran before core autoloading; and token substitutions copied contracts instead of reading them.

**What changed.** App-level module loading, booted module/domain verification, `run_step` failure propagation, tree snapshots/restore, design-system/locale/typecheck skeletons, direct permission manifests, and name normalization/validation. The permission compiler (#124), Prettier, real-smoke CI and adoption namespace are carried in #219.

**Spec feedback.** GEN-09 should name the exact generated root files a rollback restores and whether a rolled-back CLI exits non-zero. GEN-03 should name the gem-name/namespace rules during adoption. Related IDs: GEN-01; GEN-03; GEN-05; GEN-09; ARCH-06.

## 2026-11-13 — v0.16.0 — issue #267 (gate)

**What happened.** The v0.16.0 gate (GEN-02/GEN-04/GEN-06/TS-06) passed with no S1 and four S2 findings carried into v0.17.0 (#219). Generator smoke (`script/ci/generator_smoke`) and CI wiring were completed and made green in #279, but page/move/rename generators still only partially satisfy the full slice and release-compatibility requirements.

**Root cause.** End-to-end smoke proved the happy path (create/verify/move/rename/verify) before dedicated generator specs, legacy-URL/permission pinning specs, and full GEN-02/GEN-06 behaviors (root-route reassignment, legacy table-prefix/constant metadata and ratchets, trigger/skip exactness) were complete.

**What changed.** Posted gate traceability/audit on #267, recorded S2 carries in #219, added lessons-learned entry, and bumped `VERSION` to `0.16.0` for release. `bin/ci` and generator smoke are green.

**Spec feedback.** GEN-04/TS-06 could clarify whether the smoke skip must be declared as a job-level `if:` when the job always runs a cheap decide step with an explicit skip reason. GEN-06 could spell out the minimum evidence for `legacy_paths` redirect and permission-key stability (request-spec shape). Related IDs: GEN-02, GEN-04, GEN-06, TS-06.

## 2026-11-13 — v0.17.0 — issue #287

**What happened.** The SEC-16 carry-over found that the v0.16.0 format fixtures had been generated by the then-current code after the release rather than from the released tag, and the compatibility spec only created them back through the current writers. It did not prove a previous-release row and a current-release row could be read from the same tables, and it did not reject an unreadable format version.

**Root cause.** The release step that runs `bin/rails formats:dump` was treated as a file-generation step instead of part of the release contract, and the spec exercised the writer path instead of the production readers.

**What changed.** Regenerated `spec/fixtures/formats/v0.16.0/` from tag `v0.16.0` in a clean worktree, added `PersistedFormatsReader` to load a folder through the current readers and refuse unsupported versions, expanded the spec with previous/current mixed-release reads and an unsupported-version canary, and added `bin/rails formats:check` to the CI gate. No guard, budget, or ratchet was loosened.

**Spec feedback.** SEC-16 should say which tag's code generates a release's fixtures when the release pull request is prepared, and whether the compatibility spec loads the latest folder or the N-2 window. Related IDs: SEC-16; TS-01; WF-05.

## 2026-11-13 — v0.17.0 — issue #291

**What happened.** The TS-02 carry-over found that the page matchers proved the wrong things: `have_resolvable_hrefs` accepted any route-recognizable path instead of the paths Rails built, `match_policy_capabilities` checked the shape of `can` rather than the policy method and grant matrix, and `be_within_props_budget` never required the maximum page size. The budget matcher also counted session refreshes against the page's upstream budget, and a page could render a different component than the page key under test.

**Root cause.** The matchers reimplemented weak approximations in the test support layer, and the request flow did not expose `Urls#built` or the props object to a request spec. The per-upstream budget lookup also used symbol keys against a YAML hash with string keys, so any upstream call would have failed the budget.

**What changed.** `BaseController#render_page` records the built URLs and, for a `PageProps`, the props object in the request env. The matchers now compare the component with the page key, require every href path to be in `Urls#built`, compare `can` with `CapabilityMap` over the declared policy methods and flags, enforce `ListQuery.max_per_page` and `data.items` length for paginated pages, and count `session_refresh`/`auth`/`resend` upstream notifications separately from page calls. Added `spec/core/page_matchers_spec.rb` with mutation-style canaries, fixed the string-key budget lookup, and made `pages:check --matchers` reject records for page keys that have no contract.

**Spec feedback.** TS-02 should name the request-env capture seam for `Urls#built` and the props object, and say that the paginated list is `data.items`. It should also say whether `paginated: false` is represented only by a `null` pagination. Related IDs: TS-02; CT-02; BE-04; BE-16; ARCH-10.

## 2026-11-13 — v0.17.0 — issue #296

**What happened.** The SEC-09/SEC-13/SEC-14 carry-over found that the body-limit 413 returned before the controller stack and carried neither the request/trace ids nor the security headers, that `Current.trace_id` only ever fell back to the Rails request id, and that upstream path validation rejected literal `..`, `/`, and `\` but not their percent-encoded forms.

**Root cause.** The limit is a Rack middleware response, so controller callbacks and `default_headers` do not run for it. The path check split the raw string before decoding.

**What changed.** Added `TraceMiddleware` after `ActionDispatch::RequestId`, moved `BodyLimit` after it, and made the 413 payload and headers self-contained. `UpstreamClient#validate_path!` now rejects `%2e`, `%2f`, `%5c`, and `%00` before any call. Request and client specs pin the ids, headers, and traversal cases.

**Spec feedback.** SEC-13 should name the exact headers a middleware response must carry. SEC-14 should say whether encoded separators are rejected or decoded before validation. Related IDs: SEC-09; SEC-13; SEC-14; OPS-02.

## 2026-11-13 — v0.17.0 — issue #299

**What happened.** The BE-22/deploy-preflight carry-over found that `StrongMigrations.statement_timeout` (5 minutes) exceeded `deploy_timeout` (120 seconds), so a boot migration could outlive the deploy that runs it. The preflight also checked only that `.kamal/secrets` was untracked; it did not require the secret names or the daily advisory workflow.

**Root cause.** The two timeouts were configured in different files with no relation test, and the preflight was a tracked-secret check rather than a deploy-contract check.

**What changed.** Set the statement timeout to 2 minutes, added a migration guard spec that reads `deploy_timeout` from `config/deploy.yml` and a concurrent-index expand/contract fixture, and taught the preflight to require `RAILS_MASTER_KEY` in `.kamal/secrets` (or its example) and in `env.secret`, plus the scheduled advisory workflow. The canary now covers the unlucky secret file.

**Spec feedback.** BE-22 should name whether the statement timeout equals or is merely bounded by `deploy_timeout`. OPS-06 should name the exact secret names a preflight must see. Related IDs: BE-22; OPS-06; WF-05.

## 2026-11-13 — v0.17.0 — issues #306–#308, #313

**What happened.** The GEN-08 examples landed after the independent gate audit found S1s: the v0.16.0 format fixture had been given an example job row (making a kernel compatibility check depend on an example engine), the removal job patched that fixture, and the example export CSV was formula-injectable and silently capped at 100 rows. The audit also found hardcoded English copy, an ungated edit link, dropped pagination/filter query state, an optional edit version, and a non-idempotent export POST.

**Root cause.** The examples were built as a feature slice, while GEN-08 treats them as removable teaching code. The format fixture and the export job were treated as ordinary feature code rather than as kernel-adjacent proof.

**What changed.** The format guard now excludes `engines/example_*` job classes (GEN-08 wins over SEC-16 for removable examples) and the v0.16.0 fixture is unchanged from its tag. The removal job deletes the examples and runs `bin/ci` without editing kernel fixtures. The export job now pages through the filtered collection and escapes CSV fields, the examples use their locale catalogs and `can`, pagination/filter links preserve query state, update requires a version, export uses `IdempotencyClaim`, and the show edit link is capability-gated. Remaining example-depth S2s (browser flow, shared `formatMoney`, root TypeScript example-import scope) are carried in #314.

**Spec feedback.** GEN-08 should say whether example-engine jobs are part of the kernel persisted-format fixtures, or explicitly exempt them. It should also say whether examples need a browser flow when the template's Playwright config only names design_system. Related IDs: GEN-08; SEC-16; CT-08; FE-11; BE-15; TS-01; TS-07.

## 2026-11-13 — v0.18.0 — issue #317

**What happened.** The first example_orders browser journey found two runtime gaps that the request specs could not see: the deferred chart block raised `NameError` on every deferred reload, and a conflicting edit returned a base error in props that no screen rendered.

**Root cause.** Inertia evaluates a deferred prop block with `instance_exec` on the controller, so a block that calls an instance method of the props object loses that receiver. The edit and new screens passed only field errors to the form fields, and the request specs asserted `props.errors.base` rather than a visible state.

**What changed.** The index props compute the chart data before passing a block that closes over the value; the order form renders a base error with a test id on both new and edit; the browser flow signs in through the real form, reads the form token from the rendered page, asserts the PATCH carries it, hits the 409, and recovers with the fresh version. A stateful fake upstream serves the committed fixtures during `script/ci/e2e`, which now runs Rails with `E2E_SERVER=1` (CSRF on) and removes the BFF-owned test rows after the run.

**Spec feedback.** TS-03 describes the fake upstream being mounted in the app, while this flow runs it as a separate Rack process; the spec could name the allowed process boundary for a browser-only upstream. Related IDs: GEN-08; TS-01; TS-03; BE-13; BE-15.

## 2026-11-13 — v0.18.0 — issue #321 (gate)

**What happened.** The independent v0.18.0 gate found S1s before release: a throttle or CSRF failure stopped before `assign_request_context`, so its error page and report lost the request and trace ids; the CSRF report was labelled `unexpected` instead of `request.csrf_failed`; sign-in refusals were handled without a `Rails.error` report; and the production route checker let an allow-listed multi-verb, `Proc`, redirect or non-registry mount route pass. It also found S2s in the real route-walker's mount handling and in `legacy_paths` double slashes.

**Root cause.** Throttles are prepended before every controller callback (BE-12), so request context must also be available before them. The route checker compared the allow-list before checking whether a route kind could be classified, and the walker could not tell a registry engine from an arbitrary mounted engine. `legacy_paths` keys already carry a leading slash, so string concatenation produced `//`.

**What changed.** `TraceMiddleware` now sets `Current`'s request id, trace id and sampled bit before any controller callback; early error paths share `trace` before rendering. CSRF failures have their own rescue handler and report `request.csrf_failed`. Sign-in refusals report through the same `ErrorReporter`. The route walker receives the registry engines, marks any other engine mount unknown, and `ProductionRoutes.check` rejects unsupported or disallowed kinds before allow-list matching; the canary covers allow-listed multi-verb, `Proc`, redirect and fake-mount routes, and the walker/legacy-path cases have unit specs. OPS-04 remains a SHOULD: the implemented series cover request rate/latency, upstream calls/time, catalog errors, refreshes, dropped grants, jobs and pool gauges; dashboards, alert routing, circuit-breaker/bulkhead, CSP and database dead-tuple/HOT series are deployment-monitoring work, recorded here as the reason rather than silently omitted.

**Spec feedback.** OPS-02 should state that throttles and CSRF failures must publish the ids before controller callbacks, and SEC-12 should say whether an allow-listed route whose kind is `Proc`, redirect or multi-verb can ever pass. OPS-04 should name which series are mandatory for a SHOULD and where dashboards/alerts live. Related IDs: OPS-01; OPS-02; OPS-03; OPS-04; OPS-05; SEC-12.

## 2026-11-14 — v0.19.0 — issue #333 (gate)

**What happened.** The independent v0.19.0 gate found S1/S2 issues the feature
pull requests had missed: the role bootstrap script ran before the tables it
granted on, so it aborted on a fresh database, and it never gave the migration
role ownership of the tables a v0.18.0 database already had, so `db:prepare`
as the migrator could not run the expand migration. The runtime role kept
`UPDATE`/`DELETE` on the legacy `core_audits` table, and a rollback copied
every already-copied audit row into `core_audits` a second time. The
production credentials file was missing, the pgBackRest stanza pointed at the
PostgreSQL 17 data directory, #336 had rewritten the v0.18.0 format fixtures,
and the Dev Container workflow did not rebuild when `mise.toml` or the npm
lockfile changed.

**Root cause.** The role work was specified from the finished state (both
roles, both audit tables) while the expand release runs with a pre-existing
database and a legacy table. Source-shaped specs (`include "REVOKE ..."`)
proved the text rather than the PostgreSQL privileges. The production
credentials contract was described in the spec but no release-owned file was
created. The Dev Container workflow copied the `paths` filter from the spec's
example even though its Dockerfile consumes root-level pin files.

**What changed.** The role script is re-runnable, creates the roles when
missing, transfers ownership of existing tables and sequences to the migrator,
uses the database's own name, sets default privileges, and restricts
`core_audits` as well as `core_audit_events`. A real-database spec creates a
scratch database, runs the script twice, and checks ownership and every
privilege; a second spec runs the expand migration up and down against a
v0.18.0-shaped table and proves no row is duplicated. The rollback uses a
`NOT EXISTS` copy, and `restrict_grants!` covers the legacy table while it
exists. `config/credentials/production.yml.enc` is committed with placeholder
values (key never committed); the pgBackRest path is the pinned image's
`/var/lib/postgresql/18/docker`; the v0.18.0 fixtures are restored from tag
`v0.18.0` and v0.19.0 is dumped from this release; the Dev Container workflow
also watches `mise.toml`, `package.json`, and `package-lock.json`.

**Spec feedback.** OPS-09's literal filter (`paths: [".devcontainer/**",
"!.devcontainer/image_digest"]`) contradicts the same rule's requirement that
the image install Node and npm from `mise.toml`; proposed wording: "also
trigger on the root pin files the image Dockerfile copies (`mise.toml`,
`package.json`, `package-lock.json`)". OPS-08 should say that the role script
runs before the first `db:prepare`, is re-runnable, and transfers ownership of
existing tables during the expand release. OPS-06 should say whether the
template commits placeholder production credentials or expects the adopter to
create the file. Related IDs: OPS-06; OPS-07; OPS-08; OPS-09; SEC-16; ARCH-13.

## 2026-11-14 — v0.20.0 — issue #345 (gate)

**What happened.** The independent v0.20.0 gate found S1s the feature pull
requests had missed: the ratchet check read only the root `config/ratchets.yml`
and ignored every engine ratchet; CODEOWNERS did not own
`config/production_routes.yml`, `spec/enforcement/`, or the engine
`package.yml` files, so the guard check passed them; `release --check` passed
a `VERSION` whose tag already existed; the release check was wired into local
`bin/ci` but not into a GitHub CI job; the scheduled `repo_rules` compared
only the branch ruleset; and `docs:check`/`docs:canary` were not GitHub CI
steps. It also found stale milestone-triggered release wording in `README.md`,
`CONTRIBUTING.md`, and the implementation protocol.

**Root cause.** Each feature PR tested its own happy path. The gate is the
first place that combines the checks: a required check that reads only one of
several ratchet files, a CODEOWNERS file that does not cover the whole guard
list, and a local gate step that has no CI counterpart all pass their own
canaries.

**What changed.** `script/ci/ratchet` aggregates the root and every engine
ratchet, keyed by file; CODEOWNERS covers the missing guard paths; the release
check fails an existing tag, a missing format folder, or a locale placeholder,
and a `script/ci/release_check` wrapper runs it only when `VERSION` changed,
with a GitHub CI step and the tags fetched; the
scheduled `repo_rules` compares both exports; `docs:check` and `docs:canary`
run in the CI test job; the release order is documented as merge → release
workflow → confirm → close milestone; the canaries cover engine ratchets,
canary fixtures, tag rulesets, and both release paths. The gate also found
that WF-04 had no review-gate issue template despite the milestone naming it;
`.github/ISSUE_TEMPLATE/review_gate.yml` now carries the severity table, the
two-round limit, the evidence requirement, and the person's sign-off.

**Round 2.** The independent re-audit found more gaps in the workflow payload:
CI did not run on `merge_group` and `affected` ignored the merge-group base
SHA; CODEOWNERS left the root `package.yml` and parts of the kernel
uncovered; the ratchet canary raised the root and engine counts together, so
it did not prove engine aggregation; the pull request and release canaries
ran only locally; `repo_rules` compared the tag rules but not its
`refs/tags/v*` scope; and the review-gate form did not prompt the whole-slice
review areas. CI now runs on `merge_group`, uses its base SHA, owns the whole
kernel and root package, runs the pull request and release canaries, and
compares the tag conditions; `ratchet_canary` has an engine-only rise; the
review-gate form asks for bugs, edge cases, security, performance,
accessibility, and documentation. Two S1 findings are carried to v0.21.0:
the single-owner guard approval fallback and the missing
`script/ci/ratchet --update`/scheduled lowering job (#354, #355). CT-09's
envelope table in the read-only spec copy is not a finding; #356 records the
spec question, and the generated table lives in `docs/contracts.md`.

**Single-owner fallback.** This repository has one CODEOWNERS owner, so an
owner-authored PR cannot receive an independent approval. `guard_approval`
records the guard files and passes only when the sole owner is the PR author;
a non-owner author still needs that owner, and a repository with a second
owner requires a real approval. This is the spec's fallback for a repository
that lacks code-owner review; #347 asks the owner to add a second owner and
apply the ruleset, and #355 tracks the finding. It is not used for ratchet
rises.

**Spec feedback.** WF-03 should name the single-owner case explicitly.
WF-05 should say the VERSION check runs only when VERSION differs from the
merge base; otherwise the latest release's own tag makes the check fail.
CT-09 should state that a pre-release repository may stage paths owned by a
later milestone in a list that fails when the path lands. Related IDs:
CT-09; WF-03; WF-04; WF-05; WF-07; TS-07.

## 2026-11-14 — v0.21.0 — issue #354 (ratchet update)

**What happened.** The v0.20.0 gate carried the missing `script/ci/ratchet
--update` and its scheduled lowering job. Implementing the update showed that
the committed `skipped_tests: 0` is below the six annotated skips in the
repository: a scheduled job cannot raise it without an owner, so it reports
the rise and lowers only the counts that fell. The scheduled workflow must
open its pull request with a GitHub App or personal token; a pull request
opened with the workflow `GITHUB_TOKEN` does not start CI.

**Root cause.** The ratchet check was written as a comparator first; the
first delivery did not add the counting side that maintains the ceilings. The
existing skipped tests were never counted into the ceiling.

**What changed.** `script/ci/ratchet_counts.rb` computes the frontend
disable/no-memo counts, Ruby `rubocop:disable`, annotated skips, page-budget
overrides, legacy table prefixes/constants, and the clone baseline through
`script/ci/clones`. `--update` writes only falls and reports rises without
raising them; `--no-clones` keeps the canary fast. `.github/workflows/ratchet.yml`
runs daily and opens one lowering pull request; it uses
`secrets.RATCHET_TOKEN` when set. Canaries cover a fall, a rise, and the
setting-preserving write. #363 tracks the stale skip ceiling; #364 tracks the
app token.

**Spec feedback.** WF-03 should say that `--update` reports a rise instead of
failing when the committed ceiling is stale, and that the scheduled workflow
needs a token that can trigger CI. Related IDs: WF-03; TS-05; ARCH-05.

## 2026-11-14 — v0.21.0 — issue #361 (gate)

**What happened.** The independent v0.21.0 gate found one S1 and six S2s in
the new template and updater. Round 1 fixed the N-1 commit identity (#368),
the app-owned names and docs (#369), and the `.github`/conflict state in the
updater (#370). Round 2 found that the N-1 proof would fail once `VERSION`
moved to 0.21.0: the updater did not carry the app-owned specs, tasks,
packaging and container files whose names #369 had changed. It also found
app-owned `rafelo` names left in two documents and a `--continue` false
positive on a Markdown setext separator; #371–#373 fixed those. Round 3 found
one regression from #373: a partially resolved marker (only `<<<<<<<` or
only `>>>>>>>`) no longer blocked `--continue`; #374 fixed it and added the
four partial-marker cases. No S1/S2 remains.

**Root cause.** The template renderer and the updater kept two hand-written
lists of what follows the app name, so #369 changed the copied files but not
the default update paths. The N-1 branch is skipped until `VERSION` names a
release whose predecessor has the payload, so feature CI at 0.20.0 could not
see the break; only an explicit `ADOPTION_VERSION=0.21.0` run did. The first
conflict-scan fix then over-corrected: requiring a full marker pair let a
partially resolved conflict through, while treating any seven-character
separator as a marker blocked ordinary Markdown.

**What changed.** `bin/kernel_update` now updates `spec/config`,
`spec/requests`, `spec/support`, `spec/tasks`, `lib/tasks/restore.rake`,
`config/storage.yml`, `package.json`, `package-lock.json`, `.devcontainer`
and `Dockerfile`; the source documents use the `acme` placeholder for
app-owned image, stanza, repository and database names; `--continue` requires
no `<<<<<<<` or `>>>>>>>` line (a lone `=======` is not a conflict) and
ignores `public/vite*` paths; the render spec asserts the rendered docs;
`ADOPTION_VERSION=0.21.0 script/ci/adoption` proved the v0.20.0 → 0.21.0
update before the release. S3 notes are in #375; the single-owner guard
finding (#355) is carried to v0.22.0.

**Spec feedback.** GEN-07 should say that a kernel update includes the
app-owned files whose names the template renders (config, specs, tasks,
packaging and container files), or name them in the update list; otherwise
the N-1 proof and the "adopter owns the kernel" rule pull in opposite
directions. GEN-07 should also define a conflict as a remaining `<<<<<<<` or
`>>>>>>>` line, not a lone `=======` separator. Related IDs: GEN-07; GEN-08;
ADR-27; ADR-28; WF-03.

## 2026-11-14 — v0.22.0 — issue #379 (skills audit)

**What happened.** The final skills audit read the nine shipped skills (the
request workflow and eight task skills) and all 49 `oo-*` pack skills, then
compared them with the final rules and the code as built. It found drift in
six task skills and sixteen places where the pack's general advice contradicts
a project rule or ADR. The vendored pack was not edited.

**Root cause.** The task skills were written before the generators and kernel
settled, so a few paths and rule IDs described the intended shape rather than
the generated one. The pack assumes a local domain model that owns its business
rules and stores aggregates; Rafelo is a BFF whose upstreams own the business
data and rules, whose engine boundaries decide code ownership, and whose React
is functional with immutable TypeScript classes only in `domain/` and `forms/`.

**What changed.** `add-design-system-component` now names the real flat
component path, both export files, the catalog page, and the committed Playwright
snapshots. `add-read-page` and `add-write-action` now put fixtures under the
engine's `spec/fixtures/upstream/` and cite BE-03, BE-06, and CT-08; the
irrelevant BE-11/BE-22 citations are gone. `add-module` now separates what a
product module gets from what a domain engine gets and no longer claims the
domain generator writes permissions, errors, budgets, or ratchets. `add-copy`
and `expose-public-interface` follow the standard skill shape. `docs:check` now
fails an `ai_instruction_files` entry that matches no file and a `SKILL.md`
whose front matter is missing, whose `name` differs from its directory, or
whose `description` is empty; `docs:canary` proves all four cases (32 cases).

**Pack advice that the rules replace.** Each row names the pack skill and rule,
then the project rule that wins and how the project resolves it. The root guide
already states that a rule or ADR wins over the pack.

| Pack advice | Project rule | Resolution in the project |
| --- | --- | --- |
| `oo-assigning-responsibilities` 5, `oo-placing-domain-logic` 2, `oo-layering-the-system` 1–2, `oo-designing-repositories` 1–2/5, `oo-taming-persistence` 4: send each request to a use-case object, load aggregates through repositories, and open one unit of work per use case. | ADR-05; BE-01; BE-10; BE-20 | The controller action is the use case: authorize → gateway → props → render. Reads use props/query objects; upstreams use gateways returning `Data` value objects. There is no repository, application-service, or unit-of-work layer; a new layer needs an ADR. Local BFF writes may use their own transaction, never around an upstream call. |
| `oo-design` design-loop step 3 (`oo-layering-the-system` 2, `oo-placing-domain-logic` 5): put the business rules in an entity, value object, or domain service. | ARCH-03; OOP-08; ADR-01 | The upstreams own business data and rules. Local `domain/` and `forms/` code is only for presentation, derived values, invariants, and instant feedback; ask the upstream instead of mirroring or re-implementing its rules. |
| `oo-constructing-valid-objects` 1/3/4, `oo-encapsulating-state-and-behaviour` 1, `oo-making-illegal-states-impossible` 3, `oo-modeling-values-and-entities` 5, `oo-designing-failure-behaviour` 1/4, `oo-modeling-lifecycles` 2, `oo-placing-domain-logic` 5: a constructor or command rejects invalid input by raising, so a forbidden state cannot exist. | OOP-03; BE-13; FE-15 | Input from a person is never validated by throwing. The form's plain type keeps the raw value, `fromPlain` accepts what its plain type allows, and `issues()` reports stable codes while the field renders. The value type is built only after `issues()` is empty; a server refusal becomes 303 with errors or 422/409, not an unhandled raise. Only invariant violations throw `DomainError`. |
| `oo-designing-failure-behaviour` 3: never one error with a code field that callers test. | OOP-03; CT-06 | `DomainError` carries a stable code, and UI-visible errors use the catalog codes. Callers and the error responder translate codes; there is no class per code. |
| `oo-modeling-values-and-entities` 5 / `oo-deciding-object-or-data` 2/4: a class per form is unnecessary, and a value must reject an invalid state at construction. | OOP-02; BE-13 | A write form gets a form model in `forms/` with its field rules, `issues()`, and payload conversion. Plain wire types stay plain; the form model is the one place that turns person input into a payload. |
| `oo-ruby` 1: write each role contract as one Minitest module. | TS-01; ADR-20 | Ruby is tested with RSpec at every level. A role contract is an RSpec shared example group included by each implementation's spec; no Minitest suite or CI step is added. |
| `oo-reviewing-object-design` 3: a broken pack `Rule.` or `Default.` blocks the merge. | ADR-32; WF-04 | The pack assists a person; it is not a guard. An AI review drafts findings, a person confirms their severity, and the project's P0–P3 gate decides what blocks. Only an adopted project rule or ADR can block. |
| `oo-working-within-a-framework` 5: in a framework built of functions, keep the rules in functions and never force classes into the code. | ADR-14; OOP-01; OOP-02; OOP-07; FE-04 | React stays functional, and client domain logic stays in immutable classes in `domain/` and `forms/`. Hooks (`useDomainReducer`, `useUiState`) are the bridge; `toPlain()`/`fromPlain()` cross the boundary. |
| `oo-managing-shared-state` 1/pattern/6: share a cache in memory between threads and give a slow dependency an active object with its own thread and queue. | ARCH-13; BE-17; BE-16; BE-11 | Cross-request state lives only in PostgreSQL or Active Storage. Cache through `ScopedCache` with a validated `module:`. Concurrent upstream calls use `Core::Executor`; background work uses Solid Queue. No in-process cache, lock, or active object. |
| `oo-publishing-domain-events` 2–4 and `oo-separating-reads-from-writes` 3/6: record events in the aggregate, publish after commit through an outbox, and project read rows into a second store. | ARCH-03; BE-20; BE-07 | Upstream business changes are not local aggregates, so there is no outbox, event store, or read-model projection for them. Reads go gateway → value objects → props; after-commit work uses jobs. A BFF-owned event or second store needs an ADR and must live in PostgreSQL. |
| `oo-designing-what-to-record` 2: write the audit record as domain data in the same transaction as the act. | OPS-08; BE-15; BE-20 | Core writes exactly one audit row from the write path or the error responder. The row is its own statement; no transaction spans the upstream call, and the audit is not an aggregate in a use-case object. |
| `oo-crossing-system-boundaries` 4: never rename, remove, or retype a contract field; version an incompatible contract. | CT-05; CT-12; ADR-31 | Additive first. A breaking change takes two releases: add the new field, switch the UI, remove the old field later with `!`. Old tabs reload through the asset version; page props do not get a parallel contract version. |
| `oo-bounding-contexts` 3 (shared kernel) and `oo-organising-modules` 4–5 (consumer-owned port): two teams share a model, or the depending module owns the interface and the provider implements it. | ARCH-05; ARCH-08; ARCH-09 | Shared code has exactly one owning engine and is exposed through its public surface; the consumer declares the dependency. No jointly owned shared kernel and no consumer-owned port that reverses the engine graph. If no engine owns the concept, extract a domain engine. |
| `oo-inverting-dependencies` 1–5: put a port beside the domain, make the provider implement it, and wire adapters at a composition root. | ARCH-04; ARCH-08; ARCH-09; ADR-05; BE-01 | The controller action is the composition edge. An engine declares its dependencies in `package.yml` and calls the owning engine's gateway or public object directly; there is no port/adapters layer and no separate composition root. A new layer or a consumer-owned port needs an ADR. |
| `oo-testing-object-oriented-code` 7: check the adapter against the real outside system in a few slower tests. | TS-03 | Tests never reach the network. Each upstream has recorded fixtures and an in-process fake; `WebMock.disable_net_connect!` enforces it. A scheduled, non-blocking drift job checks the real system, not a test. |
| `oo-designing-for-testability` 8: add no public field, getter, flag, or method that only tests use. | CT-12 | `AssetVersion.reset!` is a documented kernel test hook and stays. A new test-only public hook needs a person to decide it; the general rule does not silently remove this one. |

The remaining 23 pack skills were read and had no conflict with a project rule
or ADR; the table names every conflict, not every skill.

**Spec feedback.** `14_working_with_ai.md` could say that a pinned general
design pack may assume a local domain model and that the adopter's ADRs decide
where business rules and persistence live; otherwise an agent may treat the
pack's aggregate/repository examples as the target architecture. Related IDs:
ADR-32; ARCH-03; ARCH-05; ARCH-13; OOP-03; BE-01; BE-20; TS-03.

## 2026-11-14 — v0.22.0 — issue #382 (final gate)

**What happened.** The final gate audited the v0.22.0 AI-file changes
(#383–#385), the eight request-workflow trials (#380), and the rule/ADR
traceability table (#381). The independent audit found two release blockers
and four S2 evidence defects. The enforcement matrix names 17 custom cops and
20 ESLint-dependent rules; the repository implements 5 cops and has no ESLint.
The root `AGENTS.md` "Never" bullet said "Put secrets or real personal data in
code, tests, fixtures, logs, or issues" as a positive sentence. The trial
record called trial 3's first push green when it was red, and said no baseline
changed while the design-system trial updated the TS-11 screenshots. The
traceability table cited an empty CT-10 glob and the wrong cop for BE-09. The
`add-write-action` skill said a validation failure re-renders, contradicting
BE-13.

**What changed.** Root `AGENTS.md` now says "Put no secrets or real personal
data in code, tests, fixtures, logs, or issues"; `spec-provenance.md` records
that the gist copy is historical and not loaded. The engine guides cite their
rule IDs and no longer say "once the engine has a test suite".
`add-write-action` says every write outcome, including a validation failure,
redirects with 303 and the translated errors. The trials record marks trial 3's
first push red, records the TS-11 baseline update, defines the supervisor
hand-over, and fixes the adoption wording. The traceability table uses the
matrix statuses, marks each missing cop or ESLint tool as review with #387,
fixes CT-10's glob, and cites the real `Current` path for BE-09. The 49-pack
skill count and the `oo-inverting-dependencies` conflict row are corrected.
The missing cops and ESLint rules are carried in #387; the S3 notes are in
#390.

**Spec feedback.** `09_enforcement.md` should not name a custom cop or ESLint
rule that the template does not ship; mark the rule review until the tool
exists. `docs:check` could fail an unlisted non-`oo-*` skill. The final
traceability table is the place to record a spec-versus-code gap, not to repeat
the matrix's claim. Related IDs: ADR-32; TS-07; CT-09; BE-13; BE-08; WF-06;
ARCH-09; BE-09.
