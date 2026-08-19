// sub_innergears.scad — shared inner gear ring (ring with inward-pointing teeth)
// Requires caller to define: plate_w, plate_d, plate_h, pattern_h (see sub_base_plate.scad)
// Units: inches
//
// Usage — must be `include`, positioned after sub_base_plate.scad and before any
// code that references gear_r_tip/gear_r_root/gear_r_bore:
//   include <sub_base_plate.scad>
//   include <sub_innergears.scad>
//   gear("darkred");
//   gear_bore("lightgray");
//
// gear(c) and gear_bore(c) take a color string so tiles with different gear
// colors (e.g. darkred vs darkgreen) can share this same file.
//
// gear(c)/gear_bore(c) sit in the top pattern_h-thick slice of the plate — z
// from (plate_h - pattern_h) to plate_h — rather than spanning the plate's
// full thickness from z=0. gear_holes()/gear_bore_holes() (which carve the
// matching recess out of the plate) live in the same z-slice.

gear_r_tip  = 1.18;   // outer edge of ring (plain)
gear_r_root = 1.00;   // ring inner edge; teeth root here
gear_r_bore = 0.82;   // bore radius / tooth tip depth
gear_n      = 20;
tooth_hw    = 4.5;
tooth_tip_f = 0.80;

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
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 2)
    difference() {
        gear_2d();
        bore_2d();
    }
}

module gear(c) {
    color(c)
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h])
    linear_extrude(pattern_h)
    difference() { gear_2d(); bore_2d(); }
}

// ── Gear bore hole & gear bore ────────────────────────────────────────────────

module gear_bore_holes() {
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 2)
    bore_2d();
}

module gear_bore(c) {
    color(c)
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h])
    linear_extrude(pattern_h)
    offset(delta = -0.001) bore_2d();
}
