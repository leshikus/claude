---
name: reports
description: Generate the morning, daily or weekly PR/issue report for leshikus into morning.txt, daily.txt or weekly.txt under ~/repos/reports. Trigger on "morning report", "daily report", "weekly report", "PR report", "update the report", or a /loop cron invocation of any of them.
---

# Reports

Three reports, one collector script. All output goes to `~/repos/reports/`.

| Report  | File          | Question it answers                                  |
| ------- | ------------- | ---------------------------------------------------- |
| morning | `morning.txt` | What can I act on right now?                          |
| daily   | `daily.txt`   | What moved since 13:00 Munich yesterday?              |
| weekly  | `weekly.txt`  | What landed between Monday 13:00 and Monday 13:00?    |

## The focus task

One issue at a time is *the* thing Max is watching, and it changes. It is recorded as a
URL in `~/repos/reports/focus.txt`:

```bash
cat ~/repos/reports/focus.txt    # e.g. https://github.com/ClickHouse/clickhouse-private/issues/66856
```

Read it at the start of every report. If the file is missing or empty, omit the Focus
section entirely rather than guessing which task is meant — a wrong focus is worse than
none, because the section is the one Max reads first.

Pull its state and everything that referenced it:

```bash
gh issue view <n> --repo <owner/repo> --json title,state,url,comments
gh api repos/<owner>/<repo>/issues/<n>/timeline --paginate \
  -q '.[] | select(.event=="cross-referenced") | .source.issue | "\(.html_url) \(.title)"'
```

The timeline's cross-references are what make this a progress report rather than a link:
they are the pull requests that claim to move the task. Apply the same window cutoff to
them as to everything else.

## Collecting the data

```bash
~/.claude/skills/reports/scripts/gh_report.sh <morning|daily|weekly>
~/.claude/skills/reports/scripts/gh_report.sh window <daily|weekly>   # just the cutoffs
```

Each mode writes TSV to stdout, split into sections by a `# SECTION` header line naming its columns. Override the account and organisation with `REPORT_LOGIN` and `REPORT_ORG`.

Column notes:

- `checks` is the rollup over the head commit only: `SUCCESS`, `FAILURE`, `PENDING`, `ERROR`, or `NONE` when no run exists for that commit.
- `mergeable` is `UNKNOWN` until GitHub computes it in the background — re-run the script rather than reporting a conflict.
- `unresolved` counts open review threads a human opened. Bot-raised threads are excluded, `clickhouse-gh` above all, so the number is review debt somebody is actually waiting on.
- `human_reviews` lists everyone who has already submitted a review, excluding leshikus, the PR author (authors review their own PRs by replying to threads) and bots. `clickhouse-gh` counts as a bot here even though its review author login carries no `[bot]` suffix.
- `reply_threads` counts review threads leshikus has commented in where another human spoke last. This is the precise "you owe an answer" signal.
- `mentions` counts human comments that write `@leshikus` anywhere on the PR.
- `last_other_comment` / `last_other_login` are the newest human activity by *anybody*, bots excluded. On a busy PR that is almost always two other people talking to each other, so it is context, never on its own a reason to act.

The script decides nothing. Read the signals and write the report.

## Morning report (`morning.txt`)

A shortlist of the items worth completing today, most valuable first, as URL and the action to take. Not a dump of everything open — the collector finds twenty-odd actionable items on a normal morning and a list that long gets skimmed and dropped.

```
## Morning Report YYYY-MM-DD

<n> of <total> actionable items, ordered by what to finish first.

<URL>
<title>
<action>

<URL>
<title>
<action>

## Not Selected

<one line per group naming what was left out and why>
```

Aim for six to ten selected items. Rank them:

1. Something that finishes: a merge, or the last thread standing between a green PR and review.
2. Something that unblocks another person: a requested review on a fresh green PR, an answer somebody is waiting on.
3. Something cheap and decisive: trigger a missing CI run, close a PR that is dead.
4. Everything else — month-old conflicting drafts, stale issues. These belong in a single sweep, not in a morning list one at a time. Name the group in Not Selected with the PR numbers, so nothing disappears silently.

Prefer one item per cluster. Four conflicting drafts of the same release change are one decision, not four; select the one that decides the rest and group the others.

Signal to action, first match wins:

| Section          | Signal                                                        | Action                                                                    |
| ---------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Review Requested | in `REVIEW_REQUESTED` with `human_reviews` empty                | Review it, or decline if it is a C++ fix (see the review-selection rules)   |
| Reply Needed     | `ENGAGED`, leshikus not in `approvals`, `reply_threads>0` or `mentions>0`, and `last_other_comment` newer than `last_own_comment` | Answer the reply |
| Own PRs          | `mergeable=CONFLICTING`                                        | Rebase onto `master`, or close if superseded                                |
| Own PRs          | `checks=FAILURE`                                               | Fix the failing job                                                         |
| Own PRs          | `checks=NONE`                                                  | Push the branch or trigger CI — no run on the head commit                   |
| Own PRs          | `unresolved>0`                                                 | Triage each thread P1/P2/P3 and resolve it                                  |
| Own PRs          | `approvals` set and `checks=SUCCESS`                           | Merge                                                                       |
| Own PRs          | `draft`, `checks=SUCCESS`, `unresolved=0`                      | Mark ready for review — regenerate title and body first                     |
| Own PRs          | `ready`, no approvals, quiet for two days or more              | Ping a reviewer                                                             |
| Own PRs          | quiet for 30 days or more                                      | Close, or say what still blocks it                                          |
| Issues           | authored by leshikus, no comments at all                       | Ask for reviewers — nobody has answered yet                                 |
| Issues           | authored by leshikus, quiet for 30 days or more                | Close it or post the current state                                          |
| Issues           | assigned to leshikus, `last_comment_by` somebody else          | Answer, or hand it back                                                     |

