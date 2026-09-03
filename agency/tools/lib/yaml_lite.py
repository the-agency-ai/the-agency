#!/usr/bin/env python3
"""Minimal, stdlib-only YAML reader for the agency.yaml subset.

Why: `config` (a core framework tool that `principal`, `agent-identity` and much
else depend on) parsed agency.yaml with PyYAML — a pip package. Framework tools
are supposed to be zero-pip / stdlib-only, and the PyYAML dependency made the
whole suite red on any host/container without it (#42 / flag #264). This reader
removes that dependency.

Supported (the agency.yaml subset):
  - block maps (nested, N-space indent)
  - block lists ("- item" scalars, and "- key: val" lists-of-maps)
  - scalars: double/single-quoted strings, unquoted strings, int, float,
    true/false (any case) -> bool, null/~/empty -> None
  - "# " comments (whole-line and inline when preceded by whitespace and not
    inside quotes)

NOT supported (absent from agency.yaml): anchors/aliases (&/*), flow style
({}/[]), block scalars (|, >), multiple documents, complex keys. Unsupported
constructs degrade to plain strings rather than raising.

The output structure matches yaml.safe_load(agency.yaml) for the shipped file
(validated against PyYAML in src/tests/tools/yaml-lite.bats), so `config`'s
`print(value)` output — including the Python dict repr other tools consume — is
byte-for-byte unchanged.
"""

import sys


def _strip_comment(line):
    """Remove an unquoted trailing '# ...' comment, respecting quotes."""
    in_single = in_double = False
    for i, ch in enumerate(line):
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == '#' and not in_single and not in_double:
            # A '#' starts a comment only at line start or after whitespace.
            if i == 0 or line[i - 1] in (' ', '\t'):
                return line[:i]
    return line


def _split_flow(inner):
    """Split a flow sequence body on commas, respecting quotes."""
    parts, buf = [], []
    in_single = in_double = False
    for ch in inner:
        if ch == "'" and not in_double:
            in_single = not in_single
            buf.append(ch)
        elif ch == '"' and not in_single:
            in_double = not in_double
            buf.append(ch)
        elif ch == ',' and not in_single and not in_double:
            parts.append(''.join(buf))
            buf = []
        else:
            buf.append(ch)
    if ''.join(buf).strip() != '' or parts:
        parts.append(''.join(buf))
    return [p for p in parts if p.strip() != '']


def _parse_scalar(s):
    s = s.strip()
    if s == '' or s == '~' or s in ('null', 'Null', 'NULL'):
        return None
    # Flow style (unquoted): [a, b] sequence and {k: v} mapping.
    if len(s) >= 2 and s[0] == '[' and s[-1] == ']':
        return [_parse_scalar(x) for x in _split_flow(s[1:-1].strip())]
    if len(s) >= 2 and s[0] == '{' and s[-1] == '}':
        d = {}
        for pair in _split_flow(s[1:-1].strip()):
            k, sep, v = pair.partition(':')
            if sep:
                d[_parse_key(k)] = _parse_scalar(v)
        return d
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        return s[1:-1]
    if len(s) >= 2 and s[0] == "'" and s[-1] == "'":
        return s[1:-1]
    low = s.lower()
    if low == 'true':
        return True
    if low == 'false':
        return False
    try:
        return int(s)
    except ValueError:
        pass
    try:
        return float(s)
    except ValueError:
        pass
    return s


def _indent_of(raw):
    return len(raw) - len(raw.lstrip(' '))


def _prepare(text):
    """-> list of (indent, content) for non-blank, non-comment lines."""
    out = []
    for raw in text.splitlines():
        raw = _strip_comment(raw).rstrip()
        if raw.strip() == '':
            continue
        out.append((_indent_of(raw), raw.strip()))
    return out


