// element10.scad
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

// Roller slots
roller_count  = 11;
roller_h_size = 3/16;   // top-to-bottom thickness of each roller slot
roller_r      = roller_h_size / 2;

// Available space inside rivet frame (same inset as rivet spacing)
roller_inset_x = (plate_w / 10) / 2;
roller_inset_y = (plate_d / 10) / 2;
roller_zone_w  = plate_w - 2 * roller_inset_x;
roller_zone_d  = plate_d - 2 * roller_inset_y;

// Gap between rollers: split remaining vertical space evenly across 12 gaps
roller_gap = (roller_zone_d - roller_count * roller_h_size) / (roller_count + 1);

module roller_slots() {
    // Additional left/right clearzone equal to rivet-to-edge inset
    roller_x_start = 2 * roller_inset_x;
    roller_x_end   = plate_w - 2 * roller_inset_x;

    for (i = [0:roller_count - 1]) {
        cy = roller_inset_y + roller_gap + roller_r + i * (roller_h_size + roller_gap);
        translate([0, 0, -0.001])
        // Stadium shape: hull of two cylinders
        hull() {
            translate([roller_x_start + roller_r, cy, 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
            translate([roller_x_end - roller_r, cy, 0])
                cylinder(h = plate_h + 0.002, r = roller_r, $fn = 20);
        }
    }
}

belt_w = 1.5;
belt_d = 2 + 13/16;

module rollers() {
    roller_x_start = 2 * roller_inset_x;
    roller_x_end   = plate_w - 2 * roller_inset_x;

    color("blue")
    difference() {
        for (i = [0:roller_count - 1]) {
            cy = roller_inset_y + roller_gap + roller_r + i * (roller_h_size + roller_gap);
            hull() {
                translate([roller_x_start + roller_r, cy, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
                translate([roller_x_end - roller_r, cy, 0])
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

module belt_cutout() {
    translate([(plate_w - belt_w) / 2, -0.001, -0.001])
        cube([belt_w, plate_d + 0.002, plate_h + 0.002]);
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

arrow_w       = belt_w * 0.75;
arrow_total_h = 3/4 * plate_d;
arrow_gap     = 1/16;
arrow_h       = (arrow_total_h - arrow_gap) / 2;  // each arrow: arrow1 + gap + arrow2 = arrow_total_h
arrow_outline = 1/16;
arrow_head_h  = arrow_w / 2;               // 90° tip
arrow_shaft_w = arrow_w * 0.4;
arrow_shaft_h = arrow_h - arrow_head_h;

lower_arrow_y = (plate_d - arrow_total_h) / 2;
upper_arrow_y = lower_arrow_y + arrow_h + arrow_gap;

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
    for (ay = [upper_arrow_y, lower_arrow_y])
        translate([plate_w/2, ay, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
}

module arrow() {
    color("blue")
    for (ay = [upper_arrow_y, lower_arrow_y])
        translate([plate_w/2, ay, 0])
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
belt();
arrow();

