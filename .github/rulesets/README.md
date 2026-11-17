# Ruleset exports

`main.json` and `release_tags.json` are the template payload, also shipped
from `template/.github/rulesets/`. An adopter's owner applies them.

This repository does not apply the four-check export. Its active ruleset keeps
the two-check fallback (`ci-ok` and `pr-check / check`); it never adds required
checks, approvals, or a merge queue (owner decision; #347 and #353 are
superseded). `release_tags.json` allows the GitHub Actions integration (actor
id `15368`) to create release tags; verify that ID against the installation
before applying the ruleset in an adopted app.
