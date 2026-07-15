#!/usr/bin/env python3
"""
QA Coverage Audit — core logic.

Reads index.md and QA Coverage Matrices, detects when code has been shipped for
a requirement but QA coverage has not been executed. Called by audit-coverage.sh.

Environment:
    ROOT             — repo root directory
    INDEX            — path to index.md
    PDEQ_CONFIG      — path to pdeq.json
    PDEQ_ALLOW_DRIFT — if "1", demote all blocks to warnings

Output protocol (one line per result, written to stdout):
    CLEAR:<message>       — no issues found
    WARN:<message>        — non-blocking warning (NFR/AC uncovered)
    BLOCK:<message>       — blocking condition (FR code + non-terminal coverage)
    SUPPRESS:<message>    — condition that would block but for PDEQ_ALLOW_DRIFT
    FAIL:<message>        — fatal error (e.g. index not found)
    NO_DATA                — index has no product slugs

Exit codes:
    0 — all clear
    1 — at least one blocking condition
"""

import json
import os
import re
import sys


# Implements: FR-coverage-audit-code-signal, FR-coverage-audit-reads-index
def parse_index(index_path):
    """Parse index.md and return list of (slug, type, feature, code_col) tuples.

    Only FR-, NFR-, AC- slugs are returned. TC- slugs are skipped.
    Feature is derived from the Defined In path (filename stem).
    """
    with open(index_path) as f:
        content = f.read()

    lines = content.splitlines()
    table_start = None
    for i, line in enumerate(lines):
        if re.match(
            r'^\|\s*Slug\s*\|\s*Type\s*\|\s*Defined In\s*\|\s*Referenced In\s*\|\s*Code\s*\|',
            line,
        ):
            table_start = i + 2
            break

    if table_start is None:
        return []

    slugs = []
    for line in lines[table_start:]:
        s = line.strip()
        if not s.startswith("|"):
            continue
        if re.match(r'\|[-: ]+\|', s):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 5:
            continue
        slug = cells[0]
        slug_type = cells[1]
        if not re.match(r'^(FR|NFR|AC)-', slug):
            continue
        defined_in = cells[2]
        code_col = cells[4].strip()
        feature = os.path.splitext(os.path.basename(defined_in))[0] if defined_in else ""
        slugs.append((slug, slug_type, feature, code_col))

    return slugs


# Implements: FR-coverage-audit-prose-skip, FR-coverage-audit-reuse-parser
def parse_qa_matrix(qa_path):
    """Parse Coverage Matrix section from a QA markdown file.

    Returns list of (requirement_slug, tc_slugs, status) for rows that cite
    at least one TC slug. Rows without TC slugs (prose coverage) are skipped.
    """
    if not os.path.isfile(qa_path):
        return []

    with open(qa_path) as f:
        text = f.read()

    m = re.search(r'^##\s+Coverage Matrix\s*$', text, flags=re.MULTILINE)
    if not m:
        return []

    start = m.end()
    rest = text[start:]
    next_h = re.search(r'^#{1,2} ', rest, flags=re.MULTILINE)
    section = rest if not next_h else rest[: next_h.start()]

    rows = []
    for line in section.splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        if re.match(r'\|[-: ]+\|', s):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        if len(cells) < 3:
            continue
        status = cells[-1]
        req_slug_match = re.search(r'(FR|NFR|AC)-[a-z0-9-]+', cells[0])
        req_slug = req_slug_match.group(0) if req_slug_match else ""
        tcs = re.findall(r'TC-[a-z0-9-]+', " ".join(cells[:-1]))
        if not tcs:
            continue  # prose row, skip
        rows.append((req_slug, tcs, status))

    return rows


def parse_covers_coverage(qa_path):
    """Parse test case Covers fields from a QA markdown file.

    Returns set of requirement slugs found in `Covers:` lines of
    test case descriptions. These FRs/NFRs/ACs are covered by
    test cases even if they lack their own table row.
    """
    if not os.path.isfile(qa_path):
        return set()

    with open(qa_path) as f:
        text = f.read()

    result = set()
    for m in re.finditer(r'^- \*\*Covers\*\*: (.+)$', text, flags=re.MULTILINE):
        covers_line = m.group(1)
        slugs = re.findall(r'(?:FR|NFR|AC)-[a-z0-9-]+', covers_line)
        result.update(slugs)
    return result


def read_platforms(root, config_path):
    """Read platform list from pdeq.json, or probe qa/ directories."""
    platforms = []
    if os.path.isfile(config_path):
        with open(config_path) as f:
            cfg = json.load(f)
        platforms = cfg.get("platforms", [])
    else:
        qa_root = os.path.join(root, "qa")
        if os.path.isdir(qa_root):
            platforms = sorted(
                e for e in os.listdir(qa_root)
                if os.path.isdir(os.path.join(qa_root, e))
            )
    return platforms


