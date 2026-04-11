// element110-8.scad
// Gear tile variant — number "8" in the bore.
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

// Gear geometry — centered on tile
gear_n      = 20;
gear_r_tip  = 1.18;
gear_r_root = 1.00;
gear_r_bore = 0.82;
tooth_hw    = 4.5;
tooth_tip_f = 0.80;

// ── Standard modules ─────────────────────────────────────────────────────────

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    // Front edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, inset_y,           -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    // Back edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, plate_d - inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    // Left edge
    for (i = [0:9])
        translate([inset_x,           inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    // Right edge
    for (i = [0:9])
        translate([plate_w - inset_x, inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
}

module frame() {
    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
    }
}

// ── Gear modules ─────────────────────────────────────────────────────────────

module gear_tooth_2d() {
    polygon([
        [gear_r_root * cos(-tooth_hw),               gear_r_root * sin(-tooth_hw)],
        [gear_r_tip  * cos(-tooth_hw * tooth_tip_f),  gear_r_tip  * sin(-tooth_hw * tooth_tip_f)],
        [gear_r_tip  * cos( tooth_hw * tooth_tip_f),  gear_r_tip  * sin( tooth_hw * tooth_tip_f)],
        [gear_r_root * cos( tooth_hw),               gear_r_root * sin( tooth_hw)],
    ]);
}

module gear_2d() {
    pitch = 360 / gear_n;
    union() {
        circle(r = gear_r_root, $fn = gear_n * 8);
        for (i = [0:gear_n - 1])
            rotate([0, 0, i * pitch])
                gear_tooth_2d();
    }
}

// Cut the full gear profile (ring + teeth, including bore) through the plate
module gear_holes() {
    translate([plate_w / 2, plate_d / 2, -1])
    linear_extrude(plate_h + 2)
    gear_2d();
}

// Cut the number text through the plate
module label_holes() {
    translate([plate_w / 2, plate_d / 2, -1])
    linear_extrude(plate_h + 2)
    text("8", size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module plate() {
    difference() {
        color("darkgray")
            cube([plate_w, plate_d, plate_h]);
        rivet_holes();
        gear_holes();
        label_holes();
    }
}

rivet_h = plate_h;
module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9])
            translate([inset_x + i * spacing_x, inset_y,           0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9])
            translate([inset_x + i * spacing_x, plate_d - inset_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9])
            translate([inset_x,           inset_y + i * spacing_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9])
            translate([plate_w - inset_x, inset_y + i * spacing_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
    }
}

module gear() {
    color("black")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    difference() {
        gear_2d();
        circle(r = gear_r_bore, $fn = 80);
    }
}

module gear_bore() {
    color([0.80, 0.80, 0.80])
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    circle(r = gear_r_bore - 0.001, $fn = 80);
}

// ── Label ─────────────────────────────────────────────────────────────────────

module label() {
    color("green")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    text("8", size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Assembly ──────────────────────────────────────────────────────────────────

frame();
plate();
rivets();
gear_bore();
gear();
label();
