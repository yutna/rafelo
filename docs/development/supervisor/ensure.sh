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
  # An owner-decision pause resolves by itself when none of the issues it names
  # is still open and labelled "blocked". A "no progress" or infrastructure
  # pause stays until a person removes it.
  marker="$(cat "$state/NEEDS_OWNER")"
  issues="$(printf '%s\n' "$marker" \
    | grep -E '^OWNER DECISION NEEDED( #[0-9]+)+$' \
    | grep -oE '#[0-9]+' | tr -d '#')"
  still_blocked=1
  if [ -n "$issues" ]; then
    for issue in $issues; do
      line="$(timeout 30 gh issue view "$issue" -R yutna/rafelo --json state,labels \
        --jq '[.state, (.labels | map(.name) | join(","))] | @tsv' 2>/dev/null || true)"
      state_name="${line%%$'\t'*}"
      labels="${line#*$'\t'}"
      if [ "$state_name" != "OPEN" ]; then
        still_blocked=0
        break
      fi
      case ",$labels," in
        *,blocked,*) ;;
        *) still_blocked=0; break ;;
      esac
    done
  else
    still_blocked=1
  fi
  if [ "$still_blocked" = "0" ]; then
    rm -f "$state/NEEDS_OWNER"
    printf '%s resumed: the owner-decision issues are no longer open and blocked\n' \
      "$(date -Is)" >>"$state/supervisor.log"
  else
    exit 0
  fi
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
