// wall-base.scad
// Support base that holds a stack of 9 Element200 wall tiles, each flipped
// upside down (wall hanging down). Every tile sits directly on the one below
// it, shifted +Y by one wall thickness so its wall hangs just outside the
// previous tile's edge. A staircase under the walls supports each wall.
// Units: inches

include <sub_base_plate.scad>

// Tile geometry (must match element200-u.scad)
wall_h     = plate_h + 1/2;   // total wall height measured from plate bottom
wall_thick = 1/8;
wall_y     = plate_d - frame_w;
tile_w     = plate_w + 2 * frame_w;   // 3.0"
tile_y0    = -frame_w;                // front edge of a tile

// Base parameters
num_tiles  = 9;
clr        = 0.015;       // clearance between tile and base surfaces
floor_t    = 1/8;         // floor thickness
ledge_w    = 3/8;         // inward shelf under tile 1's plate
step_y     = wall_thick;  // Y shift between consecutive tiles
show_tiles = false;       // preview ghost tiles

wall_drop  = wall_h - plate_h;                 // how far a wall hangs below its plate
z0         = floor_t + wall_drop;              // plate bottom of tile 1
function tile_z(k) = z0 + k * plate_h;         // plate bottom of tile k
function tile_yoff(k) = k * step_y;

cav_w      = tile_w + 2 * clr;                 // base width: tile width plus clearance
base_w     = cav_w;
y_front    = tile_y0 - clr;
y_end      = tile_yoff(num_tiles - 1) + wall_y + wall_thick;
base_x0    = -frame_w - clr;

module floor_plate() {
    translate([base_x0, y_front, 0])
        cube([base_w, y_end - y_front, floor_t]);
}

// One step per wall: step k rises to the underside of wall k and extends to the rear
module wall_steps() {
    for (k = [0:num_tiles-1]) {
        y = tile_yoff(k) + wall_y;
        translate([-frame_w - clr, y, 0])
            cube([cav_w, y_end - y, tile_z(k) - wall_drop - clr]);
    }
}

// Shelves carrying the plate edges of tile 1 in front of its wall
module ledges() {
    for (x = [-frame_w - clr, -frame_w - clr + cav_w - ledge_w])
        translate([x, y_front, 0])
            cube([ledge_w, wall_y + tile_yoff(0) - y_front, z0 - clr]);
}

module wall_base() {
    color("dimgray") union() {
        floor_plate();
        wall_steps();
        ledges();
    }
}

// Placeholder tile (flipped about Y so the wall stays on the +Y edge)
module ghost_tile(k) {
    translate([plate_w + frame_w, tile_yoff(k), tile_z(k) + plate_h])
        rotate([0, 180, 0]) {
            color("gray", 0.5) translate([-frame_w, -frame_w, 0]) cube([tile_w, tile_w, plate_h]);
            color("firebrick", 0.7) translate([-frame_w, wall_y, 0]) cube([tile_w, wall_thick, wall_h]);
        }
}

wall_base();
if (show_tiles) for (k = [0:num_tiles-1]) ghost_tile(k);
