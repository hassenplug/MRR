"""
build_all.py
Reads md/piece_count.md and builds 3MF files for all elements
where "Need to Print" > 0 and both top and bottom SCAD files exist.

Usage:
    py -3.12 build_all.py

    cd "c:/Users/hasse/OneDrive/Documents/git/MRR" && py -3.12 build_all.py

"""

import re
import subprocess
import sys
from pathlib import Path

BASE     = Path(__file__).parent
MD_FILE  = BASE / "md" / "piece_count.md"
OUT_DIR  = BASE / "3mf"
SCAD_DIR = BASE / "aaron"


def parse_element_id(cell):
    """Extract lowercase element ID from a markdown image cell.
    e.g. '![Element10](../Images/Element10.jpg)' -> 'element10'
    """
    m = re.search(r'!\[([^\]]+)\]', cell)
    return m.group(1).lower() if m else None


def main():
    OUT_DIR.mkdir(exist_ok=True)

    lines = MD_FILE.read_text(encoding="utf-8").splitlines()

    # Locate header row and column indices
    header_idx = None
    for i, line in enumerate(lines):
        if "Need to Print" in line:
            header_idx = i
            break

    if header_idx is None:
        print("Could not find header row in piece_count.md")
        sys.exit(1)

    headers = [c.strip() for c in lines[header_idx].split("|")]

    def col(name):
        for i, h in enumerate(headers):
            if name.lower() in h.lower():
                return i
        return None

    elem_col = col("Element")
    back_col = col("Back")
    need_col = col("Need to Print")

    if None in (elem_col, back_col, need_col):
        print(f"Could not locate required columns. Found: {headers}")
        sys.exit(1)

    data_lines = lines[header_idx + 2:]  # skip header + separator

    built = 0
    skipped_missing = 0
    skipped_no_need = 0

    for line in data_lines:
        if not line.strip() or not line.startswith("|"):
            continue

        cells = [c.strip() for c in line.split("|")]
        if len(cells) <= max(elem_col, back_col, need_col):
            continue

        need_str = cells[need_col].strip()
        try:
            need = int(need_str)
        except ValueError:
            skipped_no_need += 1
            continue
        if need <= 0:
            skipped_no_need += 1
            continue

        bottom_id = cells[elem_col].lower()             # Element column = top (plain text)
        top_id    = parse_element_id(cells[back_col])  # Back= column   = bottom layer (image link)

        if not top_id or not bottom_id:
            print(f"Skipping row (could not parse element IDs): {line.strip()}")
            skipped_missing += 1
            continue

        top_scad    = SCAD_DIR / f"{top_id}.scad"
        bottom_scad = SCAD_DIR / f"{bottom_id}.scad"
        out_3mf     = OUT_DIR  / f"{bottom_id}.3mf"

        if not top_scad.exists():
            print(f"Skipping {top_id}: {top_scad.relative_to(BASE)} not found")
            skipped_missing += 1
            continue
        if not bottom_scad.exists():
            print(f"Skipping {top_id}: {bottom_scad.relative_to(BASE)} not found")
            skipped_missing += 1
            continue

        print(f"\n{'='*60}")
        print(f"Building {top_id}  (need={need})")
        print(f"  Top:    {top_scad.relative_to(BASE)}")
        print(f"  Bottom: {bottom_scad.relative_to(BASE)}")
        print(f"  Output: {out_3mf.relative_to(BASE)}")
        print(f"{'='*60}")

        result = subprocess.run(
            ["py", "-3.12", "scad_to_3mf.py",
             str(top_scad.relative_to(BASE)),
             str(bottom_scad.relative_to(BASE)),
             str(out_3mf.relative_to(BASE))],
            cwd=str(BASE)
        )
        if result.returncode != 0:
            print(f"  FAILED (exit {result.returncode})")
        else:
            built += 1

    print(f"\nDone: {built} built, {skipped_missing} skipped (missing SCAD), "
          f"{skipped_no_need} skipped (no print need)")


if __name__ == "__main__":
    main()
