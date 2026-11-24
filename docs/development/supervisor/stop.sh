#!/usr/bin/env bash
set -uo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=state.sh
. "$script_dir/state.sh"
state="$(supervisor_state)"
session="$(supervisor_session "$state")"
title="$(supervisor_title "$state")"
mkdir -p "$state"
touch "$state/STOP"

if tmux has-session -t "$session" 2>/dev/null; then
  tmux send-keys -t "$session" C-c 2>/dev/null || true
  for _ in $(seq 1 10); do
    tmux has-session -t "$session" 2>/dev/null || break
    sleep 1
  done
  tmux kill-session -t "$session" 2>/dev/null || true
fi

for pattern in \
  "timeout --signal=TERM --kill-after=60s 21600 opencode run --model opencode-go/deepseek-v4.1-flash#max --auto --archived --title $title" \
  "opencode run --model opencode-go/deepseek-v4.1-flash#max --auto --archived --title $title"; do
  pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
  [ -n "$pids" ] && kill $pids 2>/dev/null || true
done
sleep 2
for pattern in \
  "timeout --signal=TERM --kill-after=60s 21600 opencode run --model opencode-go/deepseek-v4.1-flash#max --auto --archived --title $title" \
  "opencode run --model opencode-go/deepseek-v4.1-flash#max --auto --archived --title $title"; do
  pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
  [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
done

touch "$state/STOPPED"
remove_cron_for_state "$state" "# rafelo-supervisor"
echo "supervisor stopped; remove $state/STOP and $state/STOPPED, then run install.sh to resume"
