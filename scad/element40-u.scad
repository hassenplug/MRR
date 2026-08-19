// element40.scad — Pit
// Yellow/black hazard border (diagonal-striped band just inside the frame),
// then an actual open pit cut into the tile: the pit's yellow wall starts
// right at the top surface and runs down to the bottom of the pit; the
// bottom pattern_h of the pit is capped with a black floor.
// Units: inches
//
// The hazard stripes (and their black ring background) sit in the top
// pattern_h-thick slice of the plate — z from (plate_h - pattern_h) to
// plate_h — like gear()/gear_bore() in sub_innergears.scad. The pit itself
// is real geometry: open from the top down pit_depth, floored with a black,
// pattern_h-thick cap that does not extend past the bottom of the tile.

include <sub_base_plate.scad>

plate_colors = ["yellow", undef, undef, undef, undef, "yellow"];

// Hazard stripe band — diagonal yellow stripes on black, just inside the frame
stripe_band_w = 0.30;
stripe_w      = 0.18;
stripe_pitch  = 0.36;

// Pit wall — outer edge sits at the inner edge of the hazard stripe band
wall_inset = stripe_band_w;
wall_w     = 0.05;

pit_depth = 2/32; // depth of the open pit void, measured down from the top surface

// ── Hazard stripes (diagonal yellow, mitered ring) → black ring background ──

module hazard_ring_2d() {
    difference() {
        square([plate_w, plate_d], center = true);
        square([plate_w - 2 * stripe_band_w, plate_d - 2 * stripe_band_w], center = true);
    }
}

module hazard_stripes_2d() {
    diag = sqrt(plate_w * plate_w + plate_d * plate_d) + stripe_pitch * 2;
    n    = ceil(diag / stripe_pitch / 2) + 1;
    intersection() {
        hazard_ring_2d();
        rotate([0, 0, 45])
        for (i = [-n : n])
            translate([i * stripe_pitch - stripe_w / 2, -diag / 2])
            square([stripe_w, diag]);
    }
}

module hazard_bg_holes() {
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 0.002)
    hazard_ring_2d();
}

module hazard_bg_black() {
    color("black")
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h])
    linear_extrude(pattern_h)
    hazard_ring_2d();
}

module hazard_holes() {
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h - 0.001])
    linear_extrude(pattern_h + 0.002)
    hazard_stripes_2d();
}

module hazard_yellow() {
    color("yellow")
    translate([plate_w / 2, plate_d / 2, plate_h - pattern_h])
    linear_extrude(pattern_h)
    hazard_stripes_2d();
}

// ── Pit: open shaft (yellow wall, top to bottom) → black floor ──────────────

module pit_outer_2d() {
    square([plate_w - 2 * wall_inset, plate_d - 2 * wall_inset], center = true);
}

module pit_inner_2d() {
    square([plate_w - 2 * (wall_inset + wall_w), plate_d - 2 * (wall_inset + wall_w)], center = true);
}

module pit_wall_ring_2d() {
    difference() {
        pit_outer_2d();
        pit_inner_2d();
    }
}

module pit_holes() {
    translate([plate_w / 2, plate_d / 2, plate_h - pit_depth - pattern_h - 0.001])
    linear_extrude(pit_depth + pattern_h + 0.002)
    pit_outer_2d();
}

module pit_wall_yellow() {
    color("yellow")
    translate([plate_w / 2, plate_d / 2, plate_h - pit_depth - pattern_h])
    linear_extrude(pit_depth + pattern_h)
    pit_wall_ring_2d();
}

module pit_floor_black() {
    color("black")
    translate([plate_w / 2, plate_d / 2, plate_h - pit_depth - pattern_h])
    linear_extrude(pattern_h)
    pit_inner_2d();
}

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

union() {                                           // step 4: add black floor
    union() {                                       // step 3: add yellow pit wall
        difference() {
            union() {                               // step 2: add hazard stripes
                difference() {
                    union() {                       // step 1: add black background
                        difference() {
                            plate(plate_colors);   // step 0: plate (frame + rivets)
                            hazard_bg_holes();
                        }
                        hazard_bg_black();
                    }
                    hazard_holes();
                }
                hazard_yellow();
            }
            pit_holes();
        }
        pit_wall_yellow();
    }
    pit_floor_black();
}
