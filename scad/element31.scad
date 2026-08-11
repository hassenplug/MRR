// element31.scad
// Element 31: Large gear (centered) with rotation arrows and mid ring, meshed with small gear
// Units: inches

include <modules.scad>

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

module tile_base() {
    difference() {
        plate([undef, "green", undef, undef, "green", undef]);
        small_gear_outline(-1);
        large_gear_outline(-1);
    }
    color("black") small_gear_outline(0);
    color("black") large_gear_outline(0);
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
    circle(r=r_r, $fn=n*8);
    union() {
        circle(r=r_r, $fn=n*8);
        for (i=[0:n-1]) rotate([0,0, i*(360/n)]) gear_tooth_2d(n, r_t, r_r, tw_factor);
    }
}


// ── Small gear ────────────────────────────────────────────────────────────────

module small_gear_outline(z = 0) {
    color("black")
    translate([sg_cx, sg_cy, z])
    rotate([0, 0, sg_phase])
    linear_extrude(plate_h - 2 * z)
    offset(delta = sg_outline) gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
}

module small_gear(z = 0) {
    color("green")
    translate([sg_cx, sg_cy, z])
    rotate([0, 0, sg_phase])
    linear_extrude(plate_h - 2 * z)
    gear_2d(sg_n, sg_r_tip, sg_r_root, sg_tw_scale, sg_round_r);
}

module small_gear_mid_ring(z = 0) {
    color("black")
    translate([sg_cx, sg_cy, z])
    linear_extrude(plate_h - 2 * z)
    circle(r = sg_hub_ring_r + sg_hub_ring_w, $fn=80);
}

module small_gear_hub(z = 0) {
    color("darkgray")
    translate([sg_cx, sg_cy, z])
    linear_extrude(plate_h - 2 * z)
    circle(r = sg_hub_ring_r - sg_hub_ring_w, $fn=80);
}

// ── Large gear ────────────────────────────────────────────────────────────────

module large_gear_outline(z = 0) {
    color("black")
    translate([lg_cx, lg_cy, z])
    linear_extrude(plate_h - 2 * z)
    offset(delta = lg_outline) gear_2d(lg_n, lg_r_tip, lg_r_root);
}

module large_gear(z = 0) {
    color("green")
    translate([lg_cx, lg_cy, z])
    linear_extrude(plate_h - 2 * z)
    gear_2d(lg_n, lg_r_tip, lg_r_root);
}

module large_gear_mid_ring(z = 0) {
    color("black")
    translate([lg_cx, lg_cy, z])
    linear_extrude(plate_h - 2 * z)
    difference() {
        circle(r = lg_mid_r + lg_mid_w, $fn=120);
        //circle(r = lg_mid_r - lg_mid_w, $fn=120);
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

module rotation_arrows_outline(z = 0) {
    color("black")
    translate([lg_cx, lg_cy, z])
    linear_extrude(plate_h - 2 * z)
    offset(delta = arr_outline) rotation_arrows_2d();
}

module rotation_arrows(z = 0) {
    color("lightgray")
    translate([lg_cx, lg_cy, z])
    linear_extrude(plate_h - 2 * z)
    rotation_arrows_2d();
}

module large_gear_hub(z = 0) {
    color("darkgray")
    translate([lg_cx, lg_cy, z])
    linear_extrude(plate_h - 2 * z)
    circle(r = lg_mid_r - lg_mid_w, $fn=120);
}

// ── Layer chain ───────────────────────────────────────────────────────────────

module layer_sg()          { union() { difference() { tile_base();          small_gear(-1);                } small_gear();                } }
module layer_sg_mid_ring() { union() { difference() { layer_sg();           small_gear_mid_ring(-1);       } small_gear_mid_ring();       } }
module layer_sg_hub()      { union() { difference() { layer_sg_mid_ring();  small_gear_hub(-1);            } small_gear_hub();            } }
module layer_lg()          { union() { difference() { layer_sg_hub();       large_gear(-1);                } large_gear();                } }
module layer_lg_mid_ring() { union() { difference() { layer_lg();           large_gear_mid_ring(-1);       } large_gear_mid_ring();       } }
module layer_lg_hub()      { union() { difference() { layer_lg_mid_ring();  large_gear_hub(-1);            } large_gear_hub();            } }
module layer_arr_outline() { union() { difference() { layer_lg_hub();       rotation_arrows_outline(-1);   } rotation_arrows_outline();   } }
//module layer_arr()         { union() { difference() { layer_arr_outline();  rotation_arrows(-1);           }            } }
module layer_arr()         { union() { difference() { layer_arr_outline();  rotation_arrows(-1);           } rotation_arrows();           } }

// ─────────────────────────────────────────────────────────────────────────────
//tile_base();
//layer_sg();
//layer_sg_mid_ring();
//layer_sg_hub();
//layer_lg();
//layer_lg_mid_ring();
//layer_lg_hub();
//layer_arr_outline();
layer_arr();
