// element21.scad — right-turn double-speed belt tile (two blue arrows)
// Units: inches

straight     = false;
left_turn    = false;
right_turn   = true;
double_speed = true;

include <sub_base_plate.scad>
include <sub_belts.scad>

plate_colors = [undef, undef, undef, undef, "blue", "blue"];

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
