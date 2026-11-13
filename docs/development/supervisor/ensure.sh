#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../../.." && pwd)"
state="${SUPERVISOR_STATE:-/tmp/opencode/rafelo-supervisor}"
mkdir -p "$state"

if [ -f "$state/STOPPED" ]; then
  if crontab -l >/tmp/rafelo-cron 2>/dev/null; then
    grep -v '# rafelo-supervisor' /tmp/rafelo-cron | crontab - || true
  fi
  exit 0
fi
if [ -f "$state/STOP" ]; then
  touch "$state/STOPPED"
  if crontab -l >/tmp/rafelo-cron 2>/dev/null; then
    grep -v '# rafelo-supervisor' /tmp/rafelo-cron | crontab - || true
  fi
  exit 0
fi
if tmux has-session -t rafelo-supervisor 2>/dev/null; then
  exit 0
fi
tmux new-session -d -s rafelo-supervisor "$root/docs/development/supervisor/supervisor.sh"
