#!/usr/bin/env bash
set -uo pipefail
export PATH="$HOME/.opencode/bin:$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
root="$(cd "$(dirname "$0")/../../.." && pwd)"
state="${SUPERVISOR_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/rafelo-supervisor}"
mkdir -p "$state"

if [ -f "$state/STOPPED" ]; then
  if crontab -l >/tmp/rafelo-cron 2>/dev/null; then
    grep -v '# rafelo-supervisor' /tmp/rafelo-cron | crontab - || true
  fi
  exit 0
fi
if [ -f "$state/NEEDS_OWNER" ]; then
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
  # A session can outlive its command (a failed shell, a dead tmux pane). Only
  # treat it as healthy while the supervisor script itself is alive.
  if pgrep -f "$root/docs/development/supervisor/supervisor.sh" >/dev/null 2>&1; then
    exit 0
  fi
  tmux kill-session -t rafelo-supervisor 2>/dev/null || true
fi
export SUPERVISOR_STATE="$state"
tmux new-session -d -s rafelo-supervisor "$root/docs/development/supervisor/supervisor.sh"
