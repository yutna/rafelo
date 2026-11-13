# Autonomous supervisor

Install once with `./install.sh`. It adds two crontab entries (every five
minutes and at reboot) that keep a `rafelo-supervisor` tmux session alive. The
session runs `opencode run` with `prompt.md`, one fresh session per run, and
repeats until the final audit passes.

Runtime state and logs live in `/tmp/opencode/rafelo-supervisor/`:

- `STATE.md` — the agent's next steps
- `DONE` — written by the agent after the full plan is complete
- `STOP` — written by `stop.sh`
- `STOPPED` — written when the supervisor has stopped and removed its cron entries
- `supervisor.log` — every run, exit code and progress check

The final audit independently verifies every version milestone and release,
`VERSION`, a clean tree, `bin/ci` and the DONE marker before the supervisor
removes its cron entries and exits. A premature DONE is deleted and the loop
continues.
