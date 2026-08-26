#!/bin/sh
# Install the standing instructions and skills where Claude Code reads them.
#
# Copies, not symlinks: ~/.claude is mounted into containers and this checkout is not,
# and a container writing through a symlink would clobber the source here.
#
# CLAUDE.md.in is the importing wrapper; without it nothing loads the prompts at all.
# It is `.in` rather than CLAUDE.md so that working *in* this repository does not pick
# it up as project instructions, where its `@prompts/...` paths do not resolve.
#
# Nothing is removed: a skill deleted here stays installed until you delete it there.
set -eu
src=$(dirname "$0")
dest="$HOME/.claude"
mkdir -p "$dest/prompts" "$dest/skills"

for f in "$src"/prompts/*.md; do
    cp "$f" "$dest/prompts/"
    echo "installed $dest/prompts/$(basename "$f")"
done

for d in "$src"/skills/*/; do
    name=$(basename "$d")
    rm -rf "$dest/skills/$name"
    cp -Rp "$d" "$dest/skills/$name"
    echo "installed $dest/skills/$name"
done

if [ -f "$dest/CLAUDE.md" ] && ! cmp -s "$src/CLAUDE.md.in" "$dest/CLAUDE.md"; then
    cp "$dest/CLAUDE.md" "$dest/CLAUDE.md.bak"
    echo "kept the previous wrapper as $dest/CLAUDE.md.bak"
fi
cp "$src/CLAUDE.md.in" "$dest/CLAUDE.md"
echo "installed $dest/CLAUDE.md"
