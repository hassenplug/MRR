// element100-6.scad
// Flag square tile variant — gear with pennant flag, number "6" on flag.

include <modules.scad>
include <innergears.scad>
include <flag.scad>

// ── Assembly ──────────────────────────────────────────────────────────────────
// Each level: difference() cuts the holes INTO the running assembly,
//             union() then adds the feature that fills those holes.
// Innermost = first step; outermost = last step.

union() {                                           // step 5: add label
    difference() {
        union() {                                   // step 4: add flag pole & flag
            difference() {
                union() {                           // step 3: add flag outline
                    difference() {
                        union() {                   // step 2: add gear bore
                            difference() {
                                union() {           // step 1: add gear
                                    difference() {
                                        plate(["red", "red", "red", "red", "red", undef]);   // step 0: plate (frame + rivets)
                                        gear_holes();       // cut gear holes
                                    }
                                    gear("darkred");        // fill with gear
                                }
                                gear_bore_holes();          // cut gear bore hole
                            }
                            gear_bore("lightgray");         // fill with gear bore
                        }
                        flag_outline_holes();               // cut flag outline hole
                    }
                    flag_outline();                         // fill with flag outline
                }
                flag_pole_holes();                          // cut flag pole hole
                flag_holes();                               // cut flag hole
            }
            flag_pole();                                    // fill with flag pole
            flag();                                         // fill with flag
        }
        label_holes("6");                                   // cut label hole
    }
    flag_label("6");                                        // fill with label
}
