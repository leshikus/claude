# ClickHouse instructions

Workflow specific to the ClickHouse repositories.

## Reports

Three reports live under `~/repos/reports/`: `morning.txt` (everything open where an action is available, as URL and supposed action), `daily.txt` (what moved since 13:00 Munich yesterday) and `weekly.txt` (what landed Monday 13:00 to Monday 13:00).

When asked for any of them, invoke the `reports` skill (via the Skill tool) — it owns the collector script, the windows, the section formats and the signal-to-action rules. Never hand-assemble the `gh` queries.

The monitor asks on a schedule for two picks out of the same actionable set as `morning.txt` — the oldest item waiting on me, and the highest-priority one — and wants only the labelled URLs back. Build the set the same way: run `~/.claude/skills/reports/scripts/gh_report.sh morning` and apply the skill's signal-to-action rules. The highest pick is the item that ordering puts first, by the same "what to finish first" judgment the morning report uses. Repositories outside the ClickHouse organisation are out of scope.

## Processing review comments

Process review comments in two phases; do not collapse them.

**Phase 1 — planning (no side effects).** Triage every open comment, verifying each against the actual code. Produce a per-comment plan: the comment text and the proposed action, and prepare each fix as a separate patch — one standalone diff per comment, saved under the working directory's `tmp`, not applied. Touch nothing else: no code edits, no commits, no PR/issue/label/body changes, no posted replies. This phase is read-and-prepare only, and it ends with the plan shown to me.

**Phase 2 — human review and action.** Walk the comments with me one at a time, in dialogue. For each, show the comment and its proposed solution (with the prepared patch), then wait for my decision before acting. Only once I agree on that comment do you apply its patch, commit, post the sanctioned reply, or open the follow-up. Do not batch-apply, and do not move to the next comment until the current one is resolved with me.

The triage and reply mechanics below apply within these phases — triage in Phase 1, apply/reply in Phase 2.

