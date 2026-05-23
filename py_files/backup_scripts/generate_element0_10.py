"""
Generate Element0 + Element10 double-sided tile (4 color STL bodies).

Bottom face (z=0): Element0 — gray field, black border, light-gray rivet discs
Top face (z=D):   Element10 — gray panels, black belt, green rollers, green arrow outline,
                               light-gray rivets (only on gray panels, not where belt is)

Each color is a thin surface slab (SURFACE_D) on the relevant face(s),
plus a full-height gray base box. Import all 4 into your slicer and assign:
  Element0_10_gray.stl      → Gray
  Element0_10_black.stl     → Black
  Element0_10_lightgray.stl → Light Gray
  Element0_10_green.stl     → Green
"""

import struct, math, os

OUT_DIR = "c:/Users/hasse/OneDrive/Documents/git/MRR/stl"
os.makedirs(OUT_DIR, exist_ok=True)

# ── Dimensions ────────────────────────────────────────────────────────────────
W, H, D  = 76.2, 76.2, 3.175
SURFACE_D = 0.4          # surface color layer thickness (~2 print layers)

# ── Element0 (both faces) ─────────────────────────────────────────────────────
BORDER      = 1.5875     # 1/16" black border
RIVET_R     = 1.8
RIVET_INSET = 3.5
N_PER_SIDE  = 9

# ── Element10 belt (top face only) ────────────────────────────────────────────
BELT_CX   = W / 2        # 38.1 mm
BELT_HALF = 11.0         # half-width → belt = 27.1 to 49.1 mm
BELT_X0   = BELT_CX - BELT_HALF
BELT_X1   = BELT_CX + BELT_HALF

# ── Rollers (top face, visible outside belt) ──────────────────────────────────
ROLLER_R  = 2.5          # roller disc radius on face
N_ROLLERS = 15

# ── Arrow outline on belt (pointing up = +Y) ──────────────────────────────────
ARROW_CX      = BELT_CX
STEM_HALF_OUT = 5.5      # outer stem half-width (11mm stem)
STEM_HALF_IN  = 3.0      # inner stem half-width → 2.5mm outline each side
STEM_Y0       = 8.0      # stem bottom
STEM_Y1       = 50.0     # stem top / head base
STEM_IN_Y1    = 47.5     # inner stem top (2.5mm below STEM_Y1)

HEAD_HALF_OUT = 10.5     # outer head half at base (21mm → fits belt)
HEAD_HALF_IN  = 8.0      # inner head half at base → 2.5mm outline each side
HEAD_Y0       = STEM_Y1  # head base
HEAD_Y1       = 67.0     # head tip
HEAD_IN_Y0    = 52.5     # inner head base (2.5mm above HEAD_Y0)
HEAD_IN_Y1    = 64.5     # inner head tip  (2.5mm below HEAD_Y1)

GRID = 200               # grid resolution (cell ≈ 0.38mm)


# ── STL helpers ───────────────────────────────────────────────────────────────

def wtri(f, v0, v1, v2):
    ax,ay,az = v1[0]-v0[0], v1[1]-v0[1], v1[2]-v0[2]
    bx,by,bz = v2[0]-v0[0], v2[1]-v0[1], v2[2]-v0[2]
    nx = ay*bz-az*by;  ny = az*bx-ax*bz;  nz = ax*by-ay*bx
    l  = math.sqrt(nx*nx+ny*ny+nz*nz)
    if l: nx,ny,nz = nx/l,ny/l,nz/l
    f.write(struct.pack('<3f', nx,ny,nz))
    f.write(struct.pack('<3f', *v0))
    f.write(struct.pack('<3f', *v1))
    f.write(struct.pack('<3f', *v2))
    f.write(struct.pack('<H', 0))

def open_stl(path, label):
    f = open(path, 'wb')
    f.write(label.ljust(80, b'\x00'))
    f.write(struct.pack('<I', 0))
    return f

def close_stl(f, count):
    f.seek(80);  f.write(struct.pack('<I', count));  f.close()


# ── Geometry classifiers ──────────────────────────────────────────────────────

def in_border(cx, cy):
    return cx < BORDER or cx > W-BORDER or cy < BORDER or cy > H-BORDER

def in_belt(cx, cy):
    return BELT_X0 <= cx <= BELT_X1

