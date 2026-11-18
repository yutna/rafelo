#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$root"
state="${SUPERVISOR_STATE:-/tmp/opencode/rafelo-supervisor}"
repository="yutna/rafelo"

fail() { echo "final_audit: $*" >&2; exit 1; }

git diff --quiet || fail "working tree has unstaged changes"
git diff --cached --quiet || fail "working tree has staged changes"
test -z "$(git status --porcelain)" || fail "working tree is dirty"
git fetch --tags --quiet origin || fail "git fetch failed"
gh auth status >/dev/null 2>&1 || fail "gh is not authenticated"

for n in $(seq 24 43); do
  state_json="$(gh api "repos/$repository/milestones/$n" --jq '[.state,(.open_issues|tostring)] | @tsv')"
  test "$state_json" = $'closed\t0' || fail "milestone $n is not closed with zero open issues: $state_json"
done

for version in 0.23.0 0.24.0 0.25.0 0.26.0 0.27.0 0.28.0 0.29.0 0.30.0 0.31.0 0.32.0 0.33.0 0.34.0 0.35.0 0.36.0 0.37.0 0.38.0 0.39.0 0.40.0 0.41.0 0.42.0; do
  gh release view "v$version" -R "$repository" >/dev/null 2>&1 || fail "release v$version is missing"
done

test "$(cat VERSION)" = "0.42.0" || fail "VERSION is not 0.42.0"
test -d "spec/fixtures/formats/v0.42.0" || fail "formats fixture v0.42.0 is missing"

open_gates="$(gh issue list -R "$repository" --state open --limit 100 --search 'audit: feature gate in:title' --json number --jq length)"
test "$open_gates" = "0" || fail "an audit gate issue is still open"
open_high="$(gh issue list -R "$repository" --state open --limit 100 --label 'priority: high' --json number --jq length)"
test "$open_high" = "0" || fail "an open priority:high issue remains"
test -z "$(grep -R "deferred_paths" config script/ci script/docs 2>/dev/null || true)" || fail "deferred_paths remains"

ruby -ryaml -rdate -e '
  path = "config/audit_exceptions.yml"
  exit 0 unless File.file?(path)
  entries = (YAML.safe_load_file(path, aliases: false) || {})["exceptions"] || []
  entries.each do |entry|
    raise "exception without an expiry" unless entry["expires_on"].is_a?(String)
    raise "exception expired" if Date.iso8601(entry["expires_on"]) < Date.today
    raise "exception without an issue" unless entry["issue"].to_s.match?(/issues\/\d+|#\d+/)
  end
' || fail "an audit exception is expired or incomplete"

push_conclusion="$(gh run list -R "$repository" --workflow CI --branch main --event push --limit 1 --json conclusion --jq '.[0].conclusion // "missing"')"
test "$push_conclusion" = "success" || fail "the last push CI on main is $push_conclusion"
scheduled_conclusion="$(gh run list -R "$repository" --workflow CI --branch main --event schedule --limit 1 --json conclusion --jq '.[0].conclusion // "missing"')"
test "$scheduled_conclusion" = "success" || fail "the last scheduled CI on main is $scheduled_conclusion"

trials_commit="$(git log -1 --format=%ct -- docs/development/ai-workflow-trials.md 2>/dev/null || echo 0)"
ai_commit="$(git log -1 --format=%ct -- .opencode AGENTS.md docs/opencode.md engines/core/lib/generators template 2>/dev/null || echo 0)"
test "$trials_commit" -ge "$ai_commit" || fail "the trials record is older than an AI file or generator change"

bin/ci >/tmp/opencode/rafelo-supervisor/final-ci.log 2>&1 || fail "bin/ci is not green"

test -f "$state/DONE" || fail "DONE sentinel is missing"
echo "final_audit: PASS"
