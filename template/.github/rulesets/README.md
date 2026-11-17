# Ruleset exports

`main.json`, `main-full.json`, and `release_tags.json` are the committed
exports of the branch and tag rulesets (WF-03, WF-05). `script/ci/repo_rules`
compares the active rules with `main.json` and the tag rules with
`release_tags.json`, and fails when a rule or a required check name drifts.

Choose one branch arrangement at adoption:

- `main.json` — the fallback for a plan without merge queues or a repository
  with one owner: the four checks (`ci-ok`, `title`, `ratchet`,
  `guard_approval`), resolved review threads, no independent code-owner
  review, and no merge queue. An owner-authored guard change then merges only
  through the owner's recorded admin bypass (WF-03).
- `main-full.json` — the full arrangement for a plan with merge queues and at
  least two owners: the same four checks, one code-owner approval, and the
  squash merge queue. Copy it over `main.json` before applying it, so
  `script/ci/repo_rules` compares the arrangement in force.

`release_tags.json` allows the GitHub Actions integration (actor id `15368`)
to create release tags; verify that ID against the installation before
applying the ruleset. The owner applies the exports; the supervisor never
changes repository settings.
