// element200.scad
// Steel tile with a yellow brick-pattern wall along the back edge.
// Wall sits over the black frame border (+Y), spans full 3" width, rises 1/2"
// above the tile surface, and wraps brick texture on all four exposed faces.
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/8;
frame_w = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

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
brick_z0       = 1/8;                   // bricks start here (bottom of first row)
brick_l        = (wall_total_w - (brick_cols - 1) * brick_gap) / brick_cols;
brick_h_f      = (wall_h - brick_z0 - (brick_num_rows - 1) * brick_gap) / brick_num_rows;
brick_col_pitch = brick_l + brick_gap;
brick_row_pitch = brick_h_f + brick_gap;

// ── Standard tile modules ────────────────────────────────────────────────────

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) translate([inset_x + i*spacing_x, inset_y,           -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
    for (i = [0:9]) translate([inset_x + i*spacing_x, plate_d-inset_y,   -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
    for (i = [0:9]) translate([inset_x,           inset_y + i*spacing_y, -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
    for (i = [0:9]) translate([plate_w-inset_x,   inset_y + i*spacing_y, -1]) cylinder(h=plate_h+2, r=hole_r, $fn=20);
}

module frame() {
    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0]) cube([plate_w+2*frame_w, plate_d+2*frame_w, plate_h]);
        translate([0, 0, -0.001])          cube([plate_w, plate_d, plate_h+0.002]);
    }
}

module plate() {
    difference() {
        color("darkgray") cube([plate_w, plate_d, plate_h]);
        rivet_holes();
    }
}

rivet_h = plate_h;
module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9]) translate([inset_x + i*spacing_x, inset_y,           0]) cylinder(h=rivet_h, r=hole_r, $fn=20);
        for (i = [0:9]) translate([inset_x + i*spacing_x, plate_d-inset_y,   0]) cylinder(h=rivet_h, r=hole_r, $fn=20);
        for (i = [0:9]) translate([inset_x,           inset_y + i*spacing_y, 0]) cylinder(h=rivet_h, r=hole_r, $fn=20);
        for (i = [0:9]) translate([plate_w-inset_x,   inset_y + i*spacing_y, 0]) cylinder(h=rivet_h, r=hole_r, $fn=20);
    }
}

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

frame();
plate();
rivets();
wall_mortar();
wall_bricks();
