# New Element Builder Script — Implementation Plan

Based entirely on `ELEMENT_NOTES.md`. Do NOT reference `element_builder_agent.py`.

---

## Constants (all derived from inches, converted via S)

```python
S = 500 / (3.0 * 25.4)          # px/mm
SIZE = 500
CX = 250                         # tile center X

def _in(x): return x * 25.4 * S  # inches → px

FRAME_W   = _in(1/16)
PLATE_W   = _in(2 + 7/8)
PLATE_BOT = FRAME_W              # PIL Y of plate bottom edge (= top in SCAD)
BELT_W    = _in(1.75)
BELT_HALF = BELT_W / 2           # = 104 px (also b_L and b_top by symmetry)

# Arrow
ARROW_W        = BELT_W * 0.75
ARROW_TIP_IN   = 3*(2+7/8)/20 + 1/4 + 7*(2+7/8)/10   # inches
ARROW_SHAFT_W  = ARROW_W * 0.4
ARROW_SHAFT_H  = _in(1.5)
ARROW_HEAD_H   = ARROW_W / 2
ARROW_H        = ARROW_SHAFT_H + ARROW_HEAD_H
ARROW_Y        = _in(ARROW_TIP_IN) - ARROW_H          # shaft base from plate bottom (px)
OUTLINE        = _in(1/16)

# Curved belt
R_CURVE_PX    = 80
STRAIGHT_PX   = 20
H_STRAIGHT_PX = 40
SY1           = PLATE_BOT + ARROW_Y + ARROW_SHAFT_H    # arrowhead base (SCAD Y from bottom, in px)
Y_MERGE       = SIZE - SY1
Y_ARC_CENTER  = Y_MERGE + STRAIGHT_PX
Y_ENTRY       = Y_ARC_CENTER + R_CURVE_PX
CX_L          = CX - R_CURVE_PX   # = 170
CX_R          = CX + R_CURVE_PX   # = 330

# Rollers
ROLLER_COUNT  = 13
ROLLER_H_IN   = 3/16
ROLLER_D      = round(_in(ROLLER_H_IN) / 2)
ROLLER_INSET  = _in((2+7/8) / 10 / 2)
_rx_start     = _in(1/16) + 2*ROLLER_INSET
_rx_end       = _in(1/16) + _in(2+7/8) - 2*ROLLER_INSET
_ry_step      = _in((2+7/8 - 2*(ROLLER_INSET/_in(1))) / 12)  # recalc from notes formula
b_L  = CX - BELT_HALF   # = 104
b_R  = CX + BELT_HALF   # = 396
b_top = Y_ENTRY - BELT_HALF   # = 104 (same as b_L)
b_bot = Y_ENTRY + BELT_HALF   # = 396 (same as b_R)
nub  = _rx_end - b_R          # ≈ 46 px

# Rivets
RIVET_N      = 10
RIVET_R      = _in(3/32) / 2
RIVET_INSET  = _in((2+7/8)/10/2)
RIVET_STEP   = _in((2+7/8)/10)
```

---

## Pixel Grid

```python
import numpy as np
xs = np.arange(SIZE) + 0.5
ys = np.arange(SIZE) + 0.5
XX, YY = np.meshgrid(xs, ys)   # YY[0,0] = 0.5 = PIL top
```

---

## Layer Functions (return boolean masks or paint directly)

### 1. `draw_background(img)` — dark gray 500×500, then black frame border

### 2. `rivet_mask()` — 10 circles per side along each edge
- X positions: `frame_w + rivet_inset + i * rivet_step` for i=0..9
- Same spacing for Y positions
- Top/bottom rows: Y = `frame_w + rivet_inset`, `SIZE - frame_w - rivet_inset`
- Left/right cols: X = same offsets
- Return disk mask: `(XX-cx)**2 + (YY-cy)**2 <= RIVET_R**2`

### 3. `roller_mask(straight, left_turn, right_turn)` — green capsule bars
Five sub-components (see ELEMENT_NOTES.md roller strategy table):

**a. Horizontal bars** (all elements):
- 13 positions: `ry_scad[i] = _rx_start + i * _ry_step`; PIL_Y = SIZE - ry_scad
- Bar runs from `_rx_start` to `_rx_end` (full), clipped at `b_L`/`b_R` depending on turn flags
- Topmost (i=12) and bottommost (i=0) always full-width
- Non-straight: skip bars where `PIL_Y > Y_ARC_CENTER`

**b. Vertical entry bars** (left/right turn):
- For right_turn: X = ry_scad[i], skip if X < CX_R; vertical capsule
- For left_turn: X = SIZE - ry_scad[i], skip if X > CX_L; vertical capsule
- Outermost (i=12): full height `_rx_start` to `SIZE - _rx_start`
- Others: y_lo = b_top, y_hi = b_bot (straight) or SIZE - _rx_start (non-straight)

