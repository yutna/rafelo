#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
# Cron starts this script with a minimal PATH. The model, Ruby, and npm live
# in the user's tool directories; a missing opencode must not look like a
# no-progress run (see the supervisor canary).
export PATH="$HOME/.opencode/bin:$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
cd "$root"
state="${SUPERVISOR_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/rafelo-supervisor}"
run_timeout=21600
mkdir -p "$state"
log="$state/supervisor.log"
lock="$state/lock"
opencode_bin="${SUPERVISOR_OPENCODE:-opencode}"
exec 9>"$lock"
flock -n 9 || { printf '%s %s\n' "$(date -Is)" "supervisor already running" >>"$log"; exit 0; }

logline() { printf '%s %s\n' "$(date -Is)" "$*" >>"$log"; }

pause() {
  local reason="$1"
  printf '%s\n' "$reason" > "$state/NEEDS_OWNER"
  logline "paused: $reason"
  exit 0
}

stop_supervisor() {
  touch "$state/STOPPED"
  if crontab -l >/tmp/rafelo-cron 2>/dev/null; then
    grep -v '# rafelo-supervisor' /tmp/rafelo-cron | crontab - || true
  fi
  logline "stopped"
  exit 0
}

# A run can time out or be killed after editing files but before committing.
# Commit and push that work on its branch, then start the next run on a clean
# main. The final audit requires a clean tree; losing the work would make the
# next run start from a half-written state.
recover_worktree() {
  [ "${SUPERVISOR_SKIP_RECOVERY:-0}" = "1" ] && return 0
  [ -z "$(git status --porcelain 2>/dev/null)" ] && return 0
  if git status --porcelain 2>/dev/null | cut -c4- | grep -Eq '(^|/)(\.env($|\.)|[^/]*\.(key|pem|crt)$)'; then
    logline "dirty tree contains a possible secret; not checkpointing"
    return 0
  fi

  local branch stamp
  branch="$(git branch --show-current 2>/dev/null || true)"
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  if [ -z "$branch" ] || [ "$branch" = "main" ]; then
    branch="wip/supervisor-$stamp"
    git switch -c "$branch" 2>/dev/null || git checkout -b "$branch" 2>/dev/null || return 0
  fi

  git add -A 2>/dev/null || true
  git -c user.name="Rafelo Supervisor" -c user.email="supervisor@rafelo.invalid" \
    commit -q -m "chore(supervisor): checkpoint interrupted work $stamp" >/dev/null 2>&1 || true
  timeout 60 git push -u origin "$branch" >/dev/null 2>&1 9>&- || true
  git switch main >/dev/null 2>&1 || true
  logline "checkpointed dirty tree on $branch"
}

# Counts only, plus the local worktree. Counts avoid the hourly report thread
# resetting progress; the local hash lets a long un-pushed edit count as work.
# A GitHub failure returns nonzero so the caller does not count a transient
# outage as "no progress".
state_hash() (
  exec 9>&-
  local head prs issues releases local_state local_hash
  head="$(timeout 10 git rev-parse HEAD 2>/dev/null)" || return 1
  prs="$(timeout 30 gh pr list -R yutna/rafelo --state open --limit 100 --json number --jq length 2>/dev/null)" || return 1
  issues="$(timeout 30 gh issue list -R yutna/rafelo --state open --limit 1000 --json number --jq length 2>/dev/null)" || return 1
  releases="$(timeout 30 gh release list -R yutna/rafelo --limit 5 --json tagName --jq '.[].tagName' 2>/dev/null | tr '\n' ',')" || return 1
  local_state="$(git status --porcelain=v1 2>/dev/null && git rev-parse HEAD 2>/dev/null && git diff --stat 2>/dev/null)" || return 1
  local_hash="$(printf '%s' "$local_state" | sha256sum | cut -d' ' -f1)" || return 1
  printf '%s|%s|%s|%s|%s' "$head" "$prs" "$issues" "$releases" "$local_hash"
)

# The marker is the last non-empty line of the run's final message, on its own.
# A protocol quote, a process listing, or a line followed by more output can
# contain the phrase; none may pause the loop. Strip ANSI and CR first because
# the CLI may colorize the line.
owner_decision_marker() {
  local output="$1"
  printf '%s\n' "$output" \
    | sed -e 's/\x1b\[[0-9;]*[A-Za-z]//g' -e 's/\r$//' -e 's/[[:space:]]*$//' \
    | grep -v '^$' | tail -1 \
    | grep -E '^OWNER DECISION NEEDED( #[0-9]+)+$'
}

# Every issue number in the last owner-decision marker, unique, in order.
owner_decision_issues() {
  local output="$1"
  owner_decision_marker "$output" | grep -o "#[0-9][0-9]*" | sed 's/^#//' | sort -un
}

# A marker pauses only for issues that are still open and labelled "blocked".
# A closed, unblocked, or missing issue means the run's plan moved on and the
# marker is stale; the supervisor logs it and resumes instead.
issues_open_and_blocked() {
  local issue line state labels
  for issue in "$@"; do
    line="$(timeout 30 gh issue view "$issue" --json state,labels \
      --jq '[.state, (.labels | map(.name) | join(","))] | @tsv' 2>/dev/null 9>&- || true)"
    state="${line%%$'\t'*}"
    labels="${line#*$'\t'}"
    [ "$state" = "OPEN" ] || return 1
    case ",$labels," in
      *,blocked,*) ;;
      *) return 1 ;;
    esac
  done
  return 0
}

