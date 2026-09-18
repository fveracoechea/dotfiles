# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Use GitHub's native sub-issue and issue dependency relationships. Do not encode
these relationships in issue bodies.

- **Add a child issue**: get the child's numeric database ID with
  `gh api repos/{owner}/{repo}/issues/<child> --jq .id`, then run
  `gh api --method POST repos/{owner}/{repo}/issues/<map>/sub_issues -F sub_issue_id=<database-id>`.
- **Add a blocking edge**: get the blocking issue's numeric database ID with
  `gh api repos/{owner}/{repo}/issues/<blocking> --jq .id`, then
  run `gh api --method POST repos/{owner}/{repo}/issues/<blocked>/dependencies/blocked_by -F issue_id=<database-id>`.
- **Load a map and its children**: run
  `gh issue view <map> --json number,title,body,url,subIssues,subIssuesSummary`.
- **Find the frontier**: query the map's open children with GraphQL. A child is
  on the frontier when it has no open `blockedBy` issues and no assignee.
- **Claim a ticket**: run `gh issue edit <ticket> --add-assignee @me` before
  reading or working beyond the map's low-resolution context.
