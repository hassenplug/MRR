// element21.scad — right-turn double-speed belt tile (two blue arrows)
// Units: inches

straight   = false;
left_turn  = false;
right_turn = true;

include <modules.scad>

belt_w    = 1.75;
belt_half = belt_w / 2;

roller_count  = 13;
roller_h_size = 3/16;
roller_r      = roller_h_size / 2;
roller_inset  = plate_w / 20;
roller_x_lo   = 2 * roller_inset;
roller_x_hi   = plate_w - 2 * roller_inset;
roller_y_step = (plate_w - 2 * roller_inset) / 12;

b_L = plate_w / 2 - belt_half;
b_R = plate_w / 2 + belt_half;
nub = roller_x_hi - b_R;

cx         = plate_w / 2;
r_curve    = 0.48;
cx_l       = cx - r_curve;
cx_r       = cx + r_curve;
r_outer   = r_curve + belt_half;
// Belt arc threshold for roller row selection — geometric constant, not arrow-derived
y_arc_ctr = plate_d/2 + r_curve + 0.24;

arrow_w       = belt_w * 0.75;
arrow_shaft_w = arrow_w * 0.4;
arrow_head_h  = arrow_w / 2;
arrow_shaft_h = 0.25;
arrow_h       = arrow_shaft_h + arrow_head_h;
arrow_outline = 1/8;

// Upward arrow: tip at same position as element20's top arrow tip
arrow_tip_y  = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;
arrow_up_x   = cx;
arrow_up_y   = arrow_tip_y - arrow_h;
y_merge_up   = arrow_tip_y - arrow_head_h;  // shaft/head junction = top of vertical segment

// Leftward arrow: shaft base inset from right edge by same distance as top arrow tip from top edge
// After rotate([0,0,90]) on arrow_2d, tip lands at (-arrow_h, 0) relative to translate origin
arrow_lf_y = plate_d / 2;
arrow_lf_x = plate_w - (plate_d - arrow_tip_y);
// Horizontal shaft: end where the arrowhead outer edge meets the shaft strip outer edge
h_straight = 0;

module belt_cutout() {
    // Straight vertical strip (top)
    translate([(plate_w - belt_w) / 2, plate_d/2 + r_curve - 0.001, -0.001])
        cube([belt_w, plate_d/2 - r_curve + 0.002, plate_h + 0.002]);
    // Horizontal entry from right
    translate([cx_r - 0.001, plate_d/2 - belt_half - 0.001, -0.001])
        cube([plate_w - cx_r + 0.002, belt_w + 0.002, plate_h + 0.002]);
    // Arc corner fill: lower-left quadrant at (cx_r, plate_d/2 + r_curve)
    translate([cx_r, plate_d/2 + r_curve, -0.001])
    linear_extrude(plate_h + 0.002)
    intersection() {
        circle(r = r_outer, $fn = 120);
        translate([-r_outer, -r_outer]) square([r_outer, r_outer]);
    }
    // Curved corner — bottom-left of the top-right uncovered square
    translate([b_R, plate_d/2 + belt_half, -0.001])
    linear_extrude(plate_h + 0.002)
    difference() {
        square([b_L/2, b_L/2]);
        translate([b_L/2, b_L/2])
            circle(r = b_L/2, $fn = 120);
    }
}