def _parse_block(lines, start, indent):
    """Parse the block of lines at column `indent`. Returns (value, next_idx)."""
    if start >= len(lines):
        return None, start
    first_indent, first_text = lines[start]
    if first_indent < indent:
        return None, start
    is_list = first_text.startswith('- ') or first_text == '-'

    if is_list:
        result = []
        i = start
        while i < len(lines):
            ind, text = lines[i]
            if ind < indent or not (text.startswith('- ') or text == '-'):
                break
            item_text = text[1:].lstrip()  # drop the leading '-'
            if item_text == '':
                # "-" then a nested block on following deeper lines.
                val, i = _parse_block(lines, i + 1, indent + 1)
                result.append(val)
            elif ':' in item_text and _looks_like_map_entry(item_text):
                # "- key: val" — a list item that is a MAP. The map's first key
                # sits at (indent + 2 + leading spaces after the dash); rewrite
                # this line to that effective indent and parse a map from here.
                dash_col = ind + (len(text) - len(text[1:].lstrip())) - 0
                eff_indent = ind + (len(text[1:]) - len(text[1:].lstrip())) + 1
                synthetic = [(eff_indent, item_text)]
                # Gather the continuation lines of this map (deeper-indented,
                # not starting a new '- ' item at this list's indent).
                j = i + 1
                while j < len(lines):
                    jind, jtext = lines[j]
                    if jind <= ind and (jtext.startswith('- ') or jtext == '-'):
                        break
                    if jind < eff_indent:
                        break
                    synthetic.append((jind, jtext))
                    j += 1
                val, _ = _parse_block(synthetic, 0, eff_indent)
                result.append(val)
                i = j
            else:
                result.append(_parse_scalar(item_text))
                i += 1
        return result, i

    # Otherwise: a MAP.
    result = {}
    i = start
    while i < len(lines):
        ind, text = lines[i]
        if ind < indent:
            break
        if ind > indent:
            # Shouldn't happen at a well-formed map head; skip defensively.
            i += 1
            continue
        if text.startswith('- ') or text == '-':
            break
        key, sep, rest = text.partition(':')
        if sep == '':
            # Not a map entry — treat the whole block as a scalar string.
            return _parse_scalar(text), i + 1
        key = _parse_key(key)
        rest = rest.strip()
        if rest == '':
            # Nested block value on the following deeper lines (or null).
            if i + 1 < len(lines) and lines[i + 1][0] > indent:
                val, i = _parse_block(lines, i + 1, lines[i + 1][0])
            else:
                val = None
                i += 1
            result[key] = val
        else:
            result[key] = _parse_scalar(rest)
            i += 1
    return result, i


def _looks_like_map_entry(text):
    """True if `text` is 'key: ...' (a mapping) vs a scalar containing ':'."""
    key, sep, _ = text.partition(':')
    if sep == '':
        return False
    # A quoted scalar like "http://x" wouldn't split cleanly; require the key to
    # be a bare token (no spaces, not quoted).
    k = key.strip()
    if k == '' or k[0] in ('"', "'"):
        return False
    return ' ' not in k


def _parse_key(k):
    k = k.strip()
    if len(k) >= 2 and k[0] == '"' and k[-1] == '"':
        return k[1:-1]
    if len(k) >= 2 and k[0] == "'" and k[-1] == "'":
        return k[1:-1]
    return k


def load(path):
    with open(path, 'r') as f:
        text = f.read()
    lines = _prepare(text)
    if not lines:
        return None
    value, _ = _parse_block(lines, 0, lines[0][0])
    return value


if __name__ == '__main__':
    # CLI: yaml_lite.py <file> [dotted.key.path]
    data = load(sys.argv[1])
    if len(sys.argv) > 2:
        cur = data
        for k in sys.argv[2].split('.'):
            if isinstance(cur, dict) and k in cur:
                cur = cur[k]
            else:
                print("not found: %s" % sys.argv[2], file=sys.stderr)
                sys.exit(1)
        if cur is not None:
            print(cur)
    else:
        print(data)
