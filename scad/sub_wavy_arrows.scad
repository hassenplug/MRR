// sub_wavy_arrows.scad — shared wavy-arrow geometry for the "water" tile
// family (element56 straight, element57 right-turn, element58 left-turn)
// Requires caller to define: plate_w, plate_d, plate_h, pattern_h (see
// sub_base_plate.scad) and frame_with_id() (also sub_base_plate.scad)
// Units: inches
//
// Unlike sub_belts.scad, these tiles have no physical belt/roller pattern —
// the entire top face is one flat tilecolor, painted straight over where
// rivets would otherwise show (see plate_flat()). Only a wavy directional
// arrow sits on top, layered into the pattern_h-thick top slice exactly like
// rollers/belt/arrow in sub_belts.scad.
//
// Dispatch flags the caller must define before including this file:
//   straight, right_turn, left_turn — independent, any combination may be
//   true (no double_speed for this family). Where active directions'
//   silhouettes overlap, the interior is one merged black blob — see
//   visible_ring_2d().
//
// tilecolor, arrow_color — color strings, set by the caller (may be defined
// after this include, since they're only referenced inside modules below).
//
// Arrowhead proportions are ported directly from sub_belts.scad (element10-
// 12) so every arrow family shares the same head shape; only the shaft
// differs here (wavy instead of straight/arc-only).

arrow_w       = 1.4875;      // = sub_belts.scad belt_w(1.75) * 0.85
arrow_shaft_w = 0.669375;    // = arrow_w * 0.45
arrow_head_h  = 0.74375;     // = arrow_w / 2
arrow_outline = 1/8;
arrow_tip_y   = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;

// Straight/turn shaft heights, ported from sub_belts.scad's arrow_shaft_h
// ternary (evaluated here with double_speed always false).
shaft_h_straight = 1.4825;
shaft_h_turn     = 1.5;

arrow_h_straight = shaft_h_straight + arrow_head_h;
arrow_h_turn     = shaft_h_turn + arrow_head_h;
arrow_y_straight = arrow_tip_y - arrow_h_straight;
arrow_y_turn     = arrow_tip_y - arrow_h_turn;

// Turn-path arc geometry, ported from sub_belts.scad's curved_* modules.
cx           = plate_w / 2;
r_curve      = 0.48;
cx_r         = cx + r_curve;
h_straight   = 0.49;                          // horizontal run, arc exit toward the edge
y_merge_turn = arrow_y_turn + shaft_h_turn;

// Wave shape — zero displacement at both path ends so the wavy shaft always
// meets the (unwavy) arrowhead and the tile edge cleanly, whatever the
// amplitude/cycle count (any multiple of 0.5 cycles works).
// Peak curvature of a sine of this amplitude/frequency is amp * (2*pi*
// cycles/shaft_h)^2 — it must stay well below 1/arrow_outline, or offset()
// folds the ring back on itself at the wave crests (self-intersection).
wave_amp     = 0.22;
wave_cycles  = 1.0;
wave_samples = 40;

function wave_disp(t) = wave_amp * sin(360 * wave_cycles * t);

// ── Straight wavy shaft + head — single polygon, local coords (origin =
// shaft bottom-center; y runs up to shaft_h at the head base) ─────────────

function straight_edge_asc(shaft_h, half_w, sign, n) =
    [ for (i = [0:n])
        let (t = i / n, y = t * shaft_h, dx = wave_disp(t))
        [dx + sign * half_w, y]
    ];

function straight_edge_desc(shaft_h, half_w, sign, n) =
    [ for (i = [n:-1:0])
        let (t = i / n, y = t * shaft_h, dx = wave_disp(t))
        [dx + sign * half_w, y]
    ];

function straight_arrow_pts(shaft_h) =
    concat(
        straight_edge_asc(shaft_h, arrow_shaft_w / 2, 1, wave_samples),
        [ [arrow_w / 2, shaft_h], [0, shaft_h + arrow_head_h], [-arrow_w / 2, shaft_h] ],
        straight_edge_desc(shaft_h, arrow_shaft_w / 2, -1, wave_samples)
    );

module straight_arrow_full_2d() {
    polygon(straight_arrow_pts(shaft_h_straight));
}

// ── Turn wavy shaft (vertical + arc + horizontal) + head — single polygon,
// absolute plate coordinates. right_turn as drawn; left_turn = mirrored(). ─
//
// Path parameter t in [0,1]: t=0 at the horizontal run's far end (near the
// tile edge), t=1 at the vertical run's top (head base, y = y_merge_turn).
// Segments in travel order: horizontal (0..f1), arc (f1..f2), vertical
// (f2..1). The normal field is kept continuous across both joins (checked
// at the boundary angles) so waviness doesn't kink at the segment seams.

