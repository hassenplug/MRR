"""
scad_to_3mf.py
Converts a colored OpenSCAD file into a Bambu Studio-compatible multi-color 3MF.
Each color() call in the SCAD file becomes a separate part assigned to its own filament slot.

Usage:
    py -3.12 scad_to_3mf.py <input.scad> [output.3mf]
"""

import os
import re
import struct
import zipfile
import subprocess
import tempfile
import sys
from pathlib import Path

OPENSCAD = "C:/Program Files/OpenSCAD/openscad.exe"


def find_colors(scad_path):
    """Return unique color name strings from color() calls, in order of appearance."""
    text = Path(scad_path).read_text(encoding="utf-8")
    colors = re.findall(r'color\s*\(\s*["\']([^"\']+)["\']', text)
    return list(dict.fromkeys(colors))  # deduplicate, preserve order


def make_filter_scad(scad_abs, target_color):
    """
    Return SCAD source that redefines color() to only render the target color,
    then includes the original file.
    """
    escaped = scad_abs.replace("\\", "/")
    return f"""module color(c, alpha=1.0) {{
    if (c == "{target_color}") children();
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
    Build a Bambu Studio-compatible 3MF.
    parts: list of (color_name, triangles)
          triangles: list of (v0, v1, v2) where each vi is (x, y, z)
    """

    def object_xml(obj_id, color_name, triangles):
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

    objects = "\n".join(
        object_xml(i, name, tris) for i, (name, tris) in enumerate(parts, 1)
    )
    items = "\n".join(
        f'    <item objectid="{i}" printable="1"/>' for i in range(1, len(parts) + 1)
    )

    model_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US"
    xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
  <resources>
{objects}
  </resources>
  <build>
{items}
  </build>
</model>"""

    # Bambu model_settings.config: assigns each part to a filament/extruder slot
    obj_configs = []
    for i, (name, _) in enumerate(parts, 1):
        obj_configs.append(
            f'  <object id="{i}" instances_count="1">\n'
            f'    <metadata key="name" value="{name}"/>\n'
            f'    <part id="{i}" subtype="normal_part">\n'
            f'      <metadata key="name" value="{name}"/>\n'
            f'      <metadata key="extruder" value="{i}"/>\n'
            f'    </part>\n'
            f'  </object>'
        )
    settings_xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n'
        + "\n".join(obj_configs)
        + "\n</config>"
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


def main():
    if len(sys.argv) < 2:
        print("Usage: py -3.12 scad_to_3mf.py <input.scad> [output.3mf]")
        sys.exit(1)

    scad_path = Path(sys.argv[1]).resolve()
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else scad_path.with_suffix(".3mf")

    print(f"Input:  {scad_path}")
    print(f"Output: {out_path}")

    colors = find_colors(scad_path)
    if not colors:
        print("No color() calls found. Exporting as single-color 3MF.")
        colors = ["default"]

    print(f"Colors found: {colors}\n")

    parts = []
    with tempfile.TemporaryDirectory() as tmpdir:
        for color in colors:
            stl_path = Path(tmpdir) / f"{color}.stl"
            print(f"Rendering '{color}' ...", end=" ", flush=True)

            if color == "default":
                scad_src = scad_path.read_text(encoding="utf-8")
            else:
                scad_src = make_filter_scad(str(scad_path), color)

            ok = export_stl(scad_src, stl_path)
            if not ok or not stl_path.exists():
                print("FAILED (skipped)")
                continue

            triangles = read_binary_stl(stl_path)
            if not triangles:
                print(f"0 triangles (skipped)")
                continue

            print(f"{len(triangles):,} triangles")
            parts.append((color, triangles))

    if not parts:
        print("No geometry produced. Check your SCAD file.")
        sys.exit(1)

    print(f"\nBuilding 3MF with {len(parts)} part(s) ...")
    build_3mf(parts, out_path)
    size_kb = out_path.stat().st_size / 1024
    print(f"Done: {out_path}  ({size_kb:.1f} KB)")
    print()
    print("In Bambu Studio: File > Open > select the .3mf")
    print(f"Each part will be on its own filament slot (1={parts[0][0]}, etc.)")


if __name__ == "__main__":
    main()
