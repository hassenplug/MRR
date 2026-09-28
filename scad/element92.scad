// element92.scad — Tool Kit
// Scattered mechanical parts on the perforated plate: a purple industrial
// component, a ball bearing, a ball-and-socket robot-arm joint, a pick
// hammer, a tank-tread gear track, and a yellow/black striped roller.
// Units: inches
//
// Every part sits in the top pattern_h-thick slice of the plate — z from
// (plate_h - pattern_h) to plate_h — like belt/gear/panel tiles. Each part's
// footprint is cut from the plate once (all_cutouts()); parts with more than
// one color subtract their own already-drawn sub-shapes from the next
// sub-shape so no two colors occupy the same area (see element34.scad for
// the same technique).

include <sub_base_plate.scad>

tagcolor = "purple";

plate_colors = [tagcolor, undef, undef, undef, undef, tagcolor];

chrome_color = [0.80, 0.82, 0.85];
socket_color = "dimgray";
purple_color = [0.56, 0.40, 0.78];
bearing_color = [0.75, 0.75, 0.78];
handle_color = "lightgray";
head_color   = "dimgray";
track_color  = "black";
sprocket_color = "dimgray";
sprocket_hub_color = "darkgray";
roller_yellow = "yellow";
roller_black  = "black";
box_frame_color = "lightgray";
box_floor_color = "darkgray";

// ── Tool tray box ────────────────────────────────────────────────────────────
// rivet_holes()/rivets() (sub_base_plate.scad) inset the rivet ring by
// plate_w/20 from the plate edge — the same gap the outer frame sits at from
// the rivets. Mirroring that gap on the inside of the ring puts the box's
// outer edge at 2 * (plate_w/20) = plate_w/10 from the edge; the box border
// itself reuses frame_w so it reads as a matching inner frame.

box_outer_inset = plate_w / 10;
box_frame_w     = frame_w;
box_outer_lo    = box_outer_inset;
box_outer_hi    = plate_w - box_outer_inset;
box_inner_lo    = box_outer_lo + box_frame_w;
box_inner_hi    = plate_w - box_inner_lo;

// ── Generic 2D helpers ──────────────────────────────────────────────────────

module stadium_2d(len, w) {
    r = w / 2;
    hull() {
        translate([-(len / 2 - r), 0]) circle(r = r, $fn = 32);
        translate([ (len / 2 - r), 0]) circle(r = r, $fn = 32);
    }
}

module gear_tooth_2d(n, r_t, r_r) {
    tw = (360 / n) / 4;
    polygon([
        [r_r * cos(-tw),       r_r * sin(-tw)],
        [r_t * cos(-tw * 0.7), r_t * sin(-tw * 0.7)],
        [r_t * cos( tw * 0.7), r_t * sin( tw * 0.7)],
        [r_r * cos( tw),       r_r * sin( tw)],
    ]);
}

module gear_2d(n, r_t, r_r) {
    union() {
        circle(r = r_r, $fn = n * 8);
        for (i = [0:n - 1]) rotate([0, 0, i * (360 / n)]) gear_tooth_2d(n, r_t, r_r);
    }
}

// ── Purple industrial component ─────────────────────────────────────────────

pc_cx = 0.70; pc_cy = 0.70; pc_len = 0.41; pc_w = 0.165; pc_ang = 25;

module purple_footprint_2d() { stadium_2d(pc_len, pc_w); }

module purple_component() {
    translate([pc_cx, pc_cy, plate_h - pattern_h]) rotate([0, 0, pc_ang])
    color(purple_color) linear_extrude(pattern_h) purple_footprint_2d();
}

// ── Ball bearing ─────────────────────────────────────────────────────────────

bb_cx = 1.11; bb_cy = 0.58; bb_r = 0.10;

module bearing_footprint_2d() { circle(r = bb_r, $fn = 32); }

module ball_bearing() {
    translate([bb_cx, bb_cy, plate_h - pattern_h])
    color(bearing_color) linear_extrude(pattern_h) bearing_footprint_2d();
}

// ── Chrome ball-and-socket joint arm ────────────────────────────────────────

ja_cx = 1.00; ja_cy = 2.01; ja_len = 0.45; ja_w = 0.08;
ja_ball_r = 0.11; ja_sock_r = 0.11; ja_ang = 110;

module joint_rod_ball_2d() {
    union() {
        stadium_2d(ja_len, ja_w);
        translate([-ja_len / 2 + ja_w / 2, 0]) circle(r = ja_ball_r, $fn = 32);
    }
}

module joint_socket_raw_2d() {
    translate([ja_len / 2 - ja_w / 2, 0]) circle(r = ja_sock_r, $fn = 32);
}

module joint_socket_2d() {
    difference() {
        joint_socket_raw_2d();
        joint_rod_ball_2d();
    }
}

module joint_footprint_2d() {
    union() {
        joint_rod_ball_2d();
        joint_socket_raw_2d();
    }
}

module joint_arm() {
    translate([ja_cx, ja_cy, plate_h - pattern_h]) rotate([0, 0, ja_ang]) {
        color(chrome_color) linear_extrude(pattern_h) joint_rod_ball_2d();
        color(socket_color) linear_extrude(pattern_h) joint_socket_2d();
    }
}

// ── Pick hammer ──────────────────────────────────────────────────────────────

hm_cx = 1.75; hm_cy = 1.93; hm_len = 0.75; hm_w = 0.11; hm_ang = 55;
hd_len = 0.41; hd_h = 0.12;

module hammer_handle_2d() { stadium_2d(hm_len, hm_w); }

