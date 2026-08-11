// sub_belts.scad — shared roller/belt/arrow geometry for element10, 11, 12, 20, 21, 22
// Requires caller to define: plate_w, plate_d, plate_h (see sub_base_plate.scad)
// Units: inches
//
// Dispatch flags the caller must define before including this file:
//   straight      — true to also draw the straight-through belt
//   right_turn    — true to draw the belt curving out to the right edge
//   left_turn     — true to draw the belt curving out to the left edge
//                   (the mirror of right_turn's geometry — see below)
//   double_speed  — false for single-arrow tiles (10, 11, 12), true for
//                   double-arrow tiles (20, 21, 22)
//   roller_color, arrow_color — color strings ("green"/"green" for 10-12,
//                   "blue"/"lightblue" for 20-22); only used inside the
//                   modules below, so they may be defined after this include
//
// straight/right_turn/left_turn are independent, not mutually exclusive — any
// combination may be true, drawing up to 3 belt paths sharing one tile (e.g.
// a straight-through run plus a left and/or right branch). Each public module
// (belt_cutout/roller_slots/rollers/belt/arrow) is a dispatcher: it draws the
// straight_*() geometry when straight is set, the curved_*() geometry as-is
// when right_turn is set, and curved_*() again mirrored across the tile's
// vertical centerline when left_turn is set — there is only one curved
// implementation, reused for both directions.
//
// element11/21 (right-turn) and element12/22 (left-turn) therefore share
// identical geometry; element12/22 differ only in which flag is set (no
// separate mirrored assembly file needed).

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

arrow_w       = belt_w * 0.75;
arrow_shaft_w = arrow_w * 0.4;
arrow_head_h  = arrow_w / 2;
arrow_outline = 1/8;
arrow_tip_y   = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;
arrow_gap     = 1/8;

// Turn-tile curve geometry — unused (harmless) when neither turn flag is set
cx      = plate_w / 2;
r_curve = 0.48;
cx_r    = cx + r_curve;
r_outer = r_curve + belt_half;

// Arrow shaft height is tuned per family; straight-double instead derives it
// from the tile height so two arrows plus the gap fit exactly.
arrow_shaft_h = (straight && double_speed) ? (plate_d * 3/4 - arrow_gap) / 2 - arrow_head_h
              : straight                   ? 1.676
              : double_speed               ? 0.25
              : 1.5;
arrow_h = arrow_shaft_h + arrow_head_h;

// Straight tiles: arrow Y position(s)
arrow_y  = arrow_tip_y - arrow_h;           // single arrow (also used as the turn tiles' arrow_y)
arrow2_y = arrow_tip_y - arrow_h;           // double: upper arrow
arrow1_y = arrow2_y - arrow_gap - arrow_h;  // double: lower arrow

// Turn tiles: curve/merge geometry
y_merge    = arrow_y + arrow_shaft_h;                 // single: vertical/arc junction
y_merge_up = arrow_tip_y - arrow_head_h;              // double: vertical/arc junction
y_arc_ctr  = double_speed ? plate_d/2 + r_curve + 0.24 : y_merge + 0.12;
h_straight = double_speed ? 0 : 0.49;

// Turn, double-speed: upward + leftward arrow placement
arrow_up_y = arrow_y;
arrow_lf_y = plate_d / 2;
arrow_lf_x = plate_w - (plate_d - arrow_tip_y);

// Mirrors curved_*() geometry across the tile's vertical centerline for left_turn
module mirrored() {
    translate([plate_w, 0, 0])
    mirror([1, 0, 0])
    children();
}

// ── Belt cutout ───────────────────────────────────────────────────────────────

module straight_belt_cutout() {
    translate([(plate_w - belt_w) / 2, -0.001, -0.001])
        cube([belt_w, plate_d + 0.002, plate_h + 0.002]);
}

