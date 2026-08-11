// element20.scad — straight double-speed belt tile (two blue arrows)
// Units: inches

straight   = true;
left_turn  = false;
right_turn = false;

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

arrow_w       = belt_w * 0.75;
arrow_shaft_w = arrow_w * 0.4;
arrow_head_h  = arrow_w / 2;
arrow_gap     = 1/8;
arrow_h       = (plate_d * 3/4 - arrow_gap) / 2;
arrow_shaft_h = arrow_h - arrow_head_h;
arrow_outline = 1/8;

arrow_tip_y   = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;
arrow2_y      = arrow_tip_y - arrow_h;
arrow1_y      = arrow2_y - arrow_gap - arrow_h;

module belt_cutout() {
    translate([(plate_w - belt_w) / 2, -0.001, -0.001])
        cube([belt_w, plate_d + 0.002, plate_h + 0.002]);
}

module roller_slots() {
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

module rollers() {
    color("blue")
    difference() {
        for (i = [0:roller_count - 1]) {
            cy = roller_inset + i * roller_y_step;
            hull() {
                translate([roller_x_lo + roller_r, cy, 0])
                    cylinder(h = plate_h, r = roller_r, $fn = 20);
                translate([roller_x_hi - roller_r, cy, 0])
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
    color("lightblue")
    for (ay = [arrow1_y, arrow2_y])
        translate([plate_w / 2, ay, 0])
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
        for (ay = [arrow1_y, arrow2_y])
            translate([plate_w / 2, ay, -0.001])
            linear_extrude(plate_h + 0.002)
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
    }
}

difference() {
    plate([undef, undef, "lightblue", "lightblue", undef, undef]);
    roller_slots();
    belt_cutout();
}
rollers();
belt();
arrows();
