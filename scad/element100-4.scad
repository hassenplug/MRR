// element100-4.scad
// Flag square tile variant — gear with pennant flag, number "4" on yellow flag.

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

gear_n      = 20;
gear_r_tip  = 1.18;
gear_r_root = 1.00;
gear_r_bore = 0.82;
tooth_hw    = 4.5;
tooth_tip_f = 0.80;

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

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
}

module frame() {
    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0]) cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])          cube([plate_w, plate_d, plate_h + 0.002]);
    }
}

module plate() {
    difference() {
        color("darkgray") cube([plate_w, plate_d, plate_h]);
        rivet_holes();
    }
}

rivet_h = plate_h;
module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           0]) cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, 0]) cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, 0]) cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, 0]) cylinder(h = rivet_h, r = hole_r, $fn = 20);
    }
}

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
        for (i = [0:gear_n - 1]) rotate([0, 0, i * pitch]) gear_tooth_2d();
    }
}

module gear() {
    color("black")
    translate([plate_w / 2, plate_d / 2, +0.001])
    linear_extrude(plate_h)
    difference() { gear_2d(); circle(r = gear_r_bore, $fn = 80); }
}

module gear_bore() {
    color([0.80, 0.80, 0.80])
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h + 0.001)
    circle(r = gear_r_bore - 0.001, $fn = 80);
}

module flag_pennant_2d() {
    polygon([
        [flag_base_x, flag_top_y],
        [flag_base_x, flag_bot_y],
        [flag_tip_x,  flag_mid_y]
    ]);
}

module flag_pole() {
    color("red")
    translate([pole_cx - pole_r, pole_y1, 0.002])
    cube([pole_r * 2, pole_y2 - pole_y1, plate_h]);
}

module flag_outline() {
    color("darkgray")
    translate([0, 0, 0.001])
    linear_extrude(plate_h)
    difference() {
        offset(delta = outline_t) flag_pennant_2d();
        flag_pennant_2d();
    }
}

module flag() {
    color("red")
    translate([0, 0, 0.002])
    linear_extrude(plate_h)
    flag_pennant_2d();
}

frame();
plate();
rivets();
gear_bore();
gear();
flag_outline();
flag_pole();
flag();

module flag_label() {
    color("darkblue")
    translate([flag_base_x + (flag_tip_x - flag_base_x) * 0.38, flag_mid_y, 0])
    linear_extrude(plate_h + 0.003)
    text("4", size = 0.65, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

flag_label();
