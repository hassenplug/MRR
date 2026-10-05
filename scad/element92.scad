// element92.scad — Tool Kit
// A hammer and a wrench crossed in the middle of a tool tray on the perforated plate.
// Units: inches
//
// Every part sits in the top pattern_h-thick slice of the plate. The tray is
// cut from the plate once (all_cutouts()); each tool's own sub-shapes are
// subtracted from one another and from the tray floor so no two colors occupy
// the same area (see element34.scad for the same technique).

include <sub_base_plate.scad>

tagcolor = "saddlebrown";

plate_colors = [tagcolor, undef, undef, undef, undef, tagcolor];


chrome_color = [0.80, 0.82, 0.85];
handle_color = "saddlebrown";
head_color   = "dimgray";
drill_body_color  = "gold";
drill_grip_color  = "black";
drill_chuck_color = "dimgray";
drill_bit_color   = "lightgray";
box_frame_color = "lightgray";
box_floor_color = "darkgray";

// ── Tool tray box ────────────────────────────────────────────────────────────
// Outer edge sits plate_w/10 from the plate edge, just inside the rivet ring.

box_outer_inset = plate_w / 10;
box_frame_w     = frame_w;
box_outer_lo    = box_outer_inset;
box_outer_hi    = plate_w - box_outer_inset;
box_inner_lo    = box_outer_lo + box_frame_w;
box_inner_hi    = plate_w - box_inner_lo;

module stadium_2d(len, w) {
    r = w / 2;
    hull() {
        translate([-(len / 2 - r), 0]) circle(r = r, $fn = 32);
        translate([ (len / 2 - r), 0]) circle(r = r, $fn = 32);
    }
}

// ── Hammer ───────────────────────────────────────────────────────────────────

hm_cx = plate_w / 2; hm_cy = plate_w / 2; hm_len = 2.10; hm_w = 0.17; hm_ang = 45;

module hammer_handle_2d() { stadium_2d(hm_len, hm_w); }

// Sledge head: a double-faced block centered across the handle, handle tip
// poking just past it. Corners are beveled so the faces read as striking faces.
module hammer_head_raw_2d() {
    translate([hm_len / 2 - 0.42, -0.32]) polygon([
        [0.00, 0.04], [0.04, 0.00], [0.32, 0.00], [0.36, 0.04],
        [0.36, 0.60], [0.32, 0.64], [0.04, 0.64], [0.00, 0.60],
    ]);
}

module hammer_head_2d() {
    difference() {
        hammer_head_raw_2d();
        hammer_handle_2d();
    }
}

// Wrench lies over the hammer where they cross, so its footprint is cut out of
// the hammer's pieces, expressed in the hammer's local frame.
module wrench_in_hammer_frame_2d() {
    rotate([0, 0, -hm_ang]) translate([wr_cx - hm_cx, wr_cy - hm_cy])
        rotate([0, 0, wr_ang]) wrench_footprint_2d();
}

module hammer_footprint_2d() {
    union() { hammer_handle_2d(); hammer_head_raw_2d(); }
}

module hammer() {
    translate([hm_cx, hm_cy, plate_h - pattern_h]) rotate([0, 0, hm_ang]) {
        color(handle_color) linear_extrude(pattern_h)
            difference() { hammer_handle_2d(); wrench_in_hammer_frame_2d(); }
        color(head_color)   linear_extrude(pattern_h)
            difference() { hammer_head_2d(); wrench_in_hammer_frame_2d(); }
    }
}

// ── Wrench (open end + ring end) ─────────────────────────────────────────────

wr_cx = plate_w / 2; wr_cy = plate_w / 2; wr_len = hm_len; wr_w = 0.20; wr_ang = 135;
wr_jaw_r = 0.30; wr_slot_w = 0.20; wr_ring_r = 0.25; wr_hole_r = 0.11;

module wrench_footprint_2d() {
    jx = wr_len / 2 - wr_jaw_r * 0.6;
    rx = -wr_len / 2 + wr_ring_r * 0.6;
    difference() {
        union() {
            stadium_2d(wr_len, wr_w);
            translate([jx, 0]) circle(r = wr_jaw_r, $fn = 40);
            translate([rx, 0]) circle(r = wr_ring_r, $fn = 40);
        }
        translate([jx + 0.02, -wr_slot_w / 2]) square([wr_jaw_r + 0.1, wr_slot_w]);
        translate([rx, 0]) circle(r = wr_hole_r, $fn = 6);
    }
}

module wrench() {
    translate([wr_cx, wr_cy, plate_h - pattern_h]) rotate([0, 0, wr_ang])
    color(chrome_color) linear_extrude(pattern_h) wrench_footprint_2d();
}

// ── Tool tray box ────────────────────────────────────────────────────────────
// The whole box (frame + floor) is one recess cut from the plate; the floor
// has every tool's footprint subtracted so its dark gray never overlaps a tool.

module all_tool_footprints_2d() {
    union() {
        translate([hm_cx, hm_cy]) rotate([0, 0, hm_ang]) hammer_footprint_2d();
        translate([wr_cx, wr_cy]) rotate([0, 0, wr_ang]) wrench_footprint_2d();
    }
}

module box_outer_2d() {
    translate([box_outer_lo, box_outer_lo])
        square([box_outer_hi - box_outer_lo, box_outer_hi - box_outer_lo]);
}

module box_inner_2d() {
    translate([box_inner_lo, box_inner_lo])
        square([box_inner_hi - box_inner_lo, box_inner_hi - box_inner_lo]);
}

module box_frame() {
    color(box_frame_color)
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    difference() {
        box_outer_2d();
        box_inner_2d();
    }
}

module box_floor() {
    color(box_floor_color)
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    difference() {
        box_inner_2d();
        all_tool_footprints_2d();
    }
}

// ── Combined recess cut ──────────────────────────────────────────────────────

module all_cutouts() {
    translate([0, 0, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 0.002)
    box_outer_2d();
}

// ── Assembly ──────────────────────────────────────────────────────────────────

difference() {
    plate(plate_colors);
    all_cutouts();
}
box_frame();
box_floor();
hammer();
wrench();
