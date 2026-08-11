// flag.scad — shared pennant flag, pole, and label geometry
// Requires caller to define: plate_w, plate_d, plate_h, hole_r (see modules.scad)
// and gear_r_tip (see innergears.scad — flag_tip_x is sized off the gear ring)
// Units: inches
//
// Usage — must be `include`, positioned after modules.scad and innergears.scad:
//   include <modules.scad>
//   include <innergears.scad>
//   include <flag.scad>
//   flag_label("1");
//   label_holes("1");
//
// flag_label_2d(label)/flag_label(label)/label_holes(label) take the text to
// paint on the pennant so each tile variant can pass its own number.

// Pole — same inset_x gap from right rivet column as rivets are from edge
pole_r   = 0.04;
pole_cx  = plate_w - plate_w / 10;
pole_y1  = (plate_d / 20) + hole_r + 0.01;
pole_y2  = plate_d - (plate_d / 20) - hole_r - 0.01;

// Pennant — 2/3 pole height, top at pole top, tip extends well across gear
flag_base_x  = pole_cx;
flag_top_y   = pole_y2;
flag_bot_y   = pole_y2 - (pole_y2 - pole_y1) * 2 / 3;
flag_tip_x   = plate_w / 2 - gear_r_tip * 0.60;
flag_mid_y   = (flag_top_y + flag_bot_y) / 2;
outline_t    = 0.025;

// ── Flag 2D helpers ───────────────────────────────────────────────────────────

module flag_pennant_2d() {
    polygon([
        [flag_base_x, flag_top_y],
        [flag_base_x, flag_bot_y],
        [flag_tip_x,  flag_mid_y]
    ]);
}

module flag_label_2d(label) {
    translate([flag_base_x + (flag_tip_x - flag_base_x) * 0.38, flag_mid_y])
    text(label, size = 0.65, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

// ── Flag outline hole & flag outline ─────────────────────────────────────────

module flag_outline_holes() {
    translate([0, 0, -1])
    linear_extrude(plate_h + 2)
    difference() {
        offset(delta = outline_t) flag_pennant_2d();
        flag_pennant_2d();
    }
}

module flag_outline() {
    color("darkgray")
    linear_extrude(plate_h)
    difference() {
        offset(delta = outline_t) flag_pennant_2d();
        flag_pennant_2d();
    }
}

// ── Flag pole hole, flag hole → flag pole, flag ───────────────────────────────

module flag_pole_holes() {
    translate([pole_cx - pole_r, pole_y1, -1])
    cube([pole_r * 2, pole_y2 - pole_y1, plate_h + 2]);
}

module flag_pole() {
    color("red")
    translate([pole_cx - pole_r, pole_y1, 0])
    cube([pole_r * 2, pole_y2 - pole_y1, plate_h]);
}

module flag_holes() {
    translate([0, 0, -1])
    linear_extrude(plate_h + 2)
    flag_pennant_2d();
}

module flag() {
    color("red")
    linear_extrude(plate_h)
    flag_pennant_2d();
}

// ── Label hole → label ────────────────────────────────────────────────────────

module label_holes(label) {
    translate([0, 0, -1])
    linear_extrude(plate_h + 2)
    flag_label_2d(label);
}

module flag_label(label) {
    color("white")
    linear_extrude(plate_h)
    flag_label_2d(label);
}
