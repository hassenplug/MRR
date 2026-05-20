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

Run:  python element_builder_agent.py [--elements N,M,...] [--out DIR]
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

ROLLER_D  = round(_in(ROLLER_H_IN) / 2)   # half-thickness = actual SCAD roller radius (3/32")

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

# ── Arrow interior (hollow fill — belt color, covers lines from other shafts) ──
def _straight_shaft_interior():
    cap = round(_in(ARROW_OUT_IN))
    return (YS >= SY0 + cap) & (YS <= SY1) & (np.abs(XX - CX) <= SHI)

def _arc_shaft_interior(cx_arc, a_lo, a_hi):
    D = np.sqrt((XX - cx_arc)**2 + (YY - Y_ARC_CENTER)**2)
    A = np.degrees(np.arctan2(YY - Y_ARC_CENTER, XX - cx_arc))
    arc_inn = (D >= R_CURVE_PX - SHI) & (D <= R_CURVE_PX + SHI) & (A >= a_lo) & (A <= a_hi)
    cap = round(_in(ARROW_OUT_IN))
    if cx_arc < CX:
        h_inn = (XX >= cx_arc - H_STRAIGHT_PX + cap) & (XX <= cx_arc) & (np.abs(YY - Y_ENTRY) <= SHI)
    else:
        h_inn = (XX >= cx_arc) & (XX <= cx_arc + H_STRAIGHT_PX - cap) & (np.abs(YY - Y_ENTRY) <= SHI)
    v_inn = (YY >= Y_MERGE) & (YY <= Y_ARC_CENTER) & (np.abs(XX - CX) <= SHI)
    return arc_inn | h_inn | v_inn

def arrow_interior_mask(straight, left_turn, right_turn):
    m = _head_inner()
    if straight:   m |= _straight_shaft_interior()
    if left_turn:  m |= _arc_shaft_interior(CX_L, 0, 90)
    if right_turn: m |= _arc_shaft_interior(CX_R, 90, 180)
    return m

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
def _stadium(ry, x_lo, x_hi, cap_lo=True, cap_hi=True):
    """Stadium shape at PIL row ry. cap_lo/cap_hi control semicircle caps on each end."""
    xl = x_lo + ROLLER_D if cap_lo else x_lo
    xr = x_hi - ROLLER_D if cap_hi else x_hi
    body = (np.abs(YY - ry) <= ROLLER_D) & (XX >= xl) & (XX <= xr)
    result = body
    if cap_lo:
        result = result | ((XX - xl)**2 + (YY - ry)**2 <= ROLLER_D**2)
    if cap_hi:
        result = result | ((XX - xr)**2 + (YY - ry)**2 <= ROLLER_D**2)
    return result

def _vstadium(rx, y_lo, y_hi):
    """Vertical capsule at PIL column rx, running from y_lo to y_hi."""
    yt = float(y_lo + ROLLER_D)
    yb = float(y_hi - ROLLER_D)
    body = (np.abs(XX - rx) <= ROLLER_D) & (YY >= yt) & (YY <= yb)
    return body | ((XX - rx)**2 + (YY - yt)**2 <= ROLLER_D**2) | \
                  ((XX - rx)**2 + (YY - yb)**2 <= ROLLER_D**2)

def _arc_roller_bars(cx, cy, a_lo, a_hi, count=ROLLER_COUNT, margin=0.0):
    """Radial roller bars fanning from arc center (cx, cy), count bars evenly spaced from a_lo+margin to a_hi-margin degrees."""
    r_outer = float(SIZE - Y_ARC_CENTER - _rx_start - ROLLER_D)  # outer cap edge aligns with straight bar extent
    eff_lo = a_lo + margin
    eff_hi = a_hi - margin
    m = np.zeros((SIZE, SIZE), bool)
    for i in range(count):
        a_deg = eff_lo + i * (eff_hi - eff_lo) / (count - 1)
        a_rad = _math.radians(a_deg)
        ca, sa = _math.cos(a_rad), _math.sin(a_rad)
        ix = float(cx + ROLLER_D * ca)
        iy = float(cy + ROLLER_D * sa)
        ox = float(cx + r_outer * ca)
        oy = float(cy + r_outer * sa)
        seg_dx, seg_dy = ox - ix, oy - iy
        seg_len2 = seg_dx**2 + seg_dy**2
        t = np.clip(((XX - ix)*seg_dx + (YY - iy)*seg_dy) / seg_len2, 0.0, 1.0)
        dist2 = (XX - (ix + t*seg_dx))**2 + (YY - (iy + t*seg_dy))**2
        m |= dist2 <= ROLLER_D**2
    return m & ~_FM

