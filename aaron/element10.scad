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
    }
}

frame();
plate();
rivets();

