"""
scad_to_3mf.py
Converts one or two colored OpenSCAD files into a Bambu Studio-compatible multi-color 3MF.
Each color() call becomes a separate part assigned to its own filament slot.
All parts are sub-volumes of a single parent object so Bambu keeps them in the same
coordinate system (no independent drop-to-plate per color).

Usage:
    py -3.12 py_files/scad_to_3mf.py <input.scad> [output.3mf]
    py -3.12 py_files/scad_to_3mf.py <top.scad> <bottom.scad> <output.3mf>

Two-file mode: bottom is rendered at z=0, its height is measured, then top geometry
is shifted up by that amount so the two layers sit flush against each other. The
bottom piece is always flipped face down so its own top-surface pattern ends up on
the bottom-facing side of the combined stack instead of sandwiched in the middle.

Single-file mode: the lone file is treated the same as a bottom piece and flipped
face down by default, since single-file runs are typically used to print just the
bottom half of a two-piece tile on its own. If the input filename contains "-u" or
"-U" (marking it as already upright), it's kept face up instead, and that marker
is stripped from the output 3mf filename.
"""

import os
import re
import struct
from unittest import result
import zipfile
import subprocess
import tempfile
import sys
from pathlib import Path

OPENSCAD = "C:/Program Files/OpenSCAD/openscad.exe"
#OPENSCAD = "C:/Program Files (x86)/OpenSCAD/openscad.exe"
QUIET = False


def vprint(*args, **kwargs):
    if not QUIET:
        print(*args, **kwargs)


def find_colors(scad_path):
    """
    Return list of (label, scad_expr) for each unique color used in the design, in
    order of first discovery. Handles string colors — color("name") — and array
    colors — color([r,g,b]) — plus every indirection pattern this codebase actually
    uses, since color() is rarely called with a literal directly:
      - color(some_var) where some_var = "name"; is a plain top-level assignment
        somewhere in the merged file set (e.g. sub_belts.scad's color(roller_color),
        set per-tile by each element*.scad).
      - a colors-array literal (e.g. plate_colors = ["red", undef, ...]) whose
        string elements get threaded one slot at a time into a shared module's
        color(c) (e.g. frame_with_id()) — never itself a literal color() argument.
      - "color-forwarding" modules — module NAME(c) { ... color(c) ... } — called
        elsewhere as NAME("name") or NAME(some_var) (e.g. sub_innergears.scad's
        gear(c)/gear_bore(c), called as gear("darkred")).
    False positives here are harmless: make_filter_scad()'s runtime `if (c == expr)`
    check is authoritative, so a wrongly-guessed candidate just renders 0 triangles
    and gets skipped — it can never produce a wrong color, only a wasted render.
    Follows include<>/use<> statements recursively — shared modules define their
    color() calls (and color-forwarding modules) in the included file, not in the
    file passed on the command line.
    label   : safe identifier used in filenames and part names
    scad_expr: the raw expression to compare against in the filter (e.g. '"black"'
               or '[0.72, 0.22, 0.13]')
    """
    color_pattern      = re.compile(r'color\s*\(\s*(?:"([^"\']+)"|\'([^"\']+)\'|(\[[^\]]+\])|(\w+))')
    include_pattern    = re.compile(r'^\s*(?:include|use)\s*<([^>]+)>', re.MULTILINE)
    assign_pattern     = re.compile(r'^\s*(\w+)\s*=\s*([^;]+);', re.MULTILINE)
    array_pattern      = re.compile(r'\[[^\[\]]*\]')
    string_pattern     = re.compile(r'"([^"\']+)"|\'([^"\']+)\'')
    module_def_pattern = re.compile(r'module\s+(\w+)\s*\(\s*(\w+)')

    visited = set()
    chunks  = []

    def strip_comments(text):
        text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
        return re.sub(r'//[^\n]*', '', text)

    def collect(path):
        path = path.resolve()
        if path in visited or not path.exists():
            return
        visited.add(path)
        text = strip_comments(path.read_text(encoding="utf-8"))
        chunks.append(text)
        for m in include_pattern.finditer(text):
            collect(path.parent / m.group(1))

    collect(Path(scad_path))
    merged = "\n".join(chunks)

    seen = {}

    def add_string(name):
        if name not in seen:
            seen[name] = f'"{name}"'

    def add_array(raw):
        if not string_pattern.search(raw):   # numeric rgb(a) array, not a colors[] list
            nums  = re.findall(r'[\d.]+', raw)
            label = "rgb_" + "_".join(nums)
            if label not in seen:
                seen[label] = raw

    variables = {m.group(1): m.group(2).strip() for m in assign_pattern.finditer(merged)}

    def resolve_identifier(name):
        sm = string_pattern.match(variables.get(name, ""))
        if sm:
            add_string(sm.group(1) or sm.group(2))

    # Direct color() calls: literal strings/arrays, or a bare variable reference.
    for m in color_pattern.finditer(merged):
        if m.group(1):
            add_string(m.group(1))
        elif m.group(2):
            add_string(m.group(2))
        elif m.group(3):
            add_array(m.group(3))
        elif m.group(4):
            resolve_identifier(m.group(4))

    # Color names threaded through a colors[] array param (e.g. plate_colors)
    # into a shared module's per-slot color(c) — never a literal color() argument.
    for arr in array_pattern.finditer(merged):
        for sm in string_pattern.finditer(arr.group(0)):
            add_string(sm.group(1) or sm.group(2))

    # Color-forwarding modules: module NAME(c) { ... color(c) ... }. Once found,
    # resolve every call site's first argument the same way as a direct color() arg.
    for dm in module_def_pattern.finditer(merged):
        name, param = dm.group(1), dm.group(2)
        next_def  = module_def_pattern.search(merged, dm.end())
        body      = merged[dm.end(): next_def.start() if next_def else len(merged)]
        if not re.search(rf'color\s*\(\s*{re.escape(param)}\b', body):
            continue
        call_pattern = re.compile(rf'\b{re.escape(name)}\s*\(\s*(?:"([^"\']+)"|\'([^"\']+)\'|(\w+))')
        for cm in call_pattern.finditer(merged):
            if cm.group(1):
                add_string(cm.group(1))
            elif cm.group(2):
                add_string(cm.group(2))
            elif cm.group(3) and cm.group(3) != param:   # skip the definition header itself
                resolve_identifier(cm.group(3))

    return list(seen.items())   # [(label, expr), ...]


