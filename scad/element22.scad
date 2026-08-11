// element22.scad — left-turn double-speed belt tile (mirror of element21)
// Units: inches

straight     = false;
left_turn    = true;
right_turn   = false;
double_speed = true;

include <sub_base_plate.scad>
include <sub_belts.scad>

plate_colors = [undef, undef, "lightblue", "lightblue", "lightblue", "lightblue"];

roller_color = "blue";
arrow_color  = "lightblue";

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
