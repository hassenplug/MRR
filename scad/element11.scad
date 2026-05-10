// element11.scad
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

module rivet_holes() {
    // 10 holes per side; inset = half the spacing so holes form a clean frame
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
/*
    // Front edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);

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
/*
        // Front edge
        for (i = [0:9])
            translate([inset_x + i * spacing_x, inset_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);

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

// Roller slots radiating from upper-right rivet toward right and top rivets
roller_count  = 13;
roller_h_size = 3/16;
roller_r      = roller_h_size / 2;

roller_inset_x = (plate_w / 10) / 2;
roller_inset_y = (plate_d / 10) / 2;

// Hub: upper-right rivet
hub_x = plate_w - roller_inset_x;
hub_y = plate_d - roller_inset_y;

// Radial extent matches element10 x_start / x_end clearzone
roller_inner_dist = 2 * roller_inset_x;
roller_outer_dist = plate_w - 2 * roller_inset_x;

module roller_slots() {
    for (i = [0:roller_count - 1]) {
        a = 270 + i * (180 - 270) / (roller_count - 1);
        translate([0, 0, -0.001])
        hull() {
            translate([hub_x + (roller_inner_dist + roller_r) * cos(a),
                       hub_y + (roller_inner_dist + roller_r) * sin(a), 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            translate([hub_x + (roller_outer_dist - roller_r) * cos(a),
                       hub_y + (roller_outer_dist - roller_r) * sin(a), 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
        }
    }
}

belt_w = 1.75;

// Belt arc: center at top-right corner, radius = plate_w/2.
arc_cx       = plate_w;
arc_cy       = plate_d;
arc_r        = plate_w / 2;
belt_inner_r = arc_r - belt_w / 2;
belt_outer_r = arc_r + belt_w / 2;
rivet_inset  = (plate_w / 10) / 2;
arc_fn       = 40;

// Each arc radius crosses the rivet line at a different angle offset from 270°/180°.
// inner: asin(rivet_inset / belt_inner_r), outer: asin(rivet_inset / belt_outer_r)
// This gives a vertical right face and horizontal top face on the belt polygon.
belt_inner_da = asin(rivet_inset / belt_inner_r);
belt_outer_da = asin(rivet_inset / belt_outer_r);

// CCW polygon: inner arc CW (right→top), then outer arc CCW (top→right).
// Closing edges are automatically vertical (right) and horizontal (top).
module belt_arc_2d(margin = 0) {
    inner_a_right = 270 - belt_inner_da + margin;
    inner_a_top   = 180 + belt_inner_da - margin;
    outer_a_top   = 180 + belt_outer_da - margin;
    outer_a_right = 270 - belt_outer_da + margin;
    inner_pts = [for (i = [0:arc_fn])
        let(a = inner_a_right + i * (inner_a_top - inner_a_right) / arc_fn)
        [arc_cx + belt_inner_r * cos(a), arc_cy + belt_inner_r * sin(a)]];
    outer_pts = [for (i = [0:arc_fn])
        let(a = outer_a_top + i * (outer_a_right - outer_a_top) / arc_fn)
        [arc_cx + belt_outer_r * cos(a), arc_cy + belt_outer_r * sin(a)]];
    polygon(concat(inner_pts, outer_pts));
}

module belt_cutout() {
    translate([0, 0, -0.001])
    linear_extrude(plate_h + 0.002)
    belt_arc_2d();
}

module rollers() {
    color("green")
    difference() {
        for (i = [0:roller_count - 1]) {
            a = 270 + i * (180 - 270) / (roller_count - 1);
            hull() {
                translate([hub_x + (roller_inner_dist + roller_r) * cos(a),
                           hub_y + (roller_inner_dist + roller_r) * sin(a), 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
                translate([hub_x + (roller_outer_dist - roller_r) * cos(a),
                           hub_y + (roller_outer_dist - roller_r) * sin(a), 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
            }
        }
        belt_cutout();
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
        belt_cutout();
    }
}

// Arrow — identical to element10, unchanged
arrow_w       = belt_w * 0.75;
arrow_y       = 3 * plate_d / 20;  // bottom of shaft: second-from-bottom rivet
arrow_h       = 7 * plate_d / 10;  // top of head: second-from-top rivet

arrow_outline = 1/16;

arrow_head_h  = arrow_w / 2;               // 90 deg tip

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
    translate([plate_w/2, arrow_y, -0.001])
    linear_extrude(plate_h + 0.002)
    difference() {
        arrow_2d();
        offset(delta = -arrow_outline) arrow_2d();
    }
}

module arrow() {
    color("green")
    translate([plate_w/2, arrow_y, 0])
    linear_extrude(plate_h)
    difference() {
        arrow_2d();
        offset(delta = -arrow_outline) arrow_2d();
    }
}

module belt() {
    color("black")
    difference() {
        linear_extrude(plate_h)
        belt_arc_2d();
        arrow_cutout();
    }
}

frame();
plate();
rivets();
rollers();
belt();
arrow();
