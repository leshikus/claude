# ClickHouse instructions

Workflow specific to the ClickHouse repositories.

## Reports

Three reports live under `~/repos/reports/`: `morning.txt` (everything open where an action is available, as URL and supposed action), `daily.txt` (what moved since 13:00 Munich yesterday) and `weekly.txt` (what landed Monday 13:00 to Monday 13:00).

When asked for any of them, invoke the `reports` skill (via the Skill tool) — it owns the collector script, the windows, the section formats and the signal-to-action rules. Never hand-assemble the `gh` queries.

The monitor asks on a schedule for two picks out of the same actionable set as `morning.txt` — the oldest item waiting on me, and the highest-priority one — and wants only the labelled URLs back. Build the set the same way: run `~/.claude/skills/reports/scripts/gh_report.sh morning` and apply the skill's signal-to-action rules. The highest pick is the item that ordering puts first, by the same "what to finish first" judgment the morning report uses. Repositories outside the ClickHouse organisation are out of scope.

## Processing review comments

Use the `review-comments` skill (via the Skill tool) for every review comment on my pull requests: triage, patches, the decision words and the reply forms live there.

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
