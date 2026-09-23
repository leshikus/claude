# Generic instructions

How to write and how to work, whatever the project.

## Communication

Always post the full URL whenever you reference a pull request or a GitHub Actions run (workflow dispatch, CI run, etc.) — e.g. `https://github.com/<owner>/<repo>/pull/<n>` or `https://github.com/<owner>/<repo>/actions/runs/<id>`. Include the URL both when creating/dispatching and when reporting status, so links are always one click away.

Reviews are under 100 words by default — both the review text posted to GitHub and the summary reported in chat. Lead with the finding; drop the preamble, the restatement of the diff, and the closing summary. Go longer only when explicitly asked.

Never post a review until I verify it. Show the draft in chat and wait for approval, in every repository, including `clickhouse-private`.

## Minimum number of words

Use the fewest words that carry the fact. Delete any clause whose removal loses no information — "that every contributor can already read", "which someone has to keep working", "three specific things", "it is worth noting that", "actually", "in particular". Prefer the shorter form of what survives: "Pinning changes three things" over "Pinning simplifies three specific things". This applies to RFCs, design docs, issues, pull request descriptions, commit messages and chat replies alike.

## Issues

An issue is the ask plus one sentence naming what it enables. Version, terminal and the
one-line symptom are all the context it carries. Do not include evidence of how the
product currently behaves — measurement lists, channel-by-channel findings, captures —
for readers who own the code. No "alternatives considered" section, and no paragraph
defending the proposal against an objection: where the objection is real, offer the
choice in a clause ("or markdown, if you don't like escape chars"). Investigation notes
stay in the working directory.

The title carries what the body no longer does: the surface, the ask, the acceptable
formats and the precedent — "[FEATURE] Accept a link format in hook `systemMessage`: OSC
8 or markdown, as statusline and assistant output do". Name the precedent there once,
not in the body.

## Never use the paragraph symbol

Do not write `§`. Refer to a section by name — "see Risks", "appendix B", "Phase 1", "Open questions 1" — or by number in words, "section 6". This applies everywhere: RFCs, design docs, issues, pull request descriptions, commit messages, chat replies.

## Disclaimers go in the first two sentences

Every caveat about the text itself — durations are estimates, counts are provisional, a section is a draft, a measurement is unverified — goes in the first two sentences of the document, stated once and covering everything it applies to. Two sentences is the budget, not a slot to fill: where the caveats do not fit, cut the weakest instead of writing a third sentence. Never repeat one beside the individual figure later: a caveat attached to one number casts doubt on every number that lacks one. Where the uncertainty is real and specific, name what the number depends on instead of announcing that it is uncertain.

Drop sentences that tell the reader how to read: "read this split carefully", "a fair question is …", "two properties worth stating, because they are the point", "that is the whole of the claim". State the fact and let it stand.

## Monospace for code identifiers

In every text you write — RFCs, issues, pull request descriptions, commit messages, comments, chat replies — wrap identifiers in inline code: ClickHouse class, function, method, setting and SQL names, and also **module, component and subsystem names** (`SharedMergeTree`, `DistributedCache`, `SharedCatalog`, `StatelessWorker`, `MergeTree`, `SystemLog`), file paths, CLI flags and literal log excerpts. This holds outside a repository too — documents under `~/repos/` are not covered by any project `CLAUDE.md`, and this is where the rule is most often missed.

Leave plain: product and company names (ClickHouse, AWS), tool names used as prose (CMake, Terraform, Docker), and verbatim quotations, which are reproduced exactly as written.

## Code comments

Do not add more than one line of comments. Multi-line comment blocks (3-4 lines explaining rationale) are not wanted — keep any added comment to a single, short line, or omit it.

Do not explain in a comment what is already in the code. Comment only on things that cannot be deduced from the code in front of the reader: assumptions, invariants relied on elsewhere, external behaviour of a library or tool, or why a non-obvious alternative was rejected. Everything else is noise, however short.

Do not annotate a keyword argument with a comment that restates the parameter's own description — `retries=3  # transient workflow-scope timeout` or `rebase_retries=5  # heal a non-fast-forward` just paraphrase the callee's docstring, which the reader can already read at the definition. The argument name and value carry the intent; delete the comment.

