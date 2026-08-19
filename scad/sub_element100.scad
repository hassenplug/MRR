// sub_element100.scad — shared assembly for element100 flag tile variants
// Requires caller to define: plate_colors (6-slot frame color array),
// label_num (number painted on the flag)
// Units: inches
//
// The flag outline, pole, flag, and label all sit in the top pattern_h-thick
// slice of the plate — z from (plate_h - pattern_h) to plate_h — like
// gear()/gear_bore() in sub_innergears.scad, rather than spanning the
// plate's full thickness from z=0.

include <sub_base_plate.scad>
include <sub_innergears.scad>

gear_color = "darkred";

// Pole — same inset_x gap from right rivet column as rivets are from edge
pole_r   = 0.04;
pole_cx  = plate_w - plate_w / 10;
pole_y1  = (plate_d / 20) + hole_r + 0.01;
pole_y2  = plate_d - (plate_d / 20) - hole_r - 0.01;

// Pennant — 2/3 pole height, top at pole top, tip extends well across gear
flag_base_x  = pole_cx;
flag_top_y   = pole_y2;
flag_bot_y   = pole_y2 - (pole_y2 - pole_y1) * 2 / 3;
flag_tip_x   = plate_w / 2 - gear_r_tip * 0.60;
flag_mid_y   = (flag_top_y + flag_bot_y) / 2;
outline_t    = 0.025;

// ── Flag 2D helpers ───────────────────────────────────────────────────────────

module flag_pennant_2d() {
    polygon([
        [flag_base_x, flag_top_y],
        [flag_base_x, flag_bot_y],
        [flag_tip_x,  flag_mid_y]
    ]);
}

module flag_label_2d(label) {
    translate([flag_base_x + (flag_tip_x - flag_base_x) * 0.38, flag_mid_y])
    text(label, size = 0.65, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Flag outline hole & flag outline ─────────────────────────────────────────

module flag_outline_holes() {
    translate([0, 0, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 2)
    difference() {
        offset(delta = outline_t) flag_pennant_2d();
        flag_pennant_2d();
    }
}

module flag_outline() {
    color("darkgray")
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    difference() {
        offset(delta = outline_t) flag_pennant_2d();
        flag_pennant_2d();
    }
}

// ── Flag pole hole, flag hole → flag pole, flag ───────────────────────────────

module flag_pole_holes() {
    translate([pole_cx - pole_r, pole_y1, plate_h - pattern_h - 0.001])
    cube([pole_r * 2, pole_y2 - pole_y1, pattern_h + 2]);
}

module flag_pole() {
    color("red")
    translate([pole_cx - pole_r, pole_y1, plate_h - pattern_h])
    cube([pole_r * 2, pole_y2 - pole_y1, pattern_h]);
}

module flag_holes() {
    translate([0, 0, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 2)
    flag_pennant_2d();
}

module flag() {
    color("red")
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    flag_pennant_2d();
}

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes(label) {
    translate([0, 0, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 2)
    flag_label_2d(label);
}

module flag_label(label) {
    color("white")
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    flag_label_2d(label);
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

union() {                                           // step 5: add label
    difference() {
        union() {                                   // step 4: add flag pole & flag
            difference() {
                union() {                           // step 3: add flag outline
                    difference() {
                        union() {                   // step 2: add gear bore
                            difference() {
                                union() {           // step 1: add gear
                                    difference() {
                                        plate(plate_colors);   // step 0: plate (frame + rivets)
                                        gear_holes();       // cut gear holes
                                    }
                                    gear(gear_color);        // fill with gear
                                }
                                gear_bore_holes();          // cut gear bore hole
                            }
                            gear_bore("lightgray");         // fill with gear bore
                        }
                        flag_outline_holes();               // cut flag outline hole
                    }
                    flag_outline();                         // fill with flag outline
                }
                flag_pole_holes();                          // cut flag pole hole
                flag_holes();                               // cut flag hole
            }
            flag_pole();                                    // fill with flag pole
            flag();                                         // fill with flag
        }
        label_holes(label_num);                             // cut label hole
    }
    flag_label(label_num);                                  // fill with label
}
