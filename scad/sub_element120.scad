// sub_element120.scad — shared assembly for element120 Vortex Portal tile variants
// Requires caller to define: plate_colors (6-slot frame color array),
// label_num (letter painted at the tile center)
// Units: inches

include <sub_base_plate.scad>
include <sub_innergears.scad>

cx = plate_w / 2;
cy = plate_d / 2;

// Orange dashed arc inside the ring, lower arc (portal intake indicator)
dash_r     = 0.73;
dash_count = 8;
dash_a1    = 205;
dash_a2    = 335;
dash_w     = 0.074;
dash_len   = 0.140;

// Orange upward arrow — bottom unchanged, tip restored to original position
arr_stem_w  = 0.40;
arr_stem_y1 = cy - 0.44;
arr_stem_y2 = cy + 0.20;
arr_head_w  = 0.90;
arr_head_h  = 0.38;

// ── Dash holes & dashes ───────────────────────────────────────────────────────

module dash_holes() {
    span = dash_a2 - dash_a1;
    for (i = [0 : dash_count - 1]) {
        angle = dash_a1 + span * i / (dash_count - 1);
        dx = cx + dash_r * cos(angle);
        dy = cy + dash_r * sin(angle);
        translate([dx, dy, -1])
        rotate([0, 0, angle + 90])
        linear_extrude(plate_h + 2)
        square([dash_w, dash_len], center = true);
    }
}

module white_dashes() {
    span = dash_a2 - dash_a1;
    color("orange") {
        for (i = [0 : dash_count - 1]) {
            angle = dash_a1 + span * i / (dash_count - 1);
            dx = cx + dash_r * cos(angle);
            dy = cy + dash_r * sin(angle);
            translate([dx, dy, 0])
            rotate([0, 0, angle + 90])
            linear_extrude(plate_h)
            square([dash_w, dash_len], center = true);
        }
    }
}

// ── Arrow hole & arrow ────────────────────────────────────────────────────────

module arrow_holes() {
    translate([0, 0, -1])
    linear_extrude(plate_h + 2)
    union() {
        translate([cx - arr_stem_w / 2, arr_stem_y1])
            square([arr_stem_w, arr_stem_y2 - arr_stem_y1]);
        translate([cx, arr_stem_y2])
            polygon([
                [-arr_head_w / 2, 0],
                [ arr_head_w / 2, 0],
                [0, arr_head_h]
            ]);
    }
}

module white_arrow() {
    color("orange")
    linear_extrude(plate_h)
    union() {
        translate([cx - arr_stem_w / 2, arr_stem_y1])
            square([arr_stem_w, arr_stem_y2 - arr_stem_y1]);
        translate([cx, arr_stem_y2])
            polygon([
                [-arr_head_w / 2, 0],
                [ arr_head_w / 2, 0],
                [0, arr_head_h]
            ]);
    }
}

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes(num) {
    translate([cx, cy, -1])
    linear_extrude(plate_h + 2)
    text(num, size = .3, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module label(num) {
    color("white")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    text(num, size = .3, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

union() {                                           // step 4: add label
    difference() {
        union() {                                   // step 3: add dashes & arrow
            difference() {
                union() {                           // step 2: add gear bore
                    difference() {
                        union() {                   // step 1: add gear
                            difference() {
                                plate(plate_colors);        // step 0: plate (frame + rivets)
                                gear_holes();                // cut gear holes
                            }
                            gear("orange");                  // fill with gear
                        }
                        gear_bore_holes();                   // cut gear bore holes
                    }
                    gear_bore("lightgray");                  // fill with gear bore
                }
                dash_holes();                               // cut dash holes
                arrow_holes();                               // cut arrow holes
            }
            white_dashes();                                 // fill with dashes
            white_arrow();                                  // fill with arrow
        }
        label_holes(label_num);                             // cut label hole
    }
    label(label_num);                                       // fill with label
}
