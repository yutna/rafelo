# Ruleset exports

`main.json` and `release_tags.json` are the committed exports of the branch
and tag rulesets (WF-03, WF-05). `script/ci/repo_rules` compares them with the
active rules and fails when a rule or a required check name drifts.

`main.json` records the fallback for this repository: a personal repository
cannot require a merge queue, and with a single owner it cannot require an
independent code-owner approval. It therefore requires branches to be up to
date and the four checks (`ci-ok`, `title`, `ratchet`, `guard_approval`), with
review threads resolved. Add a second code owner and set
`require_code_owner_review` to `true` to enable independent approval.

`release_tags.json` allows the GitHub Actions integration (actor id `15368`)
to create release tags; verify that ID against the installation before
applying the ruleset. The owner applies both exports; the supervisor never
changes repository settings (see #347).
