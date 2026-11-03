#!/usr/bin/env python3
"""Render a report .txt in the Slack layout with `#<num>` links, write <name>.html and copy it to the clipboard."""

import html
import re
import subprocess
import sys
from pathlib import Path

URL = re.compile(r"^https://github\.com/[^/]+/[^/]+/(?:pull|issues)/(\d+)$")


def parse(text):
    sections = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("## "):
            sections.append((line[3:], []))
        elif URL.match(line):
            sections[-1][1].append([line])
        elif line and sections[-1][1]:
            sections[-1][1][-1].append(line)
    return sections


def render(sections, link):
    blocks = []
    for header, entries in sections:
        name, _, title = header.partition(": ")
        colon = ":"
        if title and entries and len(entries[0]) == 1:
            header, entries, colon = f"{name}: {link(entries[0][0])}: {title}", entries[1:], ""
        if not entries:
            blocks.append(header)
        elif all(len(e) == 1 for e in entries):
            blocks.append(f"{header}{colon} " + " ".join(link(e[0]) for e in entries))
        else:
            lines = (link(e[0]) + (": " + " — ".join(e[1:]) if e[1:] else "") for e in entries)
            blocks.append(f"{header}{colon}\n\n" + "\n".join(lines))
    return "\n\n".join(blocks)


def number(url):
    return "#" + URL.match(url).group(1)


def anchor(url):
    return f'<a href="{html.escape(url)}">{number(url)}</a>'


def copy(markup, plain):
    hexed = markup.encode().hex()
    plain = plain.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(
        ["osascript", "-e", f'set the clipboard to {{«class HTML»:«data HTML{hexed}», string:"{plain}"}}'],
        check=True,
    )


def main():
    assert len(sys.argv) == 2, f"usage: {sys.argv[0]} <report.txt>, got {sys.argv[1:]}"
    src = Path(sys.argv[1]).expanduser()
    sections = parse(src.read_text())
    escaped = [(html.escape(h), [[e[0]] + [html.escape(x) for x in e[1:]] for e in es]) for h, es in sections]
    markup = render(escaped, anchor).replace("\n", "<br>\n")
    src.with_suffix(".html").write_text(markup + "\n")
    copy(markup, render(sections, number))
    print(src.with_suffix(".html"))


if __name__ == "__main__":
    main()
