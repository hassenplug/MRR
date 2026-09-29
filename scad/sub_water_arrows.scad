// sub_water_arrows.scad — shared arrow geometry for the water tile family
// (element55 straight, future right-turn/left-turn variants)
// Requires caller to define: plate_w, plate_d, plate_h, pattern_h, frame_h
// (see sub_water_base_plate.scad)
// Units: inches
//
// Ported from sub_belts.scad's arrow geometry with the belt/roller pattern
// removed — this family has no physical belt or rollers, only the
// directional arrow. arrow_w/arrow_shaft_w/arrow_head_h are hardcoded to the
// same values sub_belts.scad derives from belt_w(1.75) * 0.85, matching the
// convention already used by sub_wavy_arrows.scad.
//
// Dispatch flags the caller must define before including this file:
//   straight      — true to draw the straight-through arrow
//   right_turn    — true to draw the arrow curving out to the right edge
//   left_turn     — true to draw the arrow curving out to the left edge
//                   (the mirror of right_turn's geometry — see below)
//   double_speed  — false for single-arrow tiles, true for double-arrow tiles
//   arrow_color   — color string; only used inside arrow(), so it may be
//                   defined after this include
//
// straight/right_turn/left_turn are independent, not mutually exclusive —
// any combination may be true. arrow() is a dispatcher: it draws the
// straight_*() geometry when straight is set, the curved_*() geometry as-is
// when right_turn is set, and curved_*() again mirrored across the tile's
// vertical centerline when left_turn is set — there is only one curved
// implementation, reused for both directions.
//
// The arrow sits at the TOP of the background_color layer (frame_h - pattern_h
// to frame_h), not the top of the tile — the transparent_color cap stays
// uncut above it, so the arrow glows under the transparent layer rather than
// sitting on the tile's outer surface.

arrow_w       = 1.4875;      // = sub_belts.scad belt_w(1.75) * 0.85
arrow_shaft_w = 0.669375;    // = arrow_w * 0.45
arrow_head_h  = 0.74375;     // = arrow_w / 2
arrow_outline = 1/8;
arrow_tip_y   = 3 * plate_d / 20 + 1/4 + 7 * plate_d / 10;
arrow_gap     = 1/8;

// Turn-tile curve geometry — unused (harmless) when neither turn flag is set
cx      = plate_w / 2;
r_curve = 0.48;
cx_r    = cx + r_curve;

// Arrow shaft height is tuned per family; straight-double instead derives it
// from the tile height so two arrows plus the gap fit exactly.
arrow_shaft_h = (straight && double_speed) ? (plate_d * 3/4 - arrow_gap) / 2 - arrow_head_h + 0.05
              : straight                   ? 1.4825
              : double_speed               ? 0.25
              : 1.5;
arrow_h = arrow_shaft_h + arrow_head_h;

// Straight tiles: arrow Y position(s)
arrow_y  = arrow_tip_y - arrow_h;           // single arrow (also used as the turn tiles' arrow_y)
arrow2_y = arrow_tip_y - arrow_h;           // double: upper arrow
arrow1_y = arrow2_y - arrow_gap - arrow_h;  // double: lower arrow

// Turn tiles: curve/merge geometry
y_merge    = arrow_y + arrow_shaft_h;                 // single: vertical/arc junction
y_merge_up = arrow_tip_y - arrow_head_h;              // double: vertical/arc junction
h_straight = double_speed ? 0 : 0.49;

// Turn, double-speed: upward + leftward arrow placement
arrow_up_y = arrow_y;
arrow_lf_y = plate_d / 2;
arrow_lf_x = plate_w - (plate_d - arrow_tip_y);

// Mirrors curved_*() geometry across the tile's vertical centerline for left_turn
module mirrored() {
    translate([plate_w, 0, 0])
    mirror([1, 0, 0])
    children();
}

// ── Arrow shapes ────────────────────────────────────────────────────────────────

module arrow_2d() {
    polygon([
        [-arrow_shaft_w / 2, 0],
        [ arrow_shaft_w / 2, 0],
        [ arrow_shaft_w / 2, arrow_shaft_h],
        [ arrow_w / 2,       arrow_shaft_h],
        [ 0,                 arrow_h],
        [-arrow_w / 2,       arrow_shaft_h],
        [-arrow_shaft_w / 2, arrow_shaft_h]
    ]);
}

module straight_arrow_fill() {
    translate([0, 0, frame_h - pattern_h])
    if (!double_speed) {
        translate([plate_w / 2, arrow_y, 0])
        linear_extrude(pattern_h)
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    } else {
        for (ay = [arrow1_y, arrow2_y])
            translate([plate_w / 2, ay, 0])
            linear_extrude(pattern_h)
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
    }
}

