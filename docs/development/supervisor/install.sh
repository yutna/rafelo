#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../../.." && pwd)"
state="${SUPERVISOR_STATE:-/tmp/opencode/rafelo-supervisor}"
mkdir -p "$state"
entry="*/5 * * * * $root/docs/development/supervisor/ensure.sh >>$state/cron.log 2>&1 # rafelo-supervisor"
reboot="@reboot $root/docs/development/supervisor/ensure.sh >>$state/cron.log 2>&1 # rafelo-supervisor"
current="$(crontab -l 2>/dev/null || true)"
printf '%s\n%s\n%s\n' "$current" "$entry" "$reboot" | grep -v '^$' | crontab -
"$root/docs/development/supervisor/ensure.sh"
echo "supervisor installed"
