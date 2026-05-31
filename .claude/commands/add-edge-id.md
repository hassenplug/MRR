Add edge identification marks to an MRR tile element SCAD file.

Arguments: `$ARGUMENTS`
Expected format: `<element-number-or-filename> [color1,color2,color3,color4,color5,color6]`

Examples:
- `10 [undef,undef,"green","green",undef,undef]`
- `element11.scad ["red",undef,undef,undef,undef,"blue"]`

## Requirements

- The element number maps to `scad/element{N}.scad` (e.g., `10` → `scad/element10.scad`)
- If a filename is given instead, look for it in `scad/`
- Colors are 6-element OpenSCAD color values (names like `"red"` or RGB like `[1,0,0]`); `undef` means black
- **Copy the module code inline — do NOT use `use` or `include`**

## What to do

1. **Parse** the element number/filename and colors list from the arguments.

2. **Read** the target SCAD file.

3. **Replace the `module frame()` block** with the `frame_with_id()` module below.  
   The existing `frame()` module always has this exact structure — replace the entire block:
   ```openscad
   module frame() {
       color("black")
       difference() {
           translate([-frame_w, -frame_w, 0])
               cube([plate_w + 2 * frame_w, plate_d + 2 * frame_w, plate_h]);
           translate([0, 0, -0.001])
               cube([plate_w, plate_d, plate_h + 0.002]);
       }
   }
   ```
   with this module (copied verbatim):
   ```openscad
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
   ```

4. **Replace the `frame();` call** (at the bottom of the file, in the assembly section) with:
   ```openscad
   frame_with_id([color1, color2, color3, color4, color5, color6]);
   ```
   using the exact colors from the arguments (preserve `undef` as the literal token `undef`, not as a string).

5. **Write** the modified file back.

6. **Confirm** to the user: which file was modified, and which regions got non-black colors.

## Notes

- The marks appear on the +Y (top) edge of the tile, visible from the side edge only.
- A thin black layer (plate_h / 8) covers the marks on the top face.
- 6 equal regions span the full top frame width (plate_w + 2 * frame_w).
- Regions are numbered 1–6, left to right (−x to +x).
