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

## Rollers (element10.scad)

```
ROLLER_COUNT  = 13 per side
ROLLER_H_IN   = 3/16"     slot height
ROLLER_INSET  = (plate_w / 10) / 2 = 0.14375"
ROLLER_X_START = 2 * ROLLER_INSET  = 0.2875" from plate edge
ROLLER_X_END   = plate_w - 2*ROLLER_INSET = 2.5875" from plate edge
```

Roller bars are horizontal stadium shapes (hull of two cylinders), spanning from X_START to X_END.
Y positions: evenly spaced from top to bottom of plate interior.

**Roller placement rules:**
- Straight only (E10): rollers on both sides (left strip + right strip of belt)
- Left turn entry (E12, E13): rollers on right side only
- Right turn entry (E11, E14): rollers on left side only
- Both sides occupied (E15, E16): bottom rollers (horizontal bars in lower half)

Rollers are hidden behind (clipped by) belt and frame.

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

- Roller display thickness is tuned for visibility (`ROLLER_H_IN / 4`), not the actual 3/16" slot height.
- Curved element rollers are drawn as horizontal bars (left or right of belt); the SCAD uses radial fan-shaped rollers centered on the arc hub.