The compression test comes second, and it doubles as the value test. Once the rationale is squeezed to the one short line it deserves, it is usually visible that the line restates the code — `strict=True` already reads as "fail early", so a `# Fail early` next to it says nothing. In that case delete it rather than keep it. Name the idea rather than reconstructing the reasoning that led to it, and if naming the idea reproduces the code, there was no comment to write.

Only the docstring documenting a top-level function's contract is exempt, because that is user-facing documentation. Docstrings on internal helpers (private functions, and any docstring that exists to explain the implementation rather than document an API) follow the same one-line rule as comments — do not use a docstring to smuggle in a rationale block that would be unacceptable as a comment.

Do not explain in a comment how the code looked before the fix (no "was X, now Y", no "previously", no "used to"). Comments describe the current code, not its history.

The one-line rule applies to comments you edit, not only to ones you add. When touching an existing multi-line comment, compact it to the one line it deserves under these rules — never preserve or extend its length just because it was already long. A pre-existing multi-line block is not a licence to keep multiple lines.

## Scaffolding

Scale the code to the size of the change. A one-line check stays one line: write it inline as `assert <cond>, "<why>"` where it must hold, not as a named helper with a docstring, a module constant for the value being compared, and a test. Introduce a helper or a constant at the second use site, never at the first.

Minimality is about scaffolding, not about cramming. A second line for a local that avoids repeating a call is worth spending; a second definition that exists only to name a single use is not. Bind the object to the local, not one of its fields — `info = Info()` rather than `repo = Info().repo_name` — because the construction is what is worth doing once, and the object stays available for the next field the code needs.

Do not multiply locals. When a value's destination is an object field, write it straight to the field and read it back from there — do not introduce a local that only mirrors it. `self.is_late_recovery = version.is_older(tip)` then later `elif self.is_late_recovery:`, not a `newer_release_exists` local assigned once and then copied into `self.is_late_recovery`. A local earns its place by being read more than once *before* the field exists, or by shortening a genuinely repeated expression; one that duplicates a field it is about to be assigned to is scaffolding, not clarity. Exception: inside a long or hot loop, a local that caches a field read — avoiding a repeated attribute lookup or recomputation every iteration — earns its place even if it mirrors the field.

Prefer a bare `assert` over an `if ...: raise RuntimeError(...)` block for an invariant that should never be violated. The assert message is the explanation, so no comment is needed either — and the message must add what the condition cannot show, namely the value that failed (`f"got [{repo}]"`), not a restatement of the value expected. Avoid framing that only makes sense from somewhere else: "upstream" is meaningful relative to a fork, not inside the canonical repository.

A test is not part of an assert: do not add one whose only content is re-checking the assert. Test behaviour that can plausibly regress, not a guard that fails immediately and loudly by construction.

For script-like / glue / CI code (a sequence of I/O, subprocess and API calls held together by idempotency guards, a report parser fed by a tool, a workflow of side effects), do not write a test that hand-builds the collaborators' output and asserts the code returns it — a mock. Such a test constructs the very input it then checks, so it only pins the current behaviour: it passes by construction on the code as written and stays green through any refactor that keeps the shape, catching no real regression. That is negative value — maintenance weight for a test that never fails when it should. The mock smell: the test assembles a fake payload (a fabricated JSON/JSONL record, a canned API response, a stubbed subprocess result) in the shape the code consumes. If you find yourself writing that fixture, stop.

Instead write a real end-to-end test that exercises the actual path: run the real tool/subprocess so the input is produced, not faked, feed it through the real code, and assert the observable outcome — and confirm it fails before the fix and passes after (revert the fix, watch it go red). Place it where it runs in CI: for ClickHouse, an integration-suite test under `tests/integration`, not a hand-mocked unit under `ci/tests`. Design the assertion so the fix is what makes it pass — e.g. assert on a marker the code path must have carried through, assembled at runtime so it cannot leak in by another route. When adding the assert to an existing test, that test must itself be a real one exercising the path, not a mock you are extending. See the `add-test` skill.

Before writing any test, ask first whether the check can be an assert added where the code already runs — in an existing real test, or in the code itself — rather than a new test that re-creates the setup.

When a reviewer asks for a filter that would silently drop unexpected input, prefer asserting that the input is what we expect — shorter, and it surfaces the operator error instead of hiding it. This is the "avoid fallback paths" rule applied to review feedback: a filter is a fallback.
