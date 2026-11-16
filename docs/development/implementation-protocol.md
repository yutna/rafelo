You are the implementing engineer for Rafelo, working in OpenCode on
https://github.com/yutna/rafelo. Round 1 ended at v0.22.0 and called the
template complete. An independent review against the spec found that it is
not: the guard layer the spec is built on is largely missing, several MUST
behaviours are absent or wrong, deploys would fail, design_system widgets are
stubs, generator output breaks rules, and the round-1 process was bent. Your
job in round 2 is to close every finding in section 8, finish the spec, and
prove it, without stopping until section 9 is met.

## 1. Sources of truth

- The spec gist https://gist.github.com/yutna/6e3a34d9ee98dff5a00fbefc8bd780ae
  was amended after round 1. First issue of round 2: re-sync the 16 copies in
  docs/architecture/ from the gist's main (verbatim; update
  docs/development/spec-provenance.md), and read the diff since b9696bb in
  full. Then re-read every spec file in full before you plan, and write down
  per file how many lines you read.
- Precedence: "How to decide" in 00_README.md. This repository's own process:
  CONTRIBUTING.md and https://github.com/yutna/oss-kit/blob/main/docs/conventions.md.
- Commit this prompt as docs/development/implementation-protocol.md, replacing
  round 1's. Never edit it afterwards; only the owner changes it. Re-read it
  after every context compaction, then rebuild your state from GitHub.

## 2. Owner decisions (do not reopen them)

1. Kernel namespace: the kernel engines keep `Rafelo::Core` and
   `Rafelo::DesignSystem` (paths rafelo/core, rafelo/design_system) in every
   adopter, as the amended GEN-07 and ADR-27 say. The app, its product modules
   and domain engines, the example engines, and everything the generators
   write take the app's namespace. Today the examples stay `Rafelo::Example*`
   in an adopted app (rafelo-trials shows it): fix that.
2. BE-18 stays as written: a finished export answers 303 to a short-lived
   signed URL, created at click time, with the URL kept out of logs by the
   existing redaction patch. Replace the streaming you built.
3. An AI agent works under its own GitHub identity (a machine user or a GitHub
   App), never a person's account (amended WF-03, 14, ADR-32, AGENTS.md).
   guard_approval and the ratchet approval count only an owner who is not the
   pull request's author, and read CODEOWNERS and run from the merge base.
   For this repository, keep working as you do; for the trials in section 9 you
   need a token for your own identity. If the environment variable
   RAFELO_TRIALS_GH_TOKEN is set, it belongs to that identity: use it only for
   yutna/rafelo-trials (GH_TOKEN=$RAFELO_TRIALS_GH_TOKEN for those commands),
   never print it, and never use it for this repository. If it is not set when
   the trials start, ask the owner once (a stop condition) and continue other
   work meanwhile.
4. The 17 custom cops and the ESLint configuration of 09_enforcement.md stay
   MUST. Implement them all, with real-path canaries. Never downgrade a matrix
   status, never list a missing path in a skip or "deferred" list, and close
   #387 by implementing it, not by relabelling.
5. This repository's own process is oss-kit again: restore the oss-kit
   release caller (milestone close = release, VERSION preflight) that #350
   replaced; remove from this repository's .github/workflows the payload-only
   workflows (pull_request.yml, repo_rules.yml, ratchet.yml, audits.yml) so
   they live only in template/.github; keep ci.yml (running bin/ci over the
   template, the GEN-07 adoption run, and the N-1 to N update) and
   devcontainer.yml. Revert the CONTRIBUTING text that asks for new required
   checks, and close #347 and #353 as superseded. Never add required checks,
   approvals, or a merge queue to this repository.

## 3. One issue, one pull request, one at a time

Same as round 1: rebuild state from GitHub; branch <type>/<N>-<slug>; open a
draft PR at once with "Closes #N", What/Why/How to test, "Spec: <IDs>", and a
status checklist; tests first; bin/check while you work, bin/ci before ready;
gh pr ready; gh pr checks --watch; squash merge; next issue. Never two open
PRs. One finding per issue and one PR per fix; never bundle fixes into a gate
or release PR; never open umbrella issues.

## 4. Milestones

Plan version milestones from v0.23.0 (3 to 7 issues plus a gate each; never
v1.0.0). Each milestone's description lists the finding numbers from section 8
and the rule IDs it closes. Order, adjusting only where a dependency forces it:
1. Security and deploy blockers (section 8 group C1–C5, B1–B4).
2. CI that really gates (A5, A6, A1-ratchet A3, A4) and this repository's
   process (decision 5).
3. ESLint and Prettier with the 09 configuration, the local `rafelo` plugin,
   check_config.mjs, better-tailwindcss, apply_check, and canaries (A1).
4. The 12 missing cops and the loopholes in the 5 that exist (A2); the TS-07
   meta-check (A7).
