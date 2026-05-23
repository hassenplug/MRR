"""
Generate JPG preview images for conveyor belt arrow tiles (Elements 10-16).

Flat-color style: dark gray background, black belt, green rollers/arrow, light gray rivets.

Belt geometry matches element10.scad: belt_w = 1.75" on a 3.0" tile (58% width).
Curved branches enter the tile STRAIGHT from the left/right edge, then curve with
a quarter-circle arc to merge with the straight belt at the arrowhead base.

Elements:
  10 - straight only
  11 - right-turn only   (enters from right edge)
  12 - left-turn only    (enters from left edge)
  13 - straight + left-turn
  14 - straight + right-turn
  15 - straight + left + right
  16 - left + right (no straight)
"""

import os
import math
import numpy as np

OUT_DIR = r"c:\Users\hasse\OneDrive\Documents\git\MRR\Images"
SIZE = 500      # px (square)
MM   = 76.2     # tile physical size mm (= 3.0 inches)
S    = SIZE / MM

def p(mm): return mm * S

# ── Core dimensions (from element10.scad converted to px) ────────────────────
BORDER     = p(1.5875)          # 1/16" frame
RIVET_R    = p(1.8)
RIVET_INS  = p(3.5)

# Belt: 1.75" wide on 3.0" tile → 58% of image width
BELT_W_IN  = 1.75               # inches
TILE_IN    = 3.0                # inches
BELT_HALF  = round(SIZE * (BELT_W_IN / TILE_IN) / 2)   # ≈ 146 px

CX = SIZE // 2                  # center x = 250

# Quarter-circle on-ramp radius for curved branches
# Must be > BELT_HALF so the inner arc radius stays positive
R_CURVE    = 200                # px

# Y (PIL, y=0 at top) where curved branches merge with straight belt
# = arrowhead base = SCAD SY1 = 50mm from bottom
SY1_MM     = 50.0
Y_MERGE    = SIZE - round(p(SY1_MM))   # ≈ 172 px from top

# On-ramp entry Y (bottom of the horizontal section centerline)
Y_ENTRY    = Y_MERGE + R_CURVE          # ≈ 372 px from top

# Arc centers for left/right branches
CX_L = CX - R_CURVE    # left  branch arc center x  (≈ 50)
CX_R = CX + R_CURVE    # right branch arc center x  (≈ 450)

# ── Arrow dimensions (element10.scad, converted to px) ───────────────────────
SHO  = round(p(5.5))    # stem outer half-width (≈ 36)
SHI  = round(p(3.0))    # stem inner half-width (≈ 20)
SY0  = round(p(8.0))    # stem base   (SCAD Y from bottom → PIL = SIZE-SY0)
SY1  = round(p(SY1_MM)) # stem top    (SCAD Y from bottom → PIL = Y_MERGE)
SIY1 = round(p(47.5))   # inner stem top
HHO  = round(p(10.5))   # head outer half-width at base
HHI  = round(p(8.0))    # head inner half-width at base
HY1  = round(p(67.0))   # head tip (SCAD Y)
HIY0 = round(p(52.5))   # inner head base
HIY1 = round(p(64.5))   # inner head tip

# PIL Y values (y=0 at top) for the arrow
PIL_STEM_BASE = SIZE - SY0    # bottom of straight stem
PIL_STEM_TOP  = Y_MERGE       # top of stem = arrowhead base
PIL_HEAD_TIP  = SIZE - HY1    # arrowhead tip

# ── Colours ───────────────────────────────────────────────────────────────────
C_BG    = (55,  55,  55)
C_BELT  = (20,  20,  20)
C_GREEN = (0,  200,   0)
C_RIVET = (200, 200, 200)
C_FRAME = (15,  15,  15)

# ── Element definitions ───────────────────────────────────────────────────────
ELEMENTS = {
    10: (True,  False, False),
    11: (False, False, True),
    12: (False, True,  False),
    13: (True,  True,  False),
    14: (True,  False, True),
    15: (True,  True,  True),
    16: (False, True,  True),
}

# ── Pre-compute coordinate grids (PIL: y=0 at top) ───────────────────────────
_xs = np.arange(SIZE, dtype=float) + 0.5
_ys = np.arange(SIZE, dtype=float) + 0.5
XX, YY = np.meshgrid(_xs, _ys)
YS = SIZE - YY    # SCAD Y (from bottom)

# ── Geometry helpers ──────────────────────────────────────────────────────────

def _top_section():
    """Straight belt from top edge down to Y_MERGE (shared exit for all elements)."""
    return (XX >= CX - BELT_HALF) & (XX <= CX + BELT_HALF) & (YY <= Y_MERGE)

