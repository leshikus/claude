---
name: clickhouse-pr-review
description: Inspect open pull requests in ClickHouse/ClickHouse, skip drafts and PRs whose CI is still running, decide which open PRs merit a non-trivial review, and append architecture-first draft reviews to ~/.claude/review/findings.md for the user to approve before posting. Reviews lead with problem-framing / approach / module-boundary / failure-mode / test-level concerns and only descend to correctness and style nits once the structure looks sound. Trigger phrases — "review open ClickHouse PRs", "inspect ClickHouse PRs", "find non-trivial PRs to review", or invocation via the hourly /loop cron job.
---

# ClickHouse PR Review

Surface open `ClickHouse/ClickHouse` PRs that deserve a non-trivial review, draft the review locally, and let the user gate posting.

## State files

- `~/.claude/review/findings.md` — append draft reviews here, one entry per candidate.
- `~/.claude/review/seen.txt` — newline-separated PR numbers already evaluated (whether reviewed or skipped). Always check this before evaluating a PR, and append to it after evaluating.

Never overwrite these files — always read them first, then append.

## Step 1 — List candidate PRs

```bash
gh pr list \
  --repo ClickHouse/ClickHouse \
  --state open \
  --limit 200 \
  --json number,title,url,isDraft,author,additions,deletions,changedFiles,labels,createdAt,updatedAt,statusCheckRollup,reviewRequests,reviews,reviewDecision
```

Filter the JSON in memory:

- Drop `isDraft == true`.
- Drop entries where `statusCheckRollup` is empty or contains any check with state `IN_PROGRESS`, `QUEUED`, `PENDING`, or `EXPECTED`. CI must have finished (mix of `SUCCESS`/`FAILURE`/`NEUTRAL`/`SKIPPED` is fine).
- **Drop PRs that already have a reviewer.** If `reviewRequests` is non-empty (someone has been pinged), or `reviews` contains any entry whose `state` is `APPROVED`, `CHANGES_REQUESTED`, `COMMENTED`, or `REVIEW_REQUIRED`, the PR is already covered — skip it (append to `seen.txt`, do not draft a review). The user only wants to surface PRs that are *unattended*; piling on a PR that already has e.g. ksenii on it is noise. Bot-authored review-requests (`copilot`, `claude`, automated PR bots) do not count as a real reviewer — strip those before checking.
- Drop PRs whose number is already in `seen.txt`.

If nothing remains, record `Run: <timestamp> — no new candidates` at the bottom of `findings.md` and exit.

## Step 2 — Triage each remaining PR

Order candidates by `updatedAt` descending (freshest first). Cap the work at **10 PRs per run** to keep latency bounded — the rest stay un-seen and will be picked up next hour.

For each PR:

1. Pull metadata and the diff:
   ```bash
   gh pr view <N> --repo ClickHouse/ClickHouse --json title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,files,labels
   gh pr diff <N> --repo ClickHouse/ClickHouse
   ```
2. Classify trivial vs non-trivial. **Trivial** (skip, append to `seen.txt`, do NOT add to findings):
   - C++ fixes — any PR whose changes are primarily C++ source (`.cpp`/`.h`/`.hpp`/`.cc` under `src/`), regardless of logic or architecture surface. These are handled elsewhere; do not review them.
   - Docs-only changes (`.md`, `docs/`).
   - Whitespace-only / formatting-only / typo fixes.
   - Automated bumps (Dependabot, submodule pin updates with no logic change).
   - Single-line constant tweaks, log-message wording fixes.
   - Test-only additions where the change is a straightforward new test (no production code touched).
   - Bot-authored PRs (`app/dependabot`, `app/renovate`, `backport-bot`).
   - Trivial revert PRs that just back out a recent commit.

   **Non-trivial** (continue to step 3 — but only when *not* a C++ fix per the skip rule above):
   - Touches Python/tests/configuration with logic changes.
   - New SQL function, new setting, new storage feature.
   - Performance work (planner, executor, hash table, IO).
   - Concurrency / locking / memory ordering changes.
   - Anything touching `MergeTree`, `ReplicatedMergeTree`, `Keeper`, `Parts`, `Replication`.
   - Refactors larger than ~300 lines of substantive code.
   - Format / parser / type-system changes.

