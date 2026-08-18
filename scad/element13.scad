// element12.scad — left-turn belt tile (mirror of element11)
// Units: inches

straight     = true;
left_turn    = true;
right_turn   = false;
double_speed = false;

include <sub_base_plate.scad>
include <sub_belts.scad>

// Edge-ID colors are the reverse of element11's array: sub_belts.scad now
// mirrors the belt/roller/arrow geometry internally (left_turn), so the
// frame's color-coded edges must be manually reversed to match — the whole
// tile is no longer wrapped in a geometric mirror() to do this for free.
plate_colors = ["green", "green", "green", "green", undef, undef];

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