**c. Arc radial bars** (E11 right-only, E12 left-only):
- 11 bars at angles evenly spaced over 90°, with 2.25° end-gap margin
- r_outer ≈ 256 px, capsule length = nub
- E11: center (CX_R, Y_ARC_CENTER), angles 90°–180°
- E12: center (CX_L, Y_ARC_CENTER), angles 0°–90°

**d. Diagonal corner capsules**:
| Corner | Condition |
|--------|-----------|
| top-left (b_L, b_top), angle -135° | left_turn |
| bottom-left (b_L, b_bot), angle +135° | left_turn AND straight |
| top-right (b_R, b_top), angle -45° | right_turn |
| bottom-right (b_R, b_bot), angle +45° | right_turn AND straight |

**e. E16 bottom vertical bars** (not straight AND left AND right):
- 13 vertical capsules at ry_scad X positions
- y_lo = b_bot - round(BELT_HALF * 0.9), y_hi = SIZE - _rx_start

### 4. `belt_mask(straight, left_turn, right_turn)` — black
- Straight component: vertical strip `b_L` to `b_R`, full height
- Curved components (if left or right turn):
  - Horizontal entry: `b_top` to `b_bot`, X = 0 to CX_L (left) or CX_R to SIZE (right)
  - Arc annulus: distance from arc center between `R_CURVE_PX - BELT_HALF` and `R_CURVE_PX + BELT_HALF`, clipped to correct quadrant
  - Top straight strip: `b_L` to `b_R`, Y = 0 to Y_ARC_CENTER (shared vertical portion)

### 5. `arrow_outline_mask(straight, left_turn, right_turn)` — green

For each active arm (one per straight/left/right), build the arrow polygon mask:

**Straight arm** (pointing up):
- Shaft: `|XX - CX| <= SHO`, `SY0_pil <= YY <= SY1_pil`
- Head: triangle from base corners to tip
- Arrowhead base bar: connects shaft shoulder to head corners horizontally
- Then subtract inner hollow (offset by OUTLINE inward)

**Curved arms** (left/right):
- Vertical straight segment: `b_L..b_R`, `Y_MERGE..Y_ARC_CENTER`
- Arc annulus segment: inner/outer radii `R_CURVE_PX ± BELT_HALF/2` (shaft width), correct quadrant
- Horizontal straight: `H_STRAIGHT_PX` from arc end toward tile edge
- End cap: solid 1/16" bar closing the far end
- No arrowhead for curved arms

### 6. `arrow_interior_mask(straight, left_turn, right_turn)` — black (belt color)
Drawn AFTER all outlines — covers any green lines inside shaft hollows.

- Per-arm inset version of the shaft outline — the hollow region
- Straight: `|XX - CX| <= SHI`, inner range (SY0_pil + OUTLINE) to SY1_pil
- Curved: inset arc annulus hollow + inset horizontal segment hollow

### 7. `draw_frame(img)` — black 1/16" border on all 4 sides

---

## Element Table

| Element | straight | left_turn | right_turn |
|---------|----------|-----------|------------|
| 10 | True | False | False |
| 11 | False | False | True |
| 12 | False | True | False |
| 13 | True | True | False |
| 14 | True | False | True |
| 15 | True | True | True |
| 16 | False | True | True |

---

## Main Loop

```python
for N, (straight, left_turn, right_turn) in ELEMENTS.items():
    img = np.full((SIZE, SIZE, 3), DARK_GRAY, dtype=np.uint8)
    img[rivet_mask()] = LIGHT_GRAY
    img[roller_mask(straight, left_turn, right_turn)] = GREEN
    img[belt_mask(straight, left_turn, right_turn)] = BLACK
    img[arrow_outline_mask(straight, left_turn, right_turn)] = GREEN
    img[arrow_interior_mask(straight, left_turn, right_turn)] = BLACK
    draw_frame(img)
    Image.fromarray(img).save(f"Images/drawings/Element{N}.jpg")
```

---

## Colors

```python
DARK_GRAY  = (64, 64, 64)
LIGHT_GRAY = (169, 169, 169)
GREEN      = (0, 128, 0)
BLACK      = (0, 0, 0)
```

---

## Capsule Helper

```python
def capsule_mask(XX, YY, x0, y0, x1, y1, r):
    """Stadium/capsule: all points within r of the segment (x0,y0)-(x1,y1)."""
    dx, dy = x1-x0, y1-y0
    len2 = dx*dx + dy*dy
    t = np.clip(((XX-x0)*dx + (YY-y0)*dy) / len2, 0, 1)
    dist2 = (XX - (x0 + t*dx))**2 + (YY - (y0 + t*dy))**2
    return dist2 <= r*r
```

---

## CLI

```
python element_renderer.py [--elements 10,11,...] [--out DIR]
```
