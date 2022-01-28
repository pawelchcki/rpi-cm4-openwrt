#!/usr/bin/env python3
from curses import has_key
from email.mime import base
import sys, os

if (l := len(sys.argv) - 1) != 3:
    print(f"Wrond number of arguments expected: 3, got: {l}")
    sys.exit(1)

base = sys.argv[1]
src = sys.argv[2]
target = sys.argv[3]

with open(src) as s:
    keys_to_remove = { l.split("=")[0].strip() for l in s.readlines() }
    
with open(target, "wt") as target:
    with open(base) as base:
        for line in base.readlines():
            line_key = line.split("=")[0].strip()
            if line_key not in keys_to_remove:
                target.write(line)
    with open(src) as s:
        target.writelines(s.readlines())