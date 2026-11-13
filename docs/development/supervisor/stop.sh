#!/usr/bin/env bash
set -euo pipefail
state="${SUPERVISOR_STATE:-/tmp/opencode/rafelo-supervisor}"
mkdir -p "$state"
touch "$state/STOP"
if tmux has-session -t rafelo-supervisor 2>/dev/null; then
  tmux send-keys -t rafelo-supervisor C-c 2>/dev/null || true
fi
echo "stop requested; supervisor will remove its cron entry when it exits"
