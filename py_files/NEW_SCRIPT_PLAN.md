# New Element Builder Script — SCAD Generation Plan

All geometry defined inline. No external file references.

---

## Output

Python script writes one `.scad` file per element.

```
python element_scad_builder.py [--elements 10,11,...] [--out scad/]
```

Output: `scad/element{N}.scad`

Each generated file contains: constants block, element flag variables (`straight`, `left_turn`,
`right_turn`), all module definitions, and a final assembly call.

---

## Constants (inches — SCAD native units)

```
plate_w = 2 + 7/8          // 2.875
plate_d = 2 + 7/8
plate_h = 1/16
frame_w = 1/16

belt_w    = 1.75
belt_half = belt_w / 2     // 0.875

hole_d = 3/32
hole_r = hole_d / 2        // 3/64

roller_count  = 13
roller_h_size = 3/16
roller_r      = roller_h_size / 2    // 3/32
roller_inset  = plate_w / 20         // 0.14375
roller_x_lo   = 2 * roller_inset     // 0.2875  from plate edge
roller_x_hi   = plate_w - 2 * roller_inset      // 2.5875
roller_y_step = (plate_w - 2 * roller_inset) / 12  // 0.215625

b_L = plate_w / 2 - belt_half       // 0.5625  left belt edge (from plate)
b_R = plate_w / 2 + belt_half       // 2.3125  right belt edge
nub = roller_x_hi - b_R             // 0.275   bar extension past belt edge

arrow_w       = belt_w * 0.75       // 1.3125
arrow_shaft_w = arrow_w * 0.4       // 0.525
arrow_shaft_h = 1.5
arrow_head_h  = arrow_w / 2         // 0.65625
arrow_h       = arrow_shaft_h + arrow_head_h    // 2.15625
arrow_tip_y   = 3*plate_d/20 + 1/4 + 7*plate_d/10  // 2.69375 from plate bottom
arrow_y       = arrow_tip_y - arrow_h               // 0.5375 shaft base
arrow_outline = 1/16

// Curved belt (elements 11–16)
cx         = plate_w / 2            // 1.4375
r_curve    = 0.48                   // quarter-circle radius (80 px at 500px/3in)
y_merge    = arrow_y + arrow_shaft_h  // 2.0375  arrowhead base Y from plate bottom
y_arc_ctr  = y_merge + 0.12          // 2.1575  arc center Y
y_entry    = y_arc_ctr + r_curve      // 2.6375  belt entry Y on side edge
cx_l       = cx - r_curve            // 0.9575  left-turn arc center X
cx_r       = cx + r_curve            // 1.9175  right-turn arc center X
r_outer    = r_curve + belt_half      // 1.355   arc fill radius (belt_half > r_curve)
h_straight = 0.24                    // horizontal straight at belt entry for arrow arm
```

---

## Element Flags

Written at the top of each generated `.scad` file:

| Element | straight | left_turn | right_turn |
|---------|----------|-----------|------------|
| 10      | true     | false     | false      |
| 11      | false    | false     | true       |
| 12      | false    | true      | false      |
| 13      | true     | true      | false      |
| 14      | true     | false     | true       |
| 15      | true     | true      | true       |
| 16      | false    | true      | true       |

---

## SCAD Modules

### `rivet_holes()` / `rivets()`

10 per edge, all 4 edges.
- `spacing = plate_w / 10`, `inset = spacing / 2`
- For each edge, 10 cylinders at `inset + i * spacing` along that edge
- Front/back edges: skip positions where the rivet circle overlaps any roller slot. Since front/back
  rivet Y coincides exactly with cy[0] (front) and cy[12] (back), overlap is purely an X check:
  skip if `x > roller_x_lo + roller_r - hole_r` AND `x < roller_x_hi - roller_r + hole_r`
  (≈ x ∈ (0.334", 2.541")). This subsumes the belt zone skip since [b_L, b_R] ⊂ this range.
- `rivet_holes()` — pass-through cylinders subtracted from `plate()`
- `rivets()` — lightgray cylinders (`h = plate_h`) placed on plate surface

### `frame()`

Black `difference()`: outer cube (plate + `2 * frame_w` each side) minus inner plate void.

### `belt_cutout()`

Pass-through slot at `[(plate_w - belt_w)/2, -ε, -ε]`, size `[belt_w, plate_d + 2ε, plate_h + 2ε]`.
Subtracted from `plate()` and from `rollers()` green objects.

