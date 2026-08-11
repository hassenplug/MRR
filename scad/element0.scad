// element10.scad
// Units: inches

include <modules.scad>

// Roller slots
roller_count  = 11;
roller_h_size = 3/16;   // top-to-bottom thickness of each roller slot
roller_r      = roller_h_size / 2;

// Available space inside rivet frame (same inset as rivet spacing)
roller_inset_x = (plate_w / 10) / 2;
roller_inset_y = (plate_d / 10) / 2;
roller_zone_w  = plate_w - 2 * roller_inset_x;
roller_zone_d  = plate_d - 2 * roller_inset_y;

// Gap between rollers: split remaining vertical space evenly across 12 gaps
roller_gap = (roller_zone_d - roller_count * roller_h_size) / (roller_count + 1);

plate(["lightgray", undef, undef, undef, undef, "lightgray"]);

