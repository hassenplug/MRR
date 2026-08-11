// element120-B.scad
// Vortex Portal (Orange) — orange ring with inner fill, dashes, and upward arrow;
// letter "B" marks this variant.
// Units: inches

include <modules.scad>

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
    text("B", size = .3, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module label() {
    color("white")
    translate([cx, cy, 0])
    linear_extrude(plate_h)
    text("B", size = .3, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

union() {                                           // step 4: add label
    difference() {
        union() {                                   // step 3: add dashes & arrow
            difference() {
                union() {                           // step 2: add inner fill
                    difference() {
                        union() {                   // step 1: add ring
                            difference() {
                                plate(["orange", undef, "orange", "orange", "orange", "orange"]);   // step 0: plate (frame + rivets)
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
