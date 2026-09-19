#!/usr/bin/env python3
"""Check that every top-level makefile compiles the same set of sources.

The makefiles differ only in their CUDA architectures and link flags, so a
source file added to one of them must be added to all of them. When one is
missed the build fails to link, but only for users of that makefile.

Also checks that every listed file exists.
"""
import re
import sys
from pathlib import Path

MAKEFILES = ["makefile", "makefile11", "makefile12", "makefile13"]
SOURCE = re.compile(r"\./([A-Za-z0-9_/]+\.(?:cu|cpp))\b")


def sources(path):
    text = path.read_text()
    # Only the source lists, not the rules below them.
    block = text.split("\nOBJS", 1)[0]
    return set(SOURCE.findall(block))


def main():
    root = Path(__file__).resolve().parents[2]
    lists = {}
    for name in MAKEFILES:
        path = root / name
        if path.exists():
            lists[name] = sources(path)
    if not lists:
        print("no makefiles found", file=sys.stderr)
        return 1

    union = set().union(*lists.values())
    failed = False
    for name, srcs in lists.items():
        missing = sorted(union - srcs)
        absent = sorted(s for s in srcs if not (root / s).exists())
        for s in missing:
            print(f"{name}: does not list {s}")
        for s in absent:
            print(f"{name}: lists {s}, which does not exist")
        failed |= bool(missing or absent)
        print(f"{name}: {len(srcs)} sources")
    if failed:
        print("makefile source lists differ; add the file to every makefile",
              file=sys.stderr)
        return 1
    print("all makefiles list the same sources")
    return 0


if __name__ == "__main__":
    sys.exit(main())
