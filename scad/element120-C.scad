// element120-C.scad
// Vortex Portal (Orange) — orange ring with inner fill, dashes, and upward arrow;
// letter "C" marks this variant.
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;
hole_d  = 3/32;
hole_r  = hole_d / 2;

cx = plate_w / 2;
cy = plate_d / 2;

// Orange ring — same radii as the element100/110 gear ring
ring_r_out = 1.18;
ring_r_in  = 1.00;

// Inward-pointing teeth cut into the ring's inner edge (same technique as element110-2)
ring_n        = 20;
ring_tooth_hw = 4.5;
ring_tooth_f  = 0.80;
ring_tooth_d  = 0.09;   // tooth depth, same as the gear tiles' tooth depth

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

// ── Ring 2D helpers ───────────────────────────────────────────────────────────

module ring_tooth_2d() {
    r_outer = ring_r_in + ring_tooth_d;
    r_inner = ring_r_in - ring_tooth_d;
    polygon([
        [r_outer * cos(-ring_tooth_hw),               r_outer * sin(-ring_tooth_hw)],
        [r_inner * cos(-ring_tooth_hw * ring_tooth_f), r_inner * sin(-ring_tooth_hw * ring_tooth_f)],
        [r_inner * cos( ring_tooth_hw * ring_tooth_f), r_inner * sin( ring_tooth_hw * ring_tooth_f)],
        [r_outer * cos( ring_tooth_hw),               r_outer * sin( ring_tooth_hw)],
    ]);
}

module ring_2d() {
    circle(r = ring_r_out, $fn = 120);
}

module ring_bore_2d() {
    pitch = 360 / ring_n;
    difference() {
        circle(r = ring_r_in, $fn = 120);
        for (i = [0:ring_n - 1]) rotate([0, 0, i * pitch]) ring_tooth_2d();
    }
}

// ── Ring hole & ring ─────────────────────────────────────────────────────────

module ring_holes() {
    translate([cx, cy, -1])
    linear_extrude(plate_h + 2)
    difference() {
        ring_2d();
        ring_bore_2d();
    }
}

module white_ring() {
    color("orange")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    difference() {
        ring_2d();
        ring_bore_2d();
    }
}

// ── Inner fill hole & inner fill ─────────────────────────────────────────────

module inner_fill_holes() {
    translate([cx, cy, -1])
    linear_extrude(plate_h + 2)
    ring_bore_2d();
}

module inner_fill() {
    color("lightgray")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    offset(delta = -0.001) ring_bore_2d();
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

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes() {
    translate([cx, cy, -1])
    linear_extrude(plate_h + 2)
    text("C", size = .3, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module label() {
    color("white")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    text("C", size = .3, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

frame_with_id(["orange", "orange", undef, "orange", "orange", "orange"]);

union() {                                           // step 5: add label
    difference() {
        union() {                                   // step 4: add dashes & arrow
            difference() {
                union() {                           // step 3: add inner fill
                    difference() {
                        union() {                   // step 2: add ring
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
                arrow_holes();                               // cut arrow holes
            }
            white_dashes();                                 // fill with dashes
            white_arrow();                                  // fill with arrow
        }
        label_holes();                                      // cut label hole
    }
    label();                                                // fill with label
}
