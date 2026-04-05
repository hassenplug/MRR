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

5. **Determine the output filename** from the image name (e.g., `Images/Element10.jpg` → `aaron/element10.scad`) and write the file there.

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
