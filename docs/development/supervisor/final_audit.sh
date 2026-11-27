#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$root"
script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=state.sh
. "$script_dir/state.sh"
state="$(supervisor_state)"
repository="yutna/rafelo"

fail() { echo "final_audit: $*" >&2; exit 1; }

test "$(git branch --show-current)" = "main" || fail "not on main: $(git branch --show-current)"
git diff --quiet || fail "working tree has unstaged changes"
git diff --cached --quiet || fail "working tree has staged changes"
test -z "$(git status --porcelain)" || fail "working tree is dirty"
timeout 60 git fetch --tags --quiet origin || fail "git fetch failed"
timeout 30 gh auth status >/dev/null 2>&1 || fail "gh is not authenticated"

for n in $(seq 24 44); do
  state_json="$(timeout 30 gh api "repos/$repository/milestones/$n" --jq '[.state,(.open_issues|tostring)] | @tsv')"
  test "$state_json" = $'closed\t0' || fail "milestone $n is not closed with zero open issues: $state_json"
done

for version in 0.23.0 0.24.0 0.25.0 0.26.0 0.27.0 0.28.0 0.29.0 0.30.0 0.31.0 0.32.0 0.33.0 0.34.0 0.35.0 0.36.0 0.37.0 0.38.0 0.39.0 0.40.0 0.41.0 0.42.0 0.43.0; do
  timeout 30 gh release view "v$version" -R "$repository" >/dev/null 2>&1 || fail "release v$version is missing"
done

# Round 3 (protocol section 9): VERSION follows the latest release, no version
# milestone stays open, and the Backlog is cleared.
latest="$(timeout 30 gh release view -R "$repository" --json tagName --jq .tagName)" || fail "could not read the latest release"
latest_version="${latest#v}"
test "$(cat VERSION)" = "$latest_version" || fail "VERSION is not $latest_version (the latest release)"
test -d "spec/fixtures/formats/v$latest_version" || fail "formats fixture v$latest_version is missing"
open_versions="$(timeout 30 gh api "repos/$repository/milestones?state=open&per_page=100" --jq '.[] | select(.title | test("^v[0-9]")) | .title' | tr '\n' ' ')" || fail "could not list open milestones"
test -z "${open_versions// /}" || fail "version milestones are still open: $open_versions"
unblocked="$(timeout 60 gh issue list -R "$repository" --state open --limit 1000 --json number,labels \
  --jq '.[] | select((.labels | map(.name) | index("blocked")) | not) | .number')" || fail "could not list open issues"
# The round-3 plan is the issues open at the restart, numbered below #1098 (#1202).
leftover="$(printf '%s\n' "$unblocked" | awk '/^[0-9]+$/ && $1 < 1098 && $1 != 611' | tr '\n' ' ')"
test -z "${leftover// /}" || fail "round-3 plan issues that are not blocked remain: $leftover"

open_gates="$(timeout 30 gh issue list -R "$repository" --state open --limit 100 --search 'audit: feature gate in:title' --json number --jq length)"
test "$open_gates" = "0" || fail "an audit gate issue is still open"
approved_high="$(ruby -ryaml -rdate -e '
  path = "config/audit_exceptions.yml"
  exit 0 unless File.file?(path)
  entries = (YAML.safe_load_file(path, aliases: false) || {})["exceptions"] || []
  entries.each do |entry|
    next unless entry["expires_on"].is_a?(String)
    next if Date.iso8601(entry["expires_on"]) < Date.today
    match = entry["issue"].to_s.match(/issues\/(\d+)|#(\d+)/)
    puts(match[1] || match[2]) if match
  end
' | tr '\n' ' ')" || fail "could not read the approved audit-exception issues"
open_high="$(timeout 30 gh issue list -R "$repository" --state open --limit 100 --label 'priority: high' --json number --jq '.[].number')"
for issue in $open_high; do
  case " $approved_high " in
    *" $issue "*) ;;
    *) fail "open priority:high issue #$issue is not named by an unexpired audit exception" ;;
  esac
done
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

push_conclusion=""
for _ in 1 2 3 4 5; do
  push_conclusion="$(timeout 30 gh run list -R "$repository" --workflow CI --branch main --event push --limit 1 --json conclusion --jq '.[0].conclusion // "missing"')"
  [ "$push_conclusion" != "missing" ] && break
  sleep 30
done
test "$push_conclusion" = "success" || fail "the last push CI on main is $push_conclusion"
scheduled_conclusion=""
for _ in 1 2 3 4 5; do
  scheduled_conclusion="$(timeout 30 gh run list -R "$repository" --workflow CI --branch main --event schedule --limit 1 --json conclusion --jq '.[0].conclusion // "missing"')"
  [ "$scheduled_conclusion" != "missing" ] && break
  sleep 30
done
test "$scheduled_conclusion" = "success" || fail "the last scheduled CI on main is $scheduled_conclusion"

trials_commit="$(git log -1 --format=%ct -- docs/development/ai-workflow-trials.md 2>/dev/null || echo 0)"
ai_commit="$(git log -1 --format=%ct -- .opencode AGENTS.md docs/opencode.md engines/core/lib/generators template 'engines/*/AGENTS.md' 2>/dev/null || echo 0)"
test "$trials_commit" -ge "$ai_commit" || fail "the trials record is older than an AI file or generator change"

timeout 3600 bin/ci >"$state/final-ci.log" 2>&1 || fail "bin/ci is not green"

test -f "$state/DONE" || fail "DONE sentinel is missing"
echo "final_audit: PASS"
