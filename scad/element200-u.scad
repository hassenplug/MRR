// element200.scad
// Steel tile with a yellow brick-pattern wall along the back edge.
// Wall sits over the black frame border (+Y), spans full 3" width, rises 1/2"
// above the tile surface, and wraps brick texture on all four exposed faces.
// Units: inches
plate_colors = ["red", "red", undef, undef, "red", "red"];

include <sub_base_plate.scad>

plate_h = 1/8;   // override: this tile is thicker than the standard sub_base_plate.scad 1/16

// Wall geometry
wall_h       = plate_h + 1/2;          // total height: 1/2" above tile surface
wall_thick   = 1/8;                    // depth in Y direction
wall_y       = plate_d - frame_w;      // shifted -1/16" from black frame line
wall_total_w = plate_w + 2 * frame_w;  // 3.0" — covers plate + both frame strips
wall_x0      = -frame_w;              // left edge x

// Brick pattern parameters
brick_cols     = 7;
brick_num_rows = 4;
brick_gap      = 0.02;
brick_z0       = plate_h;               // bricks start here (bottom of first row)
brick_l        = (wall_total_w - (brick_cols - 1) * brick_gap) / brick_cols;
brick_h_f      = (wall_h - brick_z0 - (brick_num_rows - 1) * brick_gap) / brick_num_rows;
brick_col_pitch = brick_l + brick_gap;
brick_row_pitch = brick_h_f + brick_gap;

// ── Brick wall ───────────────────────────────────────────────────────────────

// Single dark gray mortar cube — same depth as wall, inset by brick_gap/2 on
// each side in X and Z so it doesn't protrude past the outermost brick faces
module wall_mortar() {
    color("darkgray")
    translate([wall_x0 + brick_gap / 2,
               wall_y + brick_gap / 2,
               brick_z0 + brick_gap / 2])
        cube([wall_total_w - brick_gap,
              wall_thick - brick_gap,
              wall_h - brick_z0 - brick_gap]);
}

// Red bricks — 7 columns × 4 rows, staggered, each brick full wall_thick deep.
// Rows fill the wall height exactly; columns fill the 3" width exactly.
// Clipped to wall footprint to trim stagger overhangs at the ends.
module wall_bricks() {
    color([0.72, 0.10, 0.07])
    intersection() {
        translate([wall_x0, wall_y, brick_z0])
            cube([wall_total_w, wall_thick, wall_h - brick_z0]);
        union() {
            for (row = [0:brick_num_rows-1]) {
                col_off = (row % 2 == 0) ? -brick_col_pitch / 2 : 0;
                z0 = brick_z0 + row * brick_row_pitch;
                for (col = [0:brick_cols]) {
                    translate([wall_x0 + col * brick_col_pitch + col_off,
                               wall_y,
                               z0])
                        cube([brick_l, wall_thick, brick_h_f]);
                }
            }
        }
    }
}

// ── Assembly ─────────────────────────────────────────────────────────────────

plate(plate_colors);
wall_mortar();
wall_bricks();