module roller_slots() {
    // a. Horizontal bars — top-section only, right-clipped; i=12 full-width
    for (i = [0:roller_count - 1]) {
        if (roller_inset + i * roller_y_step >= y_arc_ctr - roller_y_step) {
            translate([0, 0, -0.001])
            hull() {
                translate([roller_x_lo + roller_r,
                           roller_inset + i * roller_y_step, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
                translate([(i == roller_count - 1 ? roller_x_hi : b_R) - roller_r,
                           roller_inset + i * roller_y_step, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            }
        }
    }
    // b. Vertical entry bars — right side; skip if rx < cx_r
    for (i = [0:roller_count - 1]) {
        if (roller_inset + i * roller_y_step >= cx_r) {
            y_hi = (i == roller_count - 1) ? plate_d - roller_x_lo : plate_d/2 + belt_half;
            translate([0, 0, -0.001])
            hull() {
                translate([roller_inset + i * roller_y_step, roller_x_lo + roller_r, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
                translate([roller_inset + i * roller_y_step, y_hi - roller_r, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            }
        }
    }
    // c. Arc radial bars — 11 bars, center (cx_r, plate_d/2 + r_curve), 180°–270°
    r_outer_bars = r_outer + nub;
    for (k = [0:10]) {
        theta = 180 + 2.25 + k * (85.5 / 10);
        translate([cx_r, plate_d/2 + r_curve, 0])
        rotate([0, 0, theta])
        translate([0, 0, -0.001])
        hull() {
            translate([r_outer_bars - roller_r, 0, 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            translate([r_outer_bars - roller_r - nub, 0, 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
        }
    }
    // d. Upper diagonal corner — upper-right of belt entry
    translate([b_R, plate_d/2 + belt_half, 0])
    rotate([0, 0, 45])
    translate([0, 0, -0.001])
    hull() {
        cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
        translate([nub, 0, 0])
            cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
    }
}

module rollers() {
    color("blue")
    difference() {
        union() {
            // a. Horizontal bars
            for (i = [0:roller_count - 1]) {
                if (roller_inset + i * roller_y_step >= y_arc_ctr - roller_y_step) {
                    hull() {
                        translate([roller_x_lo + roller_r,
                                   roller_inset + i * roller_y_step, 0])
                            cylinder(h = plate_h, r = roller_r, $fn = 20);
                        translate([(i == roller_count - 1 ? roller_x_hi : b_R) - roller_r,
                                   roller_inset + i * roller_y_step, 0])
                            cylinder(h = plate_h, r = roller_r, $fn = 20);
                    }
                }
            }
            // b. Vertical entry bars
            for (i = [0:roller_count - 1]) {
                if (roller_inset + i * roller_y_step >= cx_r) {
                    y_hi = (i == roller_count - 1) ? plate_d - roller_x_lo : plate_d/2 + belt_half;
                    hull() {
                        translate([roller_inset + i * roller_y_step, roller_x_lo + roller_r, 0])
                            cylinder(h = plate_h, r = roller_r, $fn = 20);
                        translate([roller_inset + i * roller_y_step, y_hi - roller_r, 0])
                            cylinder(h = plate_h, r = roller_r, $fn = 20);
                    }
                }
            }
            // c. Arc radial bars
            r_outer_bars = r_outer + nub;
            for (k = [0:10]) {
                theta = 180 + 2.25 + k * (85.5 / 10);
                translate([cx_r, plate_d/2 + r_curve, 0])
                rotate([0, 0, theta])
                hull() {
                    translate([r_outer_bars - roller_r, 0, 0])
                        cylinder(h = plate_h, r = roller_r, $fn = 20);
                    translate([r_outer_bars - roller_r - nub, 0, 0])
                        cylinder(h = plate_h, r = roller_r, $fn = 20);
                }
            }
            // d. Upper diagonal corner — upper-right of belt entry
            translate([b_R, plate_d/2 + belt_half, 0])
            rotate([0, 0, 45])
            hull() {
                cylinder(h = plate_h, r = roller_r, $fn = 20);
                translate([nub, 0, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
            }
        }
        belt_cutout();
    }
}

module arrow_2d() {
    polygon([
        [-arrow_shaft_w / 2, 0],
        [ arrow_shaft_w / 2, 0],
        [ arrow_shaft_w / 2, arrow_shaft_h],
        [ arrow_w / 2,       arrow_shaft_h],
        [ 0,                 arrow_h],
        [-arrow_w / 2,       arrow_shaft_h],
        [-arrow_shaft_w / 2, arrow_shaft_h]
    ]);
}

module arrows() {
    color("lightblue") {
        // Curved upward arrow (element11-style)
        union() {
            // Vertical segment: arc center up to arrowhead base
            translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve, 0])
            linear_extrude(plate_h)
            difference() {
                square([arrow_shaft_w, y_merge_up - (plate_d/2 + r_curve)]);
                translate([arrow_outline, 0])
                    square([arrow_shaft_w - 2*arrow_outline, y_merge_up - (plate_d/2 + r_curve)]);
            }
            // Arc shaft: hollow annulus, lower-left quadrant (180°–270°)
            translate([cx_r, plate_d/2 + r_curve, 0])
            linear_extrude(plate_h)
            intersection() {
                difference() {
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                    offset(delta = -arrow_outline)
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                }
                translate([-(r_curve + arrow_shaft_w/2), -(r_curve + arrow_shaft_w/2)])
                    square([r_curve + arrow_shaft_w/2, r_curve + arrow_shaft_w/2]);
            }
            // Horizontal segment: from arc 270° endpoint going right
            translate([cx_r, plate_d/2 - arrow_shaft_w/2, 0])
            linear_extrude(plate_h)
            difference() {
                square([h_straight, arrow_shaft_w]);
                translate([0, arrow_outline])
                    square([h_straight, arrow_shaft_w - 2*arrow_outline]);
            }
            // End cap — 90° V matching arrowhead tip angle
            translate([cx_r + h_straight, plate_d/2, 0])
            linear_extrude(plate_h)
            union() {
                hull() {
                    translate([-arrow_shaft_w / 2, 0]) circle(r = arrow_outline / 2, $fn = 20);
                    translate([-arrow_outline / sqrt(2),  arrow_shaft_w / 2 - arrow_outline / sqrt(2)]) circle(r = arrow_outline / 2, $fn = 20);
                }
                hull() {
                    translate([-arrow_shaft_w / 2, 0]) circle(r = arrow_outline / 2, $fn = 20);
                    translate([-arrow_outline / sqrt(2), -arrow_shaft_w / 2 + arrow_outline / sqrt(2)]) circle(r = arrow_outline / 2, $fn = 20);
                }
            }
            // Arrowhead — head only, base open to vertical shaft
            translate([cx, arrow_up_y, 0])
            linear_extrude(plate_h)
            intersection() {
                difference() {
                    arrow_2d();
                    offset(delta = -arrow_outline) arrow_2d();
                }
                translate([-arrow_w / 2, arrow_shaft_h])
                    square([arrow_w, arrow_head_h]);
            }
        }
        // Leftward arrow
        translate([arrow_lf_x, arrow_lf_y, 0])
        linear_extrude(plate_h)
        rotate([0, 0, 90])
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    }
}

module belt() {
    color("black")
    difference() {
        union() {
            translate([cx_r, plate_d/2 - belt_half, 0])
                cube([plate_w - cx_r, belt_w, plate_h]);
            translate([cx_r, plate_d/2 + r_curve, 0])
            linear_extrude(plate_h)
            intersection() {
                circle(r = r_outer, $fn = 120);
                translate([-r_outer, -r_outer]) square([r_outer, r_outer]);
            }
            translate([b_L, plate_d/2 + r_curve, 0])
                cube([belt_w, plate_d/2 - r_curve, plate_h]);
            translate([b_R, plate_d/2 + belt_half, 0])
            linear_extrude(plate_h)
            difference() {
                square([b_L/2, b_L/2]);
                translate([b_L/2, b_L/2])
                    circle(r = b_L/2, $fn = 120);
            }
        }
        // Curved arrow cutouts
        union() {
            // Vertical segment cutout
            translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve - 0.001, -0.001])
            linear_extrude(plate_h + 0.002)
            difference() {
                square([arrow_shaft_w, y_merge_up - (plate_d/2 + r_curve) + 0.001]);
                translate([arrow_outline, 0])
                    square([arrow_shaft_w - 2*arrow_outline, y_merge_up - (plate_d/2 + r_curve)]);
            }
            // Arc shaft cutout
            translate([cx_r, plate_d/2 + r_curve, -0.001])
            linear_extrude(plate_h + 0.002)
            intersection() {
                difference() {
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                    offset(delta = -arrow_outline)
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                }
                translate([-(r_curve + arrow_shaft_w/2), -(r_curve + arrow_shaft_w/2)])
                    square([r_curve + arrow_shaft_w/2, r_curve + arrow_shaft_w/2]);
            }
            // Horizontal segment cutout
            translate([cx_r, plate_d/2 - arrow_shaft_w/2, -0.001])
            linear_extrude(plate_h + 0.002)
            difference() {
                square([h_straight, arrow_shaft_w]);
                translate([0, arrow_outline])
                    square([h_straight, arrow_shaft_w - 2*arrow_outline]);
            }
            // End cap cutout — 90° V matching arrowhead tip angle
            translate([cx_r + h_straight, plate_d/2, -0.001])
            linear_extrude(plate_h + 0.002)
            union() {
                hull() {
                    translate([-arrow_shaft_w / 2, 0]) circle(r = arrow_outline / 2, $fn = 20);
                    translate([-arrow_outline / sqrt(2),  arrow_shaft_w / 2 - arrow_outline / sqrt(2)]) circle(r = arrow_outline / 2, $fn = 20);
                }
                hull() {
                    translate([-arrow_shaft_w / 2, 0]) circle(r = arrow_outline / 2, $fn = 20);
                    translate([-arrow_outline / sqrt(2), -arrow_shaft_w / 2 + arrow_outline / sqrt(2)]) circle(r = arrow_outline / 2, $fn = 20);
                }
            }
            // Arrowhead cutout (head only)
            translate([cx, arrow_up_y, -0.001])
            linear_extrude(plate_h + 0.002)
            intersection() {
                difference() {
                    arrow_2d();
                    offset(delta = -arrow_outline) arrow_2d();
                }
                translate([-arrow_w / 2, arrow_shaft_h])
                    square([arrow_w, arrow_head_h]);
            }
        }
        // Cut leftward arrow outline from belt
        translate([arrow_lf_x, arrow_lf_y, -0.001])
        linear_extrude(plate_h + 0.002)
        rotate([0, 0, 90])
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    }
}

difference() {
    plate([undef, undef, "lightblue", "lightblue", "lightblue", "lightblue"]);
    roller_slots();
    belt_cutout();
}
rollers();
belt();
arrows();
