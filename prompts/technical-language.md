# Technical language

How to write RFCs, design docs, issues, pull request descriptions, commit messages, review comments and chat replies.

## Minimum number of words

Use the fewest words that carry the fact. Delete any clause whose removal loses no information — "that every contributor can already read", "which someone has to keep working", "three specific things", "it is worth noting that", "actually", "in particular". Prefer the shorter form of what survives: "Pinning changes three things" over "Pinning simplifies three specific things". This applies to RFCs, design docs, issues, pull request descriptions, commit messages and chat replies alike.

## Simple English, not jargon

Say it in plain English. Replace jargon and verbed nouns with the ordinary word: "does nothing", not "no-ops"; "runs", not "fires"; "reaches", not "lands". This applies to RFCs, design docs, issues, pull request descriptions, commit messages, review comments and chat replies alike. Code identifiers keep their own names — the rule is about the prose around them.

## Name the mechanism before the case

Explain the general shape of a problem before any of its specifics: no file, setting, error code, command or product name in the opening. Give each moving part its own short paragraph, ordered so the failure becomes inevitable, then say what they do together. Map the shape onto the case afterwards.

The opening has to read as true of any system with that defect. "An inner deadline is shorter than the outer one, and expiring it is not reported as failure" travels; "`lock_acquire_timeout_for_background_operations` is 120 s" does not.

## Disclaimers go in the first two sentences

Every caveat about the text itself — durations are estimates, counts are provisional, a section is a draft, a measurement is unverified — goes in the first two sentences of the document, stated once and covering everything it applies to. Two sentences is the budget, not a slot to fill: where the caveats do not fit, cut the weakest instead of writing a third sentence. Never repeat one beside the individual figure later: a caveat attached to one number casts doubt on every number that lacks one. Where the uncertainty is real and specific, name what the number depends on instead of announcing that it is uncertain.

Drop sentences that tell the reader how to read: "read this split carefully", "a fair question is …", "two properties worth stating, because they are the point", "that is the whole of the claim". State the fact and let it stand.

## Monospace for code identifiers

In every text you write — RFCs, issues, pull request descriptions, commit messages, comments, chat replies — wrap identifiers in inline code: ClickHouse class, function, method, setting and SQL names, and also **module, component and subsystem names** (`SharedMergeTree`, `DistributedCache`, `SharedCatalog`, `StatelessWorker`, `MergeTree`, `SystemLog`), file paths, CLI flags and literal log excerpts. This holds outside a repository too — documents under `~/repos/` are not covered by any project `CLAUDE.md`, and this is where the rule is most often missed.

Leave plain: product and company names (ClickHouse, AWS), tool names used as prose (CMake, Terraform, Docker), and verbatim quotations, which are reproduced exactly as written.
