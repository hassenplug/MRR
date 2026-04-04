import pymeshlab
import os
import glob

robots_dir = os.path.dirname(os.path.abspath(__file__))
stl_files = glob.glob(os.path.join(robots_dir, "*.stl"))

TARGET_RATIO = 0.1  # keep 10% of triangles

for stl_path in stl_files:
    fname = os.path.basename(stl_path)
    original_size = os.path.getsize(stl_path) / 1024 / 1024

    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(stl_path)

    original_faces = ms.current_mesh().face_number()
    target_faces = max(int(original_faces * TARGET_RATIO), 1000)

    print(f"{fname}: {original_size:.1f}MB, {original_faces:,} triangles -> targeting {target_faces:,}")

    ms.meshing_decimation_quadric_edge_collapse(
        targetfacenum=target_faces,
        qualitythr=0.3,
        preservenormal=True,
        preservetopology=True,
        planarquadric=True,
    )

    ms.save_current_mesh(stl_path, save_face_color=False)

    new_size = os.path.getsize(stl_path) / 1024 / 1024
    new_faces = ms.current_mesh().face_number()
    print(f"  -> {new_size:.1f}MB, {new_faces:,} triangles  ({new_size/original_size*100:.0f}% of original)\n")

print("Done!")
