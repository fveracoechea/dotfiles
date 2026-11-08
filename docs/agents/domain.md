# Domain docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- `GLOSSARY.md` at the repo root
- ADRs in `docs/adr/` that touch the area you're about to work in

If a document is absent, continue with the available documentation.
Use the `domain-modeling` skill when defining or changing terms.
Create domain documents when terms or decisions are resolved, rather than creating empty files upfront.

## File structure

Single-context repo:

```
/
├── GLOSSARY.md
└── docs/adr/
```

## Use the glossary's vocabulary

Use the canonical terms in `GLOSSARY.md` when naming domain concepts in issues, proposals, hypotheses, and tests.

For an unfamiliar concept, check whether an existing term fits before proposing a new one through `domain-modeling`.
Keep glossary definitions separate from implementation guidance and architectural decisions.

## Flag ADR conflicts

State any conflict with an existing ADR explicitly before proposing a change.

Name the ADR and explain why its decision needs reconsideration.