L1 = h_straight;
L2 = r_curve * 3.14159265 / 2;   // quarter-circle arc length
L3 = y_merge_turn - (plate_d / 2 + r_curve);
L_total = L1 + L2 + L3;
f1 = L1 / L_total;
f2 = (L1 + L2) / L_total;

function turn_center_normal(t) =
    t <= f1 ?
        let (s = t / f1)
        [ [cx_r + L1 * (1 - s), plate_d / 2], [0, 1] ]
    : t <= f2 ?
        let (s = (t - f1) / (f2 - f1), theta = 270 - 90 * s)
        [ [cx_r + r_curve * cos(theta), (plate_d / 2 + r_curve) + r_curve * sin(theta)],
          [-cos(theta), -sin(theta)] ]
    :
        let (s = (t - f2) / (1 - f2))
        [ [cx, (plate_d / 2 + r_curve) + L3 * s], [1, 0] ];

function turn_edge_pt(t, half_w, sign) =
    let (cn = turn_center_normal(t), c = cn[0], nrm = cn[1], d = wave_disp(t))
    [ c[0] + (d + sign * half_w) * nrm[0], c[1] + (d + sign * half_w) * nrm[1] ];

function turn_edge(half_w, sign, n) =
    [ for (i = [0:n]) turn_edge_pt(i / n, half_w, sign) ];

function turn_edge_desc(half_w, sign, n) =
    [ for (i = [n:-1:0]) turn_edge_pt(i / n, half_w, sign) ];

function turn_arrow_pts() =
    concat(
        turn_edge(arrow_shaft_w / 2, 1, wave_samples),
        [ [cx + arrow_w / 2, y_merge_turn],
          [cx, y_merge_turn + arrow_head_h],
          [cx - arrow_w / 2, y_merge_turn] ],
        turn_edge_desc(arrow_shaft_w / 2, -1, wave_samples)
    );

module turn_arrow_full_2d() {
    polygon(turn_arrow_pts());
}

// Mirrors turn_arrow_full_2d() across the tile's vertical centerline for
// left_turn — same trick as sub_belts.scad's mirrored().
module mirrored() {
    translate([plate_w, 0, 0])
    mirror([1, 0, 0])
    children();
}

// ── Per-direction full silhouette (shaft + head), absolute plate
// coordinates — used both for the black interior fill and, via offset(),
// the outline ring. ─────────────────────────────────────────────────────

module full_shape_2d(which) {
    if (which == "straight")
        translate([cx, arrow_y_straight])
            straight_arrow_full_2d();
    if (which == "right_turn")
        turn_arrow_full_2d();
    if (which == "left_turn")
        mirrored() turn_arrow_full_2d();
}

module active_union_2d(exclude = "") {
    union() {
        if (straight   && exclude != "straight")   full_shape_2d("straight");
        if (right_turn && exclude != "right_turn") full_shape_2d("right_turn");
        if (left_turn  && exclude != "left_turn")  full_shape_2d("left_turn");
    }
}

module ring_2d(which) {
    difference() {
        full_shape_2d(which);
        offset(delta = -arrow_outline) full_shape_2d(which);
    }
}

// Outline visible for `which`, minus whatever's covered by any OTHER active
// direction's full silhouette — so overlapping arrows merge into a single
// black blob with no stray outline line inside it.
module visible_ring_2d(which) {
    difference() {
        ring_2d(which);
        active_union_2d(exclude = which);
    }
}

module all_visible_rings_2d() {
    union() {
        if (straight)   visible_ring_2d("straight");
        if (right_turn) visible_ring_2d("right_turn");
        if (left_turn)  visible_ring_2d("left_turn");
    }
}

// ── Flat single-color plate: built on the standard plate() (frame + darkgray
// body + rivets, unchanged), but the top pattern_h-thick slice — the same
// slice the arrow lives in — is carved out and refilled with one flat
// tilecolor, covering the rivets from the top. The bottom (plate_h -
// pattern_h) keeps its normal darkgray/rivet structure. ───────────────────

module plate_flat(tilecolor, colors = []) {
    difference() {
        plate(colors);
        translate([0, 0, plate_h - pattern_h - 0.001])
            cube([plate_w, plate_d, pattern_h + 0.002]);
    }
    color(tilecolor)
    translate([0, 0, plate_h - pattern_h])
        cube([plate_w, plate_d, pattern_h]);
}

// ── Black interior + colored outline, layered into the top pattern_h slice
// (z from plate_h - pattern_h to plate_h), same convention as sub_belts.scad.

module wavy_arrow_black_holes() {
    translate([0, 0, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 0.002)
    active_union_2d();
}

module wavy_arrow_black_fill() {
    color("black")
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    active_union_2d();
}

module wavy_arrow_outline_holes() {
    translate([0, 0, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 0.002)
    all_visible_rings_2d();
}

module wavy_arrow_outline_fill() {
    color(arrow_color)
    translate([0, 0, plate_h - pattern_h])
    linear_extrude(pattern_h)
    all_visible_rings_2d();
}
