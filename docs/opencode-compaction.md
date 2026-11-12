# GPT-6.1 Sol compaction in OpenCode V2

Checked on 2026-11-11 using official documentation and first-party source code.

**No model-specific OpenAI recommendation for compacting Sol at 60% or 85% was found in the sources below.**
OpenCode's documented default is a 15% buffer, approximately 85% usage.
Its implementation applies that percentage to the usable input window, which resolves an ambiguity in the documentation. [1] [2] [5]

## Documented defaults and limits

| Item | Officially documented value | Meaning |
| --- | --- | --- |
| Sol API context | 1,050,000 tokens | Model capacity, not a compaction threshold. |
| Sol API maximum input/output | 922,000 / 128,000 tokens | Separate request limits, not recommended compaction settings. |
| Sol in Codex and ChatGPT Work | 500,000-token default window | Subscription product default, not the API maximum. |
| OpenCode ChatGPT sign-in | 500,000-token input cap for Sol and newer | Enabled by the built-in context-cap plugin. |
| OpenCode compaction | Automatic; buffer defaults to 15%, at least 16k | An application default, not a Sol-specific quality recommendation. |

Sources: OpenAI model details and Codex models; OpenCode V2 providers and compaction. [1] [3] [4]

OpenAI charges API requests above 272k input tokens at higher rates for the full request.
Sol usage drawn from a ChatGPT subscription has no long-context surcharge. [3] [7]
Thus, 272k is neither a subscription compaction recommendation nor evidence that quality requires compaction there.
Longer context can still consume more subscription usage; no surcharge does not mean no usage cost. [7]

## What OpenCode actually calculates

The compaction guide calls `buffer` a share of the model's "context window".
The configuration guide says automatic compaction uses the selected model's "usable input budget". [1] [2]
The installed release, OpenCode 2.2.5, implements the following calculation when both input and context limits are positive. [5]

```text
window = min(limit.input, limit.context)
default threshold = window - max(floor(window * 0.15), 16000)
explicit percentage threshold = window - round(window * percentage / 100)
```

The default formula above applies to this 500k window; smaller windows have an additional minimum-reserve exception. [5]
`limit.output` does not enter this threshold calculation.
The same calculation is present in the current V2 development source. [6]

Local runtime evidence supplied for this investigation from `opencode api get /api/model/default` reported:

```text
context: 628000
input:   500000
output:  128000
```

These limits match the official context-cap plugin, which sets `input = 500000` and `context = input + output` for Sol. [8]
Only these non-private limits are reproduced here.

| Setting | Calculated trigger | Share of 500k input window |
| --- | ---: | ---: |
| Default buffer | 425,000 tokens | 85% |
| `buffer: "40%"` | 300,000 tokens | 60% |

These are source-derived calculations, not measured trigger events or OpenAI recommendations.
Neither 405,800 nor 248,800 applies: those subtract a percentage of the 628k context value from the 500k input budget.
OpenCode instead uses 500k for both the budget and the percentage base. [5]
Compaction compares estimated current prompt size with the threshold, so the actual observed trigger can overshoot it. [5]

## What the public Codex source establishes

The Codex configuration reference says an unset `model_auto_compact_token_limit` uses model defaults, without publishing a Sol-specific number. [9]
Its public implementation derives a generic fallback of 90% of the resolved context window.
An explicit model/configuration limit can lower that threshold; the implementation clamps it to that 90% ceiling. [10]
This is implementation behavior, not an OpenAI recommendation to configure OpenCode at 90%.

At the inspected Codex commit, bundled Sol metadata has `auto_compact_token_limit: null`, `context_window: 272000`, and `max_context_window: 872000`. [11]
That bundled window differs from OpenAI's documented 500k product default.
Codex also loads cached or remote model catalogs, so the bundled file cannot establish the current signed-in subscription metadata. [12]
If the resolved Codex window were 500k with no lower override, its generic method would return 450k.
That is conditional arithmetic, not a verified subscription-session default.

OpenAI's compaction guide describes configurable thresholds and requires standalone compaction input to fit the model window.
It does not recommend a Sol-specific percentage. [13]
The reviewed primary sources provide no evidence that 60% is a Sol quality boundary, or that 85% is optimal.
Using a 40% buffer is therefore a local tuning choice; retaining 15% follows OpenCode's default.

## Sources

1. [OpenCode V2 compaction](https://opencode.ai/v2/docs/compaction), especially Settings, Buffer, and Providers.
2. [OpenCode V2 configuration: compaction](https://opencode.ai/v2/docs/config#compaction).
3. [OpenAI GPT-6.1 Sol model details and pricing](https://developers.openai.com/api/docs/models/gpt-6.1-sol).
4. [OpenAI Codex models](https://developers.openai.com/codex/models) and [OpenCode V2 ChatGPT context limits](https://opencode.ai/v2/docs/providers#context-limits).
5. [OpenCode 2.2.5 threshold and input-window calculation](https://github.com/anomalyco/opencode/blob/9bbb8ce18c80f099e0e448775f59d965ead40a21/packages/core/src/session/compaction.ts#L1130-L1158) and [trigger comparison](https://github.com/anomalyco/opencode/blob/9bbb8ce18c80f099e0e448775f59d965ead40a21/packages/core/src/session/compaction.ts#L423-L432).
6. [Current V2 calculation, commit `6d023043`](https://github.com/anomalyco/opencode/blob/6d023043cad522ca140327ed5f098dbfbacdda7d/packages/core/src/session/compaction.ts#L1158-L1186).
7. [OpenAI Codex subscription pricing and usage](https://developers.openai.com/codex/pricing).
8. [OpenCode V2 context-cap plugin](https://github.com/anomalyco/opencode/blob/6d023043cad522ca140327ed5f098dbfbacdda7d/packages/core/src/plugin/provider/openai-context-caps.ts#L12-L36).
9. [OpenAI Codex configuration reference](https://developers.openai.com/codex/config-reference), `model_auto_compact_token_limit`.
10. [Codex metadata contract](https://github.com/openai/codex/blob/c95b72ed6f00348c6da5ab95b740398094023ce8/codex-rs/protocol/src/openai_models.rs#L478-L493) and [90% fallback implementation](https://github.com/openai/codex/blob/c95b72ed6f00348c6da5ab95b740398094023ce8/codex-rs/protocol/src/openai_models.rs#L567-L590).
11. [Codex bundled Sol metadata](https://github.com/openai/codex/blob/c95b72ed6f00348c6da5ab95b740398094023ce8/codex-rs/models-manager/models.json#L177-L208).
12. [Codex cached and remote catalog loading](https://github.com/openai/codex/blob/c95b72ed6f00348c6da5ab95b740398094023ce8/codex-rs/models-manager/src/manager.rs#L780-L845).
13. [OpenAI compaction guide](https://developers.openai.com/api/docs/guides/compaction).
