// element110-3.scad
// Gear tile variant — number "3" in the bore.
// Units: inches

include <modules.scad>
include <innergears.scad>

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes() {
    translate([plate_w / 2, plate_d / 2, -0.001])
    linear_extrude(plate_h + 0.002)
    text("3", size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module label() {
    color("green")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    text("3", size = 1.1, halign = "center", valign = "center",
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
                        plate(["green", "green", undef, "green", "green", "green"]);   // step 1: plate (frame + rivets)
                        gear_holes();
                    }
                    gear("darkgreen");
                }
                gear_bore_holes();
            }
            gear_bore("lightgray");
        }
        label_holes();
    }
    label();
}