def _straight_belt():
    """Full-height straight belt (top to bottom)."""
    return (XX >= CX - BELT_HALF) & (XX <= CX + BELT_HALF)

def _left_branch_belt():
    """Horizontal entry from left edge + quarter-circle curving to merge at (CX, Y_MERGE)."""
    # Horizontal section: y = Y_ENTRY +/- BELT_HALF, x = 0..CX_L
    horiz = (XX <= CX_L) & (np.abs(YY - Y_ENTRY) <= BELT_HALF)
    # Arc section: center (CX_L, Y_MERGE), radius R_CURVE, angles 0..90 deg
    D = np.sqrt((XX - CX_L)**2 + (YY - Y_MERGE)**2)
    A = np.degrees(np.arctan2(YY - Y_MERGE, XX - CX_L))
    arc = (D >= R_CURVE - BELT_HALF) & (D <= R_CURVE + BELT_HALF) & (A >= 0) & (A <= 90)
    return horiz | arc

def _right_branch_belt():
    """Horizontal entry from right edge + quarter-circle curving to merge at (CX, Y_MERGE)."""
    horiz = (XX >= CX_R) & (np.abs(YY - Y_ENTRY) <= BELT_HALF)
    D = np.sqrt((XX - CX_R)**2 + (YY - Y_MERGE)**2)
    A = np.degrees(np.arctan2(YY - Y_MERGE, XX - CX_R))
    arc = (D >= R_CURVE - BELT_HALF) & (D <= R_CURVE + BELT_HALF) & (A >= 90) & (A <= 180)
    return horiz | arc

def belt_mask(straight, left_turn, right_turn):
    # All elements share the top section (exit at top edge)
    m = _top_section()
    if straight:
        m |= _straight_belt()
    if left_turn:
        m |= _left_branch_belt()
    if right_turn:
        m |= _right_branch_belt()
    return m

# ── Arrow masks ───────────────────────────────────────────────────────────────

def _arrowhead_outer():
    """Outer filled arrowhead polygon (including stem top)."""
    # Triangular head
    denom = float(HY1 - SY1)
    t = np.clip((HY1 - YS) / denom, 0, 1) if denom else np.zeros_like(YS)
    in_head = (YS >= SY1) & (YS <= HY1) & (np.abs(XX - CX) <= HHO * t)
    return in_head

def _arrowhead_inner():
    """Inner hollow of arrowhead."""
    denom = float(HIY1 - HIY0)
    t = np.clip((HIY1 - YS) / denom, 0, 1) if denom else np.zeros_like(YS)
    return (YS >= HIY0) & (YS <= HIY1) & (np.abs(XX - CX) <= HHI * t)

def _straight_shaft_outer():
    """Outer straight stem going down from arrowhead base."""
    return (YS >= SY0) & (YS <= SY1) & (np.abs(XX - CX) <= SHO)

def _straight_shaft_inner():
    return (YS >= SY0) & (YS <= SIY1) & (np.abs(XX - CX) <= SHI)

def _left_shaft_outer():
    """Outer hollow outline of the left branch path."""
    horiz = (XX <= CX_L) & (np.abs(YY - Y_ENTRY) <= SHO)
    D = np.sqrt((XX - CX_L)**2 + (YY - Y_MERGE)**2)
    A = np.degrees(np.arctan2(YY - Y_MERGE, XX - CX_L))
    arc = (D >= R_CURVE - SHO) & (D <= R_CURVE + SHO) & (A >= 0) & (A <= 90)
    return horiz | arc

def _left_shaft_inner():
    horiz = (XX <= CX_L) & (np.abs(YY - Y_ENTRY) <= SHI)
    D = np.sqrt((XX - CX_L)**2 + (YY - Y_MERGE)**2)
    A = np.degrees(np.arctan2(YY - Y_MERGE, XX - CX_L))
    arc = (D >= R_CURVE - SHI) & (D <= R_CURVE + SHI) & (A >= 0) & (A <= 90)
    return horiz | arc

def _right_shaft_outer():
    horiz = (XX >= CX_R) & (np.abs(YY - Y_ENTRY) <= SHO)
    D = np.sqrt((XX - CX_R)**2 + (YY - Y_MERGE)**2)
    A = np.degrees(np.arctan2(YY - Y_MERGE, XX - CX_R))
    arc = (D >= R_CURVE - SHO) & (D <= R_CURVE + SHO) & (A >= 90) & (A <= 180)
    return horiz | arc

def _right_shaft_inner():
    horiz = (XX >= CX_R) & (np.abs(YY - Y_ENTRY) <= SHI)
    D = np.sqrt((XX - CX_R)**2 + (YY - Y_MERGE)**2)
    A = np.degrees(np.arctan2(YY - Y_MERGE, XX - CX_R))
    arc = (D >= R_CURVE - SHI) & (D <= R_CURVE + SHI) & (A >= 90) & (A <= 180)
    return horiz | arc

