"""
Generate a 3x3x1/8" STL plate with:
  - A raised 1/16" border frame (7mm wide) around the perimeter
  - 32 cylindrical through-holes (flush top & bottom) for rivets
  - Center area is recessed by 1/16" relative to the border frame

Cross-section (side view):
   ___________         ___________
  |   border  |_______|  border   |   <- top of frame (TOTAL_H)
  |           |center |           |   <- center top (PLATE_D)
  |___________|_______|___________|   <- bottom (z=0)

Dimensions (mm):
  PLATE_W/H : 76.2 (3 inches)
  PLATE_D   : 3.175 (1/8 inch)
  BORDER_W  : 7.0  (border frame width, rivet centres at 3.5mm from edge)
  BORDER_H  : 1.5875 (1/16 inch, raised height above plate centre)
  TOTAL_H   : 4.7625 (full outer height)
  RIVET_R   : 1.8mm
"""

import struct, math, os

OUTPUT   = "c:/Users/hasse/OneDrive/Documents/git/MRR/stl/RivetPlate.stl"

PLATE_W  = 76.2
PLATE_H  = 76.2
PLATE_D  = 3.175
BORDER_W = 7.0
BORDER_H = 1.5875          # 1/16"
TOTAL_H  = PLATE_D + BORDER_H

RIVET_R      = 1.8
RIVET_INSET  = BORDER_W / 2   # 3.5mm from outer edge
RIVETS_PER_SIDE = 9
N_SEGS   = 24   # cylinder polygon segments
GRID     = 250  # grid resolution for faces with holes


# ── geometry helpers ──────────────────────────────────────────────────────────

def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])

def sub(a, b):
    return (a[0]-b[0], a[1]-b[1], a[2]-b[2])

def norm(v):
    l = math.sqrt(v[0]**2+v[1]**2+v[2]**2)
    return (v[0]/l, v[1]/l, v[2]/l) if l else (0,0,1)

def face_normal(v0, v1, v2):
    return norm(cross(sub(v1,v0), sub(v2,v0)))

def write_tri(f, v0, v1, v2):
    n = face_normal(v0, v1, v2)
    f.write(struct.pack('<3f', *n))
    f.write(struct.pack('<3f', *v0))
    f.write(struct.pack('<3f', *v1))
    f.write(struct.pack('<3f', *v2))
    f.write(struct.pack('<H', 0))


# ── rivet positions ───────────────────────────────────────────────────────────

def rivet_positions():
    n = RIVETS_PER_SIDE
    pos = []
    for i in range(n):
        t = i / (n - 1)
        x = RIVET_INSET + t * (PLATE_W - 2*RIVET_INSET)
        y = RIVET_INSET + t * (PLATE_H - 2*RIVET_INSET)
        pos.append((x, RIVET_INSET))            # bottom edge
        pos.append((x, PLATE_H - RIVET_INSET))  # top edge
        if 0 < i < n - 1:
            pos.append((RIVET_INSET, y))            # left edge
            pos.append((PLATE_W - RIVET_INSET, y))  # right edge
    return pos


# ── grid-based face with holes ────────────────────────────────────────────────

def grid_face(f, z, normal_up, w, h, holes, hole_r,
              skip_inner=None):
    """
    Triangulate a WxH rectangle face at height z using a GRID x GRID mesh.
    Cells whose centre falls inside a hole or inside skip_inner are omitted.
    normal_up=True  -> +Z normal (CCW from above)
    normal_up=False -> -Z normal (CCW from below)
    """
    dx = w / GRID
    dy = h / GRID
    r2 = hole_r ** 2
    count = 0
    for iy in range(GRID):
        for ix in range(GRID):
            cx = (ix + 0.5) * dx
            cy = (iy + 0.5) * dy
            # skip inner rect (recessed centre area on frame-top face)
            if skip_inner:
                x0i, y0i, x1i, y1i = skip_inner
                if x0i <= cx <= x1i and y0i <= cy <= y1i:
                    continue
            # skip if inside any hole
            if any((cx-hx)**2 + (cy-hy)**2 <= r2 for hx, hy in holes):
                continue
            x0 = ix * dx;  x1 = x0 + dx
            y0 = iy * dy;  y1 = y0 + dy
            if normal_up:
                write_tri(f, (x0,y0,z), (x1,y0,z), (x1,y1,z))
                write_tri(f, (x0,y0,z), (x1,y1,z), (x0,y1,z))
            else:
                write_tri(f, (x0,y0,z), (x1,y1,z), (x1,y0,z))
                write_tri(f, (x0,y0,z), (x0,y1,z), (x1,y1,z))
            count += 2
    return count


# ── cylinder (hole) walls ─────────────────────────────────────────────────────

