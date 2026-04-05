Create an OpenSCAD file for an MRR tile based on the image at: $ARGUMENTS

## MRR Tile Specification

All tiles are **3" × 3" × 1/8"** (but modeled as 2 7/8" × 2 7/8" plate + 1/16" border on each side):

```
plate_w = 2 + 7/8;   // 2.875"
plate_d = 2 + 7/8;   // 2.875"
plate_h = 1/16;      // 0.0625"
frame_w = 1/16;      // black border extends outside the plate
hole_d  = 3/32;
hole_r  = hole_d / 2;
```

**Standard modules every tile must include:**
- `frame()` — black border ring around the plate edge (uses `color("black")`)
- `plate()` — darkgray base with rivet holes subtracted (uses `color("darkgray")`)
- `rivets()` — lightgray cylinders flush with top surface (uses `color("lightgray")`)

**Rivet pattern:** 10 rivets per side (front, back, left, right — corners shared), inset by half the spacing:
```
spacing_x = plate_w / 10;
spacing_y = plate_d / 10;
inset_x   = spacing_x / 2;
inset_y   = spacing_y / 2;
```

**rivet_holes() subtracts holes through the plate** (same positions, h = plate_h + 2, translated z = -1).

## Your Task

1. **Read/view the image** at the provided path to understand its visual content.

2. **Identify the key visual elements:**
   - What colors are present (map to OpenSCAD color names or hex: `color([r,g,b])`)
   - What shapes/regions exist (arrows, belts, gears, hazard stripes, etc.)
   - Which areas of the tile each element occupies (use fractional coordinates relative to `plate_w`/`plate_d`)

3. **Create the SCAD file** with:
   - A header comment naming the element and describing it
   - The standard dimension variables
   - `rivet_holes()` module
   - `frame()` module  
   - `plate()` module (subtract rivet_holes and any feature cutouts)
   - `rivets()` module
   - One module per major visual feature, each wrapped in its own `color()` call
   - A final section that calls all modules

4. **Geometry guidelines:**
   - All geometry stays within the 3×3" footprint (plate starts at [0,0] and goes to [plate_w, plate_d])
   - Features sit at z=0 and have height = `plate_h` (flush with top surface)
   - Use `linear_extrude(plate_h)` for 2D shapes
   - Use `polygon()` for complex outlines (arrows, chevrons, etc.)
   - Use `hull()` of two `cylinder()`s for stadium/slot shapes (like roller slots)
   - Use `difference()` to cut features out of the plate background
   - Use `offset(delta = -thickness)` to create outline-only versions of shapes
   - For diagonal hazard stripes: use rotated rectangles clipped to the tile area

5. **Determine the output filename** from the image name (e.g., `Images/Element10.jpg` → `aaron/element10.scad`) and write the file there. Use `Glob` to find the actual file if the argument has a typo.

6. **Show the user** a summary of what visual elements you detected and how you mapped them to geometry.

## Example patterns from existing tiles

**Belt (vertical black stripe with cutout):**
```openscad
belt_w = 1.75;
module belt_cutout() {
    translate([(plate_w - belt_w) / 2, -0.001, -0.001])
        cube([belt_w, plate_d + 0.002, plate_h + 0.002]);
}
module belt() {
    color("black")
    difference() {
        translate([(plate_w - belt_w) / 2, 0, 0])
            cube([belt_w, plate_d, plate_h]);
        arrow_cutout();
    }
}
```

**Arrow outline (hollow polygon):**
```openscad
module arrow_2d() {
    polygon([ /* 7 points defining arrow shape */ ]);
}
module arrow() {
    color("green")
    translate([plate_w/2, (plate_d - arrow_h)/2, 0])
    linear_extrude(plate_h)
    difference() {
        arrow_2d();
        offset(delta = -arrow_outline) arrow_2d();
    }
}
```

**Roller slots (stadium shapes cut from green background):**
```openscad
module rollers() {
    color("green")
    difference() {
        for (i = [0:roller_count - 1]) {
            cy = ...;
            hull() {
                translate([x_start + r, cy, 0]) cylinder(h=plate_h, r=r, $fn=20);
                translate([x_end   - r, cy, 0]) cylinder(h=plate_h, r=r, $fn=20);
            }
        }
        belt_cutout();
    }
}
```

**Rivet border avoidance:** When a feature fills the whole plate, avoid the rivet zone by inlining a `rivet_holes()` subtraction inside the feature's `difference()`.

---

**Curved belt arc (quarter-circle conveyor turn):**

Identify which corner has the "empty" bare-plate area — the arc center goes there. The belt arc is an annular sector (ring slice) clipped to the tile. Use these helpers:

