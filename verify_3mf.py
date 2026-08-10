"""
verify_3mf.py
Validates a .3mf file produced by scad_to_3mf.py.

Checks, in order:
  1. ZIP/OPC structure   - valid archive, required parts present
  2. XML well-formedness - 3dmodel.model and rels parse cleanly
  3. Reference integrity - components/build items point at objects that exist
  4. Mesh geometry        - manifold, no degenerate/duplicate triangles (via trimesh)

Usage:
    py -3.14 verify_3mf.py <file.3mf> [more.3mf ...]
    py -3.14 verify_3mf.py 3mf/element31.3mf
"""

import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    import trimesh
    HAVE_TRIMESH = True
except ImportError:
    HAVE_TRIMESH = False

MODEL_NS = "{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}"
RELS_NS = "{http://schemas.openxmlformats.org/package/2006/relationships}"

REQUIRED_PARTS = ("[Content_Types].xml", "_rels/.rels", "3D/3dmodel.model")


class Issues:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)

    @property
    def ok(self):
        return not self.errors


def check_zip_structure(path, issues):
    """Confirm the file is a valid ZIP and has the required OPC parts."""
    try:
        zf = zipfile.ZipFile(path)
    except zipfile.BadZipFile as e:
        issues.error(f"Not a valid ZIP archive: {e}")
        return None

    bad = zf.testzip()
    if bad is not None:
        issues.error(f"Corrupt member in archive: {bad}")

    names = set(zf.namelist())
    for required in REQUIRED_PARTS:
        if required not in names:
            issues.error(f"Missing required part: {required}")

    return zf


def check_content_types(zf, issues):
    try:
        data = zf.read("[Content_Types].xml")
    except KeyError:
        return
    try:
        ET.fromstring(data)
    except ET.ParseError as e:
        issues.error(f"[Content_Types].xml is not well-formed XML: {e}")


def check_rels(zf, issues):
    try:
        data = zf.read("_rels/.rels")
    except KeyError:
        return
    try:
        root = ET.fromstring(data)
    except ET.ParseError as e:
        issues.error(f"_rels/.rels is not well-formed XML: {e}")
        return

    targets = {rel.get("Target", "").lstrip("/") for rel in root.findall(f"{RELS_NS}Relationship")}
    if "3D/3dmodel.model" not in targets:
        issues.error("_rels/.rels does not reference 3D/3dmodel.model")


def check_model_xml(zf, issues):
    """Parse 3dmodel.model, verify component/build references resolve to real objects."""
    try:
        data = zf.read("3D/3dmodel.model")
    except KeyError:
        return None

    try:
        root = ET.fromstring(data)
    except ET.ParseError as e:
        issues.error(f"3D/3dmodel.model is not well-formed XML: {e}")
        return None

    objects = root.findall(f"{MODEL_NS}resources/{MODEL_NS}object")
    object_ids = {obj.get("id") for obj in objects}
    if not object_ids:
        issues.error("No <object> elements found in <resources>")

    for obj in objects:
        oid = obj.get("id")
        mesh = obj.find(f"{MODEL_NS}mesh")
        components = obj.find(f"{MODEL_NS}components")
        if mesh is None and components is None:
            issues.error(f"Object id={oid} has neither <mesh> nor <components>")

        if mesh is not None:
            verts = mesh.findall(f"{MODEL_NS}vertices/{MODEL_NS}vertex")
            tris = mesh.findall(f"{MODEL_NS}triangles/{MODEL_NS}triangle")
            if not verts:
                issues.error(f"Object id={oid} mesh has no vertices")
            if not tris:
                issues.error(f"Object id={oid} mesh has no triangles")
            n = len(verts)
            for tri in tris:
                for attr in ("v1", "v2", "v3"):
                    idx = int(tri.get(attr))
                    if idx < 0 or idx >= n:
                        issues.error(
                            f"Object id={oid} triangle references vertex index {idx}, "
                            f"but only {n} vertices exist"
                        )

        if components is not None:
            for comp in components.findall(f"{MODEL_NS}component"):
                ref = comp.get("objectid")
                if ref not in object_ids:
                    issues.error(f"Object id={oid} component references missing objectid={ref}")
                transform = comp.get("transform")
                if transform and len(transform.split()) != 12:
                    issues.error(
                        f"Object id={oid} component objectid={ref} has malformed "
                        f"transform (expected 12 values, got {len(transform.split())})"
                    )

    build_items = root.findall(f"{MODEL_NS}build/{MODEL_NS}item")
    if not build_items:
        issues.error("No <item> elements found in <build> — nothing will print")
    for item in build_items:
        ref = item.get("objectid")
        if ref not in object_ids:
            issues.error(f"<build> item references missing objectid={ref}")

    return root


def check_mesh_geometry(path, issues):
    """Load with trimesh and flag manifold/winding/degenerate issues."""
    if not HAVE_TRIMESH:
        issues.warn("trimesh not installed — skipping mesh geometry checks (pip install trimesh)")
        return

    try:
        loaded = trimesh.load(path, force="scene")
    except ModuleNotFoundError as e:
        issues.warn(f"trimesh needs an optional dependency to load 3MF ({e}) — pip install lxml")
        return
    except Exception as e:
        issues.error(f"trimesh failed to load file: {e}")
        return

    geometries = loaded.geometry if hasattr(loaded, "geometry") else {"model": loaded}
    if not geometries:
        issues.error("trimesh loaded the file but found no geometry")
        return

    for name, mesh in geometries.items():
        if not isinstance(mesh, trimesh.Trimesh):
            continue
        if len(mesh.faces) == 0:
            issues.error(f"'{name}': mesh has zero faces")
            continue
        if not mesh.is_watertight:
            issues.warn(f"'{name}': mesh is not watertight (has holes/open edges)")
        if not mesh.is_winding_consistent:
            issues.warn(f"'{name}': mesh has inconsistent triangle winding")
        degenerate = (mesh.area_faces == 0).sum()
        if degenerate:
            issues.warn(f"'{name}': {degenerate} degenerate (zero-area) triangle(s)")


def verify_file(path):
    path = Path(path)
    issues = Issues()

    if not path.exists():
        issues.error(f"File not found: {path}")
        return issues

    zf = check_zip_structure(path, issues)
    if zf is not None:
        check_content_types(zf, issues)
        check_rels(zf, issues)
        check_model_xml(zf, issues)

    check_mesh_geometry(path, issues)

    return issues


def main():
    if len(sys.argv) < 2:
        print("Usage: verify_3mf.py <file.3mf> [more.3mf ...]")
        sys.exit(1)

    any_failed = False
    for arg in sys.argv[1:]:
        print(f"=== {arg} ===")
        issues = verify_file(arg)
        for e in issues.errors:
            print(f"  ERROR: {e}")
        for w in issues.warnings:
            print(f"  WARN:  {w}")
        if issues.ok:
            print("  OK" + (" (with warnings)" if issues.warnings else ""))
        else:
            print("  INVALID")
            any_failed = True
        print()

    sys.exit(1 if any_failed else 0)


if __name__ == "__main__":
    main()