### `plate()`

`difference()` of darkgray cube: subtract `rivet_holes()`, `roller_slots()`, `belt_cutout()`.

---

### `roller_slots()` / `rollers()`

Both use the same capsule geometry; `roller_slots()` passes through the plate (for printing),
`rollers()` produces green `hull()` stadiums differenced with `belt_cutout()`.

**a. Horizontal bars** (all elements)

13 Y positions: `cy[i] = roller_inset + i * roller_y_step` for i = 0..12

- i=0 and i=12 (outermost rows): always full-width, `x_lo = roller_x_lo`, `x_hi = roller_x_hi`
- Non-straight elements: skip bars where `cy[i] < y_arc_ctr` (keep only top-section bars)
- Left-clipped bars: `x_lo = b_L` on left side
- Right-clipped bars: `x_hi = b_R` on right side
- Clipping applies to turn sides; i=0 and i=12 are always full-width regardless

**b. Vertical entry bars** (left_turn or right_turn)

X positions use same `rx[i] = roller_inset + i * roller_y_step` spacing.

- Right side: bar X = `rx[i]`; skip if `rx[i] < cx_r`
- Left side: bar X = `plate_w - rx[i]`; skip if `plate_w - rx[i] > cx_l`
- i=12 (outermost column): full height — `y_lo = roller_x_lo`, `y_hi = plate_d - roller_x_lo`
- All other bars: `y_lo = y_entry - belt_half`; `y_hi = y_entry + belt_half` (straight), else `plate_d - roller_x_lo` (non-straight)

**c. Arc radial bars** (E11 right-only or E12 left-only)

11 bars (not 13), evenly spaced over 90° with 2.25° end-gap margin at each end:

