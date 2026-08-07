"""
Render a top-down orthographic PNG snapshot of every .scad file in scad/.

Run:  python render_top_views.py [--scad-dir DIR] [--out DIR] [--openscad PATH]
"""

import argparse
import os
import subprocess
import sys

OPENSCAD_EXE = r"C:\Program Files (x86)\OpenSCAD\openscad.com"
IMG_SIZE = "300,300"
CAMERA = "1.43,1.43,0,0,180,0,7.8"

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SCAD_DIR = os.path.normpath(os.path.join(THIS_DIR, "..", "scad"))


def render(openscad_exe, scad_path, out_path):
    args = [
        openscad_exe,
        "-o", out_path,
        f"--imgsize={IMG_SIZE}",
        f"--camera={CAMERA}",
        "--autocenter",
        "--projection=ortho",
        scad_path,
    ]
    result = subprocess.run(args, capture_output=True, text=True)
    return result.returncode == 0, result.stderr.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scad-dir", default=DEFAULT_SCAD_DIR, help="directory of .scad files")
    parser.add_argument("--out", default=None, help="output directory for PNGs (default: <scad-dir>/png)")
    parser.add_argument("--openscad", default=OPENSCAD_EXE, help="path to openscad executable")
    args = parser.parse_args()

    scad_dir = os.path.abspath(args.scad_dir)
    out_dir = os.path.abspath(args.out) if args.out else os.path.join(scad_dir, "png")
    os.makedirs(out_dir, exist_ok=True)

    scad_files = sorted(f for f in os.listdir(scad_dir) if f.lower().endswith(".scad"))
    if not scad_files:
        print(f"No .scad files found in {scad_dir}")
        sys.exit(1)

    failures = []
    for filename in scad_files:
        scad_path = os.path.join(scad_dir, filename)
        stem = os.path.splitext(filename)[0]
        out_path = os.path.join(out_dir, f"{stem}_top.png")

        ok, err = render(args.openscad, scad_path, out_path)
        status = "OK" if ok else "FAILED"
        print(f"[{status}] {filename} -> {os.path.relpath(out_path, scad_dir)}")
        if not ok:
            failures.append((filename, err))

    if failures:
        print(f"\n{len(failures)} file(s) failed:")
        for filename, err in failures:
            print(f"  {filename}: {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
