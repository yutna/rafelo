# Autonomous supervisor

Install once with `./install.sh`. It adds two crontab entries (every five
minutes and at reboot) that keep a `rafelo-supervisor` tmux session alive. The
session runs `opencode run` with `prompt.md` (the owner's continue prompt),
one fresh session per run, and repeats until the final audit passes.

To pause, run `./stop.sh`; resume by removing `/tmp/opencode/rafelo-supervisor/STOP`
and running `./install.sh`. A run that prints `OWNER DECISION NEEDED #<issue>`
or three consecutive runs that change nothing on GitHub writes
`NEEDS_OWNER` with the reason and launches no further run; the owner deletes
that file to resume. To remove the supervisor entirely, run `./stop.sh` and
delete its two crontab entries (the script removes them when the session exits).

Runtime state and logs live in `/tmp/opencode/rafelo-supervisor/`:

- `STATE.md` — the agent's next steps
- `DONE` — written by the agent after the full plan is complete
- `STOP` — written by `stop.sh`
- `STOPPED` — written when the supervisor has stopped and removed its cron entries
- `NEEDS_OWNER` — pauses the loop; contains an issue number or `no progress`
- `supervisor.log` — every run, exit code and progress check

The final audit independently verifies milestones 24–43 and releases
v0.23.0–v0.42.0, the absence of open high-priority or gate issues, exception
expiries, the last push and scheduled CI runs, the trials record against later
AI/generator changes, `VERSION`, a clean tree, `bin/ci`, and the DONE marker
before the supervisor removes its cron entries and exits. A premature DONE is
deleted and the loop continues.
