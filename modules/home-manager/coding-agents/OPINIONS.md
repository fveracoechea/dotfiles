# Francisco's opinions

A compact map of what I believe about building software. Each rule carries its reason, so you can argue with it.

## Judgment matters more than building

- AI makes building cheap, so knowing what to build is the scarce skill.
- Good ideas start with named people who care about a real problem. Talk to them before validating your own idea.
- Learn with narrow prototypes and existing building blocks.
- Judge a technical decision on quality, simplicity, robustness, and long-term maintenance. Effort today is not a factor.

## Tools should make good choices easy

- Ergonomics matter. A good architecture that is hard to use correctly still produces slow, brittle code.
- Opinionated defaults, centrally optimized, with an escape hatch for advanced users.
- Terminal-centered workflows: grep, fzf, Neovim-style editing, low visual clutter.
- Reproducible environments turn fragile manual memory into repeatable systems.
- Clear ownership boundaries between tools beat forcing everything through one layer.
- A framework or abstraction earns its complexity by matching the problem's shape.
- Developer tools deserve visual craft when it improves comprehension.
- The platform's own mechanism beats a bespoke loader. Someone maintains the platform; nobody maintains the wrapper.

## Enforcement over prose

- Tooling wins over written rules. Tooling is deterministic, a guideline is not. Where lint enforces a rule, the document stays silent about it.
- A policy stated only in a document is not upheld. Make it a lint rule, a ruleset, or a CI check.
- When drift recurs, write a lint rule, not a stronger ADR.
- An agent hook is a nudge that saves a turn. Enforcement lives in CI. A mis-wired hook fails open.
- Review workflows read their tooling from the base ref, so a PR cannot choose the tooling that scores it.
- Pin third-party actions by commit SHA. A tag is a name its owner can move.
- Verify every guard against a deliberate break. A guard that cannot fail is vacuous.

## Toolchain

- Bun is runtime, package manager, and test runner. The manifest refuses npm, and a hook denies npm, npx, pnpm, and yarn.
- Node APIs are a legacy layer. Reach for Bun natives first. Each remaining `node:` import states why Bun has no equivalent.
- One runtime everywhere, so CI runs what production runs. A hosted test runner puts its own transform between the code and the engine it ships on.
- Publish TypeScript sources with no build step when nobody bundles the output. A build buys stale-output bugs.
- No nightly dependencies in production. Pin exactly, upgrade on a schedule. A break is cheaper on a schedule than at random.
- Shared lint config is plain JavaScript with JSDoc and `checkJs`, so its types are real.
- Add a workspace, a generator, or a utility library when the second case arrives.

## Architecture

- A feature is a deep module with one interface object and one or two entry points. A second export is a second interface, and the module stops being deep.
- Structure by feature or capability, never by technical layer. A `server/` folder is the wrong axis in an isomorphic framework. The server-client seam is per file.
- A module ships a finished use case, not parts. A caller that assembles parts holds the module's state switches.
- A factory whose arguments are all static imports exists only for a test. Declare the object directly and fake at the module boundary.
- Membership passes the deletion test. Machinery whose deletion costs nothing is not ported.
- One concept, one rendering, app-wide. Two files that agree on a signature and disagree on the answer typecheck perfectly.
- Import deeply. No barrel files, so a reader sees the real dependencies.
- Two update paths drift. Delete the old one when the new one lands.
- Server-only code carries a `$` prefix. Generated files carry `.generated.ts` or live in a `generated` folder, so provenance is visible at the call site.
- Local development scales to the whole team with no machine-specific hacks, and connects to real tenant environments instead of running the full stack.

## Data and the server boundary

- Server functions, not internal API routes. A route exists only for callers outside the bundle.
- One named server function per operation. Its validator is the browser's allowlist by construction.
- Generate only Zod schemas from a contract. The generated schema is the only committed projection and is never hand-edited.
- Tolerance for what a service really sends is a contract change negotiated with the backend, not a schema override.
- Parse at the boundary, trust the types after it. Types flow from handler to call site with no assertion.
- Infer types from schemas. A hand-written interface beside a schema is a copy that drifts.
- Validate configuration at startup and fail loudly. No silent fallbacks.

