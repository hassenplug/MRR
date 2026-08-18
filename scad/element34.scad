// element34.scad — Electrical Hazard Panel
// Two yellow/black lightning-bolt panels flanked by red-tipped toggle levers.
// Units: inches
//
// Panels, bolts, rods, and balls all sit in the top pattern_h-thick slice of
// the plate — z from (plate_h - pattern_h) to plate_h — like gear()/
// gear_bore() in sub_innergears.scad, rather than spanning the plate's full
// thickness from z=0.

include <sub_base_plate.scad>

plate_colors = ["orange", undef, undef, undef, undef, "orange"];

// Panel pair — centered as a group, side by side
panel_w   = 0.70;
panel_h   = 1.85;
panel_gap = 0.18;
frame_t   = 0.09;
outer_r   = 0.08;
inner_r   = 0.05;

panel_cx_l = plate_w / 2 - (panel_w / 2 + panel_gap / 2);
panel_cx_r = plate_w / 2 + (panel_w / 2 + panel_gap / 2);
panel_cy   = plate_d / 2;
panel_cx   = [panel_cx_l, panel_cx_r];

yellow_w = panel_w - 2 * frame_t;
yellow_h = panel_h - 2 * frame_t;
bolt_w   = yellow_w * 0.55;
bolt_h   = yellow_h * 0.55;

// Toggle levers — flank the panel pair on the outside, tilted opposite ways
toggle_len    = 1.7;
toggle_r      = 0.035;
toggle_ball_r = 0.08;
toggle_tilt   = 8;
toggle_offset = 0.22;
toggle_cy     = plate_d / 2;
// [x, tilt sign] per side, so the levers lean away from each other
toggle_pos = [
    [panel_cx_l - panel_w / 2 - toggle_offset, -1],
    [panel_cx_r + panel_w / 2 + toggle_offset,  1]
];

// ── 2D shapes ────────────────────────────────────────────────────────────────

module rounded_rect_2d(w, h, r) {
    minkowski() {
        square([w - 2 * r, h - 2 * r], center = true);
        circle(r = r, $fn = 32);
    }
}

module bolt_2d(w, h) {
    polygon([
        [ 0.20 * w,  0.50 * h],
        [-0.50 * w,  0.08 * h],
        [ 0.00 * w,  0.08 * h],
        [-0.20 * w, -0.50 * h],
        [ 0.50 * w, -0.08 * h],
        [ 0.00 * w, -0.08 * h]
    ]);
}

module toggle_rod_2d() {
    hull() {
        translate([0,  toggle_len / 2 - toggle_ball_r]) circle(r = toggle_r, $fn = 24);
        translate([0, -toggle_len / 2 + toggle_ball_r]) circle(r = toggle_r, $fn = 24);
    }
}

// ── Panel black body → yellow inset → black bolt ──────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

module panel_holes() {
    for (cx = panel_cx)
        translate([cx, panel_cy, plate_h - pattern_h - 0.001])
        linear_extrude(pattern_h + 0.002)
        rounded_rect_2d(panel_w, panel_h, outer_r);
}

module panels_black() {
    color("black")
    for (cx = panel_cx)
        translate([cx, panel_cy, plate_h - pattern_h])
        linear_extrude(pattern_h)
        rounded_rect_2d(panel_w, panel_h, outer_r);
}

module yellow_holes() {
    for (cx = panel_cx)
        translate([cx, panel_cy, plate_h - pattern_h - 0.001])
        linear_extrude(pattern_h + 0.002)
        rounded_rect_2d(yellow_w, yellow_h, inner_r);
}

module panels_yellow() {
    color("orange")
    for (cx = panel_cx)
        translate([cx, panel_cy, plate_h - pattern_h])
        linear_extrude(pattern_h)
        rounded_rect_2d(yellow_w, yellow_h, inner_r);
}

module bolt_holes() {
    for (cx = panel_cx)
        translate([cx, panel_cy, plate_h - pattern_h - 0.001])
        linear_extrude(pattern_h + 0.002)
        bolt_2d(bolt_w, bolt_h);
}

module bolts_black() {
    color("black")
    for (cx = panel_cx)
        translate([cx, panel_cy, plate_h - pattern_h])
        linear_extrude(pattern_h)
        bolt_2d(bolt_w, bolt_h);
}

// ── Toggle levers: gray rod → red end balls ────────────────────────────────────

module rod_holes() {
    for (t = toggle_pos)
        translate([t[0], toggle_cy, plate_h - pattern_h - 0.001])
        rotate([0, 0, t[1] * toggle_tilt])
        linear_extrude(pattern_h + 0.002)
        toggle_rod_2d();
}

module rods_gray() {
    color("lightgray")
    for (t = toggle_pos)
        translate([t[0], toggle_cy, plate_h - pattern_h])
        rotate([0, 0, t[1] * toggle_tilt])
        linear_extrude(pattern_h)
        toggle_rod_2d();
}

module ball_holes() {
    for (t = toggle_pos)
        translate([t[0], toggle_cy, plate_h - pattern_h - 0.001])
        rotate([0, 0, t[1] * toggle_tilt])
        for (y = [toggle_len / 2, -toggle_len / 2])
            translate([0, y, 0])
            linear_extrude(pattern_h + 0.002)
            circle(r = toggle_ball_r, $fn = 24);
}

module balls_red() {
    color("red")
    for (t = toggle_pos)
        translate([t[0], toggle_cy, plate_h - pattern_h])
        rotate([0, 0, t[1] * toggle_tilt])
        for (y = [toggle_len / 2, -toggle_len / 2])
            translate([0, y, 0])
            linear_extrude(pattern_h)
            circle(r = toggle_ball_r, $fn = 24);
}

// ── Assembly ──────────────────────────────────────────────────────────────────

union() {                                           // step 5: add red balls
    difference() {
        union() {                                   // step 4: add gray rods
            difference() {
                union() {                           // step 3: add black bolts
                    difference() {
                        union() {                   // step 2: add yellow panels
                            difference() {
                                union() {           // step 1: add black panels
                                    difference() {
                                        plate(plate_colors);   // step 0: plate (frame + rivets)
                                        panel_holes();
                                    }
                                    panels_black();
                                }
                                yellow_holes();
                            }
                            panels_yellow();
                        }
                        bolt_holes();
                    }
                    bolts_black();
                }
                rod_holes();
            }
            rods_gray();
        }
        ball_holes();
    }
    balls_red();
}
