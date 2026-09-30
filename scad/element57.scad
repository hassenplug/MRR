// element55.scad — still water tile
// Units: inches

straight     = false;
left_turn    = false;
right_turn   = true;
double_speed = false;
show_transparent = true;  // if false, the transparent layer is omitted entirely — useful for
                          // debugging the underlying layers

include <sub_water_base_plate.scad>
include <sub_water_arrows.scad>

plate_colors = [undef, undef, "lightblue", "lightblue", undef, undef];

arrow_color  = "black";
background_color = "blue";
transparent_color = "lightblue";

difference() {
    plate_trans_layer(plate_colors);
    arrow_cutout();
}
arrow();
