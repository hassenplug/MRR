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
brick_l   = 0.40;   // brick length (long axis)
brick_h_f = 0.10;   // brick face height (short axis on face)
brick_d   = 0.020;  // protrusion depth
brick_gap = 0.025;  // mortar gap between bricks

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

// Shared row layout
brick_col_pitch = brick_l   + brick_gap;
brick_row_pitch = brick_h_f + brick_gap;
brick_num_rows  = 4;
brick_row_span  = brick_num_rows * brick_h_f + (brick_num_rows - 1) * brick_gap;
brick_start_z   = (wall_h - brick_row_span) / 2;

mortar_d = brick_d;   // groove depth (same as old protrusion)

// Horizontal seam ring at height z0, band height = brick_gap —
// wraps all the way around front face, both ends, and back face.
module h_seam_ring(z0) {
    // front face — groove into -Y
    translate([wall_x0 - 0.001, wall_y - mortar_d, z0])
        cube([wall_total_w + 0.002, mortar_d + 0.001, brick_gap]);
    // back face — groove into +Y
    translate([wall_x0 - 0.001, wall_y + wall_thick - 0.001, z0])
        cube([wall_total_w + 0.002, mortar_d + 0.001, brick_gap]);
    // left end — groove into -X
    translate([wall_x0 - mortar_d, wall_y - 0.001, z0])
        cube([mortar_d + 0.001, wall_thick + 0.002, brick_gap]);
    // right end — groove into +X
    translate([wall_x0 + wall_total_w - 0.001, wall_y - 0.001, z0])
        cube([mortar_d + 0.001, wall_thick + 0.002, brick_gap]);
}

// All horizontal seams — one ring per inter-row boundary
module h_seams() {
    for (i = [0:brick_num_rows-1]) {
        h_seam_ring(brick_start_z + i * brick_row_pitch + brick_h_f);
    }
}

// Vertical seams cut into the front face (-Y)
module v_seams_front() {
    intersection() {
        translate([wall_x0 - 0.001, wall_y - mortar_d, -0.001])
            cube([wall_total_w + 0.002, mortar_d + 0.002, wall_h + 0.002]);
        for (row = [0:brick_num_rows-1]) {
            col_off = (row % 2 == 0) ? 0 : brick_col_pitch / 2;
            z0 = brick_start_z + row * brick_row_pitch;
            for (col = [0:8]) {
                translate([wall_x0 + col_off + col * brick_col_pitch + brick_l,
                           wall_y - mortar_d,
                           z0])
                    cube([brick_gap, mortar_d + 0.001, brick_h_f]);
            }
        }
    }
}

// Vertical seams cut into the back face (+Y)
module v_seams_back() {
    intersection() {
        translate([wall_x0 - 0.001, wall_y + wall_thick - 0.001, -0.001])
            cube([wall_total_w + 0.002, mortar_d + 0.002, wall_h + 0.002]);
        for (row = [0:brick_num_rows-1]) {
            col_off = (row % 2 == 0) ? 0 : brick_col_pitch / 2;
            z0 = brick_start_z + row * brick_row_pitch;
            for (col = [0:8]) {
                translate([wall_x0 + col_off + col * brick_col_pitch + brick_l,
                           wall_y + wall_thick - 0.001,
                           z0])
                    cube([brick_gap, mortar_d + 0.001, brick_h_f]);
            }
        }
    }
}

module wall() {
    color([0.72, 0.22, 0.13])   // brick red
    difference() {
        translate([wall_x0, wall_y, 0]) cube([wall_total_w, wall_thick, wall_h]);
        h_seams();
        v_seams_front();
        v_seams_back();
    }
}

// ── Assembly ─────────────────────────────────────────────────────────────────

frame();
plate();
rivets();
wall();
