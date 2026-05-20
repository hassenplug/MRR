"""
Element Builder Agent — step-by-step construction of conveyor belt tile Elements 10–16.

All dimensions derived from element10.scad / element11.scad (inches → mm → px).

Tile: 3.0" × 3.0" outer (plate 2-7/8" × 2-7/8" + 1/16" frame each side).
Rendered at 500 × 500 px  (S = 500 / 76.2 ≈ 6.561 px/mm).

Elements (straight, left_turn, right_turn):
  10 — straight only
  11 — right-turn only   (enters from right-edge center)
  12 — left-turn only    (enters from left-edge center)
  13 — straight + left-turn
  14 — straight + right-turn
  15 — straight + left + right
  16 — left + right, no straight

Build steps:
  1 — arrowhead only
  2 — arrowhead + shafts
  3 — add belt / background
  4 — add rollers (behind belt)
  5 — add rivets  (complete tile)

Run:  python element_builder_agent.py [--step N] [--out DIR]
"""

import os, argparse
import numpy as np

# ═══════════════════════════════════════════════════════════════════════════════
#  SCAD source values (inches) — edit here to tune
# ═══════════════════════════════════════════════════════════════════════════════

# ── Tile geometry  (element10.scad) ───────────────────────────────────────────
PLATE_W_IN   = 2 + 7/8        # 2.875"  inner plate
FRAME_W_IN   = 1/16           # 0.0625" border frame (each side)
TILE_W_IN    = PLATE_W_IN + 2*FRAME_W_IN  # 3.0" total tile

# ── Belt  (element10.scad: belt_w = 1.75") ────────────────────────────────────
BELT_W_IN    = 1.75

# ── Arrow  (element10.scad) ───────────────────────────────────────────────────
ARROW_W_IN       = BELT_W_IN * 0.75     # 1.3125"  full arrow width
_ARROW_TIP_IN    = 3 * PLATE_W_IN / 20 + 1/4 + 7 * PLATE_W_IN / 10  # tip from plate bottom (fixed)
ARROW_OUT_IN     = 1/16                  # 0.0625"  outline thickness

ARROW_HEAD_H_IN  = ARROW_W_IN / 2        # 0.65625"
ARROW_SHAFT_W_IN = ARROW_W_IN * 0.4      # 0.525"
ARROW_SHAFT_H_IN = 1.5                   # shaft length
ARROW_H_IN       = ARROW_SHAFT_H_IN + ARROW_HEAD_H_IN  # total arrow height
ARROW_Y_IN       = _ARROW_TIP_IN - ARROW_H_IN  # shaft base (keeps arrowhead tip fixed)

# ── Rollers  (element10.scad) ─────────────────────────────────────────────────
ROLLER_COUNT    = 13
ROLLER_H_IN     = 3/16       # slot height (display half-thickness derived below)
ROLLER_INSET_IN = (PLATE_W_IN / 10) / 2   # inset from plate edge = 0.14375"
ROLLER_X_START_IN = 2 * ROLLER_INSET_IN   # 0.2875" from plate edge (horiz span start)
ROLLER_X_END_IN   = PLATE_W_IN - 2 * ROLLER_INSET_IN  # 2.5875" from plate edge

# ── Rivets  (element11.scad: 10 per side) ────────────────────────────────────
RIVET_N         = 10
RIVET_HOLE_IN   = 3/32        # hole diameter (used as display radius, slightly enlarged)
RIVET_INSET_IN  = (PLATE_W_IN / 10) / 2   # same inset as roller  = 0.14375"
RIVET_STEP_IN   = PLATE_W_IN / 10          # 0.2875" between rivets

# ── Curved shaft arc  (tunable; element11.scad arc_r ≈ plate_w/2 ≈ 240 px) ──
R_CURVE_PX   = 80     # quarter-circle radius for arc shafts (px)
STRAIGHT_PX  = 20     # vertical straight segment at top of arc (px)
H_STRAIGHT_PX = 40    # horizontal straight segment at side entry of arc (px)

# ═══════════════════════════════════════════════════════════════════════════════
#  Canvas
# ═══════════════════════════════════════════════════════════════════════════════
SIZE = 500
S    = SIZE / (TILE_W_IN * 25.4)   # px per mm  ≈ 6.561

def _in(inches): return inches * 25.4 * S   # inches → px (float)
def _mm(mm):     return mm * S              # mm     → px (float)

# ── Frame boundary ────────────────────────────────────────────────────────────
BORDER = _in(FRAME_W_IN)    # ≈ 10.4 px

