// element11.scad
// Curved conveyor belt — quarter-circle turn
// Belt arc with radial green rollers and a hollow curved direction arrow.
// Arc center at top-right corner; belt sweeps lower-left quadrant (180°–270°).
// Belt enters from bottom-right and exits upward at the left.
// Units: inches

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/16;
frame_w = 1/16;

hole_d = 3/32;
hole_r = hole_d / 2;

// Belt arc — center at top-right corner, sweeps lower-left quadrant
arc_cx    = plate_w;
arc_cy    = plate_d;
arc_r_out = 2.80;    // outer radius of belt arc (reaches near tile edges)
arc_r_in  = 1.00;    // inner radius (leaves bare-plate corner at top-right)
arc_a1    = 180;     // left end — belt exits upward here (arrowhead end)
arc_a2    = 270;     // bottom end — belt enters here

// Curved rollers — radially oriented, 8 along arc midline
roller_count = 8;
roller_r_mid = arc_r_in + (arc_r_out - arc_r_in) * 0.47;  // ~1.80"
roller_len   = (arc_r_out - arc_r_in) * 0.62;             // ~1.12" radial length
roller_r_cap = 0.09;                                       // stadium end-cap radius

// Hollow curved arrow — yellow-green outline
arrow_r_mid  = arc_r_in + (arc_r_out - arc_r_in) * 0.38;  // ~1.62"
arrow_half_w = (arc_r_out - arc_r_in) * 0.26;             // ~0.49" half-width
arrow_stroke = 0.10;                                       // outline thickness
arrow_a1     = arc_a1 + 6;   // arrowhead angle (just inside arc edge)
arrow_a2     = arc_a2 - 6;   // tail angle
arrow_head_h = 0.32;
arrow_head_w = 0.52;

// ── Helpers ──────────────────────────────────────────────────────────────────

// Pie-slice fan for sector clipping
module fan_2d(r, a1, a2) {
    polygon(concat([[0, 0]], [for (a = [a1:1:a2]) [r * cos(a), r * sin(a)]]));
}

// Annular sector from angle a1 to a2 (counterclockwise, both inclusive)
module annular_sector_2d(r_outer, r_inner, a1, a2) {
    intersection() {
        difference() {
            circle(r = r_outer, $fn = 120);
            circle(r = r_inner, $fn = 120);
        }
        fan_2d(r_outer + 0.5, a1, a2);
    }
}

// ── Standard modules ─────────────────────────────────────────────────────────

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    // Front edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, inset_y,         -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    // Back edge
    for (i = [0:9])
        translate([inset_x + i * spacing_x, plate_d - inset_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    // Left edge
    for (i = [0:9])
        translate([inset_x,           inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    // Right edge
    for (i = [0:9])
        translate([plate_w - inset_x, inset_y + i * spacing_y, -1])
            cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
}

module frame() {
    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
    }
}

module belt_arc_cutout() {
    translate([0, 0, -0.001])
    linear_extrude(plate_h + 0.002)
    translate([arc_cx, arc_cy])
        annular_sector_2d(arc_r_out, arc_r_in, arc_a1, arc_a2);
}

module plate() {
    difference() {
        color("darkgray")
            cube([plate_w, plate_d, plate_h]);
        rivet_holes();
        belt_arc_cutout();
    }
}

rivet_h = plate_h;
module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9])
            translate([inset_x + i * spacing_x, inset_y,         0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9])
            translate([inset_x + i * spacing_x, plate_d - inset_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9])
            translate([inset_x,           inset_y + i * spacing_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
        for (i = [0:9])
            translate([plate_w - inset_x, inset_y + i * spacing_y, 0])
                cylinder(h = rivet_h, r = hole_r, $fn = 20);
    }
}

// ── Feature modules ──────────────────────────────────────────────────────────

// Black belt surface filling the arc cutout
module belt_arc() {
    color("black")
    intersection() {
        linear_extrude(plate_h)
        translate([arc_cx, arc_cy])
            annular_sector_2d(arc_r_out, arc_r_in, arc_a1, arc_a2);
        cube([plate_w, plate_d, plate_h]);
    }
}

// Green radial roller slots — stadium shapes oriented toward arc center
module curved_rollers() {
    span = arc_a2 - arc_a1 - 10;   // exclude 5° at each arc end
    color("green")
    for (i = [0:roller_count - 1]) {
        theta = arc_a1 + 5 + span * i / (roller_count - 1);
        cx = arc_cx + roller_r_mid * cos(theta);
        cy = arc_cy + roller_r_mid * sin(theta);
        translate([cx, cy, 0])
        rotate([0, 0, theta])   // align long axis with radial direction
        hull() {
            translate([-roller_len / 2, 0, 0])
                cylinder(h = plate_h, r = roller_r_cap, $fn = 20);
            translate([ roller_len / 2, 0, 0])
                cylinder(h = plate_h, r = roller_r_cap, $fn = 20);
        }
    }
}

// Yellow-green hollow curved arrow showing belt direction
// Arrowhead at arrow_a1 (exit end), pointing clockwise-tangent ≈ upward.
// Rotation formula: rotate([0,0, theta - 180]) aligns +y tip to clockwise tangent at theta.
module curved_arrow() {
    r_o = arrow_r_mid + arrow_half_w;
    r_i = arrow_r_mid - arrow_half_w;

    color([0.40, 1.00, 0.10])   // bright yellow-green
    linear_extrude(plate_h + 0.001)
    translate([arc_cx, arc_cy])
    union() {
        // Hollow arc body — outer stroke + inner stroke, open interior
        difference() {
            annular_sector_2d(r_o,               r_i,               arrow_a1, arrow_a2);
            annular_sector_2d(r_o - arrow_stroke, r_i + arrow_stroke, arrow_a1, arrow_a2);
        }

        // Arrowhead triangle at arrow_a1 (exit / upward end)
        translate([arrow_r_mid * cos(arrow_a1), arrow_r_mid * sin(arrow_a1)])
        rotate([0, 0, arrow_a1 - 180])   // clockwise tangent direction
        polygon([
            [ 0,               arrow_head_h],   // tip
            [-arrow_head_w / 2, 0],             // base left
            [ arrow_head_w / 2, 0],             // base right
        ]);
    }
}

// ── Assembly ─────────────────────────────────────────────────────────────────

frame();
plate();
rivets();
belt_arc();
curved_rollers();
curved_arrow();