def make_filter_scad(scad_abs, color_expr):
    """
    Return SCAD source that redefines color() to only render geometry whose
    color argument matches color_expr (a raw SCAD expression such as '"black"'
    or '[0.72, 0.22, 0.13]'), then includes the original file.
    """
    escaped = scad_abs.replace("\\", "/")
    return f"""module color(c, alpha=1.0) {{
    if (c == {color_expr}) children();
}}
include <{escaped}>
"""


def export_stl(scad_source, stl_path):
    """Write scad_source to a temp file and render it to stl_path via OpenSCAD."""
    with tempfile.NamedTemporaryFile(suffix=".scad", mode="w",
                                     delete=False, encoding="utf-8") as f:
        f.write(scad_source)
        tmp_scad = f.name
    try:
        result = subprocess.run(
            [OPENSCAD, "--render", "-o", str(stl_path), tmp_scad],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode != 0:
            print(f"  OpenSCAD stderr: {result.stderr.strip()}", file=sys.stderr)
        return result.returncode == 0
    finally:
        os.unlink(tmp_scad)


def max_axis(triangles,axis=2):
    """Return the maximum coordinate across all triangle vertices."""
    return max(v[axis] for tri in triangles for v in tri)


def offset_z(triangles, z):
    """Return triangles with all Z coordinates shifted by z."""
    return tuple(
        ((v0[0], v0[1], v0[2] + z),
         (v1[0], v1[1], v1[2] + z),
         (v2[0], v2[1], v2[2] + z))
        for v0, v1, v2 in triangles
    )


def flip_bottom(parts):
    """Rotate 180° around the X axis for each part in a (name, triangles) list.
    Negates Y and Z, then translates back into positive space.
    Two reflections = proper rotation, winding preserved."""
    result = []
    mx = max(v[0] for _, triangles in parts for tri in triangles for v in tri) + min(v[0] for _, triangles in parts for tri in triangles for v in tri)
    my = max(v[1] for _, triangles in parts for tri in triangles for v in tri) + min(v[1] for _, triangles in parts for tri in triangles for v in tri)
    mz = max(v[2] for _, triangles in parts for tri in triangles for v in tri) + min(v[2] for _, triangles in parts for tri in triangles for v in tri)

    vprint(f"Input:  {mx:.6f} x {my:.6f} x {mz:.6f}")
    for name, triangles in parts:
        flipped = []
        for v0, v1, v2 in triangles:
            nv0 = (mx - v0[0],v0[1],mz - v0[2])
            nv1 = (mx - v1[0],v1[1],mz - v1[2])
            nv2 = (mx - v2[0],v2[1],mz - v2[2])
            flipped.append((nv0, nv1, nv2))
        result.append((name, flipped))
    return result


def read_binary_stl(stl_path):
    """Read a binary or ASCII STL; return list of (v0, v1, v2) vertex triples."""
    data = Path(stl_path).read_bytes()
    if len(data) < 84:
        return []

    # Detect ASCII STL (starts with "solid" as text)
    if data[:5].lower() == b"solid":
        text = data.decode("utf-8", errors="replace")
        triangles = []
        verts = []
        for line in text.splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                parts = line.split()
                verts.append((float(parts[1]), float(parts[2]), float(parts[3])))
                if len(verts) == 3:
                    triangles.append(tuple(verts))
                    verts = []
        return triangles

    # Binary STL: 80-byte header, 4-byte count, then 50-byte records
    triangles = []
    offset = 84
    while offset + 50 <= len(data):
        vals = struct.unpack_from("<9f", data, offset + 12)
        triangles.append((
            (vals[0], vals[1], vals[2]),
            (vals[3], vals[4], vals[5]),
            (vals[6], vals[7], vals[8]),
        ))
        offset += 50
    return triangles


def build_3mf(parts, output_path):
    """
    Build a Bambu Studio-compatible multi-color 3MF.
    parts: list of (color_name, triangles)
          triangles: list of (v0, v1, v2) where each vi is (x, y, z)

    Structure: one parent object (id=1) references sub-objects (id=2..N+1) as
    components.  All volumes share the same coordinate system so Bambu Studio
    won't independently drop each color to the build plate.
    """

    def mesh_object_xml(obj_id, color_name, triangles):
        rows_v = []
        rows_t = []
        for i, (v0, v1, v2) in enumerate(triangles):
            base = i * 3
            rows_v.append(f'          <vertex x="{v0[0]:.6f}" y="{v0[1]:.6f}" z="{v0[2]:.6f}"/>')
            rows_v.append(f'          <vertex x="{v1[0]:.6f}" y="{v1[1]:.6f}" z="{v1[2]:.6f}"/>')
            rows_v.append(f'          <vertex x="{v2[0]:.6f}" y="{v2[1]:.6f}" z="{v2[2]:.6f}"/>')
            rows_t.append(f'          <triangle v1="{base}" v2="{base+1}" v3="{base+2}"/>')
        return (
            f'    <object id="{obj_id}" type="model" name="{color_name}">\n'
            f'      <mesh>\n'
            f'        <vertices>\n'
            + "\n".join(rows_v) + "\n"
            f'        </vertices>\n'
            f'        <triangles>\n'
            + "\n".join(rows_t) + "\n"
            f'        </triangles>\n'
            f'      </mesh>\n'
            f'    </object>'
        )

    # Sub-objects start at id=2; parent wrapper is id=1
    sub_ids = list(range(2, len(parts) + 2))
    identity = "1 0 0 0 1 0 0 0 1 0 0 0"
    components = "\n".join(
        f'      <component objectid="{oid}" transform="{identity}"/>'
        for oid in sub_ids
    )
    parent_object = (
        f'    <object id="1" type="model" name="model">\n'
        f'      <components>\n'
        f'{components}\n'
        f'      </components>\n'
        f'    </object>'
    )
    sub_objects = "\n".join(
        mesh_object_xml(oid, name, tris)
        for oid, (name, tris) in zip(sub_ids, parts)
    )

    model_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<model unit="inch" xml:lang="en-US"
    xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
  <resources>
{sub_objects}
{parent_object}
  </resources>
  <build>
    <item objectid="1" printable="1"/>
  </build>
</model>"""

    # Bambu model_settings.config: one object entry with one part per color volume
    part_configs = []
    for slot, (oid, (name, _)) in enumerate(zip(sub_ids, parts), 1):
        part_configs.append(
            f'    <part id="{oid}" subtype="normal_part">\n'
            f'      <metadata key="name" value="{name}"/>\n'
            f'      <metadata key="extruder" value="{slot}"/>\n'
            f'    </part>'
        )
    settings_xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n'
        f'  <object id="1" instances_count="1">\n'
        f'    <metadata key="name" value="model"/>\n'
        + "\n".join(part_configs) + "\n"
        f'  </object>\n'
        '</config>'
    )

    content_types = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
        '  <Default Extension="config" ContentType="application/xml"/>\n'
        '</Types>'
    )
    rels = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Target="/3D/3dmodel.model" Id="rel0"'
        ' Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
        '</Relationships>'
    )

    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types)
        zf.writestr("_rels/.rels", rels)
        zf.writestr("3D/3dmodel.model", model_xml)
        zf.writestr("Metadata/model_settings.config", settings_xml)


def render_colors(scad_path, tmpdir, prefix, z_offset=0.0):
    """
    Render each color from scad_path into STLs inside tmpdir.
    Returns list of (label, triangles) and the max Z across all parts.
    If z_offset > 0, shifts all triangles up by that amount.
    """
    colors = find_colors(scad_path)
    if not colors:
        print("  No color() calls found — skipping.")
        return [], 0.0

    parts = []
    top_z = 0.0
    for label, expr in colors:
        stl_path = Path(tmpdir) / f"{prefix}_{label}.stl"
        vprint(f"  Rendering '{label}' ...", end=" ", flush=True)
        scad_src = make_filter_scad(str(scad_path), expr)
        ok = export_stl(scad_src, stl_path)
        if not ok or not stl_path.exists():
            print("FAILED (skipped)")
            continue
        triangles = read_binary_stl(stl_path)
        if not triangles:
            print("0 triangles (skipped)")
            continue
        if z_offset:
            triangles = offset_z(triangles, z_offset)
        z = max_axis(triangles, axis=2)
        if z > top_z:
            top_z = z
        vprint(f"{len(triangles):,} triangles")
        parts.append((f"{prefix}_{label}", triangles))
    return parts, top_z


def main():
    global QUIET
    if "--quiet" in sys.argv:
        QUIET = True
        sys.argv = [a for a in sys.argv if a != "--quiet"]

    two_file_mode = len(sys.argv) == 4

    if len(sys.argv) < 2 or len(sys.argv) > 4:
        print("Usage:")
        print("  py_files/scad_to_3mf.py <input.scad> [output.3mf]")
        print("  py_files/scad_to_3mf.py <top.scad> <bottom.scad> <output.3mf>")
        sys.exit(1)

    upright = False
    if two_file_mode:
        top_path    = Path(sys.argv[1]).resolve()
        bottom_path = Path(sys.argv[2]).resolve()
        out_path    = Path(sys.argv[3])
        vprint(f"Top:    {top_path}")
        vprint(f"Bottom: {bottom_path}")
        vprint(f"Output: {out_path}\n")
    else:
        scad_path = Path(sys.argv[1]).resolve()
        out_path  = Path(sys.argv[2]) if len(sys.argv) > 2 else scad_path.with_suffix(".3mf")
        upright = re.search(r'-u', scad_path.stem, re.IGNORECASE) is not None
        if upright:
            out_path = out_path.with_name(re.sub(r'-u', '', out_path.stem, flags=re.IGNORECASE) + out_path.suffix)
        vprint(f"Input:  {scad_path}")
        vprint(f"Output: {out_path}\n")

    parts = []
    with tempfile.TemporaryDirectory() as tmpdir:
        if two_file_mode:
            vprint("--- Bottom (flipped to face down) ---")
            bottom_parts, bottom_height = render_colors(bottom_path, tmpdir, "bottom")
            parts.extend(flip_bottom(bottom_parts))
            vprint(f"\nBottom height: {bottom_height:.6f} — top will be raised by this amount\n")

            vprint("--- Top ---")
            top_parts, _ = render_colors(top_path, tmpdir, "top", z_offset=bottom_height)
            parts.extend(top_parts)
        else:
            vprint("--- Rendering ---" if upright else "--- Rendering (flipped to face down) ---")
            file_parts, _ = render_colors(scad_path, tmpdir, "")
            if not upright:
                file_parts = flip_bottom(file_parts)
            # strip the leading underscore from the prefix-less labels
            parts.extend((name.lstrip("_"), tris) for name, tris in file_parts)

    if not parts:
        print("No geometry produced. Check your SCAD file.")
        sys.exit(1)

    vprint(f"\nBuilding 3MF with {len(parts)} part(s) ...")
    build_3mf(parts, out_path)
    size_kb = out_path.stat().st_size / 1024
    print(f"Done: {out_path}  ({size_kb:.1f} KB)")
    vprint()
    vprint("In Bambu Studio: File > Open > select the .3mf")
    vprint(f"Each part will be on its own filament slot (1={parts[0][0]}, etc.)")


if __name__ == "__main__":
    main()
