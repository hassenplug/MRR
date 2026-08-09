// element20.scad — straight double-speed belt tile (two blue arrows)
// Units: inches

straight   = true;
left_turn  = false;
right_turn = false;

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
arrow_head_h  = arrow_w / 2;
arrow_gap     = 1/8;
arrow_h       = (plate_d * 3/4 - arrow_gap) / 2;
arrow_shaft_h = arrow_h - arrow_head_h;
arrow_outline = 1/8;

arrow_tip_y   = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;
arrow2_y      = arrow_tip_y - arrow_h;
arrow1_y      = arrow2_y - arrow_gap - arrow_h;

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) {
        translate([inset_x,           inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
        translate([plate_w - inset_x, inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
        if (inset_x + i * spacing_x <= roller_x_lo + roller_r - hole_r ||
            inset_x + i * spacing_x >= roller_x_hi - roller_r + hole_r) {
            translate([inset_x + i * spacing_x, inset_y,           -1])
                cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
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

module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9]) {
            translate([inset_x,           inset_y + i * spacing_y, 0])
                cylinder(h = plate_h, r = hole_r, $fn = 20);
            translate([plate_w - inset_x, inset_y + i * spacing_y, 0])
                cylinder(h = plate_h, r = hole_r, $fn = 20);
            if (inset_x + i * spacing_x <= roller_x_lo + roller_r - hole_r ||
            inset_x + i * spacing_x >= roller_x_hi - roller_r + hole_r) {
                translate([inset_x + i * spacing_x, inset_y,           0])
                    cylinder(h = plate_h, r = hole_r, $fn = 20);
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

module arrows() {
    color("blue")
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

frame_with_id([undef, undef, "blue", "blue", undef, undef]);
plate();
rivets();
rollers();
belt();
arrows();
