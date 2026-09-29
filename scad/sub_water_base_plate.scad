// sub_water_base_plate.scad — base plate for the "water" tile family
// (element55 straight, future right-turn/left-turn variants)
// Units: inches
//
// Unlike sub_base_plate.scad's single darkgray plate, this family stacks the
// top pattern_h-plus a bit into three visible layers, bottom to top:
//   darkgray          — 1/2 plate_h  (structural base)
//   background_color  — 1/4 plate_h  (caller-defined)
//   transparent_color — 1/4 plate_h  (caller-defined, spans the outer
//                                      footprint — frame included — so it
//                                      caps the border too)
// Rivets run through darkgray + background_color only (3/4 plate_h) — the
// transparent_color cap sits over them uncut. frame_with_id() is built to
// that same 3/4 plate_h, so its top 1/4 is covered by the transparent cap
// exactly like the inner plate. The arrow (sub_water_arrows.scad) is
// unaffected — it still lives in its own top pattern_h slice, which happens
// to be the same pattern_h as the transparent_color layer at current
// dimensions, but is not derived from it.

plate_w = 2 + 7/8;
plate_d = 2 + 7/8;
plate_h = 1/8; // full plate thickness
frame_w = 1/16;
hole_d  = 3/32;
hole_r  = hole_d / 2;

pattern_h = 1/32;  // thickness of the arrow's top slice (sub_water_arrows.scad) —
                   // independent of the layer fractions below even though it
                   // currently equals plate_h/4.
id_cover = plate_h * 3 / 16;

// ── Layer heights ───────────────────────────────────────────────────────
darkgray_h    = plate_h / 2;
background_h  = plate_h / 4;
transparent_h = plate_h / 4;
frame_h       = plate_h * 3 / 4;               // = darkgray_h + background_h
rivet_depth   = darkgray_h + background_h;     // rivets stop where the transparent cap starts

module rivet_holes() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           -1]) cylinder(h = rivet_depth + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, -1]) cylinder(h = rivet_depth + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, -1]) cylinder(h = rivet_depth + 2, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, -1]) cylinder(h = rivet_depth + 2, r = hole_r, $fn = 20);
}

module rivets() {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    color("lightgray") {
        for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,           0]) cylinder(h = rivet_depth, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y, 0]) cylinder(h = rivet_depth, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([inset_x,           inset_y + i * spacing_y, 0]) cylinder(h = rivet_depth, r = hole_r, $fn = 20);
        for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y, 0]) cylinder(h = rivet_depth, r = hole_r, $fn = 20);
    }
}

// Border + edge ID marks, built to frame_h (3/4 plate_h) — the transparent
// cap covers the remaining top 1/4, over the frame as well as the plate.
module frame_with_id(colors = []) {
    region_w = plate_w / 8;
    region_d = plate_d / 8;
    mark_h   = frame_h - 2 * id_cover;

    color("black")
    difference() {
        translate([-frame_w, -frame_w, 0])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, frame_h]);
        translate([0, 0, -0.001])
            cube([plate_w, plate_d, frame_h + 0.002]);
        // top/bottom/left/right straight runs only — corners stay solid black
        translate([0, plate_d - 0.001, -0.001])
            cube([plate_w, frame_w + 0.002, frame_h + 0.002]);
        translate([0, -frame_w - 0.001, -0.001])
            cube([plate_w, frame_w + 0.002, frame_h + 0.002]);
        translate([-frame_w - 0.001, 0, -0.001])
            cube([frame_w + 0.002, plate_d, frame_h + 0.002]);
        translate([plate_w - 0.001, 0, -0.001])
            cube([frame_w + 0.002, plate_d, frame_h + 0.002]);
    }

    for (i = [0:7]) {
        c     = (i == 0) ? "darkgray" : (i == 7) ? "black" : ((colors[i-1] != undef) ? colors[i-1] : "black");

        // top edge — id_cover, mark, id_cover
        color("black") translate([i * region_w, plate_d, 0]) cube([region_w, frame_w, id_cover]);
        color(c)       translate([i * region_w, plate_d, id_cover]) cube([region_w, frame_w, mark_h]);
        color("black") translate([i * region_w, plate_d, id_cover + mark_h]) cube([region_w, frame_w, id_cover]);

        // bottom edge (reversed) — id_cover, mark, id_cover
        color("black") translate([(7-i) * region_w, -frame_w, 0]) cube([region_w, frame_w, id_cover]);
        color(c)       translate([(7-i) * region_w, -frame_w, id_cover]) cube([region_w, frame_w, mark_h]);
        color("black") translate([(7-i) * region_w, -frame_w, id_cover + mark_h]) cube([region_w, frame_w, id_cover]);

        // left edge — id_cover, mark, id_cover
        color("black") translate([-frame_w, i * region_d, 0]) cube([frame_w, region_d, id_cover]);
        color(c)       translate([-frame_w, i * region_d, id_cover]) cube([frame_w, region_d, mark_h]);
        color("black") translate([-frame_w, i * region_d, id_cover + mark_h]) cube([frame_w, region_d, id_cover]);

        // right edge (reversed) — id_cover, mark, id_cover
        color("black") translate([plate_w, (7-i) * region_d, 0]) cube([frame_w, region_d, id_cover]);
        color(c)       translate([plate_w, (7-i) * region_d, id_cover]) cube([frame_w, region_d, mark_h]);
        color("black") translate([plate_w, (7-i) * region_d, id_cover + mark_h]) cube([frame_w, region_d, id_cover]);
    }
}

// Frame + inner darkgray/background_color stack, with rivets running
// through both. Does not include the transparent cap — see
// plate_trans_layer().
module plate(colors = []) {
    frame_with_id(colors);
    union() {
        difference() {
            union() {
                color("darkgray")
                    cube([plate_w, plate_d, darkgray_h]);
                translate([0, 0, darkgray_h])
                color(background_color)
                    cube([plate_w, plate_d, background_h]);
            }
            rivet_holes();
        }
        rivets();
    }
}

// plate() plus the transparent_color cap — spans the full outer footprint
// (frame included) across the top transparent_h slice. plate()'s frame and
// inner stack both already stop exactly at plate_h - transparent_h, so this
// is a plain union, not a cut-and-refill.
module plate_trans_layer(colors = []) {
    plate(colors);
    if (show_transparent) {
        color(transparent_color)
        translate([-frame_w, -frame_w, plate_h - transparent_h])
            cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, transparent_h]);
    }
}   
