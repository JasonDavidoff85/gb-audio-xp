#!/usr/bin/env python
"""
Extracts a tileset unsigned char array from a C source file and prints it
as RGBDS `db` lines (16 bytes per line) suitable for pasting into a
Tileset:: label.
"""
import argparse
import re
import sys

ARRAY_RE = re.compile(
    r'unsigned\s+char\s+(\w*tileset\w*)\s*(\[[^\]]*\])?\s*=\s*\{(.*?)\}\s*;',
    re.DOTALL | re.IGNORECASE,
)

FALLBACK_RE = re.compile(
    r'unsigned\s+char\s+(\w+)\s*(\[[^\]]*\])?\s*=\s*\{(.*?)\}\s*;',
    re.DOTALL,
)

BYTE_RE = re.compile(r'0[xX][0-9A-Fa-f]+|\d+')


def find_array_body(text):
    match = ARRAY_RE.search(text)
    if match is None:
        match = FALLBACK_RE.search(text)
    if match is None:
        raise ValueError("no unsigned char array found")
    return match.group(1), match.group(3)


def parse_bytes(body):
    return [int(tok, 0) for tok in BYTE_RE.findall(body)]


def format_db_lines(values, per_line=16):
    lines = []
    for i in range(0, len(values), per_line):
        chunk = values[i:i + per_line]
        hex_values = ",".join(f"${v:02X}" for v in chunk)
        lines.append(f"    db {hex_values}")
    return lines


def parse_argv(argv):
    p = argparse.ArgumentParser()
    p.add_argument("infile")
    return p.parse_args(argv[1:])


def main(argv=None):
    args = parse_argv(argv or sys.argv)
    with open(args.infile) as infp:
        text = infp.read()
    name, body = find_array_body(text)
    values = parse_bytes(body)
    for line in format_db_lines(values):
        print(line)


if __name__ == '__main__':
    main()
