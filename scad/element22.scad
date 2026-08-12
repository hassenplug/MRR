// element22.scad — left-turn double-speed belt tile (mirror of element21)
// Units: inches

straight     = false;
left_turn    = true;
right_turn   = false;
double_speed = true;

include <sub_base_plate.scad>
include <sub_belts.scad>

// Edge-ID colors are the reverse of element21's array: sub_belts.scad now
// mirrors the belt/roller/arrow geometry internally (left_turn), so the
// frame's color-coded edges must be manually reversed to match — the whole
// tile is no longer wrapped in a geometric mirror() to do this for free.
plate_colors = ["blue", "blue", undef, undef, undef, undef];

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
