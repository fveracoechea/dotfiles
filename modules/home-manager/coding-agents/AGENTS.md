# Francisco's agent instructions

- You run inside Herdr, a terminal multiplexer, when HERDR_ENV is 1. Load the skill `herdr` to:
  - read a neighboring pane, its output, or its agent
  - run a command or a helper agent in a sibling pane without stealing focus
  - wait for a server, a test run, or another agent to finish
  - run a long-lived process, such as a localhost dev server, in a new pane
  - give each parallel task or sub-agent its own Herdr worktree
- Talk in ASD-STE100 Simplified Technical English.
- Read every CONTEXT.md in the repo and use its ubiquitous language.
- Start a bug fix by reproducing it end to end, the way a user hits it. Change code only after the reproduction is red.
- Treat lint errors, failing tests, and flaky tests as blockers. Fix them before you report the task done.
- Write commit messages with no Co-Authored-By trailer.
- Separate thoughts with a period or a comma. Never an em dash.

Read ~/OPINIONS.md before a design decision, an architecture choice, or a tooling recommendation. It holds Francisco's rules with their reasons.
