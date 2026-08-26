# Personal facts

Who I am and where things live on my machine.

## GitHub Username

leshikus

## Repository locations

All my working repositories live under `~/repos/` (e.g. `~/repos/release`, `~/repos/ClickHouse`, `~/repos/ClickHouse-private`). Older paths like `~/ch-*` or `~/ClickHouse` are obsolete — do not look there.

When making a sparse checkout of a ClickHouse repository, always include `.claude` in the sparse set (`git sparse-checkout set <paths> .claude`). The repo ships its skills, tools and instructions under `.claude/`; excluding it hides `clickhouse-pr-description` and the other repo skills.

## Commit identity

Per the generic `## Committing` rules, always pass an explicit `--author`:

- Non-ClickHouse projects: `--author="Alexei Fedotov <alexei.fedotov@gmail.com>"`
- ClickHouse projects: `--author="Alexei Fedotov <alexei.fedotov@clickhouse.com>"`
