// element55.scad — straight water tile
// Units: inches

straight     = true;
left_turn    = false;
right_turn   = false;
double_speed = false;

include <sub_water_base_plate.scad>
include <sub_water_arrows.scad>

plate_colors = [undef, undef, "green", "green", undef, undef];

arrow_color  = "black";

difference() {
    plate_trans_blue(plate_colors);
    arrow_cutout();
}
arrow();