An item can carry more than one signal — pick the one that unblocks it and mention the rest in the action line (`Rebase onto master; 3 jobs also failing`). Drop anything whose only honest action is "wait": `checks=PENDING` with nothing else pending on leshikus is not actionable.

Once leshikus has approved somebody else's PR, he owes it nothing further, whatever has been said on it since. Landing it is the author's job.

Drop a review request that another human has already reviewed — `human_reviews` non-empty. The PR has the second pair of eyes it was asking for, and a duplicate review is the least valuable thing in the list. Name it in Not Selected with the reviewer, so the skip is visible.

### Draft reviews

Every review item that reaches the selected list carries a draft review of about 100 words underneath its action line, indented by two spaces so it reads as attached rather than as another entry.

Write it from the diff, not the title: `gh pr diff <n> --repo <repo>`. Lead with whether the approach is right — does the change fit the invariant the file already holds, is the diagnosis of the failure correct — and only then raise specifics. Verify each claim before it goes in, exactly as the review-selection rules demand: check whether an import really is orphaned, whether a role really is shared, whether a failing lane really is related. A question you have actually checked is worth more than three you have not.

These are drafts for leshikus to post, edit or discard. Never post them.

Before writing an action that asserts a relationship between two items — supersedes, duplicates, covers the same ground — compare the changed files (`gh pr view <n> --json files`). Overlapping titles are not evidence.

Repositories outside the ClickHouse organisation are out of scope; the collector filters them with `org:`.

## Daily report (`daily.txt`)

Window: activity after 13:00 Munich on the previous day, or on Friday when today is Monday. `gh_report.sh daily` applies a day-granularity prefilter — drop rows whose `updated` falls before the exact cutoff yourself.

The filter is strict. A still-open PR with no activity inside the window is excluded, however much it is still in flight.

```
## Daily Report YYYY-MM-DD

## Waiting for @Max review

<URL>
<title>
<status note>

## Focus: <issue title>

<issue URL>

<one line: where the task stands now>
<one line per PR or comment that moved it inside the window, URL then what it changed>
Blocked on: <what is stopping it, or omit the line>
Next: <the next concrete step>

## Updated Issues

<URL>
<title>
Open | Closed

## In Progress

<URL>
<title>
<status note>

## Merged

<URL>
<title>

## Reviews

<URL>
<title>
```

Each PR appears in exactly one section, and the sections claim them in the order they
are printed: **Waiting for @Max review, then Focus, then In Progress.** A PR that would
have gone to In Progress and is cross-referenced by the focus issue belongs to Focus
instead — that is the point of the section, and listing it twice makes the report
longer without saying more. One awaiting Max's review stays in his review list, because
that is what he acts on rather than reads.

Waiting for @Max review holds open PRs with no human approval where `maxknv` is a requested reviewer, drafts included. Every other PR still awaiting review — no reviewer requested, or somebody else requested — goes to In Progress, unless Focus has already claimed it. Status notes on unmerged PRs start with `Draft: <what the body says was done>` for drafts, `Testing` when a human has approved, and no label otherwise — never name the approver. Merged entries carry no note.

Focus reports progress on the issue named in `focus.txt`, and it is the section Max
reads for status, so it says where the task stands rather than listing links. "Where it
stands" is a sentence someone can act on — what is done, what is not — not a restatement
of the title. Movement inside the window comes from the issue's own comments and from
cross-referenced pull requests, which Focus lists in full rather than leaving to In
Progress; when nothing moved, say so in one line and keep
`Blocked on:` and `Next:`, which are the part that does not depend on the window.

Omit the whole section when `focus.txt` is absent. Never substitute a task of your own
choosing.

Reviews holds other people's PRs that leshikus reviewed or commented on inside the window, from the `REVIEWED` section. The same two filters the weekly report needs apply here, and the timestamp check matters more at a one-day window: drop bot- and robot-fronted authors, and drop PRs where leshikus' own review or comment landed before the cutoff. Use the `gh api` calls listed under the weekly report to check the real timestamps.

## Weekly report (`weekly.txt`)

Window: Monday 13:00 Munich of last week to Monday 13:00 Munich of this week.

```
## Merged

<URL>
<title>

## In Progress

<URL>
<title>

## Reviews

<URL>
<title>
```

In Progress holds leshikus' still-open PRs updated inside the window, drafts included — omit the section entirely when Merged has more than two PRs.

Reviews holds other people's PRs that leshikus reviewed or commented on inside the window. Two filters the search cannot apply:

- Drop bot authors. `-author:leshikus` matches the GitHub author field only, so robot-fronted backports of leshikus' own merged PRs (`robot-clickhouse-ci-1`, `robot-ch-test-poll`, any `robot-*`, titles like `Backport #<n> to release/...`) come through as somebody else's work.
- Drop PRs where leshikus' own review or comment landed outside the window. `updated:` matches anybody's update at day granularity, which both admits PRs somebody else touched and misses the hours between Munich 13:00 and UTC midnight. Check the real timestamps:

```bash
gh api "/repos/<owner>/<repo>/issues/<num>/comments" --jq '[.[] | select(.user.login=="leshikus") | .created_at]'
gh api "/repos/<owner>/<repo>/pulls/<num>/reviews"   --jq '[.[] | select(.user.login=="leshikus") | .submitted_at]'
gh api "/repos/<owner>/<repo>/pulls/<num>/comments"  --jq '[.[] | select(.user.login=="leshikus") | .created_at]'
```

## PR titles

If a title is not descriptive enough, fix it with `gh pr edit <URL> --title "..."`. Do not edit PR bodies from a report run.
