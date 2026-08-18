"""
generate_3mf.py
Iterates every scad/element*.scad file (sub_*.scad shared-include files are
never matched by that glob, so they're skipped automatically) and, for any
that don't already have a matching 3mf/<stem>.3mf, builds it by running
scad_to_3mf.py and generates its top/bottom preview PNGs via
render_top_views.py.

Usage:
    py -3.12 py_files/generate_3mf.py [--quiet]
"""

import subprocess
import sys
from pathlib import Path

THIS_DIR    = Path(__file__).parent
BASE        = THIS_DIR.parent
SCAD_DIR    = BASE / "scad"
OUT_DIR     = BASE / "3mf"
SCAD_TO_3MF = THIS_DIR / "scad_to_3mf.py"
RENDER_TOP  = THIS_DIR / "render_top_views.py"


def supports_quiet(script_path):
    """Whether script_path's own source defines a --quiet flag."""
    return "--quiet" in script_path.read_text(encoding="utf-8")


def main():
    quiet = "--quiet" in sys.argv or "-q" in sys.argv

    OUT_DIR.mkdir(exist_ok=True)

    scad_files = sorted(
        p for p in SCAD_DIR.glob("element*.scad")
        if not p.name.startswith("sub_")
    )
    if not scad_files:
        print(f"No element*.scad files found in {SCAD_DIR}")
        sys.exit(1)

    pass_quiet_to_3mf    = quiet and supports_quiet(SCAD_TO_3MF)
    pass_quiet_to_render = quiet and supports_quiet(RENDER_TOP)

    built = 0
    skipped = 0
    failed = 0

    for scad_path in scad_files:
        stem    = scad_path.stem
        out_3mf = OUT_DIR / f"{stem}.3mf"

        if out_3mf.exists():
            if not quiet:
                print(f"Skipping {stem}: {out_3mf.relative_to(BASE)} already exists")
            skipped += 1
            continue

        print(f"Building {stem}  {scad_path.relative_to(BASE)} -> {out_3mf.relative_to(BASE)}")

        cmd = [sys.executable, str(SCAD_TO_3MF.relative_to(BASE)),
               str(scad_path.relative_to(BASE)), str(out_3mf.relative_to(BASE))]
        if pass_quiet_to_3mf:
            cmd.append("--quiet")
        result = subprocess.run(cmd, cwd=str(BASE))
        if result.returncode != 0:
            print(f"  FAILED (exit {result.returncode})")
            failed += 1
            continue

        render_cmd = [sys.executable, str(RENDER_TOP.relative_to(BASE)),
                      str(scad_path.relative_to(BASE))]
        if pass_quiet_to_render:
            render_cmd.append("--quiet")
        render_result = subprocess.run(render_cmd, cwd=str(BASE))
        if render_result.returncode != 0:
            print(f"  Preview render FAILED (exit {render_result.returncode})")

        built += 1

    print(f"\nDone: {built} built, {skipped} skipped (already exists), {failed} failed")


if __name__ == "__main__":
    main()