module curved_belt_cutout() {
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

module belt_cutout() {
    if (straight)   straight_belt_cutout();
    if (right_turn) curved_belt_cutout();
    if (left_turn)  mirrored() curved_belt_cutout();
}

// ── Roller slots (cut into plate) ──────────────────────────────────────────────

module straight_roller_slots() {
    for (i = [0:roller_count - 1]) {
        cy = roller_inset + i * roller_y_step;
        translate([0, 0, -0.001])
        hull() {
            translate([roller_x_lo + roller_r, cy, 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            translate([roller_x_hi - roller_r, cy, 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
        }
    }
}

module curved_roller_slots() {
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

module roller_slots() {
    if (straight)   straight_roller_slots();
    if (right_turn) curved_roller_slots();
    if (left_turn)  mirrored() curved_roller_slots();
}

// ── Rollers (filled, colored) ───────────────────────────────────────────────────

module straight_roller_bars() {
    for (i = [0:roller_count - 1]) {
        cy = roller_inset + i * roller_y_step;
        hull() {
            translate([roller_x_lo + roller_r, cy, 0])
                cylinder(h = plate_h, r = roller_r, $fn = 20);
            translate([roller_x_hi - roller_r, cy, 0])
                cylinder(h = plate_h, r = roller_r, $fn = 20);
        }
    }
}

module curved_roller_bars() {
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

module rollers() {
    color(roller_color)
    difference() {
        union() {
            if (straight)   straight_roller_bars();
            if (right_turn) curved_roller_bars();
            if (left_turn)  mirrored() curved_roller_bars();
        }
        belt_cutout();
    }
}

// ── Arrow shapes ────────────────────────────────────────────────────────────────

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

module straight_arrow_fill() {
    if (!double_speed) {
        translate([plate_w / 2, arrow_y, 0])
        linear_extrude(plate_h)
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    } else {
        for (ay = [arrow1_y, arrow2_y])
            translate([plate_w / 2, ay, 0])
            linear_extrude(plate_h)
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
    }
}

module straight_arrow_cutout() {
    if (!double_speed) {
        translate([plate_w / 2, arrow_y, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    } else {
        for (ay = [arrow1_y, arrow2_y])
            translate([plate_w / 2, ay, -0.001])
            linear_extrude(plate_h + 0.002)
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
    }
}

module curved_arrow_fill() {
    if (!double_speed) {
        // Vertical segment: cx, from arc center up to arrowhead base
        translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve, 0])
        linear_extrude(plate_h)
        difference() {
            square([arrow_shaft_w, y_merge - (plate_d/2 + r_curve)]);
            translate([arrow_outline, 0])
                square([arrow_shaft_w - 2*arrow_outline, y_merge - (plate_d/2 + r_curve)]);
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
        // Horizontal segment: from arc 270° endpoint at (cx_r, plate_d/2) going right
        translate([cx_r, plate_d/2 - arrow_shaft_w/2, 0])
        linear_extrude(plate_h)
        difference() {
            square([h_straight, arrow_shaft_w]);
            translate([0, arrow_outline])
                square([h_straight, arrow_shaft_w - 2*arrow_outline]);
        }
        // End cap
        translate([cx_r + h_straight - arrow_outline, plate_d/2 - arrow_shaft_w/2, 0])
            cube([arrow_outline, arrow_shaft_w, plate_h]);
        // Arrowhead — clipped from full arrow_2d so base is open to shaft
        translate([cx, arrow_y, 0])
        linear_extrude(plate_h)
        intersection() {
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
            translate([-arrow_w / 2, arrow_shaft_h])
                square([arrow_w, arrow_head_h]);
        }
    } else {
        // Curved upward arrow
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

module curved_arrow_cutout() {
    if (!double_speed) {
        // Vertical segment cutout
        translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve - 0.001, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            square([arrow_shaft_w, y_merge - (plate_d/2 + r_curve) + 0.001]);
            translate([arrow_outline, 0])
                square([arrow_shaft_w - 2*arrow_outline, y_merge - (plate_d/2 + r_curve)]);
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
        // End cap cutout
        translate([cx_r + h_straight - arrow_outline, plate_d/2 - arrow_shaft_w/2, -0.001])
            cube([arrow_outline, arrow_shaft_w, plate_h + 0.002]);
        // Arrowhead cutout — clipped from full arrow_2d so base is open to shaft
        translate([cx, arrow_y, -0.001])
        linear_extrude(plate_h + 0.002)
        intersection() {
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
            translate([-arrow_w / 2, arrow_shaft_h])
                square([arrow_w, arrow_head_h]);
        }
    } else {
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

module arrow() {
    color(arrow_color)
    union() {
        if (straight)   straight_arrow_fill();
        if (right_turn) curved_arrow_fill();
        if (left_turn)  mirrored() curved_arrow_fill();
    }
}

// ── Belt (solid, colored, arrow-shaped cutout) ─────────────────────────────────

module straight_belt_base() {
    translate([(plate_w - belt_w) / 2, 0, 0])
        cube([belt_w, plate_d, plate_h]);
}

module curved_belt_base() {
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
    // Curved corner — bottom-left of the top-right uncovered square
    translate([b_R, plate_d/2 + belt_half, 0])
    linear_extrude(plate_h)
    difference() {
        square([b_L/2, b_L/2]);
        translate([b_L/2, b_L/2])
            circle(r = b_L/2, $fn = 120);
    }
}

module belt() {
    color("black")
    difference() {
        union() {
            if (straight)   straight_belt_base();
            if (right_turn) curved_belt_base();
            if (left_turn)  mirrored() curved_belt_base();
        }
        union() {
            if (straight)   straight_arrow_cutout();
            if (right_turn) curved_arrow_cutout();
            if (left_turn)  mirrored() curved_arrow_cutout();
        }
    }
}