module hammer_head_raw_2d() {
    polygon([
        [-hd_len / 2,          0],
        [-hd_len / 2 * 0.25,   hd_h / 2],
        [ hd_len / 2 * 0.55,   hd_h / 2],
        [ hd_len / 2,          hd_h / 4],
        [ hd_len / 2,         -hd_h / 4],
        [ hd_len / 2 * 0.55,  -hd_h / 2],
        [-hd_len / 2 * 0.25,  -hd_h / 2],
    ]);
}

module hammer_head_placed_2d() {
    translate([hm_len / 2 - hm_w / 2, 0]) rotate([0, 0, 90]) hammer_head_raw_2d();
}

module hammer_head_2d() {
    difference() {
        hammer_head_placed_2d();
        hammer_handle_2d();
    }
}

module hammer_footprint_2d() {
    union() {
        hammer_handle_2d();
        hammer_head_placed_2d();
    }
}

module hammer() {
    translate([hm_cx, hm_cy, plate_h - pattern_h]) rotate([0, 0, hm_ang]) {
        color(handle_color) linear_extrude(pattern_h) hammer_handle_2d();
        color(head_color)   linear_extrude(pattern_h) hammer_head_2d();
    }
}

// ── Tank-tread gear track ───────────────────────────────────────────────────

gt_cx = 1.37; gt_cy = 1.37; gt_span = 0.90; gt_ang = -5;
gt_teeth = 10; gt_r_tip = 0.21; gt_r_root = 0.165; gt_r_bore = 0.07;

module gt_sprocket_raw_2d(sx) { translate([sx, 0]) gear_2d(gt_teeth, gt_r_tip, gt_r_root); }

module gt_sprockets_2d() {
    union() {
        gt_sprocket_raw_2d(-gt_span / 2);
        gt_sprocket_raw_2d( gt_span / 2);
    }
}

module gt_band_raw_2d() { stadium_2d(gt_span + 2 * gt_r_tip, 2 * gt_r_tip); }

module gt_band_2d() {
    difference() {
        gt_band_raw_2d();
        gt_sprockets_2d();
    }
}

module gt_sprocket_body_2d(sx) {
    difference() {
        gt_sprocket_raw_2d(sx);
        translate([sx, 0]) circle(r = gt_r_bore, $fn = 24);
    }
}

module gt_hub_2d(sx) { translate([sx, 0]) circle(r = gt_r_bore, $fn = 24); }

module gear_track_footprint_2d() { gt_band_raw_2d(); }

module gear_track() {
    translate([gt_cx, gt_cy, plate_h - pattern_h]) rotate([0, 0, gt_ang]) {
        color(track_color) linear_extrude(pattern_h) gt_band_2d();
        color(sprocket_color) linear_extrude(pattern_h) {
            gt_sprocket_body_2d(-gt_span / 2);
            gt_sprocket_body_2d( gt_span / 2);
        }
        color(sprocket_hub_color) linear_extrude(pattern_h) {
            gt_hub_2d(-gt_span / 2);
            gt_hub_2d( gt_span / 2);
        }
    }
}

// ── Yellow/black hazard roller ───────────────────────────────────────────────

rl_cx = 1.90; rl_cy = 0.79; rl_len = 0.64; rl_w = 0.26; rl_ang = -32;
rl_stripe_w = 0.045; rl_stripe_n = 5; rl_cap_r = 0.07;

module roller_body_2d() { stadium_2d(rl_len, rl_w); }

module roller_caps_2d() {
    for (sx = [-(rl_len / 2 - rl_w / 2), (rl_len / 2 - rl_w / 2)])
        translate([sx, 0]) circle(r = rl_cap_r, $fn = 32);
}

module roller_stripes_2d() {
    span = rl_len - rl_w;
    for (i = [0 : rl_stripe_n - 1]) {
        sx = -span / 2 + span * i / (rl_stripe_n - 1);
        translate([sx, 0]) rotate([0, 0, 45]) square([rl_stripe_w, rl_w * 1.6], center = true);
    }
}

module roller_black_2d() {
    intersection() {
        union() {
            roller_caps_2d();
            roller_stripes_2d();
        }
        roller_body_2d();
    }
}

module roller_yellow_2d() {
    difference() {
        roller_body_2d();
        roller_black_2d();
    }
}

module roller() {
    translate([rl_cx, rl_cy, plate_h - pattern_h]) rotate([0, 0, rl_ang]) {
        color(roller_yellow) linear_extrude(pattern_h) roller_yellow_2d();
        color(roller_black)  linear_extrude(pattern_h) roller_black_2d();
    }
}

// ── Tool tray box ────────────────────────────────────────────────────────────
// The whole box (frame + floor) is one recess cut from the plate; the floor
// then has every tool's footprint subtracted so its dark gray never overlaps
// a tool's own color, matching the layered technique used for each tool above.

module all_tool_footprints_2d() {
    union() {
        translate([pc_cx, pc_cy]) rotate([0, 0, pc_ang]) purple_footprint_2d();
        translate([bb_cx, bb_cy]) bearing_footprint_2d();
        translate([ja_cx, ja_cy]) rotate([0, 0, ja_ang]) joint_footprint_2d();
        translate([hm_cx, hm_cy]) rotate([0, 0, hm_ang]) hammer_footprint_2d();
        translate([gt_cx, gt_cy]) rotate([0, 0, gt_ang]) gear_track_footprint_2d();
        translate([rl_cx, rl_cy]) rotate([0, 0, rl_ang]) roller_body_2d();
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
purple_component();
ball_bearing();
joint_arm();
hammer();
gear_track();
roller();
