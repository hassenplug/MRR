// element31.scad
// Element 31: Large gear (centered) with rotation arrows and mid ring, meshed with small gear
// Units: inches

plate_colors = ["green", undef, undef, undef, undef, "green"];
gear_color   = "green";
sg_angle     = 45;
sg_phase     = -9;   // gap at 225° aligns with lg tooth at 45° (n=10: default gap at 234°, rotate −9°)
clockwise    = true;

include <sub_gears.scad>
