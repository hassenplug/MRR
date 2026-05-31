// element31.scad
// Element 31: Large gear (centered) with rotation arrows and mid ring, meshed with small gear
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;

hole_d  = 3/32;
hole_r  = hole_d / 2;
frame_w = 1/16;

// ── Large gear ────────────────────────────────────────────────────────────────
lg_cx      = plate_w / 2;
lg_cy      = plate_d / 2;
lg_n       = 32;
lg_m       = 0.06;
tooth_h    = lg_m * 0.6;            // tooth height (shorter than full-depth)
lg_r_pit   = lg_n * lg_m / 2;       // 0.96
lg_r_tip   = lg_r_pit + tooth_h;    // 1.032
lg_r_root  = lg_r_pit - tooth_h;    // 0.888
lg_mid_r   = 0.30;                   // hub ring center radius
lg_mid_w   = 0.022;                  // hub ring half-width
lg_r_bore  = lg_mid_r + lg_mid_w;   // gear face extends inward to meet hub ring outer edge
lg_outline = 0.025;
arr_outline = 0.020;

// ── Small gear ────────────────────────────────────────────────────────────────
sg_n       = 10;
sg_m       = lg_m;
sg_r_pit   = sg_n * sg_m / 2;       // 0.36
sg_r_tip   = sg_r_pit + tooth_h;    // 0.432
sg_r_root  = sg_r_pit - tooth_h;    // 0.288
sg_r_hub      = 0.12;
sg_hub_ring_w = 0.012;               // half-width of hub ring (mirrors lg_mid_w)
sg_hub_ring_r = sg_r_hub - sg_hub_ring_w;  // ring sits flush with bore inner edge
sg_outline = 0.020;
sg_angle   = 45;
sg_tw_scale = 0.6;                  // tooth width fraction vs gap (1.0 = equal, 0.5 = half as wide)
sg_round_r  = 0.012;               // tooth corner rounding radius
sg_gap     = 0.003;                  // clearance between tooth tips
sg_cd      = lg_r_tip + sg_r_tip + sg_gap;
sg_cx      = lg_cx + sg_cd * cos(sg_angle);
sg_cy      = lg_cy + sg_cd * sin(sg_angle);
sg_phase   = -9;                     // gap at 225° aligns with lg tooth at 45° (n=10: default gap at 234°, rotate −9°)

// ── Rotation arrows (on gear body, between bore and root) ─────────────────────
arr_r_in   = lg_r_bore + 0.063;     // 0.56
arr_r_out  = lg_r_root - 0.073;     // 0.79
arr_r_mid  = (arr_r_in + arr_r_out) / 2;
arr_head_h      = 0.20;
arr_head_w      = arr_r_out - arr_r_in;   // full band width at arrowhead
arr_head_w_scale = 0.90;                  // arrowhead width as fraction of band width
arr_shaft_w     = 0.176;                   // shaft radial width (narrower than head)
arr_shaft_r_in  = arr_r_mid - arr_shaft_w / 2;
arr_shaft_r_out = arr_r_mid + arr_shaft_w / 2;
arr_arrow_span  = 55;                      // degrees each arrow arc covers
arr_arrow_gap   = 360 / 4 - arr_arrow_span; // gap between arrows (20°)