module straight_arrow_cutout() {
    translate([0, 0, frame_h - pattern_h])
    if (!double_speed) {
        translate([plate_w / 2, arrow_y, -0.001])
        linear_extrude(pattern_h + 0.002)
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    } else {
        for (ay = [arrow1_y, arrow2_y])
            translate([plate_w / 2, ay, -0.001])
            linear_extrude(pattern_h + 0.002)
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
    }
}

module curved_arrow_fill() {
    translate([0, 0, frame_h - pattern_h])
    if (!double_speed) {
        // Vertical segment: cx, from arc center up to arrowhead base
        translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve, 0])
        linear_extrude(pattern_h)
        difference() {
            square([arrow_shaft_w, y_merge - (plate_d/2 + r_curve)]);
            translate([arrow_outline, 0])
                square([arrow_shaft_w - 2*arrow_outline, y_merge - (plate_d/2 + r_curve)]);
        }
        // Arc shaft: hollow annulus, lower-left quadrant (180°–270°)
        translate([cx_r, plate_d/2 + r_curve, 0])
        linear_extrude(pattern_h)
        intersection() {
            difference() {
                difference() {
                    circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                    circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                }
                offset(delta = -arrow_outline)
                difference() {
                    circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                    circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                }
            }
            translate([-(r_curve + arrow_shaft_w/2), -(r_curve + arrow_shaft_w/2)])
                square([r_curve + arrow_shaft_w/2, r_curve + arrow_shaft_w/2]);
        }
        // Horizontal segment: from arc 270° endpoint at (cx_r, plate_d/2) going right
        translate([cx_r, plate_d/2 - arrow_shaft_w/2, 0])
        linear_extrude(pattern_h)
        difference() {
            square([h_straight, arrow_shaft_w]);
            translate([0, arrow_outline])
                square([h_straight, arrow_shaft_w - 2*arrow_outline]);
        }
        // End cap
        translate([cx_r + h_straight - arrow_outline, plate_d/2 - arrow_shaft_w/2, 0])
            cube([arrow_outline, arrow_shaft_w, pattern_h]);
        // Arrowhead — clipped from full arrow_2d so base is open to shaft
        translate([cx, arrow_y, 0])
        linear_extrude(pattern_h)
        intersection() {
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
            translate([-arrow_w / 2, arrow_shaft_h])
                square([arrow_w, arrow_head_h]);
        }
    } else {
        // Curved upward arrow
        union() {
            // Vertical segment: arc center up to arrowhead base
            translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve, 0])
            linear_extrude(pattern_h)
            difference() {
                square([arrow_shaft_w, y_merge_up - (plate_d/2 + r_curve)]);
                translate([arrow_outline, 0])
                    square([arrow_shaft_w - 2*arrow_outline, y_merge_up - (plate_d/2 + r_curve)]);
            }
            // Arc shaft: hollow annulus, 180°–225° (stops 45° short of the old
            // 270° end, at arc_stop — a radial cut, which is why it comes out
            // at exactly 45° — where the closing line below connects it).
            arc_stop = 225;
            arc_big = 10;
            translate([cx_r, plate_d/2 + r_curve, 0])
            linear_extrude(pattern_h)
            intersection() {
                difference() {
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                    offset(delta = -arrow_outline)
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                }
                polygon([[0, 0], [arc_big*cos(180), arc_big*sin(180)], [arc_big*cos(arc_stop), arc_big*sin(arc_stop)]]);
            }
            // Horizontal segment: from arc 270° endpoint going right
            translate([cx_r, plate_d/2 - arrow_shaft_w/2, 0])
            linear_extrude(pattern_h)
            difference() {
                square([h_straight, arrow_shaft_w]);
                translate([0, arrow_outline])
                    square([h_straight, arrow_shaft_w - 2*arrow_outline]);
            }
            // Closing line: a 45° radial spoke at arc_stop, connecting the
            // outer and inner rail arcs exactly where the shaft-arc stops.
            translate([cx_r, plate_d/2 + r_curve, 0])
            rotate([0, 0, arc_stop])
            translate([r_curve - arrow_shaft_w/2, -arrow_outline/2, 0])
            linear_extrude(pattern_h)
            square([arrow_shaft_w, arrow_outline]);
            // Arrowhead — head only, base open to vertical shaft
            translate([cx, arrow_up_y, 0])
            linear_extrude(pattern_h)
            intersection() {
                difference() {
                    arrow_2d();
                    offset(delta = -arrow_outline) arrow_2d();
                }
                translate([-arrow_w / 2, arrow_shaft_h])
                    square([arrow_w, arrow_head_h]);
            }
        }
        // Leftward arrow
        translate([arrow_lf_x, arrow_lf_y, 0])
        linear_extrude(pattern_h)
        rotate([0, 0, 90])
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    }
}

