"""
Re-create every JPG in images/ using only the reduced palette from colors_reduced.md,
saving results to images_reduced/.
Each pixel is mapped to the nearest palette color by Euclidean RGB distance.
"""

import os
import re
import math
from PIL import Image

IMAGES_DIR  = "c:/Users/hasse/OneDrive/Documents/git/MRR/images"
OUTPUT_DIR  = "c:/Users/hasse/OneDrive/Documents/git/MRR/images_reduced"
COLORS_FILE = "c:/Users/hasse/OneDrive/Documents/git/MRR/colors_reduced.md"


def load_palette(path):
    with open(path, encoding="utf-8") as f:
        content = f.read()
    # Pull hex colors from the global summary table (after the --- divider)
    summary = content.split("---")[-1]
    hexes = re.findall(r'`(#[0-9A-Fa-f]{6})`', summary)
    seen, palette = set(), []
    for h in hexes:
        if h not in seen:
            seen.add(h)
            r = int(h[1:3], 16)
            g = int(h[3:5], 16)
            b = int(h[5:7], 16)
            palette.append((r, g, b))
    return palette


def nearest(pixel, palette):
    pr, pg, pb = pixel
    best, best_d = None, float('inf')
    for (r, g, b) in palette:
        d = (pr-r)**2 + (pg-g)**2 + (pb-b)**2
        if d < best_d:
            best_d, best = d, (r, g, b)
    return best


def remap_image(img, palette):
    img = img.convert("RGB")
    # Quantize to our exact palette using PIL:
    # Build a palette image with our colors padded to 256 entries
    pal_img = Image.new("P", (1, 1))
    flat = []
    for (r, g, b) in palette:
        flat += [r, g, b]
    # Pad to 256 colors
    flat += [0, 0, 0] * (256 - len(palette))
    pal_img.putpalette(flat)

    # Quantize using our palette (no dithering)
    quantized = img.quantize(palette=pal_img, dither=0)
    return quantized.convert("RGB")


def main():
    palette = load_palette(COLORS_FILE)
    print(f"Loaded {len(palette)} palette colors:")
    for r, g, b in palette:
        print(f"  #{r:02X}{g:02X}{b:02X}")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    jpg_files = sorted(
        f for f in os.listdir(IMAGES_DIR)
        if f.lower().endswith(".jpg")
    )

    for fname in jpg_files:
        src = os.path.join(IMAGES_DIR, fname)
        dst = os.path.join(OUTPUT_DIR, fname)
        img = Image.open(src)
        out = remap_image(img, palette)
        out.save(dst, quality=95)
        print(f"  {fname} -> {dst}")

    print(f"\nDone. {len(jpg_files)} images saved to {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
