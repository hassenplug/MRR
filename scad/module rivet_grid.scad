module rivet_grid(z) {
    spacing_x = plate_w / 10;
    spacing_y = plate_d / 10;
    inset_x   = spacing_x / 2;
    inset_y   = spacing_y / 2;
    h = plate_h - 2 * z;
    for (i = [0:9]) translate([inset_x + i * spacing_x, inset_y,             z]) cylinder(h = h, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x + i * spacing_x, plate_d - inset_y,   z]) cylinder(h = h, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([inset_x,             inset_y + i * spacing_y, z]) cylinder(h = h, r = hole_r, $fn = 20);
    for (i = [0:9]) translate([plate_w - inset_x, inset_y + i * spacing_y,   z]) cylinder(h = h, r = hole_r, $fn = 20);
}