def arrow_mask(straight, left_turn, right_turn):
    outer = _arrowhead_outer()
    inner = _arrowhead_inner()

    if straight:
        outer |= _straight_shaft_outer()
        inner |= _straight_shaft_inner()
    if left_turn:
        outer |= _left_shaft_outer()
        inner |= _left_shaft_inner()
    if right_turn:
        outer |= _right_shaft_outer()
        inner |= _right_shaft_inner()

    return outer & ~inner

# ── Roller masks ──────────────────────────────────────────────────────────────
N_ROLLERS  = 15
ROLLER_D   = 4.0   # display half-thickness (px)

_ry_list = [SIZE * (i + 1) / (N_ROLLERS + 1) for i in range(N_ROLLERS)]

def _side_rollers(x_lo, x_hi, belt_m):
    m = np.zeros((SIZE, SIZE), bool)
    for ry in _ry_list:
        m |= (np.abs(YY - ry) <= ROLLER_D) & (XX >= x_lo) & (XX <= x_hi)
    return m & ~belt_m & ~_BORDER_M

def _bottom_rollers(belt_m):
    """Horizontal bars in the lower portion, on both sides of the straight belt."""
    y0 = Y_MERGE   # start from the merge point downward
    n  = 12
    ys = [y0 + (SIZE - BORDER - y0) * (i + 1) / (n + 1) for i in range(n)]
    m = np.zeros((SIZE, SIZE), bool)
    for ry in ys:
        m |= (np.abs(YY - ry) <= ROLLER_D)
    return m & ~belt_m & ~_BORDER_M

def roller_mask(straight, left_turn, right_turn, belt_m):
    lx0 = BORDER
    lx1 = CX - BELT_HALF
    rx0 = CX + BELT_HALF
    rx1 = SIZE - BORDER

    if straight and not left_turn and not right_turn:
        return _side_rollers(lx0, lx1, belt_m) | _side_rollers(rx0, rx1, belt_m)
    elif left_turn and not right_turn:
        # left side has belt entry → rollers only on right
        return _side_rollers(rx0, rx1, belt_m)
    elif right_turn and not left_turn:
        # right side has belt entry → rollers only on left
        return _side_rollers(lx0, lx1, belt_m)
    else:
        # both sides occupied → bottom rollers
        return _bottom_rollers(belt_m)

# ── Rivet mask ────────────────────────────────────────────────────────────────
def _rivet_positions():
    n, pos = 9, []
    for i in range(n):
        t = i / (n - 1)
        x = RIVET_INS + t * (SIZE - 2 * RIVET_INS)
        y = RIVET_INS + t * (SIZE - 2 * RIVET_INS)
        pos.append((x, RIVET_INS))
        pos.append((x, SIZE - RIVET_INS))
        if 0 < i < n - 1:
            pos.append((RIVET_INS, y))
            pos.append((SIZE - RIVET_INS, y))
    return pos

_ALL_RIVETS_M = np.zeros((SIZE, SIZE), bool)
for _rx, _ry in _rivet_positions():
    _ALL_RIVETS_M |= (XX - _rx)**2 + (YY - _ry)**2 <= RIVET_R**2

_BORDER_M = (XX < BORDER) | (XX > SIZE - BORDER) | (YY < BORDER) | (YY > SIZE - BORDER)

# ── Image builder ─────────────────────────────────────────────────────────────

def build_image(num):
    straight, left_turn, right_turn = ELEMENTS[num]

    belt_m   = belt_mask(straight, left_turn, right_turn)
    arrow_m  = arrow_mask(straight, left_turn, right_turn)
    roller_m = roller_mask(straight, left_turn, right_turn, belt_m)
    rivet_m  = _ALL_RIVETS_M & ~belt_m & ~_BORDER_M

    img = np.full((SIZE, SIZE, 3), C_BG, dtype=np.uint8)
    img[belt_m]   = C_BELT
    img[roller_m] = C_GREEN
    img[rivet_m]  = C_RIVET
    img[arrow_m]  = C_GREEN
    img[_BORDER_M] = C_FRAME

    from PIL import Image as PILImage
    return PILImage.fromarray(img, 'RGB')


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for num in sorted(ELEMENTS):
        print(f"  Generating Element{num}...", end="", flush=True)
        img = build_image(num)
        path = os.path.join(OUT_DIR, f"Element{num}_preview.jpg")
        img.save(path, quality=95)
        print(f" -> {path}")
    print("Done.")


if __name__ == "__main__":
    main()
