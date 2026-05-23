#!/usr/bin/env python3
"""Convert two JPG images into a textured 3MF tile (3" x 3" x 1/8").

Usage:
    python jpg_to_3mf.py face_down.jpg face_up.jpg
    python jpg_to_3mf.py face_down.jpg face_up.jpg -o output.3mf
"""

import argparse
import zipfile
from pathlib import Path

MM_PER_IN = 25.4
W = 3.0 * MM_PER_IN    # 76.2 mm
L = 3.0 * MM_PER_IN    # 76.2 mm
H = 0.125 * MM_PER_IN  # 3.175 mm  (1/8")

SIDE_COLOR = "#808080"


def _content_types() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels"'
        ' ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="model"'
        ' ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
        '  <Default Extension="jpg" ContentType="image/jpeg"/>\n'
        '  <Default Extension="jpeg" ContentType="image/jpeg"/>\n'
        '</Types>'
    )


def _rels() -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Relationships'
        ' xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Target="/3D/3dmodel.model" Id="rel0"'
        ' Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
        '</Relationships>'
    )


def _model(up_path: str, dn_path: str) -> str:
    fv = lambda v: f"{v:.6f}"

    # v0-v3 bottom (z=0), v4-v7 top (z=H)
    verts = [
        (0, 0, 0), (W, 0, 0), (W, L, 0), (0, L, 0),
        (0, 0, H), (W, 0, H), (W, L, H), (0, L, H),
    ]

    # UV per vertex index within each texture2dgroup.
    # Convention: u=x/W, v=1-y/L  (v=0 top of image, v=1 bottom).
    # up_uvs: indices 0-3 correspond to v4-v7
    up_uvs = [(0.0, 1.0), (1.0, 1.0), (1.0, 0.0), (0.0, 0.0)]
    # dn_uvs: U is mirrored so the image reads correctly when tile is flipped over
    # indices 0-3 correspond to v0-v3
    dn_uvs = [(1.0, 1.0), (0.0, 1.0), (0.0, 0.0), (1.0, 0.0)]

    # (v1, v2, v3, pid, p1, p2, p3) — winding order gives outward normals
    # Resource IDs: 1=tex2d up, 2=tex2d down, 3=tex2dgroup up,
    #               4=tex2dgroup down, 5=colorgroup sides, 6=object
    tris = [
        # Top face, normal +Z
        (4, 5, 6, 3, 0, 1, 2),
        (4, 6, 7, 3, 0, 2, 3),
        # Bottom face, normal -Z
        (0, 3, 1, 4, 0, 3, 1),
        (1, 3, 2, 4, 1, 3, 2),
        # Front (y=0), normal -Y
        (0, 1, 5, 5, 0, 0, 0), (0, 5, 4, 5, 0, 0, 0),
        # Right (x=W), normal +X
        (1, 2, 6, 5, 0, 0, 0), (1, 6, 5, 5, 0, 0, 0),
        # Back (y=L), normal +Y
        (2, 3, 7, 5, 0, 0, 0), (2, 7, 6, 5, 0, 0, 0),
        # Left (x=0), normal -X
        (3, 0, 4, 5, 0, 0, 0), (3, 4, 7, 5, 0, 0, 0),
    ]

    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<model unit="millimeter" xml:lang="en-US"'
        ' xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02"'
        ' xmlns:m="http://schemas.microsoft.com/3dmanufacturing/material/2015/02"'
        ' requiredextensions="m">',
        "  <resources>",
        f'    <m:texture2d id="1" path="{up_path}" contenttype="image/jpeg"'
        ' tilestyleu="clamp" tilestylev="clamp" filter="linear"/>',
        f'    <m:texture2d id="2" path="{dn_path}" contenttype="image/jpeg"'
        ' tilestyleu="clamp" tilestylev="clamp" filter="linear"/>',
        '    <m:texture2dgroup id="3" texid="1">',
    ]
    for u, v in up_uvs:
        lines.append(f'      <m:tex2coord u="{fv(u)}" v="{fv(v)}"/>')
    lines += ["    </m:texture2dgroup>", '    <m:texture2dgroup id="4" texid="2">']
    for u, v in dn_uvs:
        lines.append(f'      <m:tex2coord u="{fv(u)}" v="{fv(v)}"/>')
    lines += [
        "    </m:texture2dgroup>",
        '    <m:colorgroup id="5">',
        f'      <m:color color="{SIDE_COLOR}"/>',
        "    </m:colorgroup>",
        '    <object id="6" type="model">',
        "      <mesh>",
        "        <vertices>",
    ]
    for x, y, z in verts:
        lines.append(f'          <vertex x="{fv(x)}" y="{fv(y)}" z="{fv(z)}"/>')
    lines.append("        </vertices>")
    lines.append("        <triangles>")
    for v1, v2, v3, pid, p1, p2, p3 in tris:
        lines.append(
            f'          <triangle v1="{v1}" v2="{v2}" v3="{v3}"'
            f' pid="{pid}" p1="{p1}" p2="{p2}" p3="{p3}"/>'
        )
    lines += [
        "        </triangles>",
        "      </mesh>",
        "    </object>",
        "  </resources>",
        "  <build>",
        '    <item objectid="6"/>',
        "  </build>",
        "</model>",
    ]
    return "\n".join(lines)


def convert(face_down: str, face_up: str, output: str) -> None:
    face_down = Path(face_down)
    face_up = Path(face_up)
    output = Path(output)

    for p in (face_down, face_up):
        if not p.exists():
            raise FileNotFoundError(p)

    up_tex = "/3D/Textures/face_up.jpg"
    dn_tex = "/3D/Textures/face_down.jpg"

    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", _content_types())
        zf.writestr("_rels/.rels", _rels())
        zf.writestr("3D/3dmodel.model", _model(up_tex, dn_tex))
        zf.write(face_up, "3D/Textures/face_up.jpg")
        zf.write(face_down, "3D/Textures/face_down.jpg")

    print(f"Written: {output}")


def main() -> None:
    ap = argparse.ArgumentParser(
        description='Convert two JPGs into a textured 3MF tile (3" x 3" x 1/8").'
    )
    ap.add_argument("face_down", help="JPG for the bottom (face-down) surface")
    ap.add_argument("face_up", help="JPG for the top (face-up) surface")
    ap.add_argument(
        "-o", "--output",
        help="Output .3mf path (default: <face_up_stem>.3mf in current directory)",
    )
    args = ap.parse_args()

    out = args.output or (Path(args.face_up).stem + ".3mf")
    convert(args.face_down, args.face_up, out)


if __name__ == "__main__":
    main()
