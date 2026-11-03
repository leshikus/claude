# claude

Standing instructions and skills for Claude Code.

`prompts/` is loaded on every session, so it is split by how far each part travels:

- `generic.md` — how to work: communication, questions, issues, code comments,
  scaffolding. Nothing in it is specific to a project, a company or a person.
- `technical-language.md` — how to word any text: RFCs, issues, PR descriptions,
  commit messages, reviews, chat replies. Equally generic.
- `clickhouse.md` — workflow for the ClickHouse repositories: reports, the
  review-comment protocol, PR selection, fork vs upstream.
- `personal.md` — account name, where repositories live, commit identity.

The split is the point. `generic.md` is the half worth reading if none of the rest
applies to you, and `personal.md` is the half that can never be shared.

`skills/` is loaded only when a task calls for it — `clickhouse-pr-description`,
`clickhouse-pr-review`, `reports`, `test-debug-fix`. A procedure with an obvious
trigger belongs here rather than in `prompts/`, where it would be paid for on every
session. A rule that has to shape output without anyone thinking to fetch it does not:
nobody invokes a skill before writing a code comment.

## Install

Clone the repository as `~/.claude`. `.gitignore` ignores everything except `CLAUDE.md`, `prompts/` and `skills/`, so credentials, transcripts and settings stay untracked:

```
git init ~/.claude && cd ~/.claude
git remote add origin https://github.com/leshikus/claude.git
git fetch origin && git reset origin/main && git checkout -- .
```

`CLAUDE.md` imports the prompts:

```
@prompts/generic.md
@prompts/technical-language.md
@prompts/clickhouse.md
@prompts/macos-runner-logging.md
@prompts/personal.md
```
