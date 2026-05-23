"""
Generate Element0 as three separate STL files (one per color region).
All regions share the same flat 3.175mm height — no protrusions.

  Element0_black.stl     — 1/16" (1.5875mm) border frame
  Element0_lightgray.stl — 32 flat rivet discs (r=1.8mm)
  Element0_gray.stl      — center field (full plate minus border minus rivets)

All three together tile exactly 3" × 3" × 1/8".
"""

import struct, math, os

OUT_DIR = "c:/Users/hasse/OneDrive/Documents/git/MRR/stl"
os.makedirs(OUT_DIR, exist_ok=True)

W = 76.2      # plate width  (3 in)
H = 76.2      # plate height (3 in)
D = 3.175     # plate depth  (1/8 in)

BORDER      = 1.5875   # 1/16" border width
RIVET_R     = 1.8      # rivet disc radius
RIVET_INSET = 3.5      # rivet centre distance from outer edge
N_PER_SIDE  = 9        # rivets per side (corners shared)
N_SEGS      = 32       # polygon segments per rivet circle

GRID = 300   # mesh resolution for cut-out faces


# ── STL write helpers ─────────────────────────────────────────────────────────

def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])

def sub(a, b):
    return (a[0]-b[0], a[1]-b[1], a[2]-b[2])

def norm3(v):
    l = math.sqrt(v[0]**2+v[1]**2+v[2]**2)
    return (v[0]/l, v[1]/l, v[2]/l) if l else (0.0, 0.0, 1.0)

def face_normal(v0, v1, v2):
    return norm3(cross(sub(v1,v0), sub(v2,v0)))

def write_tri(f, v0, v1, v2):
    n = face_normal(v0, v1, v2)
    f.write(struct.pack('<3f', *n))
    f.write(struct.pack('<3f', *v0))
    f.write(struct.pack('<3f', *v1))
    f.write(struct.pack('<3f', *v2))
    f.write(struct.pack('<H', 0))

def open_stl(path, name):
    f = open(path, 'wb')
    f.write(name.ljust(80, b'\x00'))
    f.write(struct.pack('<I', 0))   # placeholder count
    return f

def close_stl(f, count):
    f.seek(80)
    f.write(struct.pack('<I', count))
    f.close()


# ── rivet positions ───────────────────────────────────────────────────────────

def rivet_positions():
    n = N_PER_SIDE
    pos = []
    for i in range(n):
        t = i / (n - 1)
        x = RIVET_INSET + t * (W - 2*RIVET_INSET)
        y = RIVET_INSET + t * (H - 2*RIVET_INSET)
        pos.append((x, RIVET_INSET))
        pos.append((x, H - RIVET_INSET))
        if 0 < i < n - 1:
            pos.append((RIVET_INSET, y))
            pos.append((W - RIVET_INSET, y))
    return pos


# ── grid face helpers ─────────────────────────────────────────────────────────

def in_rivet(cx, cy, rivets, r2):
    return any((cx-rx)**2 + (cy-ry)**2 <= r2 for rx, ry in rivets)

def in_border(cx, cy):
    return cx < BORDER or cx > W-BORDER or cy < BORDER or cy > H-BORDER

def write_quad(f, x0, y0, x1, y1, z, flip):
    """Write a quad as two triangles. flip=True gives -Z normal."""
    if flip:
        write_tri(f, (x0,y0,z), (x1,y1,z), (x1,y0,z))
        write_tri(f, (x0,y0,z), (x0,y1,z), (x1,y1,z))
    else:
        write_tri(f, (x0,y0,z), (x1,y0,z), (x1,y1,z))
        write_tri(f, (x0,y0,z), (x1,y1,z), (x0,y1,z))

def write_side(f, x0, y0, x1, y1, z0, z1, nx, ny):
    """Write a vertical quad (wall segment) with given outward normal direction."""
    write_tri(f, (x0,y0,z0), (x1,y1,z0), (x1,y1,z1))
    write_tri(f, (x0,y0,z0), (x1,y1,z1), (x0,y0,z1))


# ── BORDER STL ────────────────────────────────────────────────────────────────

def generate_border(rivets):
    path = os.path.join(OUT_DIR, "Element0_black.stl")
    f = open_stl(path, b"Element0 border (black)")
    count = 0
    r2 = RIVET_R ** 2
    dx = W / GRID
    dy = H / GRID

    for face_top in [True, False]:
        z = D if face_top else 0
        flip = not face_top
        for iy in range(GRID):
            for ix in range(GRID):
                cx = (ix + 0.5) * dx
                cy = (iy + 0.5) * dy
                if not in_border(cx, cy):
                    continue
                if in_rivet(cx, cy, rivets, r2):
                    continue
                x0, x1 = ix*dx, (ix+1)*dx
                y0, y1 = iy*dy, (iy+1)*dy
                write_quad(f, x0, y0, x1, y1, z, flip)
                count += 2

    # Outer walls (full outer perimeter, full height)
    # Front (y=0)
    write_tri(f, (0,0,0), (W,0,D), (W,0,0))
    write_tri(f, (0,0,0), (0,0,D), (W,0,D))
    # Back (y=H)
    write_tri(f, (0,H,0), (W,H,0), (W,H,D))
    write_tri(f, (0,H,0), (W,H,D), (0,H,D))
    # Left (x=0)
    write_tri(f, (0,0,0), (0,H,0), (0,H,D))
    write_tri(f, (0,0,0), (0,H,D), (0,0,D))
    # Right (x=W)
    write_tri(f, (W,0,0), (W,H,D), (W,H,0))
    write_tri(f, (W,0,0), (W,0,D), (W,H,D))
    count += 8

    # Inner walls of border (facing inward toward center)
    bw = BORDER
    # Front inner (y=bw, normal +Y)
    write_tri(f, (bw,bw,0), (W-bw,bw,0), (W-bw,bw,D))
    write_tri(f, (bw,bw,0), (W-bw,bw,D), (bw,bw,D))
    # Back inner (y=H-bw, normal -Y)
    write_tri(f, (bw,H-bw,0), (W-bw,H-bw,D), (W-bw,H-bw,0))
    write_tri(f, (bw,H-bw,0), (bw,H-bw,D), (W-bw,H-bw,D))
    # Left inner (x=bw, normal +X)
    write_tri(f, (bw,bw,0), (bw,bw,D), (bw,H-bw,D))
    write_tri(f, (bw,bw,0), (bw,H-bw,D), (bw,H-bw,0))
    # Right inner (x=W-bw, normal -X)
    write_tri(f, (W-bw,bw,0), (W-bw,H-bw,D), (W-bw,bw,D))
    write_tri(f, (W-bw,bw,0), (W-bw,H-bw,0), (W-bw,H-bw,D))
    count += 8

    close_stl(f, count)
    print(f"Border:     {path}  ({count:,} tris)")


