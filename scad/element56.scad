// element56.scad — arrow water tile
// Units: inches

straight     = true;
left_turn    = false;
right_turn   = false;
double_speed = false;
show_transparent = true;  // if false, the transparent layer is omitted entirely — useful for
                          // debugging the underlying layers

include <sub_water_base_plate.scad>
include <sub_water_arrows.scad>

plate_colors = [undef, undef, "white", "white", undef, undef];

arrow_color  = "white";
background_color = "blue";
transparent_color = "lightblue";

difference() {
    plate_trans_layer(plate_colors);
    arrow_cutout();
}
arrow();
