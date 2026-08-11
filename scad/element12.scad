// element12.scad — left-turn belt tile (mirror of element11)
// Units: inches

straight     = false;
left_turn    = true;
right_turn   = false;
double_speed = false;

include <sub_base_plate.scad>
include <sub_belts.scad>

plate_colors = [undef, undef, "green", "green", "green", "green"];

roller_color = "green";
arrow_color  = "green";

translate([plate_w, 0, 0])
mirror([1, 0, 0]) {
    difference() {
        plate(plate_colors);
        roller_slots();
        belt_cutout();
    }
    rollers();
    belt();
    arrow();
}
