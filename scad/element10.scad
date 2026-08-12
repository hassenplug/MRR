// element10.scad — straight belt tile
// Units: inches

straight     = true;
left_turn    = false;
right_turn   = false;
double_speed = false;

include <sub_base_plate.scad>
include <sub_belts.scad>

plate_colors = [undef, undef, "green", "green", undef, undef];

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
