// element120.scad
// Vortex Portal (Orange) — orange ring with inner fill, dashes, and upward arrow.
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;
hole_d  = 3/32;
hole_r  = hole_d / 2;

cx = plate_w / 2;
cy = plate_d / 2;

// Orange ring (scaled to match original disc footprint, r_out = former disc_r)
ring_r_out = 1.22;
ring_r_in  = 0.89;

// Orange dashed arc inside the ring, lower arc (portal intake indicator)
dash_r     = 0.73;
dash_count = 8;
dash_a1    = 205;
dash_a2    = 335;
dash_w     = 0.074;
dash_len   = 0.140;

// Orange upward arrow — bottom unchanged, tip restored to original position
arr_stem_w  = 0.40;
arr_stem_y1 = cy - 0.44;
arr_stem_y2 = cy + 0.20;
arr_head_w  = 0.90;
arr_head_h  = 0.38;

// ── Standard modules ─────────────────────────────────────────────────────────

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
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
    }
}

// Plate with rivet holes only — all other holes are added at assembly level
module plate() {
    difference() {
        color("darkgray")
            cube([plate_w, plate_d, plate_h]);
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

// ── Ring hole & ring ─────────────────────────────────────────────────────────

module ring_holes() {
    translate([cx, cy, -1])
    linear_extrude(plate_h + 2)
    difference() {
        circle(r = ring_r_out, $fn = 120);
        circle(r = ring_r_in,  $fn = 120);
    }
}

module white_ring() {
    color("orange")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    difference() {
        circle(r = ring_r_out, $fn = 120);
        circle(r = ring_r_in,  $fn = 120);
    }
}

// ── Inner fill hole & inner fill ─────────────────────────────────────────────

module inner_fill_holes() {
    translate([cx, cy, -1])
    linear_extrude(plate_h + 2)
    circle(r = ring_r_in, $fn = 120);
}

module inner_fill() {
    color("lightgray")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    circle(r = ring_r_in - 0.001, $fn = 120);
}

// ── Dash holes & dashes ───────────────────────────────────────────────────────

module dash_holes() {
    span = dash_a2 - dash_a1;
    for (i = [0 : dash_count - 1]) {
        angle = dash_a1 + span * i / (dash_count - 1);
        dx = cx + dash_r * cos(angle);
        dy = cy + dash_r * sin(angle);
        translate([dx, dy, -1])
        rotate([0, 0, angle + 90])
        linear_extrude(plate_h + 2)
        square([dash_w, dash_len], center = true);
    }
}

module white_dashes() {
    span = dash_a2 - dash_a1;
    color("orange") {
        for (i = [0 : dash_count - 1]) {
            angle = dash_a1 + span * i / (dash_count - 1);
            dx = cx + dash_r * cos(angle);
            dy = cy + dash_r * sin(angle);
            translate([dx, dy, 0])
            rotate([0, 0, angle + 90])
            linear_extrude(plate_h)
            square([dash_w, dash_len], center = true);
        }
    }
}

// ── Arrow hole & arrow ────────────────────────────────────────────────────────

module arrow_holes() {
    translate([0, 0, -1])
    linear_extrude(plate_h + 2)
    union() {
        translate([cx - arr_stem_w / 2, arr_stem_y1])
            square([arr_stem_w, arr_stem_y2 - arr_stem_y1]);
        translate([cx, arr_stem_y2])
            polygon([
                [-arr_head_w / 2, 0],
                [ arr_head_w / 2, 0],
                [0, arr_head_h]
            ]);
    }
}

module white_arrow() {
    color("orange")
    linear_extrude(plate_h)
    union() {
        translate([cx - arr_stem_w / 2, arr_stem_y1])
            square([arr_stem_w, arr_stem_y2 - arr_stem_y1]);
        translate([cx, arr_stem_y2])
            polygon([
                [-arr_head_w / 2, 0],
                [ arr_head_w / 2, 0],
                [0, arr_head_h]
            ]);
    }
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

frame();

union() {                                           // step 4: add dashes & arrow
    difference() {
        union() {                                   // step 3: add inner fill
            difference() {
                union() {                           // step 2: add ring
                    difference() {
                        // step 1: plate & rivet holes + rivets
                        union() {
                            plate();
                            rivets();
                        }
                        ring_holes();               // cut ring holes
                    }
                    white_ring();                   // fill with ring
                }
                inner_fill_holes();                 // cut inner fill holes
            }
            inner_fill();                           // fill with inner fill
        }
        dash_holes();                               // cut dash holes
        arrow_holes();                              // cut arrow holes
    }
    white_dashes();                                 // fill with dashes
    white_arrow();                                  // fill with arrow
}
