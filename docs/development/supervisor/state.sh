#!/usr/bin/env bash
# Shared state, tmux session, title, and cron helpers for the supervisor.
#
# A temporary SUPERVISOR_STATE (a test) gets its own session and title and
# only removes its own cron entries. The default state keeps the historical
# session name and title.

supervisor_default_state() {
  printf '%s/rafelo-supervisor' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

supervisor_state() {
  printf '%s' "${SUPERVISOR_STATE:-$(supervisor_default_state)}"
}

supervisor_session() {
  local state="${1:-$(supervisor_state)}" default
  default="$(supervisor_default_state)"
  if [ "$state" = "$default" ]; then
    printf 'rafelo-supervisor'
  else
    printf 'rafelo-supervisor-%s' "$(printf '%s' "$state" | sha256sum | cut -c1-8)"
  fi
}

supervisor_title() {
  local state="${1:-$(supervisor_state)}" default
  default="$(supervisor_default_state)"
  if [ "$state" = "$default" ]; then
    printf 'Rafelo supervisor'
  else
    printf 'Rafelo supervisor %s' "$(supervisor_session "$state")"
  fi
}

# Remove the cron lines for one state and marker. A line without
# SUPERVISOR_STATE belongs to the default state; a line with another state is
# left alone. The report marker is separate so stopping the supervisor can
# leave the hourly report in place.
remove_cron_for_state() {
  local state="$1" marker="$2" default lines
  default="$(supervisor_default_state)"
  lines="$(crontab -l 2>/dev/null || true)"
  [ -z "$lines" ] && return 0
  printf '%s\n' "$lines" | awk -v state="$state" -v def="$default" -v marker="$marker" -v q="'" '
    index($0, marker) == 0 { print; next }
    index($0, "SUPERVISOR_STATE=") == 0 {
      if (state == def) next
      print; next
    }
    index($0, "SUPERVISOR_STATE=" q state q) > 0 { next }
    { print }
  ' | crontab -
}
