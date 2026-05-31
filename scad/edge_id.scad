// edge_id.scad — tile edge-identification mark module
// Replaces frame() with frame_with_id() for tiles using edge ID marks.
// Requires caller to define: plate_w, plate_d, plate_h, frame_w
// Units: inches
//
// Usage:
//   use <edge_id.scad>
//   frame_with_id(["red", undef, "blue", undef, undef, "green"]);
//
// Colors are applied left-to-right (−x to +x) across the +Y frame edge.
// Any position left as undef or omitted defaults to black.
// 6 regions span the full top frame edge (plate_w + 2*frame_w), equal width.
// A thin black layer covers the marks on the top face; marks are visible from the edge.

module frame_with_id(colors = []) {
    id_cover = plate_h / 8;
    region_w = (plate_w + 2 * frame_w) / 6;
    mark_h   = plate_h - id_cover;

    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, plate_h + 0.002]);
        translate([-frame_w, plate_d, -0.001])
            cube([plate_w + 2 * frame_w, frame_w + 0.002, plate_h + 0.002]);
    }

    for (i = [0:5]) {
        c = (colors[i] != undef) ? colors[i] : "black";
        color(c)
        translate([-frame_w + i * region_w, plate_d, 0])
            cube([region_w, frame_w, mark_h]);
        color("black")
        translate([-frame_w + i * region_w, plate_d, mark_h])
            cube([region_w, frame_w, id_cover]);
    }
}