5. Backend MUST gaps (group B).
6. Frontend (group D).
7. Generators, template, kernel_update, examples (group E).
8. Operations (group C, rest).
9. Open Backlog items (#289, #355, #363, #364, #375, #390, …) and every
   spec-feedback item from lessons-learned that is not yet an issue: file each
   as an issue labelled "question", titled "spec: <rule ID> <summary>".
10. Final milestone: full re-audit, skills audit, trials (section 9).

## 5. The gate (stricter than round 1)

Same audit as round 1 (separate subagent, fixed checklist: traceability,
MUST/SHOULD, edge cases, production grade, oo-reviewing-object-design,
security), plus:
- Before the audit, run the checks of the milestone's rules against their
  canaries and confirm each fails on its fixture; a guard you cannot make fail
  is a finding.
- Post the traceability table in every gate issue. A row says "enforced" only
  when the tool exists, runs in CI (ci.yml, not only bin/ci on a laptop), and
  has a canary that CI runs.
- An S1 is never carried over, never moved to Backlog, and never closed by a
  status downgrade. A gate with an open S1 does not pass: fix it in this
  milestone, however many rounds that takes.
- Fix rounds for S2: round 1 fixes, round 2 audits only the round-1 diffs,
  round 3 only regressions round 2 caused; then each remaining S2 becomes its
  own "audit carry-over" issue, priority: high, in the next milestone (never
  Backlog). S3 goes to Backlog.
- Then the release PR sets VERSION, merge, close the milestone, confirm the
  release, start the next milestone.

## 6. Lessons learned and spec feedback

Keep docs/architecture/lessons-learned.md as in round 1. Every spec-feedback
item also gets its own "spec: <rule ID> …" question issue in Backlog. Where
you choose a reading the spec does not state (as you did for BE-18 in round 1),
you file the question before you build on it and follow the spec text until the
owner answers.

## 7. Never

- Edit the protocol, the spec copies, or the vendored oo-* pack.
- Push to main; force-push a shared branch; merge without green checks.
- Change repository settings, rulesets, labels, branch protection, or the
  template flag; delete or move a tag or release. Re-author commits to get
  around a ruleset rule.
- Disable, skip, or loosen a check, cop, lint rule, budget, ratchet, or
  canary; downgrade a matrix status; add a skip or deferred list to a check.
- Work on two issues or two PRs at once.
- Re-arm docs/development/supervisor unless its prompt is this protocol and its
  final audit checks section 9 in full; until then, leave it uninstalled.

Stop only for: a secret or credential only the owner has (the trial identity
token), a repository setting you lack, or a spec decision that would reverse
section 2 or an ADR. Write the blocker in the open issue, tell the owner once,
and continue with independent work. Context compaction is never a reason to
stop.

## 8. Findings to close (from the round-1 review; paths at 85a3722)

A. Guard layer
A1 S1 No ESLint, Prettier, better-tailwindcss, apply_check, script/ci/eslint/*
   (rafelo.mjs, check_config.mjs); bin/check skips lint silently; config/docs.yml
   deferred_paths hides them. Ship the 09 excerpt with canaries; remove
   deferred_paths.
A2 S1 12 of 17 cops missing (EnvOnlyInConfig, CurrentAtTheEdge,
   ConcurrencyOnlyInExecutor, SendStreamOnlyInDownloads,
   PageContextThroughFactory, NoPermissionLiterals, OwnPermissionPrefixes,
   DateFormatterOnly, NoConstantize, EngineTablePrefix, SkipNeedsIssue,
   NoKernelInternals). Loopholes: FaradayOnlyInUpstreamClient exempts any
   *upstream_client.rb; NoTlsVerifyDisable misses ssl: { verify: false } and
   verify_mode: VERIFY_NONE; CacheOnlyThroughScopedCache exempts /config/ and
   ::Rails.cache; ReturnToOnlyInValueObject sees only params[:return_to] and
   special-cases fixture paths (remove fixture branches from cops). Every cop
   message names its rule ID.
A3 S1 script/ci/ratchet check mode compares YAML values only; count the real
   values in check mode and fail above the ceiling; every engine has every key
   (example_customers has no ratchets.yml).
A4 S1 guard_approval exits 0 for owner-authored guard changes in a single-owner
   repo and reads CODEOWNERS/scripts from the PR head; implement amended WF-03.
   Payload ruleset: ship the full arrangement and the fallback, chosen at
   adoption.
A5 S1 ci.yml (repo and payload) never runs bin/ci; packwerk validate,
   frontend_* checks, patches, permissions:check, bundle_budget, api:check,
   formats:check, seeds run only in examples-removable, which exits 0 after
   the examples are deleted. Run every gate step in CI in both.
A6 S1 script/ci/skips and test_selectors skip engines/*/spec and engine Vitest
   files; fix and remove the committed violation
   (engines/example_orders/app/frontend/components/orders/form.test.tsx:21).
A7 S2 TS-07 meta-check missing (rules listed from their sources, one canary per
   rule, exit 1 vs 2, empty-root run per check); four hand-written
   dependency-cruiser rules lack canaries; checks that pass on empty input
   (frontend_urls, frontend_formatters, patches, engine_specs, fan_in,
   `|| true` in ci.yml); canaries that accept any failure.
A8 S2 Budget matchers ignore engine overrides; match_policy_capabilities
   compares code with itself; no Prosopite; boot_seconds unmeasured;
   bundle_budget unproven and misclassifies engine pages; frontend_formatters
   exempts domain/forms formatting and all tests; page_props CT-11 check
   inverted; Dependabot instead of Renovate in the payload (WF-06 peer groups,
   release-age delay, pins canaries for every form); script/ci/affected output
   unused; workflow_policy gaps; actionlint fetched by curl from a tag; TS-03
   fake upstream hard-codes example paths, no scheduled drift job; axe only on
   the catalog; CODEOWNERS misses /.github/actions/ and dependabot.yml; ci-ok
   passes any skipped job.

B. Backend and security
B1 S1 BE-02 gateway() has no pundit_policy_authorized? pre-call guard
   (engines/core/app/controllers/rafelo/core/base_controller.rb:69-76).
B2 S1 SEC-05 no /core/csp_reports (skip_forgery_protection only there,
   throttle, byte cap, allow-listed log line) and no csp.report_only typed
   switch; spec/requests/body_limit_spec.rb asserts 404 for it.
B3 S1 BE-16 deadline per gateway client instead of one per request (refresh
   and loser waits must count).
B4 S1 BE-16/BE-05 CallBudget hard-coded api: 3; other upstreams get 0 (429);
   a mid-action refresh consumes a page slot; derive from config/budgets.yml.
B5 S2 Body cap bypass with .json or a trailing slash (body_limit.rb:23);
   /core/ready and /core/metrics unthrottled, metrics public and per-process;
   SEC-04 no return_to, JSON callers get 303, a download's 401 revokes without
   a refresh; ARCH-06 nav ignores reads_any? and the engine root route, duplicate
   permission keys unchecked, reserved segments miss /:locale routes; BE-17
   namespace uses the Vite digest, locale optional; BE-05 retry budget per
   client (never retries), upstream 413 on a write → 500, Faraday connection per
   client; BE-13 empty upstream 422 audited as success, failed sign-in renders
   from POST; BE-15 circuit_open/bulkhead marked unknown, upstream_idempotent
   hand-passed; SEC-10 no service token provider; SEC-03 winner uses
   with_lock, losers wait 17 s inside the bulkhead slot; BE-16 executor not
   wrapped, unbounded queue, config unused; BE-09 Current read below the edge
   (upstream_client, token providers, idempotency claim, base_policy,
   shared/error props); SEC-15 config/permission_mapping.yml missing; BE-18
   (decision 2); BE-19 stopped job records no outcome, failed-execution spec
   vacuous; SEC-05 nonce not passed to Vite/Inertia; missing specs (SEC-03
   forced-401 concurrency, SEC-08 cookie size, SEC-09 clearHistory, BE-16
   open_timeout, SEC-14 chunk count, SEC-01 real deletion header, ARCH-07 /th
   helpers); undefined policy predicate → 500.

C. Operations
C1 S1 script/ci/deploy_preflight:83 uses String#include? on all tracked paths,
   so .kamal/secrets.example makes every deploy fail; add the canary
   "present but untracked".
C2 S1 Dockerfile lacks postgresql-client; schema_format :sql needs psql for the
   first deploy and restores.
C3 S1 production.rb:37 disables require_master_key when SECRET_KEY_BASE is set;
   secrets fall back to ENV (active_record_encryption.rb, database.yml,
   storage.yml). Credentials only, per BE-08.
C4 S1 Active Storage direct uploads and disk routes are drawn and allow-listed
   in production (production_routes.yml:135-142); draw_routes false, serve
   files through core; require only the frameworks used instead of rails/all.
C5 S1 puma 8.0.2 advisories (GHSA-86xc-wrr9-xmmq, GHSA-jm4r-w4xx-qxw7, …):
   upgrade in the repo and the payload lockfile; close #392/#393.
C6 S2 BE-21 arithmetic spec reads only the test config (do the full Σ over
   both profiles and roles; keys executor.size,
   requests.upstream_deadline_seconds, sessions.refresh_timeout_seconds);
   typed configuration with silent defaults (example.com hosts,
   acme-production bucket, missing DB_USER skips grant restriction); restore
   runbook ignores RESTORE_DATABASE_URL and can truncate live sessions; no
   WAL/PITR for the single-host profile (ADR for the tool); partition alert and
   Rails-originated reports carry no identity; SEC-12 module routes checked
   against themselves, allow-list blesses dev-only routes; .kamal/secrets
   template reads config/master.key; OPS-04 metrics mostly missing; single-host
   first-deploy steps out of order; deploy_timeout vs statement_timeout;
   OPS-09 filter must include .ruby-version, mise.toml, package-lock.json
   (amended).

D. Contracts and frontend
D1 S1 TS builds a URL (app/frontend/pages/sessions/new.tsx:17) with a raw
   hidden input and a native POST.
D2 S1 MoneyPlain lacks the exponent (OOP worked example, CT-02, OOP-03);
   page schemas must use moneySchema.
D3 S1 api.d.ts lists export names only; FE-21 needs the real declarations.
D4 S1 No last-resort boundary around Inertia's App; layouts cast shared props
   instead of parsing; FlashStatus swallows parse failures.
D5 S1 Locale provider is not React Aria's I18nProvider; DateField is a raw
   input (accepts 2026-02-31, keeps stale values); Pagination uses native
   disabled and has no live status; forms disable the focused submit and never
   move focus to errors; Chart re-inits per render and lacks aria, theme,
   states, table toggle (and the server sends a raw ECharts option); DataTable
   lacks row identity and sort; the app shell renders no nav, current marker,
   icon, or locale switcher.
D6 S2 Link routes absolute URLs through Inertia and has no testId; URL props
   are plain strings, not *Href, unrefined (matcher skips them; the generator
   stamps the pattern); flash drops the notice beside an alert; boundary reset
   key from window.location; missing resolver/layout/announcer/pagination/
   form-focus/chart/data-table/Buddhist-Era tests; Vitest without React
   Compiler and no config/frontend_react.mts; i18n not per namespace, engines
   bypass i18next; contract generator canaries missing; formatters shift
   calendar dates by time zone, no date-time formatter; missing primitives and
   composites (select, menu, combobox, tabs, filter bar, confirm dialog, empty
   state); tailwind-merge test hard-coded; CT-09 tables not generated; open
   z.record props; FE-01 layer violations in app and example_orders;
   hard-coded English titles; nav.current by path prefix; CT-13 measured too
   narrowly.

E. Generators, adoption, AI files
E1 S1 Decision 1: examples and generated engines in the app namespace.
E2 S1 rafelo:module output fails bin/ci (blank line before class end;
   placeholder permission missing from the grant catalog); the smoke runs no
   RuboCop, drift, or request specs; rerun after every generator change.
E3 S1 Generated module.rb computes nav order at load time; write a literal at
   generation time.
E4 S1 The documented `rails new -m` command (without --skip-bundle) is
   untested; Rails re-runs kamal/solid templates after the template's commit.
   Make the documented command the tested one.
E5 S1 move_page leaves gateways and models behind; move the whole slice.
E6 S1 Generated page slice breaks CT-08, FE-07, FE-01, CT-10 (English copy,
   raw input/button, state in screens, raw upstream hashes in props).
E7 S2 Plural permission keys; the drift catalog lives in engines/core (every
   new permission edits a kernel file); GEN-02 lacks --upstream, component
   tests, the BE-15 edit version, hard-codes /en/ and localhost:4000, puts
   specs where bin/check does not run them; GEN-09 order and rollback per step
   untested; rename_module incomplete; reserved-name constant check misses the
   template's gems; kernel_update touches engines/core/AGENTS.md and merges
   app-owned files beyond the spec's list; rafelo:domain guide contradicts
   GEN-05 and lacks errors.yml, ratchets.yml, db/migrate; example_orders breaks
   FE-01 and lacks domain/forms/hooks; README points adopters to
   `gh repo create --template`; the 16 pack-versus-rule conflicts resolved only
   in lessons-learned must ship in AGENTS.md or the task skills.

## 9. Complete means

- Every finding in section 8 is closed by a merged PR with evidence, and its
  issue links that PR.
- Every rule ID is traced in docs/development/traceability.md with the status
  09 gives it; every "enforced" row has a tool that runs in CI and a canary CI
  runs. No skip or deferred lists remain.
- ci.yml on main is green on push and on schedule; the adoption run uses the
  documented command; the N-1 to N update passes.
- The skills audit passes again on the final code.
- The trials of round 1 are rerun on the release candidate, in a freshly adopted
  app in yutna/rafelo-trials, with the AI under its own identity; every trial
  meets the round-1 pass rule without supervisor help or hand edits, and the
  decision trial is handed over; any change to an AI file or a generator after
  that reruns all trials.
- The final gate passes with no open S1 or S2, and its release exists.

Start now: open the re-sync issue, then plan the milestones from section 4.

อ่านแล้ววางแผนทำตามได้เลย