def _element_rollers(straight, left_turn, right_turn):
    """Unified roller mask for all elements.

    Corner treatment: at each belt outer corner, the nearest horizontal bar
    (ROLLER_YS_SCAD[-1] for top, ROLLER_YS_SCAD[0] for bottom) is kept full-width;
    all other bars are clipped at the belt edge so their nubs don't appear in the
    corner gap.  A 45° diagonal capsule extends nub-length from each active corner.
    Arc radial bars are added for curved entry branches."""
    nub   = _rx_end - (CX + BELT_HALF)   # ≈ 46 px — same extension as normal bar nubs
    b_top = float(Y_ENTRY - BELT_HALF)   # 104 px — top belt edge
    b_bot = float(Y_ENTRY + BELT_HALF)   # 396 px — bottom belt edge
    b_L   = float(CX - BELT_HALF)        # 104 px — left belt edge
    b_R   = float(CX + BELT_HALF)        # 396 px — right belt edge
    m = np.zeros((SIZE, SIZE), bool)

    # Horizontal roller bars
    for ry_scad in ROLLER_YS_SCAD:
        ry = float(SIZE - ry_scad)
        if not straight and ry > Y_ARC_CENTER:
            continue
        x_lo, x_hi = _rx_start, _rx_end
        if ry_scad != ROLLER_YS_SCAD[-1] and ry_scad != ROLLER_YS_SCAD[0]:
            if left_turn and (ry < b_top or not straight):
                x_lo = b_L
            if left_turn and straight and ry > b_bot:
                x_lo = b_L
            if right_turn and (ry < b_top or not straight):
                x_hi = b_R
            if right_turn and straight and ry > b_bot:
                x_hi = b_R
        m |= _stadium(ry, x_lo, x_hi)

    # E16 bottom vertical bars — mirrors entry-bar style across the full tile width
    if not straight and left_turn and right_turn:
        y_lo = b_bot - round(BELT_HALF * 0.9)   # tuck bars almost halfway into belt from bottom
        y_hi = float(SIZE - _rx_start)
        for ry_scad in ROLLER_YS_SCAD:
            m |= _vstadium(float(ry_scad), y_lo, y_hi)

    # Vertical entry bars
    for side, cx_arc in ((1, CX_R), (-1, CX_L)):
        if (side > 0 and not right_turn) or (side < 0 and not left_turn):
            continue
        for ry_scad in ROLLER_YS_SCAD:
            rx = float(ry_scad if side > 0 else SIZE - ry_scad)
            if (side > 0 and rx < cx_arc) or (side < 0 and rx > cx_arc):
                continue
            y_lo = float(_rx_start)
            y_hi = float(SIZE - _rx_start)
            if ry_scad != ROLLER_YS_SCAD[-1]:
                y_lo = b_top
                if straight:
                    y_hi = b_bot
            m |= _vstadium(rx, y_lo, y_hi)

    # 45° diagonal corner bars
    corners = []
    if left_turn:
        corners.append((b_L, b_top, -135.0))
        if straight:
            corners.append((b_L, b_bot, +135.0))
    if right_turn:
        corners.append((b_R, b_top, -45.0))
        if straight:
            corners.append((b_R, b_bot, +45.0))
    for cx, cy, deg in corners:
        ang = _math.radians(deg)
        x0, y0 = cx, cy
        x1 = x0 + nub * _math.cos(ang)
        y1 = y0 + nub * _math.sin(ang)
        dx, dy = x1 - x0, y1 - y0
        seg_len2 = dx**2 + dy**2
        t = np.clip(((XX - x0)*dx + (YY - y0)*dy) / seg_len2, 0.0, 1.0)
        dist2 = (XX - (x0 + t*dx))**2 + (YY - (y0 + t*dy))**2
        m |= dist2 <= ROLLER_D**2

    # Arc radial bars: only for pure curved elements (E11/E12)
    if not straight and right_turn != left_turn:
        arc_count  = ROLLER_COUNT - 2
        arc_margin = (90.0 / (arc_count - 1)) / 4
        if right_turn:
            m |= _arc_roller_bars(CX_R, Y_ARC_CENTER, 90, 180, arc_count, arc_margin)
        if left_turn:
            m |= _arc_roller_bars(CX_L, Y_ARC_CENTER, 0, 90, arc_count, arc_margin)

    return m & ~_FM


def roller_mask(straight, left_turn, right_turn, belt_m):
    return _element_rollers(straight, left_turn, right_turn)

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

    belt_m  = belt_mask(straight, left_turn, right_turn) if step >= 3 else np.zeros((SIZE,SIZE), bool)
    if step >= 1:
        if step == 1:
            arrow_m     = arrowhead_mask()
            arrow_int_m = _head_inner()
        else:
            arrow_m     = arrow_mask(straight, left_turn, right_turn)
            arrow_int_m = arrow_interior_mask(straight, left_turn, right_turn)
    else:
        arrow_m     = np.zeros((SIZE,SIZE), bool)
        arrow_int_m = np.zeros((SIZE,SIZE), bool)
    roller_m = roller_mask(straight, left_turn, right_turn, belt_m) if step >= 4 else np.zeros((SIZE,SIZE), bool)
    rivet_m  = rivet_mask(belt_m) if step >= 5 else np.zeros((SIZE,SIZE), bool)

    img = np.full((SIZE, SIZE, 3), C_BG, dtype=np.uint8)
    img[rivet_m]     = C_RIVET   # 1. rivets
    img[roller_m]    = C_GREEN   # 2. rollers
    img[belt_m]      = C_BELT    # 3. belt
    img[arrow_m]     = C_GREEN   # 4. arrow outline
    img[arrow_int_m] = C_BELT    # 5. arrow interior (belt color — drawn after all arrows)
    img[_FM]         = C_FRAME

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