## Client state and loading

- The query cache is the state. A store or context holding server-derived truth beside it is a second source of truth, which is how mismatches are born.
- Identity lives in the query key. An imperative invalidation is a side effect that must fire from one place and never be missed.
- Polling is the wrong trigger for a once-a-day event. Window focus plus a slow visible-tab interval catches it.
- A data transform is a named, tested selector in its own module, typed against wire shapes. Nothing inline in `select`.
- Data-module functions take one object argument named `input`, destructured on the first line. Elsewhere it is good practice, not a rule.
- Components do not know how data is fetched. Errors surface on the query error path, never during render.
- A spinner belongs to a control the operator touched. It never stands for a page or a section.
- A surface loads behind a skeleton that mirrors its populated layout, so nothing jumps when data lands.
- A change to visible data is a transition. The old content stays dimmed and marked stale, never emptied into a second first load.
- The suspending read is the default. A non-suspending read states its reason at the call site.
- Honour reduced motion. No timer imitates a state; every moment on screen is a frame or the operator's action.

## Web fundamentals

- Use the web platform, even inside React.
- Progressive enhancement and server-side rendering make apps resilient and accessible.
- Web standard APIs over npm libraries. No utility library for a handful of small helpers.
- Dates render on the viewer's clock and zone. The server never evaluates a date on the viewer's behalf.

## React and TypeScript

- Most effects are unnecessary. Derive during render, put interaction logic in the handler, fetch through the query layer, and use `useSyncExternalStore` for the outside world.
- A needed effect is a named function declaration.
- Compose parts instead of adding a mode. A boolean prop that selects what renders is a mode, and three of them make eight states.
- A growing feature becomes a compound component. The provider is the only place that reads state, so parts never know their source.
- The React Compiler memoises. Manual `useMemo`, `useCallback`, or `React.memo` is a lint error that gets fixed, never suppressed.
- Function declarations over named const arrows. Arrows are for one-off inline callbacks.
- No unsafe type assertions. `satisfies`, predicates that check what they claim, and a typed `reduce` replace the cast.
- Do not mutate a value you do not own. `toSorted` over `sort`, Map and Set for repeated reads, `for...of` for real logic, `Object.keys` in place of `for...in`.
- A comment says why, never what. One short line per function, a little more on the module object, and only for a business rule, a trap, or a contract.
- Research does not ship. Findings go on the ticket.

## Design systems and UI

- Consistency beats local preference, and the reason is accessibility. A token inherits verified contrast; a one-off class inherits nothing.
- A one-off class is a second design system that nothing measures. File the gap upstream and keep it as the smallest className. Never fake the component.
- Semantic tokens carry meaning. Categorical labels get a separate color family. The test is whether a screen reader user would also need the information.
- A `dark:` class is a smell. Every token already has a light and a dark value, so the class is redundant, structural, or a missing token.
- Read the compiled result, not the class. Modifiers compose in ways the class name does not show.
- Wire a token only when a real call site paints it. A custom property is not an API.
- Measure accessibility per WCAG criterion, never per token. The promise is AA as a target with documented exceptions.
- Color is never the only signal. Meaning lives in text, an icon, or ARIA.
- Restriction lives in the API. Closed unions start small, typography components refuse className, and a required `as` turns an outline mistake into a compile error.
- A rare tool carries discovery friction. Negative space is a component, not a prop beside `gap` on every element.
- Geometry belongs to the component. A control that needs a different shape is a different control, which is a design conversation.
- Design tools own values only while a designer maintains them. When code leads, code owns the palette, and hand-off becomes a conversation, not a pipeline.
- Tuning a value by eye at the call site produces a third style that matches neither the old nor the target design.
- The visual regression golden diff is the design review. A tolerance threshold hides real changes.
- Charts are declared and painted only through the token layer. More categories than slots means fewer categories drawn.
- Calm UI: foreground text over semantic color, one spacing rhythm, one heading scale, real data or nothing.

