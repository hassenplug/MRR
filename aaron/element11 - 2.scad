// element11 - 2.scad
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    // Front edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
/*
    // Back edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, plate_d - inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
*/
    // Left edge
    for (i = [0:9])
        translate([inset_x, inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);

    // Right edge
    for (i = [0:9])
        translate([plate_w - inset_x, inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
}

rivet_h = plate_h;

module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;

    color("lightgray") {
        // Front edge
        for (i = [0:9])
            translate([inset_x + i * spacing_x, inset_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
/*
        // Back edge
        for (i = [0:9])
            translate([inset_x + i * spacing_x, plate_d - inset_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
*/
        // Left edge
        for (i = [0:9])
            translate([inset_x, inset_y + i * spacing_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);

        // Right edge
        for (i = [0:9])
            translate([plate_w - inset_x, inset_y + i * spacing_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
    }
}

frame_w = 1/16;

// Roller slots
roller_count  = 11;
roller_h_size = 3/16;
roller_r      = roller_h_size / 2;

rivet_inset  = (plate_w / 10) / 2;
arc_cx       = plate_w - rivet_inset;
arc_cy       = plate_d - rivet_inset;
arc_a_start  = 180;
arc_a_end    = 270;
roller_gap_a = (arc_a_end - arc_a_start) / (roller_count - 1);

roller_r_lo  = plate_w / 10 - rivet_inset;
roller_r_hi  = plate_w - plate_w / 10 - rivet_inset;
roller_r_mid = (roller_r_lo + roller_r_hi) / 2;

belt_w = 1.5;

module belt_cutout() {
    translate([(plate_w - belt_w) / 2, -0.001, -0.001])
        cube([belt_w, plate_d + 0.002, plate_h + 0.002]);
}

module roller_slots() {
    for (i = [0:roller_count - 1]) {
        a = arc_a_start + roller_gap_a * i;
        translate([arc_cx, arc_cy, -0.001])
        rotate([0, 0, a]) {
            // Inner half cutout — only first, middle, last
            if (i == 0 || i == floor((roller_count - 1) / 2) || i == roller_count - 1)
            hull() {
                translate([roller_r_lo + roller_r, 0, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
                translate([roller_r_mid, 0, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            }
            // Outer half cutout — all rollers
            hull() {
                translate([roller_r_mid, 0, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
                translate([roller_r_hi - roller_r, 0, 0])
                    cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            }
        }
    }
}

module frame() {
    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2*frame_w, plate_d + 2*frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
    }
}

module plate() {
    difference() {
        color("darkgray")
            cube([plate_w, plate_d, plate_h]);
        rivet_holes();
        roller_slots();
        //belt_cutout();
    }
}

module rollers() {
    for (i = [0:roller_count - 1]) {
        a = arc_a_start + roller_gap_a * i;
        translate([arc_cx, arc_cy, 0])
        rotate([0, 0, a]) {
            // Inner half (closer to arc center) — red; only first, middle, last
            if (i == 0 || i == floor((roller_count - 1) / 2) || i == roller_count - 1)
            color("red")
            hull() {
                translate([roller_r_lo + roller_r, 0, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
                translate([roller_r_mid, 0, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
            }
            // Outer half (farther from arc center) — blue
            color("blue")
            hull() {
                translate([roller_r_mid, 0, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
                translate([roller_r_hi - roller_r, 0, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
            }
        }
    }
}

arrow_w       = belt_w * 0.75;
arrow_h       = 1/2 * plate_d;
arrow_outline = 1/16;
arrow_head_h  = arrow_w / 2;
arrow_shaft_w = arrow_w * 0.4;
arrow_shaft_h = arrow_h - arrow_head_h;

module arrow_2d() {
    polygon([
        [-arrow_shaft_w/2, 0],
        [ arrow_shaft_w/2, 0],
        [ arrow_shaft_w/2, arrow_shaft_h],
        [ arrow_w/2,       arrow_shaft_h],
        [ 0,               arrow_h],
        [-arrow_w/2,       arrow_shaft_h],
        [-arrow_shaft_w/2, arrow_shaft_h]
    ]);
}

module arrow_cutout() {
    translate([plate_w/2, (plate_d - arrow_h)/2, -0.001])
    linear_extrude(plate_h + 0.002)
    difference() {
        arrow_2d();
        offset(delta = -arrow_outline) arrow_2d();
    }
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

module belt() {
    color("black")
    difference() {
        translate([(plate_w - belt_w) / 2, 0, 0])
            cube([belt_w, plate_d, plate_h]);
        arrow_cutout();
    }
}

frame();
plate();
rivets();
rollers();
//belt();
//arrow();