# ── Belt ──────────────────────────────────────────────────────────────────────
BELT_HALF = round(_in(BELT_W_IN) / 2)     # ≈ 146 px
CX        = SIZE // 2                      # 250

# ── Arrow pixel positions (SCAD Y = px from tile bottom) ─────────────────────
# All positions referenced from tile bottom (= plate_bottom + frame).
_PLATE_BOT = _in(FRAME_W_IN)   # plate starts this many px from tile bottom

SY0  = round(_PLATE_BOT + _in(ARROW_Y_IN))                           # stem base
SY1  = round(_PLATE_BOT + _in(ARROW_Y_IN + ARROW_SHAFT_H_IN))        # stem top / head base
HY1  = round(_PLATE_BOT + _in(ARROW_Y_IN + ARROW_H_IN))              # head tip

SHO  = round(_in(ARROW_SHAFT_W_IN) / 2)   # stem outer half-width
SHI  = round(_in(ARROW_SHAFT_W_IN - 2*ARROW_OUT_IN) / 2)  # stem inner
SIY1 = round(SY1 - _in(ARROW_OUT_IN))     # inner stem top (outline below head base)

HHO  = round(_in(ARROW_W_IN) / 2)         # head outer half-width at base

# Inner head hollow — uniform 1/16" perpendicular outline on 45° head sides:
#   inner_hw = outer_hw - outline / sin(45°)
import math as _math
_sin45 = _math.sqrt(2) / 2
HHI    = round(HHO - _in(ARROW_OUT_IN) / _sin45)   # inner half-width at base
HIY0   = SY1                                         # hollow starts at head base
HIY1   = round(HY1 - _in(ARROW_OUT_IN) / _sin45)   # hollow tip

# ── Roller pixel values ───────────────────────────────────────────────────────
# Y positions (SCAD Y = px from tile bottom)
_ry_step = _in((PLATE_W_IN - 2*ROLLER_INSET_IN) / (ROLLER_COUNT - 1))
_ry0     = _PLATE_BOT + _in(ROLLER_INSET_IN)
ROLLER_YS_SCAD = [_ry0 + i * _ry_step for i in range(ROLLER_COUNT)]

ROLLER_D  = round(_in(ROLLER_H_IN) / 4)   # display half-thickness ≈ 3 px  (visual; full slot is 3/16")

# X extent of roller bars (tile px from left)
_rx_start = _in(FRAME_W_IN + ROLLER_X_START_IN)   # ≈ 58 px
_rx_end   = _in(FRAME_W_IN + ROLLER_X_END_IN)     # ≈ 442 px

# ── Rivet pixel values ────────────────────────────────────────────────────────
_riv_inset = _in(FRAME_W_IN + RIVET_INSET_IN)      # ≈ 34 px from tile edge
_riv_step  = _in(RIVET_STEP_IN)                    # ≈ 48 px between rivets
RIVET_R    = round(_in(RIVET_HOLE_IN) / 2)          # hole radius = hole_d / 2 (matches SCAD)

# ── Arc shaft merge / entry points ────────────────────────────────────────────
Y_MERGE      = SIZE - SY1                    # PIL y where arc meets arrowhead base
Y_ARC_CENTER = Y_MERGE + STRAIGHT_PX        # arc center Y (straight segment above arc)
Y_ENTRY      = Y_ARC_CENTER + R_CURVE_PX    # PIL y where belt enters tile side
CX_L         = CX - R_CURVE_PX              # arc center x for left branch
CX_R         = CX + R_CURVE_PX              # arc center x for right branch

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

# ═══════════════════════════════════════════════════════════════════════════════
#  Pixel grids
# ═══════════════════════════════════════════════════════════════════════════════
_xs = np.arange(SIZE, dtype=float) + 0.5
_ys = np.arange(SIZE, dtype=float) + 0.5
XX, YY = np.meshgrid(_xs, _ys)
YS  = SIZE - YY    # SCAD Y (px from tile bottom)
_FM = (XX < BORDER) | (XX > SIZE-BORDER) | (YY < BORDER) | (YY > SIZE-BORDER)

# ═══════════════════════════════════════════════════════════════════════════════
#  Mask builders
# ═══════════════════════════════════════════════════════════════════════════════

# ── Arrowhead ─────────────────────────────────────────────────────────────────
def _head_outer():
    denom = float(HY1 - SY1) or 1.0
    t = np.clip((HY1 - YS) / denom, 0, 1)
    return (YS >= SY1) & (YS <= HY1) & (np.abs(XX - CX) <= HHO * t)