// ─────────────────────────────────────────────────────────────────────────────

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) translate([inset_x + i*spacing_x, inset_y,           -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
    for (i = [0:9]) translate([inset_x + i*spacing_x, plate_d-inset_y,   -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
    for (i = [0:9]) translate([inset_x,           inset_y + i*spacing_y, -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
    for (i = [0:9]) translate([plate_w-inset_x, inset_y + i*spacing_y,   -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
}

module frame_with_id(colors = []) {
    id_cover = plate_h / 8;
    region_w = (plate_w + 2 * frame_w) / 6;
    mark_h   = plate_h - id_cover;

    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
        translate([-frame_w, plate_d, -0.001])
            cube([plate_w + 2 * frame_w, frame_w + 0.002, plate_h + 0.002]);
    }

    for (i = [0:5]) {
        c = (colors[i] != undef) ? colors[i] : "black";
        color(c)
        translate([-frame_w + i * region_w, plate_d, 0])
            cube([region_w, frame_w, mark_h]);
        color("black")
        translate([-frame_w + i * region_w, plate_d, mark_h])
            cube([region_w, frame_w, id_cover]);
    }
}

module plate() {
    color("darkgray")
    difference() {
        cube([plate_w, plate_d, plate_h]);
        rivet_holes();
        translate([lg_cx, lg_cy, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            offset(delta = lg_outline) gear_2d(lg_n, lg_r_tip, lg_r_root);
            gear_2d(lg_n, lg_r_tip, lg_r_root);
        }
        translate([lg_cx, lg_cy, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            circle(r = lg_mid_r + lg_mid_w, $fn=120);
            circle(r = lg_mid_r - lg_mid_w, $fn=120);
        }
        translate([sg_cx, sg_cy, -0.001])
        rotate([0, 0, sg_phase])
        linear_extrude(plate_h + 0.002)
        difference() {
            offset(delta = sg_outline) gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
            gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
        }
        translate([lg_cx, lg_cy, -0.001])
        linear_extrude(plate_h + 0.002)
        difference() {
            gear_2d(lg_n, lg_r_tip, lg_r_root);
            circle(r=lg_r_bore, $fn=80);
        }
        translate([sg_cx, sg_cy, -0.001])
        rotate([0, 0, sg_phase])
        linear_extrude(plate_h + 0.002)
        difference() {
            gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
            circle(r=sg_r_hub, $fn=40);
        }
        translate([sg_cx, sg_cy, -0.001])
        linear_extrude(plate_h + 0.002)
        circle(r=sg_r_hub, $fn=40);
    }
}

module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9]) translate([inset_x + i*spacing_x, inset_y,           0]) cylinder(h=plate_h, r=hole_r, $fn=20);
        for (i = [0:9]) translate([inset_x + i*spacing_x, plate_d-inset_y,   0]) cylinder(h=plate_h, r=hole_r, $fn=20);
        for (i = [0:9]) translate([inset_x,           inset_y + i*spacing_y, 0]) cylinder(h=plate_h, r=hole_r, $fn=20);
        for (i = [0:9]) translate([plate_w-inset_x, inset_y + i*spacing_y,   0]) cylinder(h=plate_h, r=hole_r, $fn=20);
    }
}

// ── Gear geometry ─────────────────────────────────────────────────────────────

module gear_tooth_2d(n, r_t, r_r, tw_factor = 1.0) {
    tw = (360/n) / 4 * tw_factor;
    polygon([
        [r_r * cos(-tw),        r_r * sin(-tw)],
        [r_t * cos(-tw * 0.7),  r_t * sin(-tw * 0.7)],
        [r_t * cos( tw * 0.7),  r_t * sin( tw * 0.7)],
        [r_r * cos( tw),        r_r * sin( tw)],
    ]);
}

module gear_2d(n, r_t, r_r, tw_factor = 1.0, round_r = 0) {
    offset(r=round_r, $fn=16)
    offset(delta=-round_r)
    union() {
        circle(r=r_r, $fn=n*8);
        for (i=[0:n-1]) rotate([0,0, i*(360/n)]) gear_tooth_2d(n, r_t, r_r, tw_factor);
    }
}

// 3D mask for cutting holes in sg layers at the lg meshing footprint
module lg_silhouette_cut() {
    translate([lg_cx, lg_cy, -0.001])
    linear_extrude(plate_h + 0.002)
    offset(delta = lg_outline) gear_2d(lg_n, lg_r_tip, lg_r_root);
}

// ── Small gear ────────────────────────────────────────────────────────────────

module small_gear() {
    color("green")
    difference() {
        translate([sg_cx, sg_cy, 0])
        rotate([0, 0, sg_phase])
        linear_extrude(plate_h)
        difference() {
            gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
            circle(r=sg_r_hub, $fn=40);
        }
        lg_silhouette_cut();
    }
}

module small_gear_outline() {
    color("black")
    difference() {
        translate([sg_cx, sg_cy, 0])
        rotate([0, 0, sg_phase])
        linear_extrude(plate_h)
        difference() {
            offset(delta = sg_outline) gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
            gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
        }
        lg_silhouette_cut();
    }
}

module small_gear_hub() {
    color("darkgray")
    translate([sg_cx, sg_cy, 0])
    linear_extrude(plate_h)
    difference() {
        circle(r=sg_r_hub, $fn=40);
        difference() {
            circle(r = sg_hub_ring_r + sg_hub_ring_w, $fn=80);
            circle(r = sg_hub_ring_r - sg_hub_ring_w, $fn=80);
        }
    }
}

module small_gear_mid_ring() {
    color("black")
    translate([sg_cx, sg_cy, 0])
    linear_extrude(plate_h)
    difference() {
        circle(r = sg_hub_ring_r + sg_hub_ring_w, $fn=80);
        circle(r = sg_hub_ring_r - sg_hub_ring_w, $fn=80);
    }
}

// ── Large gear ────────────────────────────────────────────────────────────────

module large_gear_outline() {
    color("black")
    translate([lg_cx, lg_cy, 0])
    linear_extrude(plate_h)
    difference() {
        offset(delta = lg_outline) gear_2d(lg_n, lg_r_tip, lg_r_root);
        gear_2d(lg_n, lg_r_tip, lg_r_root);
    }
}

module large_gear() {
    color("green")
    translate([lg_cx, lg_cy, 0])
    linear_extrude(plate_h)
    difference() {
        gear_2d(lg_n, lg_r_tip, lg_r_root);
        circle(r=lg_r_bore, $fn=80);
        offset(delta = arr_outline) rotation_arrows_2d();
    }
}

module large_gear_mid_ring() {
    color("black")
    translate([lg_cx, lg_cy, 0])
    linear_extrude(plate_h)
    difference() {
        circle(r = lg_mid_r + lg_mid_w, $fn=120);
        circle(r = lg_mid_r - lg_mid_w, $fn=120);
    }
}

// ── Rotation arrows ───────────────────────────────────────────────────────────

module fan_2d(r, a1, a2) {
    polygon(concat([[0,0]], [for (a=[a1:1:a2]) [r*cos(a), r*sin(a)]]));
}

module annular_sector_2d(r_o, r_i, a1, a2) {
    intersection() {
        difference() {
            circle(r=r_o, $fn=120);
            circle(r=r_i, $fn=120);
        }
        fan_2d(r_o + 0.5, a1, a2);
    }
}

module rotation_arrows_2d() {
    union() {
        for (i = [0:3]) {
            a_head = 20 + i * 90;
            a_tail = a_head + arr_arrow_span;
            annular_sector_2d(arr_shaft_r_out, arr_shaft_r_in, a_head, a_tail);
            translate([arr_r_mid * cos(a_head), arr_r_mid * sin(a_head)])
            rotate([0, 0, a_head - 180])
            polygon([[0, arr_head_h], [-arr_head_w*arr_head_w_scale/2, 0], [arr_head_w*arr_head_w_scale/2, 0]]);
        }
    }
}

module rotation_arrows_outline() {
    color("black")
    translate([lg_cx, lg_cy, 0])
    linear_extrude(plate_h)
    difference() {
        offset(delta = arr_outline) rotation_arrows_2d();
        rotation_arrows_2d();
    }
}

module rotation_arrows() {
    color("lightgray")
    translate([lg_cx, lg_cy, 0])
    linear_extrude(plate_h)
    rotation_arrows_2d();
}

// ─────────────────────────────────────────────────────────────────────────────

frame_with_id(["green", undef, undef, undef, undef, "green"]);
plate();
rivets();
small_gear();
small_gear_outline();
large_gear_outline();
large_gear();
large_gear_mid_ring();
rotation_arrows();
rotation_arrows_outline();
small_gear_hub();
small_gear_mid_ring();