# ── RIVET STL ─────────────────────────────────────────────────────────────────

def generate_rivets(rivets):
    path = os.path.join(OUT_DIR, "Element0_lightgray.stl")
    f = open_stl(path, b"Element0 rivets (light gray)")
    count = 0

    for (cx, cy) in rivets:
        # Top disc (z=D, normal +Z)
        for j in range(N_SEGS):
            a1 = (j     / N_SEGS) * 2 * math.pi
            a2 = ((j+1) / N_SEGS) * 2 * math.pi
            x1 = cx + RIVET_R * math.cos(a1);  y1 = cy + RIVET_R * math.sin(a1)
            x2 = cx + RIVET_R * math.cos(a2);  y2 = cy + RIVET_R * math.sin(a2)
            write_tri(f, (cx,cy,D), (x1,y1,D), (x2,y2,D))
            count += 1

        # Bottom disc (z=0, normal -Z)
        for j in range(N_SEGS):
            a1 = (j     / N_SEGS) * 2 * math.pi
            a2 = ((j+1) / N_SEGS) * 2 * math.pi
            x1 = cx + RIVET_R * math.cos(a1);  y1 = cy + RIVET_R * math.sin(a1)
            x2 = cx + RIVET_R * math.cos(a2);  y2 = cy + RIVET_R * math.sin(a2)
            write_tri(f, (cx,cy,0), (x2,y2,0), (x1,y1,0))
            count += 1

        # Side wall
        for j in range(N_SEGS):
            a1 = (j     / N_SEGS) * 2 * math.pi
            a2 = ((j+1) / N_SEGS) * 2 * math.pi
            x1 = cx + RIVET_R * math.cos(a1);  y1 = cy + RIVET_R * math.sin(a1)
            x2 = cx + RIVET_R * math.cos(a2);  y2 = cy + RIVET_R * math.sin(a2)
            write_tri(f, (x1,y1,0), (x2,y2,D), (x1,y1,D))
            write_tri(f, (x1,y1,0), (x2,y2,0), (x2,y2,D))
            count += 2

    close_stl(f, count)
    print(f"Rivets:     {path}  ({count:,} tris)")


# ── GRAY CENTER STL ───────────────────────────────────────────────────────────

def generate_gray(rivets):
    path = os.path.join(OUT_DIR, "Element0_gray.stl")
    f = open_stl(path, b"Element0 center field (gray)")
    count = 0
    r2 = RIVET_R ** 2
    dx = W / GRID
    dy = H / GRID

    for face_top in [True, False]:
        z = D if face_top else 0
        flip = not face_top
        for iy in range(GRID):
            for ix in range(GRID):
                cx = (ix + 0.5) * dx
                cy = (iy + 0.5) * dy
                if in_border(cx, cy):
                    continue
                if in_rivet(cx, cy, rivets, r2):
                    continue
                x0, x1 = ix*dx, (ix+1)*dx
                y0, y1 = iy*dy, (iy+1)*dy
                write_quad(f, x0, y0, x1, y1, z, flip)
                count += 2

    # Inner walls (border side, facing outward from center)
    bw = BORDER
    # Front (y=bw, normal -Y)
    write_tri(f, (bw,bw,0), (W-bw,bw,D), (W-bw,bw,0))
    write_tri(f, (bw,bw,0), (bw,bw,D), (W-bw,bw,D))
    # Back (y=H-bw, normal +Y)
    write_tri(f, (bw,H-bw,0), (W-bw,H-bw,0), (W-bw,H-bw,D))
    write_tri(f, (bw,H-bw,0), (W-bw,H-bw,D), (bw,H-bw,D))
    # Left (x=bw, normal -X)
    write_tri(f, (bw,bw,0), (bw,H-bw,0), (bw,H-bw,D))
    write_tri(f, (bw,bw,0), (bw,H-bw,D), (bw,bw,D))
    # Right (x=W-bw, normal +X)
    write_tri(f, (W-bw,bw,0), (W-bw,bw,D), (W-bw,H-bw,D))
    write_tri(f, (W-bw,bw,0), (W-bw,H-bw,D), (W-bw,H-bw,0))
    count += 8

    close_stl(f, count)
    print(f"Gray field: {path}  ({count:,} tris)")


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    rivets = rivet_positions()
    print(f"Rivets: {len(rivets)}, Grid: {GRID}x{GRID}")
    generate_border(rivets)
    generate_rivets(rivets)
    generate_gray(rivets)
    print("Done.")

if __name__ == "__main__":
    main()