def _head_inner():
    denom = float(HIY1 - HIY0) or 1.0
    t = np.clip((HIY1 - YS) / denom, 0, 1)
    return (YS >= HIY0) & (YS <= HIY1) & (np.abs(XX - CX) <= HHI * t)

def arrowhead_mask():
    head = _head_outer() & ~_head_inner()
    # Horizontal shoulder bar connecting head base corners to shaft top (SCAD outline gap)
    bar = (YS >= SIY1) & (YS <= SY1) & (np.abs(XX - CX) >= SHO) & (np.abs(XX - CX) <= HHO)
    return head | bar

# ── Straight stem ─────────────────────────────────────────────────────────────
def _straight_shaft():
    out = (YS >= SY0) & (YS <= SY1) & (np.abs(XX - CX) <= SHO)
    inner_bot = SY0 + round(_in(ARROW_OUT_IN))   # solid bottom cap
    inn = (YS >= inner_bot) & (YS <= SY1) & (np.abs(XX - CX) <= SHI)
    return out & ~inn

# ── Curved arc shaft ──────────────────────────────────────────────────────────
def _arc_shaft(cx_arc, a_lo, a_hi):
    D = np.sqrt((XX - cx_arc)**2 + (YY - Y_ARC_CENTER)**2)
    A = np.degrees(np.arctan2(YY - Y_ARC_CENTER, XX - cx_arc))
    arc_out = (D >= R_CURVE_PX - SHO) & (D <= R_CURVE_PX + SHO) & (A >= a_lo) & (A <= a_hi)
    arc_inn = (D >= R_CURVE_PX - SHI) & (D <= R_CURVE_PX + SHI) & (A >= a_lo) & (A <= a_hi)
    cap = round(_in(ARROW_OUT_IN))   # solid end-cap thickness = outline width
    if cx_arc < CX:
        # left branch: horizontal exits left; cap closes the left end
        x0, x1 = cx_arc - H_STRAIGHT_PX, cx_arc
        h_out = (XX >= x0) & (XX <= x1) & (np.abs(YY - Y_ENTRY) <= SHO)
        h_inn = (XX >= x0 + cap) & (XX <= x1) & (np.abs(YY - Y_ENTRY) <= SHI)
    else:
        # right branch: horizontal exits right; cap closes the right end
        x0, x1 = cx_arc, cx_arc + H_STRAIGHT_PX
        h_out = (XX >= x0) & (XX <= x1) & (np.abs(YY - Y_ENTRY) <= SHO)
        h_inn = (XX >= x0) & (XX <= x1 - cap) & (np.abs(YY - Y_ENTRY) <= SHI)
    # vertical straight segment connecting arc top to arrowhead base
    v_out = (YY >= Y_MERGE) & (YY <= Y_ARC_CENTER) & (np.abs(XX - CX) <= SHO)
    v_inn = (YY >= Y_MERGE) & (YY <= Y_ARC_CENTER) & (np.abs(XX - CX) <= SHI)
    return (arc_out | h_out | v_out) & ~(arc_inn | h_inn | v_inn)

def shaft_mask(straight, left_turn, right_turn):
    m = np.zeros((SIZE, SIZE), bool)
    if straight:    m |= _straight_shaft()
    if left_turn:   m |= _arc_shaft(CX_L, 0, 90)
    if right_turn:  m |= _arc_shaft(CX_R, 90, 180)
    return m

def arrow_mask(straight, left_turn, right_turn):
    return arrowhead_mask() | shaft_mask(straight, left_turn, right_turn)

# ── Belt ──────────────────────────────────────────────────────────────────────
def _top_strip():
    return (XX >= CX - BELT_HALF) & (XX <= CX + BELT_HALF) & (YY <= Y_ARC_CENTER)

def _straight_belt():
    return (XX >= CX - BELT_HALF) & (XX <= CX + BELT_HALF)

def _branch_belt(cx_arc, a_lo, a_hi):
    D = np.sqrt((XX - cx_arc)**2 + (YY - Y_ARC_CENTER)**2)
    A = np.degrees(np.arctan2(YY - Y_ARC_CENTER, XX - cx_arc))
    arc = (D >= R_CURVE_PX - BELT_HALF) & (D <= R_CURVE_PX + BELT_HALF) & (A >= a_lo) & (A <= a_hi)
    if cx_arc < CX:
        horiz = (XX <= cx_arc) & (np.abs(YY - Y_ENTRY) <= BELT_HALF)
    else:
        horiz = (XX >= cx_arc) & (np.abs(YY - Y_ENTRY) <= BELT_HALF)
    return horiz | arc

