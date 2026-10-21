// element26.scad — straight + left + right-turn double-speed belt tile (double-speed counterpart of element16)
// Units: inches

straight     = true;
left_turn    = true;
right_turn   = true;
double_speed = true;

include <sub_base_plate.scad>
include <sub_belts.scad>

// Edge-ID colors match element16's array, in blue. sub_belts.scad mirrors the
// belt/roller/arrow geometry internally (left_turn), so the frame's color-coded
// edges must be set per tile rather than via a geometric mirror().
plate_colors = ["blue", "blue", "blue", "blue", "blue", "blue"];

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
