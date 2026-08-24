// element56.scad — Water Straight Arrow
// Units: inches

straight    = true;
right_turn  = false;
left_turn   = false;

include <sub_base_plate.scad>
include <sub_wavy_arrows.scad>

plate_colors = [undef, undef, "lightblue", "lightblue", undef, undef];

tilecolor   = "blue";
arrow_color = "lightblue";

union() {
    difference() {
        union() {
            difference() {
                plate_flat(tilecolor, plate_colors);   // step 0: frame + flat tilecolor plate
                wavy_arrow_black_holes();               // cut arrow silhouette
            }
            wavy_arrow_black_fill();                    // fill with black
        }
        wavy_arrow_outline_holes();                     // cut outline ring
    }
    wavy_arrow_outline_fill();                           // fill with arrow_color
}
