# Why OpenCode v2 does not run LSP

Research date: 2026-10-24.
GitHub evidence comes from the original `anomalyco/opencode` repository, read with `gh api`.
Dates are UTC.

## Answer

The best-supported explanation is an unfinished port to v2's rewritten architecture.
The official tracker calls for porting LSP and formatter services, and a maintainer explicitly confirms that LSP's return is tracked there. [1] [2]
This supports a planned return.
It does not explain why the team shipped v2 before completing the port or why other work took priority.
No explicit maintainer or founder statement in the examined sources attributes the omission to stability, memory use, token cost, operating cost, or a belief that LSP is unnecessary.

## What the project says

### The services need a v2 implementation

On 2026-07-23, `opencode-agent[bot]`, GitHub association `CONTRIBUTOR`, opened [#38528, "V2: port LSP and formatter services"][1].
Its summary says:

> Port the LSP and formatter services to the V2 Core/runtime architecture so V2 sessions regain language-server diagnostics and configured formatter behavior without depending on V1 service implementations.

Its scope includes service boundaries, configuration resolution, process ownership, file-mutation and tool integration, diagnostics and client events, location scoping, shutdown/reload behavior, and tests. [1]
These are implementation requirements, not proof that any one caused the delay.
The issue attributes the work announcement to James in a linked Slack coordination thread.
That is a bot-authored account, not a publicly verified direct quote from James.

The official [OpenCode 2.0 announcement][3] supplies broader rewrite context.
It describes a shared background service and says of the API, "We started from scratch".
It gives no LSP-specific removal rationale.

### A maintainer confirms the return plan

On 2026-10-20, `neriousy`, GitHub association `MEMBER`, replied to #50916:

> This is the same missing V2 LSP support as #38528, and we're tracking its return there.

Source: [exact comment][2], posted at 09:30:33 UTC.
They then closed #50916 as a duplicate of the port tracker.
The closure redirects the request; it does not mean LSP shipped or that its return was rejected.

On 2026-10-22, the same maintainer closed a request to enable the LSP tool by default:

> Closing as outdated: the V1 registry that gated the lsp tool behind the experimental flag has been removed, and V2 doesn't have an LSP tool yet, so there's nothing to turn on by default.

Source: [#44759 comment][4].
This confirms that the old experimental flag cannot enable a missing v2 implementation.

## Current status and schedule

As checked on 2026-10-24, #38528 is open, assigned to `jlongster`, with labels `enhancement`, `core`, and `2.0`.
It has no milestone or public delivery date in the examined issue and comments. [1]
Assignment and an open tracker do not establish active implementation or a release commitment.
The evidence supports a planned return, with no public ETA found.

The website-listed/tagged v2.1.4 migration guide still states that v2 "does not run language servers, expose LSP tools, or produce LSP diagnostics". [5]
The tag resolves to `68bc26b7da1990ce10ffecfbc1e09eb13aa5d824`.
This confirms the documented gap beyond the 2.0.32 upgrade target.
No live binary test was performed for this research.

## Stability and cost are context, not proven causes

The official [v1 LSP best-practices guidance][6] says language servers can "get out of sync, use significant memory, vary by version or project, and slow down agent workflows".
It recommends direct lint, typecheck, or diagnostic CLI commands in many projects while retaining opt-in LSP for projects that benefit.
This explains tradeoffs in using LSP.
It does not state that those tradeoffs caused the v2 omission.

Two search leads do not establish a shipped removal or restoration:

- [PR #18603, "refactor: remove LSP, formatters, and CodeSearch tool"][7], is closed without a merge.
- [PR #55485][8] changes old `packages/opencode/src/lsp/` files and is also closed without a merge.
  Those files do not demonstrate a completed v2 service port.

## Effect on this upgrade

The earlier finding that v2 lacks working LSP is correct.
The more precise description is that the v2 port is still missing and the project tracks its return.
Keeping the configured servers or experimental flag will not restore it.
The official migration guide recommends project lint, typecheck, or compiler commands in the meantime. [5]

## Sources

[1]: https://github.com/anomalyco/opencode/issues/38528
[2]: https://github.com/anomalyco/opencode/issues/50916#issuecomment-6287891675
[3]: https://anoma.ly/notes/opencode-2-0
[4]: https://github.com/anomalyco/opencode/issues/44759#issuecomment-6346835986
[5]: https://github.com/anomalyco/opencode/blob/68bc26b7da1990ce10ffecfbc1e09eb13aa5d824/services/www/src/docs/content/migrate-v1.mdx
[6]: https://opencode.ai/docs/lsp/#best-practices
[7]: https://github.com/anomalyco/opencode/pull/18603
[8]: https://github.com/anomalyco/opencode/pull/55485/files