## Testing

- A test lives beside its unit and carries its name. A test with no owner drifts.
- Fake only at a boundary: the module interface, the RPC, or the wire. Mocking a module by path is banned.
- Test a route through the real route tree. The route's behaviour is the composition.
- Assert what an operator or caller observes. Assert the locale and the fields, never the glue text.
- Confirm a test can fail. Delete the behaviour and the test must go red.
- Run the real consumer path in CI. A lookalike passes on the file the real path rejects.
- Each test file gets its own global. A leaked fake is a failure the next file cannot see coming, and run time is the accepted price.
- Reproduce a bug end to end, the way an operator hits it, before fixing it.

## Code quality

- Simple, modular code that is easy to read and change beats pretty and complex abstractions.
- Code is not cheap. A codebase that is hard to change locks you out of everything AI can offer.
- Codebases drift toward entropy unless senior engineers hold the bar.
- A layer, wrapper, or factory must justify itself against what the platform or library already does.
- Authors explain how they tested. Reviewers do not rediscover every bug.
- Solo ownership burns people out. Shared context and contributor growth produce better code.

## ADRs, documentation, and releases

- Record a decision only when it is hard to reverse, surprising without context, and a real trade-off.
- Write the decision, not the implementation. Every sentence passes the rename test.
- Name the rejected alternative and the accepted cost. A record of only what was chosen is worthless to the reader deciding whether to revisit it.
- Record the follow-up a decision creates without pretending to resolve it.
- On a rewrite, delete and renumber old ADRs. A restart carries no old decisions forward.
- A rule lives where the next author meets it. Convention in the style guide, gotcha in a code comment citing the ADR, operator fact in the README.
- A glossary fixes the words and lists the words to avoid. The rest of the stack uses its words exactly.
- Spec and ADRs come before the build, so every implementation change lands under them.
- The author decides what a change does to a consumer, through changesets, not the commit history.
- One product, one version, one immutable tag. A bad release is replaced, never corrected in place.
- A path a consumer names is a public contract. Moving it is a major, adding one is a patch.
- Prose that reaches other repos is a release artifact. An edit that ships no tag reaches nobody.

## Pull requests and writing

- Small PRs, one concern each. A large change becomes a reviewable stack.
- The PR body says where to start reading, what looks wrong and is not, what was verified with exact commands, where it departs from the spec, and what is not done here.
- Name out-of-scope items and their tickets instead of fixing them in passing.
- Verify claims against reality. Run the command against a real ref, read the upstream source, and say plainly what is still unproven.
- Review comments are short and friendly, with blockers separated from nice-to-haves, and read like a person wrote them.
- ASD-STE100 Simplified Technical English. One sentence per line in markdown. No em dash.
- Commit messages carry the why. No agent co-author.

## Working with agents

- A skill is a small router with topic files that load only when a task needs them. Split on the second topic, not below about 150 lines.
- A skill description says when to load and nothing else. Every agent pays for it on every turn.
- Headings are the rule index. A separate rules list is a copy that drifts.
- A skill owns one seam and names its neighbours. The package skill covers the API, the team skill covers the conventions on top.
- Every skill has one home. Author it instead of shadowing a vendored copy.
- Write to the portable frontmatter floor. A field one agent silently drops makes a skill look correct in both and behave differently.
- Ask before acting. A question is not an instruction. Show findings before posting anything.
- Mark facts verified or unverified. Settled decisions stay settled.
- Name the checkable rule, such as a lint rule id, instead of asserting a prohibition.
- Track the feedback you receive, so a mistake corrected once does not repeat in the next module.
- The step that reads untrusted content never holds a write token. One audited write path.

> "Invest in the design of the system _every day_."
> Kent Beck, Extreme Programming Explained

> "The best modules are deep. They allow a lot of functionality to be accessed through a simple interface."
> John Ousterhout, A Philosophy Of Software Design