3. **Review architecture first, then details.** The order matters because architectural issues invalidate detail-level feedback — a perfectly written function in the wrong layer is still a problem, and no amount of style nits fixes a misplaced abstraction. Walk through the levels in this order and only descend once the current level looks sound:

   a. **Problem framing.** What problem does the PR claim to solve? Is the framing accurate, or is the PR fixing a symptom while the real issue lives elsewhere? Is the scope right — too narrow (a band-aid that won't survive the next adjacent change), too wide (bundling unrelated changes that obscure the diff)? Does an existing setting / feature already cover this case?

   b. **Approach / design.** Is this the right approach at all? Compare against alternatives: a simpler refactor, a config change, a smaller surface area. Is the new abstraction (class, helper, setting) pulling its weight, or could the same effect be achieved with existing primitives? Does the change preserve or violate invariants that other parts of the codebase rely on (lock order, ownership, lifetime, error-propagation contract)?

   c. **Module boundaries / placement.** Is the change in the right file / namespace / layer? Does it leak implementation details across a boundary that was previously clean (e.g. a planner-level helper reaching into storage internals, or vice-versa)? Does it introduce a backwards dependency between subsystems? For new SQL surface (settings, functions, table engines, storage features): is the naming consistent with siblings, and does the user-facing contract fit the project's mental model?

   d. **Failure modes / observability.** Under partial failure, restart, network partition, OOM, slow disk — what does the new code do? Are the error paths *as deliberate* as the happy path, or are they accidental? Does the change degrade the diagnostics available when something goes wrong (silent fallback, swallowed exception, removed log line)?

   e. **Tests at the right level.** Is the test exercising the architectural property the PR is meant to guarantee, or only a single happy-path query? Would the test still pass if the implementation were replaced with a stub that returns the right answer for the literal input? Does the regression test fix the *bug* or just the *symptom*?

   Only after (a–e) look sound, descend to detail-level review:
   - Correctness bugs (off-by-one, missed null, wrong locking).
   - Performance regressions (extra allocations in hot path, missed move, accidental copy of large struct).
   - Style violations of repo conventions (Allman braces; `sleep` in C++ for races; `ASAN` vs `ASan`; `f` vs `f()`; "crash" vs "exception" in release-build context).
   - Missing changelog entry.
   - Backwards-compatibility shims that hide intent.
   - Fallback paths that swallow errors silently.

   When writing the draft review, lead with architectural observations (if any) and put detail-level nits last. If an architectural concern is severe enough that the detail-level review would be wasted work (because the approach has to change), say so and stop there — don't pad the review with nits on code that may not survive the discussion.

4. If after reading the code there is no substantive feedback, treat as trivial (still append to `seen.txt`, skip findings).

## Step 3 — Append a draft review entry

For each PR that yields real feedback, append a block to `findings.md` in this exact format (do NOT replace prior content):

```
## PR #<N> — <title>

- URL: <url>
- Author: <login>
- Touches: <changedFiles> files, +<additions>/-<deletions>
- Run: <ISO-8601 timestamp>
- Status: pending-user-review

### Why interesting

<2–4 lines on what makes this non-trivial and worth reading>

### Architecture notes

<Lead with the architectural lens from Step 2.3.a–e. If everything looks structurally
sound, write "No architectural concerns — change is well-scoped." and proceed to
detail-level bullets. If something is off (wrong layer, wrong abstraction,
unnecessary new surface area, missed simpler alternative, fragile failure-mode
contract), state it concretely here — one short paragraph per concern, naming the
file/module that anchors the concern.>

### Draft review

<Bullet list of concrete observations *in priority order*:
1. Architectural / approach-level questions first (if not fully covered above).
2. Correctness / safety / concurrency bugs.
3. Test quality (right level? regression covers the actual property?).
4. Performance / allocation / hot-path concerns.
5. Style / convention nits last.

Each bullet should be postable as-is:
- File-and-line reference where possible: `src/Foo/Bar.cpp:123`
- Phrase as a question or a clear ask, not a vague concern.
- Keep the tone collaborative.
- Be ruthlessly short. A posted comment states one point and stops — ideally
  one to three sentences of plain prose, no headers or bold, no restating the
  PR, no listing what's fine. Anchor to a `file:line`, hedge only where the
  intent is genuinely unclear ("this may not be intended"). If you're
  explaining rather than stating, cut it. Example of the target length:
  "fixing the jq to `any((.name? // .) == "infra")` would also auto-retry every
  other `set_label`-based infra site — notably `integration_test_job.py:935`;
  this may not be intended." A human skims a 3-line comment and engages; they
  skip a 15-line one.

If you stopped the review at the architectural level because the approach has to
change, say so explicitly and skip detail-level bullets — don't pad.>

### Open questions for the user

<optional: anything you want the user to decide before posting>

---
```

Then append the PR number to `seen.txt` on its own line.

## Step 4 — Wrap up

Append a one-liner at the end of `findings.md`:

```
Run: <ISO-8601 timestamp> — evaluated <K> PRs, surfaced <M> for review.
```

Print a short summary in chat: how many candidates were inspected, how many ended up in `findings.md`, and the PR numbers that were added.

## Posting reviews (manual step)

When the user asks to post a review for one of the entries:

1. Re-read the relevant entry from `findings.md`.
2. Confirm with the user the exact review body if it contains questions or open items.
3. Post with `gh pr review <N> --repo ClickHouse/ClickHouse --comment --body-file <tmp>` (use `--request-changes` only if the user explicitly asks).
4. Update the entry's `Status:` line to `posted` and add a `Posted at: <timestamp>` line.

## Guardrails

- Never auto-post a review. Posting is always user-initiated.
- Never push changes to the PR branches.
- Never approve or request changes without an explicit user instruction.
- Stay strictly read-only against GitHub except for the explicit post step.
- If `gh` is not authenticated or rate-limited, log the error in `findings.md` under a `Run: <timestamp> — ERROR: ...` line and stop. Do not retry in a tight loop.