# Implements: FR-coverage-audit-feature-grouping, FR-coverage-audit-status-check, FR-coverage-audit-block, FR-coverage-audit-terminal-statuses, FR-coverage-audit-nfr-ac-best-effort, FR-coverage-audit-escape-hatch
def main():
    root = os.environ.get("ROOT", "")
    index_path = os.environ.get("INDEX", os.path.join(root, "index.md"))
    config_path = os.environ.get("PDEQ_CONFIG", os.path.join(root, "pdeq.json"))
    allow_drift = os.environ.get("PDEQ_ALLOW_DRIFT", "") == "1"

    # Phase 1: Parse index.md
    try:
        slugs = parse_index(index_path)
    except FileNotFoundError:
        print("FAIL:index.md not found")
        return 1

    if not slugs:
        print("NO_DATA")
        return 0

    # Phase 2: Group FRs by feature, check code existence
    features_with_code = set()
    fr_by_feature = {}
    for slug, slug_type, feature, code_col in slugs:
        if slug_type == "FR":
            fr_by_feature.setdefault(feature, []).append(slug)
            if code_col:
                features_with_code.add(feature)

    if not features_with_code:
        print("CLEAR:No features with realizing code")
        return 0

    # Phase 3: Build per-FR code lookup (from Phase 1 index data)
    fr_has_code = {slug for slug, slug_type, _, code_col in slugs
                   if slug_type == "FR" and code_col}

    # Phase 4: Read platforms
    platforms = read_platforms(root, config_path)
    if not platforms:
        print("CLEAR:No platforms configured")
        return 0

    # Phase 5: Check coverage for each FR that has realizing code
    any_block = False
    checked_frs = 0
    fr_features = {slug: feat for slug, slug_type, feat, code_col in slugs
                   if slug_type == "FR"}

    for req_slug in sorted(fr_has_code):
        feat = fr_features.get(req_slug, "")
        if not feat:
            continue
        checked_frs += 1
        for platform in sorted(platforms):
            qa_path = os.path.join(root, "qa", platform, f"{feat}.md")
            if not os.path.isfile(qa_path):
                print(f"WARN:qa/{platform}/{feat}.md not found")
                continue

            rows = parse_qa_matrix(qa_path)
            covers_map = parse_covers_coverage(qa_path)

            # Check if FR has a table row or appears in a Covers field
            found = False
            for row_slug, tc_slugs, status in rows:
                if row_slug == req_slug:
                    found = True
                    is_terminal = status in ("Pass", "Fail", "Skip")
                    if not is_terminal:
                        msg = f"{feat}/{platform}: {req_slug} has code but coverage is '{status}'"
                        if allow_drift:
                            print(f"SUPPRESS:{msg}")
                        else:
                            print(f"BLOCK:{msg}")
                            any_block = True
                    break

            if not found and req_slug in covers_map:
                # Covered via test case Covers field — no separate table row needed
                found = True

            if not found:
                msg = f"{feat}/{platform}: {req_slug} has code but is missing from coverage matrix"
                if allow_drift:
                    print(f"SUPPRESS:{msg}")
                else:
                    print(f"BLOCK:{msg}")
                    any_block = True

            if not rows:
                if not found:
                    msg = f"{feat}/{platform}: {req_slug} has code but no QA coverage matrix"
                    if allow_drift:
                        print(f"SUPPRESS:{msg}")
                    else:
                        print(f"BLOCK:{msg}")
                        any_block = True

    # Also warn on NFRs and ACs with non-terminal coverage (warn-only)
    for feat in sorted(features_with_code):
        for platform in sorted(platforms):
            qa_path = os.path.join(root, "qa", platform, f"{feat}.md")
            if not os.path.isfile(qa_path):
                continue
            rows = parse_qa_matrix(qa_path)
            for req_slug, tc_slugs, status in rows:
                if req_slug.startswith(("NFR-", "AC-")):
                    is_terminal = status in ("Pass", "Fail", "Skip")
                    if not is_terminal:
                        msg = f"{feat}/{platform}: {req_slug} coverage is '{status}' (warn only)"
                        print(f"WARN:{msg}")

    if checked_frs == 0:
        print("CLEAR:No FRs with realizing code")
        return 0

    if any_block:
        return 1

    print("CLEAR:All FRs with code have terminal coverage")
    return 0


if __name__ == "__main__":
    sys.exit(main())
