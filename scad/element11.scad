// element11.scad — right-turn belt tile
// Units: inches

straight   = false;
left_turn  = false;
right_turn = true;

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;

belt_w    = 1.75;
belt_half = belt_w / 2;

hole_d = 3/32;
hole_r = hole_d / 2;

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
arrow_shaft_h = 1.5;
arrow_head_h  = arrow_w / 2;
arrow_h       = arrow_shaft_h + arrow_head_h;
arrow_tip_y   = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;
arrow_y       = arrow_tip_y - arrow_h;
arrow_outline = 1/16;
arrow_fill_w  = 2 * arrow_outline;

cx         = plate_w / 2;
r_curve    = 0.48;
y_merge    = arrow_y + arrow_shaft_h;
y_arc_ctr  = y_merge + 0.12;
y_entry    = y_arc_ctr + r_curve;
cx_l       = cx - r_curve;
cx_r       = cx + r_curve;
r_outer    = r_curve + belt_half;
h_straight = 0.49;

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    translate([plate_w - inset_x, plate_d - inset_y, -1])
        cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) {
        translate([inset_x, inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
        translate([inset_x + i * spacing_x, inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
        if (inset_x + i * spacing_x <= roller_x_lo + roller_r - hole_r ||
            inset_x + i * spacing_x >= roller_x_hi - roller_r + hole_r) {
            translate([inset_x + i * spacing_x, plate_d - inset_y, -1])
                cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
        }
    }
}

module frame_with_id(colors = []) {
    id_cover = plate_h / 8;
    region_w = plate_w / 6;
    region_d = plate_d / 6;
    mark_h   = plate_h - id_cover;

    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
        // top/bottom/left/right straight runs only — corners stay solid black
        translate([0, plate_d - 0.001, -0.001])
            cube([plate_w, frame_w + 0.002, plate_h + 0.002]);
        translate([0, -frame_w - 0.001, -0.001])
            cube([plate_w, frame_w + 0.002, plate_h + 0.002]);
        translate([-frame_w - 0.001, 0, -0.001])
            cube([frame_w + 0.002, plate_d, plate_h + 0.002]);
        translate([plate_w - 0.001, 0, -0.001])
            cube([frame_w + 0.002, plate_d, plate_h + 0.002]);
    }

    for (i = [0:5]) {
        c     = (colors[i] != undef) ? colors[i] : "black";

        // top edge
        color(c) translate([i * region_w, plate_d, 0]) cube([region_w, frame_w, mark_h]);
        color("black") translate([i * region_w, plate_d, mark_h]) cube([region_w, frame_w, id_cover]);

        // bottom edge (reversed)
        color(c) translate([(5-i) * region_w, -frame_w, 0]) cube([region_w, frame_w, mark_h]);
        color("black") translate([(5-i) * region_w, -frame_w, mark_h]) cube([region_w, frame_w, id_cover]);

        // left edge
        color(c) translate([-frame_w, i * region_d, 0]) cube([frame_w, region_d, mark_h]);
        color("black") translate([-frame_w, i * region_d, mark_h]) cube([frame_w, region_d, id_cover]);

        // right edge (reversed)
        color(c) translate([plate_w, (5-i) * region_d, 0]) cube([frame_w, region_d, mark_h]);
        color("black") translate([plate_w, (5-i) * region_d, mark_h]) cube([frame_w, region_d, id_cover]);
    }
}

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

module plate() {
    difference() {
        color("darkgray")
            cube([plate_w, plate_d, plate_h]);
        rivet_holes();
        roller_slots();
        belt_cutout();
    }
}

module rollers() {
    color("green")
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

module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        translate([plate_w - inset_x, plate_d - inset_y, 0])
            cylinder(h = plate_h, r = hole_r, $fn = 20);
        for (i = [0:9]) {
            translate([inset_x, inset_y + i * spacing_y, 0])
                cylinder(h = plate_h, r = hole_r, $fn = 20);
            translate([inset_x + i * spacing_x, inset_y, 0])
                cylinder(h = plate_h, r = hole_r, $fn = 20);
            if (inset_x + i * spacing_x <= roller_x_lo + roller_r - hole_r ||
                inset_x + i * spacing_x >= roller_x_hi - roller_r + hole_r) {
                translate([inset_x + i * spacing_x, plate_d - inset_y, 0])
                    cylinder(h = plate_h, r = hole_r, $fn = 20);
            }
        }
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


module arrow() {
    color("green") {
        // Vertical segment: cx, from arc center up to arrowhead base
        translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve, 0])
        linear_extrude(plate_h)
        difference() {
            square([arrow_shaft_w, y_merge - (plate_d/2 + r_curve)]);
            translate([arrow_fill_w, 0])
                square([arrow_shaft_w - 2*arrow_fill_w, y_merge - (plate_d/2 + r_curve)]);
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
                offset(delta = -arrow_fill_w)
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
            translate([0, arrow_fill_w])
                square([h_straight, arrow_shaft_w - 2*arrow_fill_w]);
        }
        // End cap
        translate([cx_r + h_straight - arrow_fill_w, plate_d/2 - arrow_shaft_w/2, 0])
            cube([arrow_fill_w, arrow_shaft_w, plate_h]);
        // Arrowhead — clipped from full arrow_2d so base is open to shaft
        translate([cx, arrow_y, 0])
        linear_extrude(plate_h)
        intersection() {
            difference() {
                arrow_2d();
                offset(delta = -arrow_fill_w) arrow_2d();
            }
            translate([-arrow_w / 2, arrow_shaft_h])
                square([arrow_w, arrow_head_h]);
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
            // Curved corner — bottom-left of the top-right uncovered square
            translate([b_R, plate_d/2 + belt_half, 0])
            linear_extrude(plate_h)
            difference() {
                square([b_L/2, b_L/2]);
                translate([b_L/2, b_L/2])
                    circle(r = b_L/2, $fn = 120);
            }
        }
        // Vertical segment cutout
        translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve - 0.001, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            square([arrow_shaft_w, y_merge - (plate_d/2 + r_curve) + 0.001]);
            translate([arrow_fill_w, 0])
                square([arrow_shaft_w - 2*arrow_fill_w, y_merge - (plate_d/2 + r_curve)]);
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
                offset(delta = -arrow_fill_w)
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
            translate([0, arrow_fill_w])
                square([h_straight, arrow_shaft_w - 2*arrow_fill_w]);
        }
        // End cap cutout
        translate([cx_r + h_straight - arrow_fill_w, plate_d/2 - arrow_shaft_w/2, -0.001])
            cube([arrow_fill_w, arrow_shaft_w, plate_h + 0.002]);
        // Arrowhead cutout — clipped from full arrow_2d so base is open to shaft
        translate([cx, arrow_y, -0.001])
        linear_extrude(plate_h + 0.002)
        intersection() {
            difference() {
                arrow_2d();
                offset(delta = -arrow_fill_w) arrow_2d();
            }
            translate([-arrow_w / 2, arrow_shaft_h])
                square([arrow_w, arrow_head_h]);
        }
    }
}

frame_with_id([undef, undef, "green", "green", "green", "green"]);
plate();
rivets();
rollers();
belt();
arrow();
