#!/bin/sh
# Install the standing instructions where Claude Code reads them.
#
# Copies, not symlinks: ~/.claude is mounted into containers and this checkout is not,
# and a container writing through a symlink would clobber the source here.
#
# CLAUDE.md.in is the importing wrapper; without it nothing loads the prompts at all.
# It is `.in` rather than CLAUDE.md so that working *in* this repository does not pick
# it up as project instructions, where its `@prompts/...` paths do not resolve.
set -eu
src=$(dirname "$0")
dest="$HOME/.claude"
mkdir -p "$dest/prompts"
for f in generic.md clickhouse.md personal.md; do
    cp "$src/$f" "$dest/prompts/$f"
    echo "installed $dest/prompts/$f"
done
if [ -f "$dest/CLAUDE.md" ] && ! cmp -s "$src/CLAUDE.md.in" "$dest/CLAUDE.md"; then
    cp "$dest/CLAUDE.md" "$dest/CLAUDE.md.bak"
    echo "kept the previous wrapper as $dest/CLAUDE.md.bak"
fi
cp "$src/CLAUDE.md.in" "$dest/CLAUDE.md"
echo "installed $dest/CLAUDE.md"