```openscad
// arc_cx, arc_cy = corner coordinates (e.g. plate_w, plate_d for top-right corner)
// arc_a1, arc_a2 = start/end angles (e.g. 180, 270 for the lower-left quadrant)
// arc_r_out, arc_r_in = outer/inner radii of the belt

module fan_2d(r, a1, a2) {
    // Pie-slice from a1 to a2 degrees — used to clip annular sectors
    polygon(concat([[0, 0]], [for (a = [a1:1:a2]) [r * cos(a), r * sin(a)]]));
}

module annular_sector_2d(r_outer, r_inner, a1, a2) {
    intersection() {
        difference() {
            circle(r = r_outer, $fn = 120);
            circle(r = r_inner, $fn = 120);
        }
        fan_2d(r_outer + 0.5, a1, a2);
    }
}

module belt_arc_cutout() {
    translate([0, 0, -0.001])
    linear_extrude(plate_h + 0.002)
    translate([arc_cx, arc_cy])
        annular_sector_2d(arc_r_out, arc_r_in, arc_a1, arc_a2);
}

module belt_arc() {
    color("black")
    intersection() {
        linear_extrude(plate_h)
        translate([arc_cx, arc_cy])
            annular_sector_2d(arc_r_out, arc_r_in, arc_a1, arc_a2);
        cube([plate_w, plate_d, plate_h]);  // clip to tile bounds
    }
}
```

**Curved radial rollers (along a belt arc):**

Rollers are stadium shapes rotated so their long axis points toward the arc center.
`rotate([0, 0, theta])` aligns the hull's ±x axis with the radial direction at angle `theta`.

```openscad
// roller_r_mid = arc_r_in + (arc_r_out - arc_r_in) * 0.45  (midpoint of belt)
// roller_len   = (arc_r_out - arc_r_in) * 0.62             (radial length)
module curved_rollers() {
    span = arc_a2 - arc_a1 - 10;  // stay 5° inside each end
    color("green")
    for (i = [0:roller_count - 1]) {
        theta = arc_a1 + 5 + span * i / (roller_count - 1);
        cx = arc_cx + roller_r_mid * cos(theta);
        cy = arc_cy + roller_r_mid * sin(theta);
        translate([cx, cy, 0])
        rotate([0, 0, theta])   // long axis = radial direction
        hull() {
            translate([-roller_len/2, 0, 0]) cylinder(h=plate_h, r=roller_r_cap, $fn=20);
            translate([ roller_len/2, 0, 0]) cylinder(h=plate_h, r=roller_r_cap, $fn=20);
        }
    }
}
```

**Curved hollow arrow (directional arc arrow):**

The belt moves CLOCKWISE when the arrowhead points "upward" at the arc's left/upper end.
Key rotation formula: `rotate([0, 0, theta - 180])` orients an arrowhead (whose tip points in +y) to the clockwise tangent direction at angle `theta` from the arc center.

```openscad
// arrow_a1 = arrowhead end angle (where belt exits)
// arrow_a2 = tail end angle (where belt enters)
module curved_arrow() {
    r_o = arrow_r_mid + arrow_half_w;
    r_i = arrow_r_mid - arrow_half_w;
    color([0.40, 1.00, 0.10])  // yellow-green
    linear_extrude(plate_h + 0.001)
    translate([arc_cx, arc_cy])
    union() {
        // Hollow arc outline (stroke on outer + inner edges, open interior)
        difference() {
            annular_sector_2d(r_o,               r_i,               arrow_a1, arrow_a2);
            annular_sector_2d(r_o - arrow_stroke, r_i + arrow_stroke, arrow_a1, arrow_a2);
        }
        // Arrowhead triangle — rotate([0,0, arrow_a1 - 180]) = clockwise tangent at arrow_a1
        translate([arrow_r_mid * cos(arrow_a1), arrow_r_mid * sin(arrow_a1)])
        rotate([0, 0, arrow_a1 - 180])
        polygon([[0, arrow_head_h], [-arrow_head_w/2, 0], [arrow_head_w/2, 0]]);
    }
}
```

**Spur gear:**

Model with a base circle at root radius plus N trapezoidal tooth polygons. Subtract the bore. Add a lighter fill circle for the open interior.

```openscad
gear_n      = 20;    // number of teeth
gear_r_tip  = 1.18;  // outer radius at tooth tips
gear_r_root = 1.00;  // root radius (base of teeth)
gear_r_bore = 0.62;  // bore (inner hole) radius
tooth_hw    = 4.5;   // half-angle per tooth in degrees
                     // total tooth width = 2*tooth_hw; gap = pitch - 2*tooth_hw
                     // equal teeth & gaps → tooth_hw = (360/n_teeth)/4

module gear_tooth_2d() {
    // Single trapezoidal tooth pointing in +x direction
    polygon([
        [gear_r_root * cos(-tooth_hw),        gear_r_root * sin(-tooth_hw)],
        [gear_r_tip  * cos(-tooth_hw * 0.80), gear_r_tip  * sin(-tooth_hw * 0.80)],
        [gear_r_tip  * cos( tooth_hw * 0.80), gear_r_tip  * sin( tooth_hw * 0.80)],
        [gear_r_root * cos( tooth_hw),        gear_r_root * sin( tooth_hw)],
    ]);
}

module gear_2d() {
    union() {
        circle(r = gear_r_root, $fn = gear_n * 8);
        for (i = [0:gear_n - 1])
            rotate([0, 0, i * (360 / gear_n)]) gear_tooth_2d();
    }
}

module gear() {
    color("black")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    difference() {
        gear_2d();
        circle(r = gear_r_bore, $fn = 80);
    }
}

module gear_bore() {
    // Lighter fill reveals interior (sits on top of plate)
    color([0.80, 0.80, 0.80])
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h + 0.001)
    circle(r = gear_r_bore - 0.001, $fn = 80);
}
```
