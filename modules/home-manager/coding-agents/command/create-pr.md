---
agent: build
description: Create GitHub pull request for current branch
---

Generate a clear PR title + body for the current branch.

Strict output order:
1. PR_TITLE: <title only, no quotes>
2. PR_BODY:\n<markdown body>

Context:
Branch: !`git rev-parse --abbrev-ref HEAD`
Ahead/behind main: !`git rev-list --left-right --count origin/main...HEAD 2>/dev/null || echo "0\t0"`
Commits (hash|subject|author|date): !`git log --pretty=format:'%h|%s|%an|%ad' --date=short main...HEAD`
Diffstat: !`git diff --stat main...HEAD`
Files: !`git diff --name-status main...HEAD`
Languages: !`git diff --name-only main...HEAD | awk -F. '{print $NF}' | sort | uniq -c | sort -nr`
Sample diff (first 50 lines – summarize only): !`git diff --unified=0 main...HEAD | head -n 50`

Title rules:
- Conventional style if clear type (feat, fix, refactor, chore, docs, test)
- Max 72 chars, imperative, specific; add ! for breaking

Body sections (omit empties):
## Summary — 1–3 sentences (what & why)
## Changes — bullets grouped by type; each: action + key file/module; mark breaking with **BREAKING**
## Motivation — problem / goal (optional)
## Technical Notes — key implementation or migration details (optional)
## Breaking Changes — required user actions (if any)
## References — issue numbers / links (optional)

Procedure:
1. Require clean tree except branch commits (warn if dirty: stop).
2. Base = main by default.
3. Push branch if missing remote.
4. If no commits vs main: output NO_PR_NEEDED and stop.
5. If existing PR: update title/body (gh pr edit) then output PR_URL: <url>.
6. If no existing PR: create (gh pr create) then output PR_URL: <url>.
7. Summarize changes; never dump raw diff; merge trivial commits.

Style:
- Specific, user‑visible impacts first.
- No boilerplate or raw diff blocks.
- Scannable, concise.
