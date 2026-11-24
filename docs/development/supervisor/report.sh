#!/usr/bin/env bash
set -uo pipefail
export PATH="$HOME/.opencode/bin:$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

repo="yutna/rafelo"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=state.sh
. "$script_dir/state.sh"
state="$(supervisor_state)"
session="$(supervisor_session "$state")"
default_state="$(supervisor_default_state)"
mkdir -p "$state"
issue="${RAFELO_REPORT_ISSUE:-611}"
if [ "$state" != "$default_state" ] && [ -z "${RAFELO_REPORT_ISSUE:-}" ]; then
  echo "report: refusing to post for a non-default state without RAFELO_REPORT_ISSUE" >&2
  exit 0
fi
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
now_epoch="$(date -u +%s)"
last="$(cat "$state/report.last" 2>/dev/null || echo 1970-01-01T00:00:00Z)"
cd "$root" || exit 1

tmux_state="not running"
tmux has-session -t "$session" 2>/dev/null && tmux_state="running"

flags="none"
for flag in NEEDS_OWNER STOP STOPPED DONE; do
  if [ -f "$state/$flag" ]; then
    flags="$flags; $flag=$(tr '\n' ' ' < "$state/$flag" | cut -c1-120)"
  fi
done

last_start="$(grep ' run start$' "$state/supervisor.log" 2>/dev/null | tail -1 || true)"
last_end="$(grep ' run end ' "$state/supervisor.log" 2>/dev/null | tail -1 || true)"
last_log="$(tail -1 "$state/supervisor.log" 2>/dev/null || true)"
start_epoch=""
end_epoch=""
[ -n "$last_start" ] && start_epoch="$(date -u -d "$(printf '%s' "$last_start" | cut -d' ' -f1)" +%s 2>/dev/null || true)"
[ -n "$last_end" ] && end_epoch="$(date -u -d "$(printf '%s' "$last_end" | cut -d' ' -f1)" +%s 2>/dev/null || true)"
if [ -n "$start_epoch" ] && { [ -z "$end_epoch" ] || [ "$start_epoch" -gt "$end_epoch" ]; } &&
   [ $((now_epoch - start_epoch)) -gt 25200 ]; then
  flags="$flags; STUCK=run started more than 7h ago"
fi

branch="$(git branch --show-current 2>/dev/null || echo unknown)"
head="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
version="$(cat VERSION 2>/dev/null || echo unknown)"
release="$(timeout 30 gh release list -R "$repo" --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null || echo unknown)"
main_ci="$(timeout 30 gh run list -R "$repo" --workflow CI --branch main --event push --limit 1 --json conclusion --jq '.[0].conclusion // "unknown"' 2>/dev/null || echo unknown)"

milestone="$(timeout 30 gh api "repos/$repo/milestones" --paginate --jq '.[] | select(.state=="open") | .title' 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | head -1 || true)"
if [ -n "$milestone" ]; then
  issues="$(timeout 30 gh issue list -R "$repo" --milestone "$milestone" --state open --limit 100 --json number,title,labels --jq '.[] | "#\(.number) \(.title) [\(.labels|map(.name)|join(","))]"' 2>/dev/null || true)"
  [ -z "$issues" ] && issues="none"
else
  milestone="none"
  issues="none"
fi
open_prs="$(timeout 30 gh pr list -R "$repo" --state open --author yutna --limit 10 --json number,title,mergeStateStatus,isDraft --jq '.[] | "#\(.number) \(.title) [\(.mergeStateStatus), draft=\(.isDraft)]"' 2>/dev/null || true)"
[ -z "$open_prs" ] && open_prs="none"
high="$(timeout 30 gh issue list -R "$repo" --state open --label 'priority: high' --limit 50 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || true)"
[ -z "$high" ] && high="none"
blocked="$(timeout 30 gh issue list -R "$repo" --state open --label blocked --limit 50 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || true)"
[ -z "$blocked" ] && blocked="none"

if printf '%s\n' "$open_prs" | grep -q '^#'; then
  pr_number="$(printf '%s\n' "$open_prs" | head -1 | sed -E 's/^#([0-9]+).*/\1/')"
  checks="$(timeout 60 gh pr checks "$pr_number" -R "$repo" 2>/dev/null | awk -F '\t' '{print $2}' | sort | uniq -c | tr '\n' ' ' || true)"
  [ -z "$checks" ] && checks="no checks reported"
else
  checks="n/a"
fi

merged="$(timeout 30 gh pr list -R "$repo" --state merged --limit 30 --json number,title,mergedAt --jq --arg last "$last" '.[] | select(.mergedAt > $last) | "#\(.number) \(.title)"' 2>/dev/null || true)"
[ -z "$merged" ] && merged="none detected"

body="$(cat <<MD
## Supervisor report — $now

**Supervisor:** tmux $tmux_state; flags: $flags
**Last run:** ${last_start:-unknown}
**Last end:** ${last_end:-unknown}
**Last log line:** ${last_log:-none}

**Current:** branch \`$branch\` at \`$head\`; dirty files: $dirty
**Open PR(s):**
\`\`\`
$open_prs
\`\`\`
**Checks:** $checks

**Merged since previous report:**
$merged

**Remaining $milestone issues:**
$issues

**Open high-priority:**
$high

**Blocked:**
$blocked

**Release:** latest \`$release\`; VERSION \`$version\`; last main push CI: $main_ci
MD
)"

printf '%s\n' "$body" | timeout 30 gh issue comment "$issue" -R "$repo" --body-file - >/dev/null || exit 1
printf '%s\n' "$now" > "$state/report.last"