owner_decision() {
  local issues="$1" numbers marker owner issue
  numbers="$(printf '%s\n' $issues | sed 's/^/#/' | tr '\n' ' ' | sed -e 's/ *$//')"
  marker="OWNER DECISION NEEDED $numbers"
  printf '%s\n' "$marker" > "$state/NEEDS_OWNER"
  owner="$(timeout 30 gh api repos/yutna/rafelo --jq .owner.login 2>/dev/null 9>&- || true)"
  owner="${owner:-yutna}"
  for issue in $issues; do
    timeout 30 gh issue edit "$issue" --add-assignee "$owner" >/dev/null 2>&1 9>&- || true
    timeout 30 gh issue comment "$issue" -b "@$owner the supervisor paused: only blocked work remains. $marker" >/dev/null 2>&1 9>&- || true
  done
  logline "paused for owner: $marker"
  exit 0
}

logline "started"
recover_worktree
no_progress=0
failures=0
state_failures=0
while true; do
  if [ -f "$state/STOP" ]; then stop_supervisor; fi
  if [ -f "$state/NEEDS_OWNER" ]; then
    logline "paused for owner: $(cat "$state/NEEDS_OWNER")"
    exit 0
  fi
  if [ -f "$state/DONE" ]; then
    if docs/development/supervisor/final_audit.sh >>"$log" 2>&1 9>&-; then
      logline "DONE verified"
      stop_supervisor
    else
      logline "DONE rejected by final audit"
      rm -f "$state/DONE"
    fi
  fi

  recover_worktree
  if ! before="$(state_hash)"; then
    state_failures=$((state_failures + 1))
    logline "state hash failed before run ($state_failures)"
    if [ "$state_failures" -ge 10 ]; then
      pause "infrastructure: state hash failed $state_failures times"
    fi
    sleep 60
    continue
  fi
  state_failures=0

  prompt="$(cat docs/development/supervisor/prompt.md)"
  if [ -f "$state/STATE.md" ]; then
    prompt="$prompt

Previous supervisor state:
$(cat "$state/STATE.md")"
  fi
  run_ends="$(date -u -d "@$(( $(date +%s) + run_timeout ))" +%Y-%m-%dT%H:%M:%SZ)"
  prompt="$prompt

This run ends at $run_ends."
  if [ "$no_progress" -ge 3 ]; then
    pause "no progress in $no_progress runs"
  fi

  decision_file="$state/owner-decision"
  rm -f "$decision_file"
  export RAFELO_OWNER_DECISION_FILE="$decision_file"

  start_line="$(wc -l < "$log")"
  logline "run start"
  # Pin the provider, model, and effort: the free model quota must never stop
  # the loop and no fallback model may run this repository (#629). Close the
  # lock FD: a surviving child must not keep the next supervisor from starting.
  timeout --signal=TERM --kill-after=60s "$run_timeout" \
    "$opencode_bin" run --model "opencode-go/deepseek-v4.1-flash#max" --auto --archived \
      --title "Rafelo supervisor" "$prompt" >>"$log" 2>&1 9>&-
  rc=$?
  run_tail="$(tail -n +"$((start_line + 1))" "$log" | tail -n 40)"
  marker_line="$(owner_decision_marker "$run_tail")"

  if [ "$rc" -eq 0 ] && [ -n "$marker_line" ]; then
    issues="$(owner_decision_issues "$run_tail")"
    if [ -n "$issues" ] && issues_open_and_blocked $issues; then
      logline "run end rc=$rc outcome=blocked"
      owner_decision "$issues"
    else
      logline "marker-ignored: $marker_line (an issue is not open and blocked)"
    fi
  fi
  if [ "$rc" -eq 0 ] && [ -s "$decision_file" ]; then
    issues="$(grep -oE '#?[0-9]+' "$decision_file" | tr -d '#' | sort -un | tr '\n' ' ')"
    if [ -n "${issues// /}" ] && issues_open_and_blocked $issues; then
      logline "run end rc=$rc outcome=blocked"
      owner_decision "$issues"
    else
      logline "marker-ignored: the decision file names an issue that is not open and blocked"
    fi
  fi
  if [ "$rc" -eq 0 ] && [ -z "$marker_line" ] && printf '%s' "$run_tail" | grep -q "OWNER DECISION NEEDED"; then
    logline "marker-ignored: the phrase is not the last non-empty line"
  fi
  if [ "$rc" -ne 0 ] && printf '%s' "$run_tail" | grep -q "OWNER DECISION NEEDED"; then
    logline "marker-ignored: the run exited $rc"
  fi

  if ! after="$(state_hash)"; then
    state_failures=$((state_failures + 1))
    logline "state hash failed after run ($state_failures)"
    if [ "$state_failures" -ge 10 ]; then
      pause "infrastructure: state hash failed $state_failures times"
    fi
    sleep 60
    continue
  fi
  state_failures=0

  if [ "$rc" -ne 0 ]; then
    outcome="aborted"
    failures=$((failures + 1))
    no_progress=0
  else
    failures=0
    if [ "$before" = "$after" ]; then
      outcome="no-progress"
      no_progress=$((no_progress + 1))
    else
      outcome="progress"
      no_progress=0
    fi
  fi

  logline "run end rc=$rc outcome=$outcome no_progress=$no_progress failures=$failures"
  if [ "$no_progress" -ge 3 ]; then
    pause "no progress in $no_progress runs"
  fi
  if [ "$rc" -eq 0 ]; then
    sleep 20
  else
    delay=$((failures * 60))
    [ "$delay" -gt 300 ] && delay=300
    sleep "$delay"
  fi
done
