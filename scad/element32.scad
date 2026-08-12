// element32.scad
// Element 32: Mirror of element31 — small gear upper-left, counter-clockwise red arrows
// Units: inches

plate_colors = ["red", undef, undef, undef, undef,  "red"];
gear_color   = "red";
sg_angle     = 135;  // upper-left (mirror of element31's 45°)
sg_phase     = 9;    // gap at 315° aligns with lg tooth at 135° (n=10: default gap at 306°, rotate +9°)
clockwise    = false;

include <sub_gears.scad>
