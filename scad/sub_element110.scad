// sub_element110.scad — shared assembly for element110 gear tile variants
// Requires caller to define: plate_colors (6-slot frame color array),
// label_num (digit painted in the gear bore)
// Units: inches

include <sub_base_plate.scad>
include <sub_innergears.scad>

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes(num) {
    translate([plate_w / 2, plate_d / 2, -0.001])
    linear_extrude(plate_h + 0.002)
    text(str(num), size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module label(num, clr) {
    color(clr)
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    text(str(num), size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

union() {                                           // step 4: add label
    difference() {
        union() {                                   // step 3: add gear bore
            difference() {
                union() {                           // step 2: add gear
                    difference() {
                        plate(plate_colors);   // step 1: plate (frame + rivets)
                        gear_holes();
                    }
                    gear("darkgreen");
                }
                gear_bore_holes();
            }
            gear_bore("lightgray");
        }
        label_holes(label_num);
    }
    label(label_num, "green");
}
