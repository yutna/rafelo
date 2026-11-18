#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$root"
state="${SUPERVISOR_STATE:-/tmp/opencode/rafelo-supervisor}"
mkdir -p "$state"
log="$state/supervisor.log"
lock="$state/lock"
exec 9>"$lock"
flock -n 9 || { echo "supervisor already running" >>"$log"; exit 0; }

logline() { printf '%s %s\n' "$(date -Is)" "$*" >>"$log"; }
stop_supervisor() {
  touch "$state/STOPPED"
  if crontab -l >/tmp/rafelo-cron 2>/dev/null; then
    grep -v '# rafelo-supervisor' /tmp/rafelo-cron | crontab - || true
  fi
  logline "stopped"
  exit 0
}
state_hash() {
  local head prs issues releases
  head="$(git rev-parse HEAD 2>/dev/null || true)"
  prs="$(gh pr list -R yutna/rafelo --state open --json number --jq length 2>/dev/null || echo x)"
  issues="$(gh issue list -R yutna/rafelo --state open --limit 100 --json number --jq length 2>/dev/null || echo x)"
  releases="$(gh release list -R yutna/rafelo --limit 5 --json tagName --jq '.[].tagName' 2>/dev/null | tr '\n' ',')"
  printf '%s|%s|%s|%s' "$head" "$prs" "$issues" "$releases"
}

logline "started"
no_progress=0
while true; do
  if [ -f "$state/STOP" ]; then stop_supervisor; fi
  if [ -f "$state/NEEDS_OWNER" ]; then
    logline "paused for owner: $(cat "$state/NEEDS_OWNER")"
    exit 0
  fi
  if [ -f "$state/DONE" ]; then
    if docs/development/supervisor/final_audit.sh >>"$log" 2>&1; then
      logline "DONE verified"
      stop_supervisor
    else
      logline "DONE rejected by final audit"
      rm -f "$state/DONE"
    fi
  fi

  before="$(state_hash)"
  prompt="$(cat docs/development/supervisor/prompt.md)"
  if [ -f "$state/STATE.md" ]; then
    prompt="$prompt

Previous supervisor state:
$(cat "$state/STATE.md")"
  fi
  if [ "$no_progress" -ge 3 ]; then
    printf 'no progress\n' > "$state/NEEDS_OWNER"
    logline "paused: no progress in $no_progress runs"
    exit 0
  fi

  start_line="$(wc -l < "$log")"
  logline "run start"
  timeout --signal=TERM --kill-after=60s 10800 \
    opencode run --auto --archived --title "Rafelo supervisor" "$prompt" >>"$log" 2>&1
  rc=$?
  run_output="$(tail -n +"$((start_line + 1))" "$log")"
  if printf '%s\n' "$run_output" | grep -q "OWNER DECISION NEEDED #[0-9][0-9]*"; then
    issue="$(printf '%s\n' "$run_output" | grep -o "OWNER DECISION NEEDED #[0-9][0-9]*" | tail -1 | grep -o '[0-9][0-9]*')"
    printf 'OWNER DECISION NEEDED #%s\n' "$issue" > "$state/NEEDS_OWNER"
    logline "paused for owner issue #$issue"
    exit 0
  fi
  after="$(state_hash)"
  if [ "$before" = "$after" ]; then
    no_progress=$((no_progress + 1))
  else
    no_progress=0
  fi
  logline "run end rc=$rc progress=$([ "$before" = "$after" ] && echo no || echo yes) no_progress=$no_progress"
  sleep 20
done