module curved_arrow_cutout() {
    translate([0, 0, frame_h - pattern_h])
    if (!double_speed) {
        // Vertical segment cutout
        translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve - 0.001, -0.001])
        linear_extrude(pattern_h + 0.002)
        difference() {
            square([arrow_shaft_w, y_merge - (plate_d/2 + r_curve) + 0.001]);
            translate([arrow_outline, 0])
                square([arrow_shaft_w - 2*arrow_outline, y_merge - (plate_d/2 + r_curve)]);
        }
        // Arc shaft cutout
        translate([cx_r, plate_d/2 + r_curve, -0.001])
        linear_extrude(pattern_h + 0.002)
        intersection() {
            difference() {
                difference() {
                    circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                    circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                }
                offset(delta = -arrow_outline)
                difference() {
                    circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                    circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                }
            }
            translate([-(r_curve + arrow_shaft_w/2), -(r_curve + arrow_shaft_w/2)])
                square([r_curve + arrow_shaft_w/2, r_curve + arrow_shaft_w/2]);
        }
        // Horizontal segment cutout
        translate([cx_r, plate_d/2 - arrow_shaft_w/2, -0.001])
        linear_extrude(pattern_h + 0.002)
        difference() {
            square([h_straight, arrow_shaft_w]);
            translate([0, arrow_outline])
                square([h_straight, arrow_shaft_w - 2*arrow_outline]);
        }
        // End cap cutout
        translate([cx_r + h_straight - arrow_outline, plate_d/2 - arrow_shaft_w/2, -0.001])
            cube([arrow_outline, arrow_shaft_w, pattern_h + 0.002]);
        // Arrowhead cutout — clipped from full arrow_2d so base is open to shaft
        translate([cx, arrow_y, -0.001])
        linear_extrude(pattern_h + 0.002)
        intersection() {
            difference() {
                arrow_2d();
                offset(delta = -arrow_outline) arrow_2d();
            }
            translate([-arrow_w / 2, arrow_shaft_h])
                square([arrow_w, arrow_head_h]);
        }
    } else {
        // Curved arrow cutouts
        union() {
            // Vertical segment cutout
            translate([cx - arrow_shaft_w/2, plate_d/2 + r_curve - 0.001, -0.001])
            linear_extrude(pattern_h + 0.002)
            difference() {
                square([arrow_shaft_w, y_merge_up - (plate_d/2 + r_curve) + 0.001]);
                translate([arrow_outline, 0])
                    square([arrow_shaft_w - 2*arrow_outline, y_merge_up - (plate_d/2 + r_curve)]);
            }
            // Arc shaft cutout, 180°–225° (see fill counterpart for arc_stop)
            arc_stop = 225;
            arc_big = 10;
            translate([cx_r, plate_d/2 + r_curve, -0.001])
            linear_extrude(pattern_h + 0.002)
            intersection() {
                difference() {
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                    offset(delta = -arrow_outline)
                    difference() {
                        circle(r = r_curve + arrow_shaft_w/2, $fn = 120);
                        circle(r = r_curve - arrow_shaft_w/2, $fn = 120);
                    }
                }
                polygon([[0, 0], [arc_big*cos(180), arc_big*sin(180)], [arc_big*cos(arc_stop), arc_big*sin(arc_stop)]]);
            }
            // Horizontal segment cutout
            translate([cx_r, plate_d/2 - arrow_shaft_w/2, -0.001])
            linear_extrude(pattern_h + 0.002)
            difference() {
                square([h_straight, arrow_shaft_w]);
                translate([0, arrow_outline])
                    square([h_straight, arrow_shaft_w - 2*arrow_outline]);
            }
            // Closing line cutout: 45° radial spoke at arc_stop (see fill counterpart)
            translate([cx_r, plate_d/2 + r_curve, -0.001])
            rotate([0, 0, arc_stop])
            translate([r_curve - arrow_shaft_w/2, -arrow_outline/2, 0])
            linear_extrude(pattern_h + 0.002)
            square([arrow_shaft_w, arrow_outline]);
            // Arrowhead cutout (head only)
            translate([cx, arrow_up_y, -0.001])
            linear_extrude(pattern_h + 0.002)
            intersection() {
                difference() {
                    arrow_2d();
                    offset(delta = -arrow_outline) arrow_2d();
                }
                translate([-arrow_w / 2, arrow_shaft_h])
                    square([arrow_w, arrow_head_h]);
            }
        }
        // Cut leftward arrow outline
        translate([arrow_lf_x, arrow_lf_y, -0.001])
        linear_extrude(pattern_h + 0.002)
        rotate([0, 0, 90])
        difference() {
            arrow_2d();
            offset(delta = -arrow_outline) arrow_2d();
        }
    }
}

module arrow() {
    color(arrow_color)
    union() {
        if (straight)   straight_arrow_fill();
        if (right_turn) curved_arrow_fill();
        if (left_turn)  mirrored() curved_arrow_fill();
    }
}

module arrow_cutout() {
    if (straight)   straight_arrow_cutout();
    if (right_turn) curved_arrow_cutout();
    if (left_turn)  mirrored() curved_arrow_cutout();
}
