// element20.scad — straight double-speed belt tile (two blue arrows)
// Units: inches

straight     = true;
left_turn    = false;
right_turn   = false;
double_speed = true;

include <sub_base_plate.scad>
include <sub_belts.scad>

plate_colors = [undef, undef, "blue", "blue", undef, undef];

roller_color = "blue";
arrow_color  = "lightblue";

difference() {
    plate(plate_colors);
    roller_slots();
    belt_cutout();
}
rollers();
belt();
arrow();
