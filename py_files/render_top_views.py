"""
Render top-down and bottom-up orthographic PNG snapshots of .scad files in scad/.

Run:  python render_top_views.py [--scad-dir DIR] [--out DIR] [--openscad PATH]
      python render_top_views.py element10.scad [--out DIR]              # single file
"""

import argparse
import os
import subprocess
import sys

OPENSCAD_EXE = r"C:\Program Files (x86)\OpenSCAD\openscad.com"
#OPENSCAD_EXE = r"C:\Program Files\OpenSCAD\openscad.com"
IMG_SIZE = "300,300"
CAMERA_T = "1.435,1.435,0,0,0,0,7.55"
CAMERA_B = "1.435,1.435,0,0,180,0,7.55"

VIEWS = [
    ("top", CAMERA_T),
    ("bottom", CAMERA_B),
]

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SCAD_DIR = os.path.normpath(os.path.join(THIS_DIR, "..", "scad"))


def render(openscad_exe, scad_path, out_path, camera):
    args = [
        openscad_exe,
        "-o", out_path,
        f"--imgsize={IMG_SIZE}",
        f"--camera={camera}",
        "--autocenter",
        "--projection=ortho",
        scad_path,
    ]
    result = subprocess.run(args, capture_output=True, text=True)
    return result.returncode == 0, result.stderr.strip()


def render_views(openscad_exe, scad_path, out_dir):
    """Render both top and bottom views of a single .scad file into out_dir.
    Returns a list of (view, ok, err, out_path) tuples.
    """
    stem = os.path.splitext(os.path.basename(scad_path))[0]
    results = []
    for view, camera in VIEWS:
        out_path = os.path.join(out_dir, f"{stem}_{view}.png")
        ok, err = render(openscad_exe, scad_path, out_path, camera)
        results.append((view, ok, err, out_path))
    return results


def resolve_scad_path(filename, scad_dir):
    """Resolve filename as given (relative to cwd) or inside scad_dir."""
    if os.path.isfile(filename):
        return os.path.abspath(filename)
    candidate = os.path.join(scad_dir, filename)
    if os.path.isfile(candidate):
        return candidate
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("filename", nargs="?", default=None,
                        help="single .scad file to render (default: render every element*.scad file in --scad-dir)")
    parser.add_argument("--scad-dir", default=DEFAULT_SCAD_DIR, help="directory of .scad files")
    parser.add_argument("--out", default=None, help="output directory for PNGs (default: <scad-dir>/png)")
    parser.add_argument("--openscad", default=OPENSCAD_EXE, help="path to openscad executable")
    args = parser.parse_args()

    scad_dir = os.path.abspath(args.scad_dir)
    out_dir = os.path.abspath(args.out) if args.out else os.path.join(scad_dir, "png")
    os.makedirs(out_dir, exist_ok=True)

    if args.filename:
        scad_path = resolve_scad_path(args.filename, scad_dir)
        if not scad_path:
            print(f"File not found: {args.filename}")
            sys.exit(1)
        scad_paths = [scad_path]
    else:
        scad_files = sorted(
            f for f in os.listdir(scad_dir)
            if f.lower().endswith(".scad") and f.lower().startswith("element")
        )
        if not scad_files:
            print(f"No .scad files found in {scad_dir}")
            sys.exit(1)
        scad_paths = [os.path.join(scad_dir, f) for f in scad_files]

    failures = []
    for scad_path in scad_paths:
        filename = os.path.basename(scad_path)
        for view, ok, err, out_path in render_views(args.openscad, scad_path, out_dir):
            status = "OK" if ok else "FAILED"
            print(f"[{status}] {filename} ({view}) -> {os.path.relpath(out_path, scad_dir)}")
            if not ok:
                failures.append((filename, view, err))

    if failures:
        print(f"\n{len(failures)} render(s) failed:")
        for filename, view, err in failures:
            print(f"  {filename} ({view}): {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
