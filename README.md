# claude

Standing instructions and skills for Claude Code.

`prompts/` is loaded on every session, so it is split by how far each part travels:

- `generic.md` — how to write and how to work: communication, wording, code comments,
  scaffolding. Nothing in it is specific to a project, a company or a person.
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

`./install.sh` copies `prompts/` and `skills/` into `~/.claude/`, and `CLAUDE.md.in`
to `~/.claude/CLAUDE.md`, which is what imports the prompts:

```
@prompts/generic.md
@prompts/clickhouse.md
@prompts/personal.md
```

The wrapper is committed too, because without it nothing loads any of this. It is named
`.in` so that working in this repository does not pick it up as project instructions,
where those relative paths do not resolve. An existing wrapper is kept as
`~/.claude/CLAUDE.md.bak`.

Copies, not symlinks, and under `~/.claude/` rather than imported from here directly.
Both constraints come from running Claude Code in a container: `~/.claude` is mounted
in, `~/repos` is not, so an import pointing at this checkout resolves on the host and
fails inside. A symlink fails the same way, and a container writing through one would
clobber the file in this repository.