def belt_mask(straight, left_turn, right_turn):
    m = _top_strip()
    if straight:   m |= _straight_belt()
    if left_turn:  m |= _branch_belt(CX_L, 0, 90)
    if right_turn: m |= _branch_belt(CX_R, 90, 180)
    return m

# ── Rollers ───────────────────────────────────────────────────────────────────
def _roller_bars(x_lo, x_hi, belt_m):
    """Horizontal roller bars clipped to [x_lo, x_hi], hidden by belt and frame."""
    m = np.zeros((SIZE, SIZE), bool)
    for ry_scad in ROLLER_YS_SCAD:
        ry_pil = SIZE - ry_scad
        m |= (np.abs(YY - ry_pil) <= ROLLER_D) & (XX >= x_lo) & (XX <= x_hi)
    return m & ~belt_m & ~_FM

def _bottom_rollers(belt_m):
    """Horizontal bars in lower half for elements with both side entries."""
    n  = 12
    ys = [Y_MERGE + (SIZE - BORDER - Y_MERGE) * (i+1) / (n+1) for i in range(n)]
    m  = np.zeros((SIZE, SIZE), bool)
    for ry in ys:
        m |= (np.abs(YY - ry) <= ROLLER_D)
    return m & ~belt_m & ~_FM

def roller_mask(straight, left_turn, right_turn, belt_m):
    # Roller bars span from _rx_start to _rx_end; belt removes center strip.
    lx0, lx1 = _rx_start, CX - BELT_HALF
    rx0, rx1 = CX + BELT_HALF, _rx_end
    if straight and not left_turn and not right_turn:
        return _roller_bars(lx0, lx1, belt_m) | _roller_bars(rx0, rx1, belt_m)
    elif left_turn and not right_turn:
        return _roller_bars(rx0, rx1, belt_m)
    elif right_turn and not left_turn:
        return _roller_bars(lx0, lx1, belt_m)
    else:
        return _bottom_rollers(belt_m)

# ── Rivets ────────────────────────────────────────────────────────────────────
def _rivet_positions():
    pos = []
    for i in range(RIVET_N):
        t = _riv_inset + i * _riv_step
        pos.append((t,        _riv_inset))           # top edge
        pos.append((t,        SIZE - _riv_inset))    # bottom edge
        if 0 < i < RIVET_N - 1:
            pos.append((_riv_inset,        t))       # left edge
            pos.append((SIZE - _riv_inset, t))       # right edge
    return pos

def rivet_mask(belt_m):
    m = np.zeros((SIZE, SIZE), bool)
    for rx, ry in _rivet_positions():
        m |= (XX - rx)**2 + (YY - ry)**2 <= RIVET_R**2
    return m & ~belt_m & ~_FM

# ═══════════════════════════════════════════════════════════════════════════════
#  Image builder
# ═══════════════════════════════════════════════════════════════════════════════
def build_image(num, step):
    straight, left_turn, right_turn = ELEMENTS[num]

    belt_m   = belt_mask(straight, left_turn, right_turn) if step >= 3 else np.zeros((SIZE,SIZE), bool)
    arrow_m  = arrow_mask(straight, left_turn, right_turn) if step >= 1 else np.zeros((SIZE,SIZE), bool)
    # Step 1: arrowhead only (no shafts); Step 2+: full arrow
    if step == 1:
        arrow_m = arrowhead_mask()
    roller_m = roller_mask(straight, left_turn, right_turn, belt_m) if step >= 4 else np.zeros((SIZE,SIZE), bool)
    rivet_m  = rivet_mask(belt_m) if step >= 5 else np.zeros((SIZE,SIZE), bool)

    img = np.full((SIZE, SIZE, 3), C_BG, dtype=np.uint8)
    img[belt_m]   = C_BELT
    img[roller_m] = C_GREEN
    img[rivet_m]  = C_RIVET
    img[arrow_m]  = C_GREEN
    img[_FM]      = C_FRAME

    from PIL import Image as PILImage
    return PILImage.fromarray(img, 'RGB')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out',      default=r'c:\Users\hasse\OneDrive\Documents\git\MRR\Images\drawings')
    parser.add_argument('--elements', default='all')
    args = parser.parse_args()

    nums = sorted(ELEMENTS) if args.elements == 'all' else [int(x) for x in args.elements.split(',')]

    os.makedirs(args.out, exist_ok=True)
    for num in nums:
        img  = build_image(num, step=5)
        name = f'Element{num}.jpg'
        path = os.path.join(args.out, name)
        img.save(path, quality=95)
        print(f'  {name}')
    print('Done.')


if __name__ == '__main__':
    main()
