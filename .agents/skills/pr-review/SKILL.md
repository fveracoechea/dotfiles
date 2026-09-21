---
name: pr-review
description: Use when asked to review a pull request by number or URL, or to post review comments on a pull request.
---

# Pull request review

This skill owns the posting seam, which turns findings into one GitHub review.
The neighbour `code-review` owns the two-axis analysis, Standards and Spec.
Invoke that skill when the agent lists it, and read the diff yourself when it is absent.

## Contract

A run posts one review, through `gh api`, with a single-line body.
The review holds at most three inline comments, and each one sits on the exact line.
A comment opens with `Blocker.` or `Nice to have.`, and it gives the evidence that you gathered.
A blocker is a defect that the author fixes before the pull request merges, and everything else is a nice to have.

## Process

### 1. Resolve the pull request and gather findings

Run `gh pr view <number> --repo <owner>/<repo> --json headRefOid,baseRefName`.
The value of `headRefOid` becomes the `commit_id` of the review.
Invoke `code-review` and give it `baseRefName` as its fixed point.

### 2. Verify every claim against its source

Read the artefact itself, and treat the pull request body and the commit message as claims that you still check.
Check a claim about a published package against the package tarball, so run `npm pack <name>@<version>` and read the extracted files, and check a claim about a route against the route file.
Check a claim about behaviour by running the command and reading its output.
Drop the claims that you cannot verify.

### 3. Keep the three that matter most

Rank the blockers above the nice-to-haves, and drop the remainder.

### 4. Anchor each comment to a line

Run `gh api repos/<owner>/<repo>/pulls/<number>/files --paginate --jq '.[] | .filename, .patch'`.
Count the right-side line numbers from each hunk header to get the value of `line`.
GitHub omits `patch` on a large file and on a binary file, so read that file at `headRefOid` and count its lines instead.
Every line sits inside a hunk of the diff, and one bad line returns 422 and rejects the whole review, so check all three before you post.

### 5. Show the findings and wait

Print the body and every comment in full, and give the file and the line of each one.
Post after the user approves, or post at once when the user pre-authorised it in this session.

### 6. Post one review

Write the payload to a file, then send the file.

```json
{
  "commit_id": "<headRefOid>",
  "event": "COMMENT",
  "body": "<one line>",
  "comments": [{ "path": "src/route.ts", "line": 42, "side": "RIGHT", "body": "Blocker. ..." }]
}
```

Run `gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input review.json --jq .html_url`, and report the URL that it returns.

## Voice

Write the way one colleague writes a note to another colleague, give the defect with its file and line, and stop on the last finding.

Apply `unslop` rules 7, 13, 18, 20, 22, 23, 25, 32 and 33, which are stable ids.
Read [`../unslop/SKILL.md`](../unslop/SKILL.md) for the text of each rule.