def cylinder_walls(f, cx, cy, radius, z_bot, z_top, n_segs):
    """Inner surface of through-hole, normals pointing inward."""
    count = 0
    for j in range(n_segs):
        a1 = (j     / n_segs) * 2 * math.pi
        a2 = ((j+1) / n_segs) * 2 * math.pi
        x1 = cx + radius * math.cos(a1);  y1 = cy + radius * math.sin(a1)
        x2 = cx + radius * math.cos(a2);  y2 = cy + radius * math.sin(a2)
        # normals face inward → wind CW when viewed from outside
        write_tri(f, (x2,y2,z_bot), (x1,y1,z_top), (x2,y2,z_top))
        write_tri(f, (x2,y2,z_bot), (x1,y1,z_bot), (x1,y1,z_top))
        count += 2
    return count


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    rivets = rivet_positions()
    print(f"Rivets: {len(rivets)}")

    # Inner rect bounds (recessed centre)
    ix0 = BORDER_W;   ix1 = PLATE_W - BORDER_W
    iy0 = BORDER_W;   iy1 = PLATE_H - BORDER_W

    # Pre-count triangles for the header (write in two passes)
    # Pass 1: count only
    # For simplicity, use a large upper-bound write approach with a tmp buffer
    # — actually we just write to file directly, then patch the header.

    with open(OUTPUT, 'wb') as f:
        # Write placeholder header (we'll patch tri count after)
        f.write(b'RivetPlate 3x3x1/8in raised border flush rivets'.ljust(80, b'\x00'))
        f.write(struct.pack('<I', 0))   # placeholder tri count

        total = 0

        # 1. BOTTOM face (z=0): full plate with rivet holes, normal -Z
        print("Writing bottom face...")
        total += grid_face(f, 0, False, PLATE_W, PLATE_H, rivets, RIVET_R)

        # 2. FRAME TOP face (z=TOTAL_H): border ring with rivet holes, normal +Z
        print("Writing frame top face...")
        total += grid_face(f, TOTAL_H, True, PLATE_W, PLATE_H, rivets, RIVET_R,
                           skip_inner=(ix0, iy0, ix1, iy1))

        # 3. CENTRE TOP face (z=PLATE_D): inner rect, no holes, normal +Z
        print("Writing centre top face...")
        write_tri(f, (ix0,iy0,PLATE_D), (ix1,iy0,PLATE_D), (ix1,iy1,PLATE_D))
        write_tri(f, (ix0,iy0,PLATE_D), (ix1,iy1,PLATE_D), (ix0,iy1,PLATE_D))
        total += 2

        # 4. OUTER WALLS (full height 0 to TOTAL_H)
        print("Writing outer walls...")
        # Front (y=0, normal -Y)
        write_tri(f, (0,0,0),        (PLATE_W,0,TOTAL_H), (PLATE_W,0,0))
        write_tri(f, (0,0,0),        (0,0,TOTAL_H),        (PLATE_W,0,TOTAL_H))
        # Back (y=H, normal +Y)
        write_tri(f, (0,PLATE_H,0),  (PLATE_W,PLATE_H,0),  (PLATE_W,PLATE_H,TOTAL_H))
        write_tri(f, (0,PLATE_H,0),  (PLATE_W,PLATE_H,TOTAL_H), (0,PLATE_H,TOTAL_H))
        # Left (x=0, normal -X)
        write_tri(f, (0,0,0),        (0,PLATE_H,0),         (0,PLATE_H,TOTAL_H))
        write_tri(f, (0,0,0),        (0,PLATE_H,TOTAL_H),   (0,0,TOTAL_H))
        # Right (x=W, normal +X)
        write_tri(f, (PLATE_W,0,0),  (PLATE_W,0,TOTAL_H),   (PLATE_W,PLATE_H,TOTAL_H))
        write_tri(f, (PLATE_W,0,0),  (PLATE_W,PLATE_H,TOTAL_H), (PLATE_W,PLATE_H,0))
        total += 8

        # 5. INNER STEP WALLS (z=PLATE_D to TOTAL_H at inner border edge)
        #    These face inward toward the centre (normals toward centre)
        print("Writing inner step walls...")
        # Front inner step (y=iy0, faces +Y toward centre)
        write_tri(f, (ix0,iy0,PLATE_D), (ix1,iy0,PLATE_D), (ix1,iy0,TOTAL_H))
        write_tri(f, (ix0,iy0,PLATE_D), (ix1,iy0,TOTAL_H), (ix0,iy0,TOTAL_H))
        # Back inner step (y=iy1, faces -Y toward centre)
        write_tri(f, (ix0,iy1,PLATE_D), (ix1,iy1,TOTAL_H), (ix1,iy1,PLATE_D))
        write_tri(f, (ix0,iy1,PLATE_D), (ix0,iy1,TOTAL_H), (ix1,iy1,TOTAL_H))
        # Left inner step (x=ix0, faces +X toward centre)
        write_tri(f, (ix0,iy0,PLATE_D), (ix0,iy0,TOTAL_H), (ix0,iy1,TOTAL_H))
        write_tri(f, (ix0,iy0,PLATE_D), (ix0,iy1,TOTAL_H), (ix0,iy1,PLATE_D))
        # Right inner step (x=ix1, faces -X toward centre)
        write_tri(f, (ix1,iy0,PLATE_D), (ix1,iy1,TOTAL_H), (ix1,iy0,TOTAL_H))
        write_tri(f, (ix1,iy0,PLATE_D), (ix1,iy1,PLATE_D), (ix1,iy1,TOTAL_H))
        total += 8

        # 6. CYLINDER WALLS for each rivet hole (z=0 to TOTAL_H)
        print("Writing cylinder walls...")
        for (cx, cy) in rivets:
            total += cylinder_walls(f, cx, cy, RIVET_R, 0, TOTAL_H, N_SEGS)

        # Patch triangle count in header
        f.seek(80)
        f.write(struct.pack('<I', total))

    size = os.path.getsize(OUTPUT)
    print(f"\nDone! {total:,} triangles")
    print(f"File: {OUTPUT}")
    print(f"Size: {size:,} bytes ({size/1024/1024:.1f} MB)")


if __name__ == "__main__":
    main()