def rivet_positions():
    n, pos = N_PER_SIDE, []
    for i in range(n):
        t = i / (n-1)
        x = RIVET_INSET + t*(W - 2*RIVET_INSET)
        y = RIVET_INSET + t*(H - 2*RIVET_INSET)
        pos.append((x, RIVET_INSET))
        pos.append((x, H-RIVET_INSET))
        if 0 < i < n-1:
            pos.append((RIVET_INSET, y))
            pos.append((W-RIVET_INSET, y))
    return pos

def roller_y_positions():
    return [H*(i+1)/(N_ROLLERS+1) for i in range(N_ROLLERS)]

def build_belt_rivet_set(rivets):
    """Indices of rivets whose disc overlaps the belt — hidden on top face."""
    return {i for i,(rx,ry) in enumerate(rivets)
            if rx+RIVET_R > BELT_X0 and rx-RIVET_R < BELT_X1}

def in_any_rivet(cx, cy, rivets, skip=frozenset()):
    r2 = RIVET_R**2
    return any((cx-rx)**2+(cy-ry)**2 <= r2
               for i,(rx,ry) in enumerate(rivets) if i not in skip)

def in_roller(cx, cy, roller_ys):
    if in_belt(cx, cy) or in_border(cx, cy):
        return False
    return any(abs(cy-ry) <= ROLLER_R for ry in roller_ys)

def in_arrow_outline(cx, cy):
    """True if cell is in the green arrow outline on the belt."""
    # Outer shape
    def outer():
        if STEM_Y0 <= cy <= STEM_Y1 and abs(cx-ARROW_CX) <= STEM_HALF_OUT:
            return True
        if HEAD_Y0 <= cy <= HEAD_Y1:
            t = (HEAD_Y1-cy)/(HEAD_Y1-HEAD_Y0)
            if abs(cx-ARROW_CX) <= HEAD_HALF_OUT*t:
                return True
        return False
    # Inner (hollow)
    def inner():
        if STEM_Y0 <= cy <= STEM_IN_Y1 and abs(cx-ARROW_CX) <= STEM_HALF_IN:
            return True
        if HEAD_IN_Y0 <= cy <= HEAD_IN_Y1:
            t = (HEAD_IN_Y1-cy)/(HEAD_IN_Y1-HEAD_IN_Y0)
            if abs(cx-ARROW_CX) <= HEAD_HALF_IN*t:
                return True
        return False
    return outer() and not inner()


# ── Mask builder ──────────────────────────────────────────────────────────────

def compute_masks(rivets, roller_ys, belt_rivet_set):
    GW = GH = GRID
    dx = W/GW;  dy = H/GH
    mk = lambda: [[False]*GW for _ in range(GH)]

    top_black = mk();  top_lg = mk();  top_green = mk()
    bot_black = mk();  bot_lg  = mk()

    for iy in range(GH):
        for ix in range(GW):
            cx = (ix+0.5)*dx;  cy = (iy+0.5)*dy

            # ── Bottom face: Element0 ──
            if in_border(cx, cy):
                bot_black[iy][ix] = True
            elif in_any_rivet(cx, cy, rivets):
                bot_lg[iy][ix] = True

            # ── Top face: Element10 ──
            if in_border(cx, cy):
                top_black[iy][ix] = True
            elif in_belt(cx, cy):
                if in_arrow_outline(cx, cy):
                    top_green[iy][ix] = True
                else:
                    top_black[iy][ix] = True   # belt body / hidden roller
            elif in_any_rivet(cx, cy, rivets, skip=belt_rivet_set):
                top_lg[iy][ix] = True
            elif in_roller(cx, cy, roller_ys):
                top_green[iy][ix] = True
            # else → gray (handled by base box)

    return top_black, top_lg, top_green, bot_black, bot_lg


# ── Watertight slab writer ────────────────────────────────────────────────────

