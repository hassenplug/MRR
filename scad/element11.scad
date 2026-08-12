// element11.scad — right-turn belt tile
// Units: inches

straight     = false;
left_turn    = false;
right_turn   = true;
double_speed = false;

include <sub_base_plate.scad>
include <sub_belts.scad>

plate_colors = [undef, undef, undef, undef, "green", "green"];

roller_color = "darkgreen";
arrow_color  = "green";

difference() {
    plate(plate_colors);
    roller_slots();
    belt_cutout();
}
rollers();
belt();
arrow();