When responding to a review comment (from a human or a bot), first triage it into one of three options and prefer the earliest that applies, rather than reflexively implementing:
1. **Do not implement (P1)** — the comment rests on a flawed premise, the concern does not actually apply to the code, or the change adds no real value. Verify against the actual code, then reply explaining why and resolve the thread.
2. **Defer to a separate PR (P2)** — the change is valid but out of scope for the current PR, or is better decoupled. Create a separate pull request for it against `master` (never stacked on the current PR's branch), then reply to the review comment linking that follow-up PR.
3. **Implement (P3)** — only when neither P1 nor P2 applies.

Do not fix a review comment in the current pull request if it can be fixed in a separate one. P2 is the default whenever the fix can stand on its own, and the clearest sign of that is a problem that existed before this pull request — a pre-existing bug, a stale runbook, a fail-open path in code the change merely touches. Such a fix does not belong here no matter how small it is: a one-line fix that is unrelated to the change still widens the diff, re-runs CI, and dismisses existing approvals. Reserve P3 for what the pull request itself introduced, or made reachable or consequential.

When a bot comment asks for a test, post the "Standard reply" from the umbrella issue
https://github.com/ClickHouse/ClickHouse/issues/116461 on that thread. The issue is the
source of truth for when a fixture test is appropriate and when a dry-run / e2e test is
wanted instead; read it rather than reconstructing the reply.

Do not implement a suggestion just because a reviewer raised it; a bot's confidence is not evidence.

When you fix a reviewer's comment, reply to that review comment with exactly three words: `Fixed in <sha_url>`, where `<sha_url>` is the full GitHub URL of the commit that fixes it (e.g. `https://github.com/ClickHouse/ClickHouse/pull/<pr>/commits/<sha>`). The reply body must be nothing but `Fixed in <sha_url>` — no leading/trailing prose, no explanation, no bullet points. Post the reply as a comment on the review thread, not just in the commit message, so the reviewer gets a notification and can follow the link to the exact fix. All explanation goes in the commit message, not the reply: the commit message itself must fully answer the review comment — explain what the reviewer raised and how the change addresses it, so the linked commit stands on its own without the reviewer needing to reconstruct the discussion.

When a comment is addressed by a follow-up pull request (the P2 case) rather than a commit in the current one, reply on that same review thread with the simple message `Will be fixed in <pr_url>`, where `<pr_url>` is the full GitHub URL of the follow-up pull request. The future tense is deliberate: the follow-up has not merged yet. As with `Fixed in <sha_url>`, the reply body must be nothing but that line, and it must be posted on the review thread (including a bot's thread) so the reviewer or bot is notified.

When a comment is addressed by moving the code it concerns into another pull request — rather than fixing it in place — reply with `Moved to <pr_url>`, the full GitHub URL of the pull request the code moved to. Same constraints: the body is nothing but that line, posted on the review thread. Use it in place of `Will be fixed in <pr_url>` whenever the change is relocated to another PR rather than merely promised there.

When a human reviewer questions a change that a bot asked for, reply with `Requested by bot in <comment_url>`, the full GitHub URL of the bot review comment that requested it — point the reviewer to the origin rather than re-arguing it. Review the cited bot comment first to confirm it actually requested the change. Same constraints: the body is nothing but that line, posted on the review thread.

`Fixed in <sha_url>`, `Will be fixed in <pr_url>`, `Moved to <pr_url>`, `Requested by bot in <comment_url>` and the test-delegation reply (the Standard reply from issue 116461) are the only comments you may post to a pull request or review thread autonomously. Any other comment — an explanation, a correction, a discussion reply, a status update, a follow-up note — must be reviewed with me before posting; show me the exact text and wait for approval. Never post it directly. This applies to review-thread replies and issue-level pull request comments alike, and to human and bot threads alike. Do not chain corrections onto GitHub either: if a comment you would have posted turns out wrong, fix it locally and re-review with me rather than posting successive amendments to the thread.

## ClickHouse projects

When creating or updating a PR description, always invoke the `clickhouse-pr-description` skill (via the Skill tool) and let it generate and apply the description — never hand-write the title/body or run `gh pr create`/`gh pr edit` for the description directly. This applies to every ClickHouse PR, including minor or CI-only ones.

Follow `.github/PULL_REQUEST_TEMPLATE.md` exactly: the body is a short description and motivation, then the Changelog category (leave one), then the Changelog entry. Do not add sections the template does not contain — in particular there is no "Documentation entry" section, so never add one. For categories whose label says the changelog entry is not required (e.g. `CI Fix or Improvement`, `Documentation`, `Not for changelog`), leave the Changelog entry empty.

Keep PR descriptions concise. The description prose (everything before the Changelog category, i.e. excluding the template's Changelog category/entry boilerplate) must be no more than 200 words, and for small PRs no more than 100 words. Trim motivation and background to the essentials rather than writing multi-paragraph explanations.

When creating a PR, open it as a **Draft** — this prevents accidental merges.

When marking a PR ready for review (transitioning it out of Draft), first actualize its title and body via the `clickhouse-pr-description` skill. Both are often written against an early draft state; by the time the PR is ready the change, motivation, and CI story have usually moved on, so regenerate the subject and description before it goes in front of reviewers.

When a PR only touches files under `.claude/` (settings, tools, skills, instructions, etc.), prefix the title with `claude: ` and use the `Documentation (changelog entry is not required)` changelog category. Example: `claude: add fetch_ci_report.js to allowed commands`.

When a PR is about Darwin fast tests (e.g. adding entries to `ci/defs/darwin.skip`, fixing tests that fail only on Darwin), prefix the title with `darwin fast test: ` and use the `CI Fix or Improvement (changelog entry is not required)` changelog category. Example: `darwin fast test: skip more tests on Darwin ARM`.

When adding new prompt conventions, rules, or guidelines that apply to all ClickHouse projects, add them to `~/.claude/CLAUDE.md` in addition to any project-specific location.

When adding or updating ClickHouse-related permissions in `~/.claude/settings.json` or rules in `~/.claude/CLAUDE.md`, accumulate the changes locally. Do not open an individual PR for each change — they will be combined into a single PR once per week. Once the combined PR is merged, remove the corresponding entries from the local `~/.claude/` files.

### Fork vs upstream

If the current repository is a fork (i.e. `git remote get-url origin` does not contain `ClickHouse/ClickHouse`), always target the upstream repository. Pass `--repo ClickHouse/ClickHouse` to `gh pr create` and set `--head <fork-owner>:<branch>` so the PR is opened against the canonical repo, not the fork.

After creating a fork-based PR, immediately add the `can be tested` label so CI is not blocked by the `can_be_tested` pre-hook:

```
gh pr edit <PR-number> --repo ClickHouse/ClickHouse --add-label "can be tested"
```

### Selecting PRs to review

When choosing open PRs to review (e.g. via the `clickhouse-pr-review` skill), select PRs that touch Python, tests, or configuration — Python tooling (`.py` under `ci/`, `tests/`, `utils/`), test additions/changes (`.sql`/`.sh`/`.reference` fixtures, `tests/clickhouse-test`, integration `test.py`), and configuration (`.xml`/`.yaml`/`.yml`/config files, CI defs). These are the preferred targets for this workflow.

Do not review C++ fixes. Skip any PR whose changes are primarily C++ source (`.cpp`/`.h`/`.hpp`/`.cc` under `src/`), even one with genuine logic or architecture surface (behavior, data layout, concurrency, planner/executor, formats). These are handled elsewhere; the preferred targets are the Python/tests/configuration PRs above.

Test-only additions and CI/tooling tweaks often produce only nits or unfounded concerns, so verify carefully before posting and skip if nothing substantive survives. A narrow filter-string or config toggle that broadens what gets masked (e.g. a broad substring added to an ignore list) is the kind of small change worth flagging.

Before surfacing any concern as a finding, verify it against the actual codebase — the type of a value, whether an existing unguarded call site already relies on the same assumption, the real call context. Do not post a concern you have not checked. Example from a real review: a suspected `TypeError` on `Info().job_name` was precluded because `JOB_NAME` is typed `str` (defaults to `""`), the code runs inside a live job where it is set, and `functional_tests.py` already does the same unguarded substring test — so it was not a finding. Do not pad a review; if nothing substantive survives verification, skip posting.

### CI monitoring

For ClickHouse PR CI reports, use `.claude/tools/fetch_ci_report.js` when fetching failed logs during the initial evaluation described in the generic `## CI monitoring` rules.