def write_slab(f, mask, z0, z1):
    """Exterior surface of all True cells in mask, extruded from z0 to z1."""
    GH = len(mask);  GW = len(mask[0])
    dx = W/GW;  dy = H/GH
    count = 0
    for iy in range(GH):
        for ix in range(GW):
            if not mask[iy][ix]: continue
            x0,x1 = ix*dx,(ix+1)*dx
            y0,y1 = iy*dy,(iy+1)*dy
            # Top (+Z)
            wtri(f,(x0,y0,z1),(x1,y0,z1),(x1,y1,z1))
            wtri(f,(x0,y0,z1),(x1,y1,z1),(x0,y1,z1)); count+=2
            # Bottom (-Z)
            wtri(f,(x0,y0,z0),(x1,y1,z0),(x1,y0,z0))
            wtri(f,(x0,y0,z0),(x0,y1,z0),(x1,y1,z0)); count+=2
            # Left (-X)
            if ix==0 or not mask[iy][ix-1]:
                wtri(f,(x0,y0,z0),(x0,y0,z1),(x0,y1,z1))
                wtri(f,(x0,y0,z0),(x0,y1,z1),(x0,y1,z0)); count+=2
            # Right (+X)
            if ix==GW-1 or not mask[iy][ix+1]:
                wtri(f,(x1,y0,z0),(x1,y1,z1),(x1,y0,z1))
                wtri(f,(x1,y0,z0),(x1,y1,z0),(x1,y1,z1)); count+=2
            # Front (-Y)
            if iy==0 or not mask[iy-1][ix]:
                wtri(f,(x0,y0,z0),(x1,y0,z1),(x0,y0,z1))
                wtri(f,(x0,y0,z0),(x1,y0,z0),(x1,y0,z1)); count+=2
            # Back (+Y)
            if iy==GH-1 or not mask[iy+1][ix]:
                wtri(f,(x0,y1,z0),(x0,y1,z1),(x1,y1,z1))
                wtri(f,(x0,y1,z0),(x1,y1,z1),(x1,y1,z0)); count+=2
    return count


# ── Gray base box ─────────────────────────────────────────────────────────────

def write_gray_box(path):
    f = open_stl(path, b"Element0-10 gray base")
    c = 0
    # Bottom
    wtri(f,(0,0,0),(W,H,0),(W,0,0)); wtri(f,(0,0,0),(0,H,0),(W,H,0)); c+=2
    # Top
    wtri(f,(0,0,D),(W,0,D),(W,H,D)); wtri(f,(0,0,D),(W,H,D),(0,H,D)); c+=2
    # Front
    wtri(f,(0,0,0),(W,0,D),(W,0,0)); wtri(f,(0,0,0),(0,0,D),(W,0,D)); c+=2
    # Back
    wtri(f,(0,H,0),(W,H,0),(W,H,D)); wtri(f,(0,H,0),(W,H,D),(0,H,D)); c+=2
    # Left
    wtri(f,(0,0,0),(0,H,0),(0,H,D)); wtri(f,(0,0,0),(0,H,D),(0,0,D)); c+=2
    # Right
    wtri(f,(W,0,0),(W,H,D),(W,H,0)); wtri(f,(W,0,0),(W,0,D),(W,H,D)); c+=2
    close_stl(f, c)
    print(f"  Gray base:  {os.path.basename(path)}  ({c} tris)")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    rivets       = rivet_positions()
    roller_ys    = roller_y_positions()
    belt_riv_set = build_belt_rivet_set(rivets)

    print(f"Rivets: {len(rivets)} total, {len(belt_riv_set)} hidden by belt")
    print(f"Computing masks ({GRID}×{GRID} grid)...")

    top_black, top_lg, top_green, bot_black, bot_lg = compute_masks(
        rivets, roller_ys, belt_riv_set)

    print("Writing STL files...")

    # 1. Gray base
    write_gray_box(os.path.join(OUT_DIR, "Element0_10_gray.stl"))

    # 2. Black (border both faces + belt top face)
    path = os.path.join(OUT_DIR, "Element0_10_black.stl")
    f = open_stl(path, b"Element0-10 black")
    c  = write_slab(f, top_black, D-SURFACE_D, D)
    c += write_slab(f, bot_black, 0, SURFACE_D)
    close_stl(f, c)
    print(f"  Black:      {os.path.basename(path)}  ({c:,} tris)")

    # 3. Light gray (rivets both faces; belt rivets only on bottom)
    path = os.path.join(OUT_DIR, "Element0_10_lightgray.stl")
    f = open_stl(path, b"Element0-10 light gray")
    c  = write_slab(f, top_lg, D-SURFACE_D, D)
    c += write_slab(f, bot_lg, 0, SURFACE_D)
    close_stl(f, c)
    print(f"  Light gray: {os.path.basename(path)}  ({c:,} tris)")

    # 4. Green (rollers + arrow outline, top face only)
    path = os.path.join(OUT_DIR, "Element0_10_green.stl")
    f = open_stl(path, b"Element0-10 green")
    c = write_slab(f, top_green, D-SURFACE_D, D)
    close_stl(f, c)
    print(f"  Green:      {os.path.basename(path)}  ({c:,} tris)")

    print("Done.")

if __name__ == "__main__":
    main()
