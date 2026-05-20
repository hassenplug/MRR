# Element Builder Notes

## Overview

Generating JPG preview images for conveyor belt arrow tiles (Elements 10–16).
Source of truth: `scad/element10.scad` (straight) and `scad/element11.scad` (right-turn arc).

Each tile is **3.0" × 3.0"** outer (2-7/8" plate + 1/16" frame on each side).
Rendered at **500 × 500 px** → S ≈ 6.561 px/mm.

---

## Tile Geometry

```
PLATE_W_IN  = 2 + 7/8   = 2.875"
FRAME_W_IN  = 1/16      = 0.0625"
TILE_W_IN   = 3.0"
```

Pixel scale: `S = 500 / (3.0 * 25.4)` ≈ 6.561 px/mm

---

## Elements

| # | Straight | Left turn | Right turn |
|---|----------|-----------|------------|
| 10 | ✓ | | |
| 11 | | | ✓ |
| 12 | | ✓ | |
| 13 | ✓ | ✓ | |
| 14 | ✓ | | ✓ |
| 15 | ✓ | ✓ | ✓ |
| 16 | | ✓ | ✓ |

---

## What Each Element Contains (from SCAD)

Each element is made up of:
1. **Dark gray plate** background (darkgray, 2-7/8" square)
2. **Black frame** border (1/16" wide, surrounds the plate)
3. **Black belt** strip
4. **Green arrow** (hollow outline — outer polygon minus inset offset)
5. **Green rollers** — 13 on each side of the belt (26 total for straight element)
6. **Light gray rivets** — 10 per side

---

## Arrow Geometry

The arrowhead tip position is fixed at `_ARROW_TIP_IN` from the plate bottom.
The shaft length is set independently; `ARROW_Y_IN` (shaft base) is derived to keep the tip fixed.

```
BELT_W_IN        = 1.75"
ARROW_W_IN       = BELT_W_IN * 0.75      = 1.3125"    full arrow width
_ARROW_TIP_IN    = 3*plate_d/20 + 1/4 + 7*plate_d/10 = 2.694"  tip from plate bottom (fixed)
ARROW_OUT_IN     = 1/16                  = 0.0625"     outline thickness

ARROW_HEAD_H_IN  = ARROW_W_IN / 2        = 0.65625"
ARROW_SHAFT_W_IN = ARROW_W_IN * 0.4      = 0.525"
ARROW_SHAFT_H_IN = 1.5"                             shaft length (tunable)
ARROW_H_IN       = ARROW_SHAFT_H_IN + ARROW_HEAD_H_IN = 2.15625"
ARROW_Y_IN       = _ARROW_TIP_IN - ARROW_H_IN       = 0.5375"  shaft base from plate bottom
```

The SCAD `arrow_2d()` polygon (Y=0 at shaft base, pointing up):
```
[-shaft_w/2, 0]
[ shaft_w/2, 0]
[ shaft_w/2, shaft_h]
[ arrow_w/2, shaft_h]   ← arrowhead base corners
[ 0,         arrow_h]   ← tip
[-arrow_w/2, shaft_h]
[-shaft_w/2, shaft_h]
```

Arrow is rendered as: `arrow_2d() MINUS offset(-1/16") arrow_2d()` → uniform 1/16" hollow outline.

### Arrowhead base horizontal bar

The horizontal step at `y = shaft_h` (from `±shaft_w/2` to `±arrow_w/2`) creates a horizontal
green bar in the outline connecting the head base corners to the shaft top. This bar is explicitly
added to the pixel mask — it is NOT produced automatically by the head or shaft masks alone.

```python
bar = (YS >= SIY1) & (YS <= SY1) & (np.abs(XX - CX) >= SHO) & (np.abs(XX - CX) <= HHO)
```

---

## Arrow Pixel Values

All SCAD Y coordinates are from tile bottom; PIL Y is from top → `PIL_Y = SIZE - SCAD_Y`.

```python
SY0  = plate_bottom + arrow_y                     # shaft base (SCAD Y from bottom)
SY1  = plate_bottom + arrow_y + shaft_h           # shaft top / head base
HY1  = plate_bottom + arrow_y + arrow_h           # head tip

SHO  = shaft_w / 2                    # shaft outer half-width
SHI  = (shaft_w - 2*outline) / 2      # shaft inner half-width
SIY1 = SY1 - outline_px               # inner stem top / shoulder bar bottom

HHO  = arrow_w / 2                    # head outer half-width at base
HHI  = HHO - outline / sin(45°)       # head inner half-width
HIY0 = SY1                            # head inner hollow starts at head base
HIY1 = HY1 - outline / sin(45°)       # head inner hollow tip
```

### Shaft Hollow Orientation

- Solid cap at BOTTOM (1/16" thick)
- Open at TOP (connects into arrowhead hollow at Y=SY1)
- Inner hollow: `inner_bot = SY0 + outline_px` to `SY1`

---

## Belt Geometry

### Element 10 (straight)
Belt is a simple vertical strip:
```
width = 1.75" centered on tile
belt_x_lo = (tile_w - belt_w) / 2
belt_x_hi = (tile_w + belt_w) / 2
runs full tile height
```

### Elements 11–16 (curved turns)
Belt enters the tile **horizontally** from the left or right edge at `Y_ENTRY`, then curves
with a **quarter-circle arc** up to `Y_ARC_CENTER`, followed by a short **vertical straight**
to `Y_MERGE` (arrowhead base level).

```
R_CURVE_PX    = 80 px    quarter-circle radius
STRAIGHT_PX   = 20 px    vertical straight at top of arc (arrow shaft outline only)
H_STRAIGHT_PX = 40 px    horizontal straight at side entry (arrow shaft outline only)

Y_MERGE      = SIZE - SY1               arrowhead base level (PIL Y from top)
Y_ARC_CENTER = Y_MERGE + STRAIGHT_PX    arc center Y
Y_ENTRY      = Y_ARC_CENTER + R_CURVE_PX   belt entry Y on tile side edge
CX_L         = CX - R_CURVE_PX          arc center X for left branch
CX_R         = CX + R_CURVE_PX          arc center X for right branch
```

Left branch:  arc angles 0°–90°,   horizontal section exits left tile edge  
Right branch: arc angles 90°–180°,  horizontal section exits right tile edge

**Belt vs. shaft outline:**
- The **belt** (black) extends to the tile edge in both directions.
- The **shaft outline** (green) is limited to `H_STRAIGHT_PX = 40 px` from the arc end,
  with a solid 1/16" end cap closing the far end.

The top strip (straight belt, Y=0 to `Y_ARC_CENTER`) is shared by all curved elements and
covers the vertical straight segment between `Y_MERGE` and `Y_ARC_CENTER`.

---

## Rollers

```
ROLLER_COUNT  = 13
ROLLER_H_IN   = 3/16"     slot height  →  ROLLER_D = round(_in(3/16) / 2) ≈ 16 px (cap radius)
ROLLER_INSET  = (plate_w / 10) / 2 = 0.14375"
_rx_start     = _in(frame_w + 2*ROLLER_INSET) ≈ 58 px from tile edge   (bar/bar-column start)
_rx_end       = _in(frame_w + plate_w - 2*ROLLER_INSET) ≈ 442 px       (bar/bar-column end)
_ry_step      = _in((plate_w - 2*ROLLER_INSET) / 12) ≈ 36 px           (spacing between bars)
```

Roller bars are stadium shapes (capsule = rectangle + two semicircle caps).
The belt is drawn over the rollers, so only portions outside the belt are visible.

All elements use the unified `_element_rollers()` function, which assembles up to five
component types depending on the element's straight/left/right flags.

### Key belt-edge pixel values

```
b_top = Y_ENTRY - BELT_HALF = 104 px    top edge of horizontal entry belt
b_bot = Y_ENTRY + BELT_HALF = 396 px    bottom edge of horizontal entry belt
b_L   = CX - BELT_HALF     = 104 px    left edge of straight/arc belt
b_R   = CX + BELT_HALF     = 396 px    right edge of straight/arc belt
nub   = _rx_end - b_R      ≈  46 px    extension past belt edge (matches normal bar nubs)
```

Note: `b_top == b_L` and `b_bot == b_R` (both = 104 and 396) due to tile symmetry.

### 1. Horizontal bars

At every ROLLER_YS_SCAD position (13 total), PIL y = SIZE − SCAD_Y:

- **Non-straight elements**: skip bars where PIL y > Y_ARC_CENTER (only top-section bars drawn).
- **ROLLER_YS_SCAD[-1]** (topmost, PIL y ≈ 34) and **ROLLER_YS_SCAD[0]** (bottommost, PIL y ≈ 466)
  are always full-width (`_rx_start` to `_rx_end`).
- **All other bars** are clipped at the belt edge on each active turn side:
  - `left_turn` and (bar is in top section OR non-straight): `x_lo = b_L`
  - `right_turn` and (bar is in top section OR non-straight): `x_hi = b_R`
  - For straight+turn elements, bars below `b_bot` are also clipped on the turn side.

### 2. Vertical entry bars

For each active turn side:

- **Right side** (right_turn): `rx = ry_scad`; skip if `rx < CX_R` (330).
- **Left side** (left_turn): `rx = SIZE − ry_scad`; skip if `rx > CX_L` (170).
- **ROLLER_YS_SCAD[-1] bar** (outermost column): full height — `y_lo = _rx_start`, `y_hi = SIZE − _rx_start`.
- **All other bars**: `y_lo = b_top`; `y_hi = b_bot` if straight, else `SIZE − _rx_start`.

### 3. 45° diagonal corner bars

A short capsule bar (length = `nub` ≈ 46 px) at 45° fills the corner gap between the outermost
horizontal bar nub and the outermost vertical entry bar nub at each active belt corner:

| Corner | Position | Angle | Condition |
|--------|----------|-------|-----------|
| Top-left | (b_L, b_top) | −135° (up-left) | left_turn |
| Bottom-left | (b_L, b_bot) | +135° (down-left) | left_turn AND straight |
| Top-right | (b_R, b_top) | −45° (up-right) | right_turn |
| Bottom-right | (b_R, b_bot) | +45° (down-right) | right_turn AND straight |

### 4. Arc radial bars (E11 and E12 only)

Only drawn when `not straight` and exactly one of left/right turn is active.

- **11 bars** (ROLLER_COUNT − 2), evenly spaced with a 2.25° end-gap margin at each end
  (= quarter of the per-bar angular spacing).
- `r_outer ≈ 256 px` — outer cap edge aligns with the extent of straight bars at the tile edge.
- E11 (right turn): center `(CX_R=330, Y_ARC_CENTER=170)`, angles 90°–180°.
- E12 (left turn): center `(CX_L=170, Y_ARC_CENTER=170)`, angles 0°–90°.

### 5. E16 bottom vertical bars (E16 only)

Only drawn when `not straight` and both left_turn and right_turn are active.

- Vertical capsules at every ROLLER_YS_SCAD X position (13 total, spanning full tile width).
- `y_lo = b_bot − round(BELT_HALF × 0.9)` ≈ 265 px — extends bars under the belt from the bottom.
- `y_hi = SIZE − _rx_start` ≈ 442 px.

### Roller strategy per element

| Element | Horiz bars | Entry bars | Arc bars | Corner diags | Bottom bars |
|---------|------------|------------|----------|--------------|-------------|
| E10 | 13, full-width | — | — | — | — |
| E11 | top section, right-clipped | right-side | 11 radial (CX_R, 90°–180°) | top-right | — |
| E12 | top section, left-clipped | left-side | 11 radial (CX_L, 0°–90°) | top-left | — |
| E13 | 13, left-clipped | left-side | — | top-left + bottom-left | — |
| E14 | 13, right-clipped | right-side | — | top-right + bottom-right | — |
| E15 | 13, both-clipped | both sides | — | all 4 corners | — |
| E16 | top section, both-clipped | both sides | — | top-left + top-right | vertical capsules |

---

## Rivets (element11.scad)

```
RIVET_N      = 10 per side
RIVET_HOLE   = 3/32" diameter  →  RIVET_R = _in(3/32) / 2  (actual SCAD radius)
RIVET_INSET  = (plate_w / 10) / 2 = 0.14375"  from plate edge
             = frame_w + RIVET_INSET = 0.20625" from tile edge
RIVET_STEP   = plate_w / 10 = 0.2875"
```

Rivets appear on all 4 edges. Hidden behind belt and frame.

---

## Drawing Order

Layers are painted in this order (later layers cover earlier ones):

1. **Background** — dark gray plate
2. **Rivets** — light gray circles
3. **Rollers** — green bars
4. **Belt** — black strip (covers rivets and rollers underneath)
5. **Arrow outline** — green (all shafts and arrowhead)
6. **Arrow interior** — belt color (black); drawn *after* all arrow outlines so it covers any green lines from other shafts that fall inside a shaft's hollow
7. **Frame** — black border (always on top)

---

## Output

Script generates one complete image per element (all layers combined):

```
python element_builder_agent.py [--elements N,M,...] [--out DIR]
```

Output: `Images/drawings/Element{N}.jpg`

---

## Files

| File | Purpose |
|------|---------|
| `py_files/element_builder_agent.py` | Main image generator for all 7 elements |
| `scad/element10.scad` | Reference: straight belt tile |
| `scad/element11.scad` | Reference: right-turn arc tile |
| `Images/drawings/Element{N}.jpg` | Output images |

---

## Known Issues / Open Questions

- `ROLLER_D = round(_in(ROLLER_H_IN) / 2)` matches the SCAD `roller_r = roller_h_size / 2` radius,
  so roller bar thickness is accurate, but bars are drawn as straight capsules rather than the SCAD's
  curved stadium shapes that follow the belt arc.
- Arc radial bars (E11/E12) are straight radial capsules; the SCAD uses curved bars that follow the
  belt arc annulus, so the visual differs near the belt edge.
- E13/E14/E15 bottom corners (bottom-left for E13, bottom-right for E14, all bottom for E15)
  currently have the diagonal corner bar but are missing the vertical entry bar nub that appears
  in E11's top-right corner, so those corners show 2 blobs instead of 3.
