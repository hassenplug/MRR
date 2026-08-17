// sub_base_plate.scad — shared tile-building blocks: plate, rivets, edge ID marks,
// and the common plate/hole dimensional constants used by every tile.
// Units: inches
//
// Usage — must be `include`, not `use`, and the include line must come
// before any code in the caller that references plate_w/plate_d/plate_h/
// frame_w/hole_d/hole_r: a variable defined only inside an included file is
// invisible to code positioned before the include statement.
//   include <sub_base_plate.scad>
//   plate(["red", undef, "blue", undef, undef, "green"]);
//
// plate(colors) is the main entry point: it builds the complete base tile in
// one call — the frame with edge ID marks, the darkgray plate, and the
// lightgray rivet ring (40 rivets, 10 per side, corners shared). colors is the
// same 6-slot frame_with_id() array described below.
//
// frame_with_id() colors are applied left-to-right (−x to +x), repeated
// identically on all four edges. Bottom and right edges read the array in
// reverse (slot 5-i) so the pattern stays consistent when the tile is flipped.
// Any position left as undef or omitted defaults to black. 6 regions span the
// straight run of each edge (corners always stay solid black). Each mark is
// sandwiched between a thin black id_cover layer on the bottom and another on
// top; marks are visible only from the edge, not from the top or bottom face.

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/8; // full plate thickness
frame_w = 1/16;
hole_d  = 3/32;
hole_r  = hole_d / 2;

pattern_h = 1/32;  // thickness of the raised pattern on the top surface of the plate, for example
                   // the belt pattern or the gear teeth. This is a separate constant
                   // from plate_h so that the pattern can be printed in a different
                   // color than the plate itself.
id_cover = plate_h / 8;

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, -1]) cylinder(h = plate_h + 2, r = hole_r, $fn = 20);
}

module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           0]) cylinder(h = plate_h, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, 0]) cylinder(h = plate_h, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, 0]) cylinder(h = plate_h, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, 0]) cylinder(h = plate_h, r = hole_r, $fn = 20);
    }
}

module frame_with_id(colors = []) {
    region_w = plate_w / 6;
    region_d = plate_d / 6;
    mark_h   = plate_h - 2 * id_cover;

    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
        // top/bottom/left/right straight runs only — corners stay solid black
        translate([0, plate_d - 0.001, -0.001])
            cube([plate_w, frame_w + 0.002, plate_h + 0.002]);
        translate([0, -frame_w - 0.001, -0.001])
            cube([plate_w, frame_w + 0.002, plate_h + 0.002]);
        translate([-frame_w - 0.001, 0, -0.001])
            cube([frame_w + 0.002, plate_d, plate_h + 0.002]);
        translate([plate_w - 0.001, 0, -0.001])
            cube([frame_w + 0.002, plate_d, plate_h + 0.002]);
    }

    for (i = [0:5]) {
        c     = (colors[i] != undef) ? colors[i] : "black";

        // top edge — id_cover, mark, id_cover
        color("black") translate([i * region_w, plate_d, 0]) cube([region_w, frame_w, id_cover]);
        color(c)       translate([i * region_w, plate_d, id_cover]) cube([region_w, frame_w, mark_h]);
        color("black") translate([i * region_w, plate_d, id_cover + mark_h]) cube([region_w, frame_w, id_cover]);

        // bottom edge (reversed) — id_cover, mark, id_cover
        color("black") translate([(5-i) * region_w, -frame_w, 0]) cube([region_w, frame_w, id_cover]);
        color(c)       translate([(5-i) * region_w, -frame_w, id_cover]) cube([region_w, frame_w, mark_h]);
        color("black") translate([(5-i) * region_w, -frame_w, id_cover + mark_h]) cube([region_w, frame_w, id_cover]);

        // left edge — id_cover, mark, id_cover
        color("black") translate([-frame_w, i * region_d, 0]) cube([frame_w, region_d, id_cover]);
        color(c)       translate([-frame_w, i * region_d, id_cover]) cube([frame_w, region_d, mark_h]);
        color("black") translate([-frame_w, i * region_d, id_cover + mark_h]) cube([frame_w, region_d, id_cover]);

        // right edge (reversed) — id_cover, mark, id_cover
        color("black") translate([plate_w, (5-i) * region_d, 0]) cube([frame_w, region_d, id_cover]);
        color(c)       translate([plate_w, (5-i) * region_d, id_cover]) cube([frame_w, region_d, mark_h]);
        color("black") translate([plate_w, (5-i) * region_d, id_cover + mark_h]) cube([frame_w, region_d, id_cover]);
    }
}

module plate(colors = []) {
    frame_with_id(colors);
    union() {
        difference() {
            color("darkgray") cube([plate_w, plate_d, plate_h]);
            rivet_holes();
        }
        rivets();
    }
}

