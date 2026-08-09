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

    // Front edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);

    // Back edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, plate_d - inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);

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

        // Back edge
        for (i = [0:9])
            translate([inset_x + i * spacing_x, plate_d - inset_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);

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

module plate() {
    difference() {
        color("darkgray")
            cube([plate_w, plate_d, plate_h]);
        rivet_holes();
    }
}

frame_with_id(["lightgray", undef, undef, undef, undef, "lightgray"]);
plate();
rivets();

