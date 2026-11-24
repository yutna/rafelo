#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../../.." && pwd)"
script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=state.sh
. "$script_dir/state.sh"
state="$(supervisor_state)"
mkdir -p "$state"
if [ -f "$state/STOP" ] || [ -f "$state/STOPPED" ]; then
  echo "supervisor is stopped; remove STOP/STOPPED before installing"
  exit 0
fi
entry="*/5 * * * * SUPERVISOR_STATE='$state' $root/docs/development/supervisor/ensure.sh >>$state/cron.log 2>&1 # rafelo-supervisor"
reboot="@reboot SUPERVISOR_STATE='$state' $root/docs/development/supervisor/ensure.sh >>$state/cron.log 2>&1 # rafelo-supervisor"
report="7 * * * * SUPERVISOR_STATE='$state' $root/docs/development/supervisor/ensure.sh >>$state/cron.log 2>&1; SUPERVISOR_STATE='$state' $root/docs/development/supervisor/report.sh >>$state/report.log 2>&1 # rafelo-report"
remove_cron_for_state "$state" "# rafelo-supervisor"
remove_cron_for_state "$state" "# rafelo-report"
current="$(crontab -l 2>/dev/null || true)"
{
  printf '%s\n' "$current" | grep -v '^$' || true
  printf '%s\n%s\n%s\n' "$entry" "$reboot" "$report"
} | crontab -
"$root/docs/development/supervisor/ensure.sh"
echo "supervisor installed"
