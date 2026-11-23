#!/usr/bin/env bash
set -uo pipefail
state="${SUPERVISOR_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/rafelo-supervisor}"
mkdir -p "$state"
touch "$state/STOP"

if tmux has-session -t rafelo-supervisor 2>/dev/null; then
  tmux send-keys -t rafelo-supervisor C-c 2>/dev/null || true
  for _ in $(seq 1 10); do
    tmux has-session -t rafelo-supervisor 2>/dev/null || break
    sleep 1
  done
  tmux kill-session -t rafelo-supervisor 2>/dev/null || true
fi

for pattern in \
  "docs/development/supervisor/supervisor.sh" \
  "timeout --signal=TERM --kill-after=60s 21600 opencode run" \
  "opencode run --model opencode-go/deepseek-v4.1-flash#max --auto --archived --title Rafelo supervisor"; do
  pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
  [ -n "$pids" ] && kill $pids 2>/dev/null || true
done
sleep 2
for pattern in \
  "docs/development/supervisor/supervisor.sh" \
  "timeout --signal=TERM --kill-after=60s 21600 opencode run" \
  "opencode run --model opencode-go/deepseek-v4.1-flash#max --auto --archived --title Rafelo supervisor"; do
  pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
  [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
done

touch "$state/STOPPED"
if crontab -l >/tmp/rafelo-cron 2>/dev/null; then
  grep -v '# rafelo-supervisor' /tmp/rafelo-cron | crontab - || true
fi
echo "supervisor stopped; remove $state/STOP and $state/STOPPED, then run install.sh to resume"
