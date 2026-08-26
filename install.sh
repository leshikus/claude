#!/bin/sh
# Copy the instruction files where ~/.claude/CLAUDE.md imports them from.
# Copies, not symlinks: ~/.claude is mounted into containers and this checkout is not,
# and a container writing through a symlink would clobber the source here.
set -eu
dest="$HOME/.claude/prompts"
mkdir -p "$dest"
for f in generic.md clickhouse.md personal.md; do
    cp "$(dirname "$0")/$f" "$dest/$f"
    echo "installed $dest/$f"
done
