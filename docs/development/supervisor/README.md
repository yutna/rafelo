# Autonomous supervisor

Install once with `./install.sh`. It adds three crontab entries (every five
minutes, at reboot, and the hourly report) that keep a `rafelo-supervisor` tmux
session alive. The session runs `opencode run` with `prompt.md` (the owner's
continue prompt), one fresh session per run, and repeats until the final audit
passes.

`install.sh` and `ensure.sh` add the user's tool directories to `PATH`
(`~/.opencode/bin`, the mise shims, and `~/.local/bin`), so a reboot does not
turn a missing `opencode`, Ruby, or npm into a "no progress" pause. Before a
new run, a dirty worktree from a timed-out run is committed and pushed on its
branch (or a `wip/supervisor-<timestamp>` branch), so the next run starts from
a clean `main` without losing the interrupted edit.

A non-default `SUPERVISOR_STATE` (a test) gets its own hashed tmux session and
title and only removes its own cron lines. `stop.sh` and `install.sh` never
remove the default supervisor's entries when they run against a temporary
state. The report cron also runs `ensure.sh`, so a lost five-minute entry is
recovered on the next hourly report.

To pause, run `./stop.sh`; it stops the session and removes the supervisor's
cron entries. Resume by removing `STOP` and `STOPPED` from the state directory
and running `./install.sh`. A run pauses only when its last non-empty line is
`OWNER DECISION NEEDED #<issue> ...` (or it writes the issue numbers to
`$RAFELO_OWNER_DECISION_FILE`) and every named issue is still open and labelled
`blocked`; it then writes `NEEDS_OWNER` and launches no further run. `ensure.sh`
deletes that file and resumes by itself once none of the named issues is still
open and blocked. A marker quoted from a protocol, a process listing, or an
earlier line is logged as `marker-ignored`; a marker naming a closed or
unblocked issue does the same. A timeout or any other non-zero exit is logged
as `outcome=aborted` and resumed with backoff, never an owner pause. Three
consecutive successful runs that change neither GitHub nor the local worktree
write `NEEDS_OWNER` with `no progress`; that pause and the state-hash
`infrastructure:` pause stay until a person handles them.

Runtime state and logs live in
`${XDG_STATE_HOME:-$HOME/.local/state}/rafelo-supervisor/` (persistent across
reboots):

- `STATE.md` — the agent's next steps
- `DONE` — written by the agent after the full plan is complete
- `STOP` — written by `stop.sh`
- `STOPPED` — written when the supervisor has stopped and removed its cron entries
- `NEEDS_OWNER` — pauses the loop; contains an issue marker, `no progress`, or an
  `infrastructure:` reason
- `supervisor.log` — every run, exit code and progress check
- `report.last` — the last hourly report time

`report.sh` posts the hourly status to #611: the current branch and dirty
count, open PRs and their checks, merged PRs since the last report, the lowest
open version milestone's open issues, open high-priority and blocked issues,
the latest release and main CI, and a `STUCK` flag when a run has been active
for more than seven hours.

The final audit independently verifies milestones 24–43 and releases
v0.23.0–v0.42.0, the absence of gate issues, the absence of open high-priority
issues except ones named by an unexpired audit exception, exception expiries,
the last push and scheduled CI runs, the trials record against later AI or
generator changes (including every `engines/*/AGENTS.md`), `VERSION`, a clean
tree on `main`, `bin/ci`, and the DONE marker before the supervisor removes its
cron entries and exits. A premature DONE is deleted and the loop continues.
