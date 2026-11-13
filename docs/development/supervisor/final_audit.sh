#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
state="${SUPERVISOR_STATE:-/tmp/opencode/rafelo-supervisor}"

fail() { echo "final_audit: $*" >&2; exit 1; }

git diff --quiet || fail "working tree has unstaged changes"
git diff --cached --quiet || fail "working tree has staged changes"
test -z "$(git status --porcelain)" || fail "working tree is dirty"
git fetch --tags --quiet origin || fail "git fetch failed"
gh auth status >/dev/null 2>&1 || fail "gh is not authenticated"

for n in $(seq 12 23); do
  state_json="$(gh api "repos/yutna/rafelo/milestones/$n" --jq '[.state,(.open_issues|tostring)] | @tsv')"
  test "$state_json" = $'closed\t0' || fail "milestone $n is not closed with zero open issues: $state_json"
done

for version in 0.11.0 0.12.0 0.13.0 0.14.0 0.15.0 0.16.0 0.17.0 0.18.0 0.19.0 0.20.0 0.21.0 0.22.0; do
  gh release view "v$version" >/dev/null 2>&1 || fail "release v$version is missing"
done

test "$(cat VERSION)" = "0.22.0" || fail "VERSION is not 0.22.0"
bin/ci >/tmp/opencode/rafelo-supervisor/final-ci.log 2>&1 || fail "bin/ci is not green"

test -f "$state/DONE" || fail "DONE sentinel is missing"
echo "final_audit: PASS"
