// element110-5.scad
// Gear tile variant — number "5" in the bore.
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

// Ring geometry with inward-pointing teeth — centered on tile
gear_r_tip  = 1.18;   // outer edge of ring (plain)
gear_r_root = 1.00;   // ring inner edge; teeth root here
gear_r_bore = 0.82;   // bore radius / tooth tip depth
gear_n      = 20;
tooth_hw    = 4.5;
tooth_tip_f = 0.80;

// ── Standard modules ─────────────────────────────────────────────────────────

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, -0.001]) cylinder(h = plate_h + 0.002, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, -0.001]) cylinder(h = plate_h + 0.002, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, -0.001]) cylinder(h = plate_h + 0.002, r = hole_r, $fn = 20);
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

module plate() {
    color("darkgray")
    cube([plate_w, plate_d, plate_h]);
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

// ── Gear 2D helpers ───────────────────────────────────────────────────────────

module gear_tooth_2d() {
    shift   = (gear_r_root - gear_r_bore) / 2;
    r_outer = gear_r_root + shift;
    r_inner = gear_r_bore + shift;
    polygon([
        [r_outer * cos(-tooth_hw),               r_outer * sin(-tooth_hw)],
        [r_inner * cos(-tooth_hw * tooth_tip_f),  r_inner * sin(-tooth_hw * tooth_tip_f)],
        [r_inner * cos( tooth_hw * tooth_tip_f),  r_inner * sin( tooth_hw * tooth_tip_f)],
        [r_outer * cos( tooth_hw),               r_outer * sin( tooth_hw)],
    ]);
}

module gear_2d() {
    circle(r = gear_r_tip, $fn = 160);
}

module bore_2d() {
    pitch = 360 / gear_n;
    difference() {
        circle(r = gear_r_root, $fn = 160);
        for (i = [0:gear_n - 1]) rotate([0, 0, i * pitch]) gear_tooth_2d();
    }
}

// ── Gear holes & gear ────────────────────────────────────────────────────────

module gear_holes() {
    translate([plate_w / 2, plate_d / 2, -0.001])
    linear_extrude(plate_h + 0.002)
    difference() {
        gear_2d();
        bore_2d();
    }
}

module gear() {
    color("darkgreen")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    difference() { gear_2d(); bore_2d(); }
}

// ── Gear bore hole & gear bore ────────────────────────────────────────────────

module gear_bore_holes() {
    translate([plate_w / 2, plate_d / 2, -0.001])
    linear_extrude(plate_h + 0.002)
    bore_2d();
}

module gear_bore() {
    color("lightgray")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    offset(delta = -0.001) bore_2d();
}

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes() {
    translate([plate_w / 2, plate_d / 2, -0.001])
    linear_extrude(plate_h + 0.002)
    text("5", size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module label() {
    color("green")
    translate([plate_w / 2, plate_d / 2, 0])
    linear_extrude(plate_h)
    text("5", size = 1.1, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

frame_with_id(["green", "green", "green", "green", undef, "green"]);

union() {                                           // step 5: add label
    difference() {
        union() {                                   // step 4: add gear bore
            difference() {
                union() {                           // step 3: add gear
                    difference() {
                        union() {                   // step 2: add rivets
                            difference() {
                                plate();            // step 1: plate
                                rivet_holes();
                            }
                            rivets();
                        }
                        gear_holes();
                    }
                    gear();
                }
                gear_bore_holes();
            }
            gear_bore();
        }
        label_holes();
    }
    label();
}
