# claude

Standing instructions for Claude Code, split by how far they travel.

- `generic.md` — how to write and how to work: communication, wording, code comments,
  scaffolding. Nothing in it is specific to a project, a company or a person.
- `clickhouse.md` — workflow for the ClickHouse repositories: reports, the
  review-comment protocol, PR selection, fork vs upstream.
- `personal.md` — account name, where repositories live, commit identity.

The split is the point. `generic.md` is the half worth reading if none of the rest
applies to you, and `personal.md` is the half that can never be shared.

## Install

`./install.sh` copies the three files into `~/.claude/prompts/`, where
`~/.claude/CLAUDE.md` imports them:

```
@prompts/generic.md
@prompts/clickhouse.md
@prompts/personal.md
```

Copies, not symlinks, and under `~/.claude/` rather than imported from here directly.
Both constraints come from running Claude Code in a container: `~/.claude` is mounted
in, `~/repos` is not, so an import pointing at this checkout resolves on the host and
fails inside. A symlink fails the same way, and a container writing through one would
clobber the file in this repository.