- E11: center `(cx_r, y_arc_ctr)`, angles 90°–180° (standard math)
- E12: center `(cx_l, y_arc_ctr)`, angles 0°–90°
- `r_outer_bars = plate_w - roller_x_lo` ≈ 2.5875" (outer cap edge)
- Capsule length = `nub` (0.275"), each bar is a radial capsule at angle θ

**d. Diagonal corner bars**

Short capsule (`length = nub`, at 45°) at each active belt corner:

| Corner | Position (SCAD) | Angle (SCAD, Y-up) | Condition |
|--------|-----------------|---------------------|-----------|
| Top-right   | `(b_R, y_entry - belt_half)` | +45° | right_turn |
| Bottom-right | `(b_R, y_entry + belt_half)` | −45° | right_turn AND straight |
| Top-left    | `(b_L, y_entry - belt_half)` | +135° | left_turn |
| Bottom-left  | `(b_L, y_entry + belt_half)` | −135° | left_turn AND straight |

**e. E16 bottom vertical bars** (not straight AND left_turn AND right_turn)

13 vertical capsules at `rx[i]` X positions:
- `y_lo = y_entry + belt_half - belt_half * 0.9` ≈ `y_entry + belt_half * 0.1`
- `y_hi = plate_d - roller_x_lo`

---

### Roller strategy per element

| Element | Horiz bars | Vert entry | Arc bars | Corner diags | Bottom bars |
|---------|------------|------------|----------|--------------|-------------|
| E10 | 13, full-width | — | — | — | — |
| E11 | top-section, right-clipped | right | 11 (cx_r, 90°–180°) | top-right | — |
| E12 | top-section, left-clipped | left | 11 (cx_l, 0°–90°) | top-left | — |
| E13 | 13, left-clipped | left | — | top-left + bottom-left | — |
| E14 | 13, right-clipped | right | — | top-right + bottom-right | — |
| E15 | 13, both-clipped | both | — | all 4 | — |
| E16 | top-section, both-clipped | both | — | top-left + top-right | 13 vertical |

"Top-section" = bars where `cy[i] >= y_arc_ctr` (i = 10..12 with corrected cy formula).

---

### `arrow_2d()`

7-point polygon, center at X=0, base at Y=0 (pointing up):

```
[-arrow_shaft_w/2, 0],  [arrow_shaft_w/2, 0],
[arrow_shaft_w/2, arrow_shaft_h],  [arrow_w/2, arrow_shaft_h],
[0, arrow_h],
[-arrow_w/2, arrow_shaft_h],  [-arrow_shaft_w/2, arrow_shaft_h]
```

### `arrow()`

**Straight arm** (if `straight`):

```scad
translate([plate_w/2, arrow_y, 0])
linear_extrude(plate_h)
difference() { arrow_2d();  offset(delta = -arrow_outline) arrow_2d(); }
```

**Curved arm** (if `left_turn` or `right_turn`):

Green hollow outline (1/16" thick) only — no arrowhead. Per active turn side:

1. Vertical segment: `arrow_shaft_w` wide centered at `cx` (= plate_w/2, both turn sides),
   from `y_merge` to `y_arc_ctr` (height 0.12").
   Arc endpoint at 180° (right turn) / 0° (left turn) is at `(cx, y_arc_ctr)` — vertical segment
   must meet arc there, so center is cx regardless of turn side.
2. Arc shaft: annulus `linear_extrude(plate_h)` of
   `difference(circle(r_curve + arrow_shaft_w/2), circle(r_curve - arrow_shaft_w/2))`,
   clipped to correct 90° quadrant at arc center, minus inner hollow
   (offset inward by arrow_outline)
3. Horizontal segment: `h_straight` = 0.24" long from arc endpoint toward tile edge,
   `arrow_shaft_w` wide, hollow (outline only)
4. End cap: solid `arrow_outline`-thick bar closing the far end of the horizontal segment

---

### `belt()`

**Straight component** (if `straight`):

```scad
difference() {
    translate([(plate_w - belt_w)/2, 0, 0]) cube([belt_w, plate_d, plate_h]);
    arrow_cutout();
}
```

Where `arrow_cutout()` is the same `arrow_2d() minus offset(-arrow_outline)` extrusion
subtracted from the belt so the arrow outline remains visible.

**Curved components** (per active turn side):

1. **Horizontal entry** — black cube from arc center X to tile edge, height `belt_w`,
   centered on `y_entry`:
   - Right: `translate([cx_r, y_entry - belt_half, 0]) cube([plate_w - cx_r, belt_w, plate_h])`
   - Left:  `translate([0,    y_entry - belt_half, 0]) cube([cx_l,            belt_w, plate_h])`

2. **Arc corner fill** — filled quarter-circle of radius `r_outer = r_curve + belt_half`
   (`belt_half > r_curve` so inner radius is zero; this is a solid sector, not an annulus):
   ```scad
   // Right turn: upper-left quadrant of (cx_r, y_arc_ctr)
   translate([cx_r, y_arc_ctr, 0])
   linear_extrude(plate_h)
   intersection() {
       circle(r = r_outer, $fn = 120);
       translate([-r_outer, 0]) square([r_outer, r_outer]);
   }

   // Left turn: upper-right quadrant of (cx_l, y_arc_ctr)
   translate([cx_l, y_arc_ctr, 0])
   linear_extrude(plate_h)
   intersection() {
       circle(r = r_outer, $fn = 120);
       square([r_outer, r_outer]);
   }
   ```

3. **Top straight strip** — shared vertical belt section above arc center:
   `translate([b_L, 0, 0]) cube([belt_w, y_arc_ctr, plate_h])`

---

## Assembly

```scad
frame();
plate();
rivets();
rollers();
belt();
arrow();
```

---

## CLI

```
python element_scad_builder.py [--elements 10,11,...] [--out DIR]
```

---

## Status

### Exists

| File | Notes |
|------|-------|
| `scad/element10.scad` | Complete, working — straight tile reference |
| `py_files/NEW_SCRIPT_PLAN.md` | This file — full geometry spec |
| `py_files/ELEMENT_NOTES.md` | Pixel-space reference for the Python image generator |

### Missing

| File | Notes |
|------|-------|
| `py_files/element_scad_builder.py` | Python generator script — not yet written |
| `scad/element11.scad` | Right-turn only (straight=false, right_turn=true) — not yet written |
| `scad/element12.scad` | Left-turn only — not yet written |
| `scad/element13.scad` | Straight + left turn — not yet written |
| `scad/element14.scad` | Straight + right turn — not yet written |
| `scad/element15.scad` | Straight + left + right — not yet written |
| `scad/element16.scad` | Left + right, no straight — not yet written |

### Approach

Option A: Write `py_files/element_scad_builder.py` to generate all `.scad` files programmatically.  
Option B: Write each `.scad` file directly by hand, following this spec.
