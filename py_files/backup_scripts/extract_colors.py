"""
Extract dominant colors from all JPG files in images/ and write a color list.
"""

import os
from PIL import Image
from collections import Counter

IMAGES_DIR = "c:/Users/hasse/OneDrive/Documents/git/MRR/images"
OUTPUT_FILE = "c:/Users/hasse/OneDrive/Documents/git/MRR/colors.md"
TOP_N = 5        # dominant colors per image
QUANTIZE = 16    # palette size for quantization


def rgb_to_hex(r, g, b):
    return f"#{r:02X}{g:02X}{b:02X}"


def make_swatch(hex_val):
    # SVG with background color set via style — width appears exactly once
    color = hex_val.replace('#', '%23')
    svg = f"data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%2216%22 height=%2216%22 style=%22background:{color}%22%3E%3C/svg%3E"
    return f'<img src="{svg}">'


def get_dominant_colors(path, top_n=TOP_N, palette_size=QUANTIZE):
    img = Image.open(path).convert("RGB")
    # Reduce to palette_size colors via median-cut quantization
    quantized = img.quantize(colors=palette_size, method=Image.Quantize.MEDIANCUT)
    palette_data = quantized.getpalette()  # flat list R,G,B,R,G,B,...

    # Count pixels per palette index
    pixel_counts = Counter(quantized.getdata())
    total = sum(pixel_counts.values())

    results = []
    for idx, count in pixel_counts.most_common(top_n):
        r = palette_data[idx * 3]
        g = palette_data[idx * 3 + 1]
        b = palette_data[idx * 3 + 2]
        pct = count / total * 100
        results.append((rgb_to_hex(r, g, b), r, g, b, pct))
    return results


def main():
    jpg_files = sorted(
        f for f in os.listdir(IMAGES_DIR)
        if f.lower().endswith(".jpg")
    )

    lines = ["# Color List\n",
             f"Dominant colors extracted from {len(jpg_files)} images in `images/`.\n",
             "Top 5 colors per image (by pixel coverage).\n\n"]

    all_colors = set()

    for fname in jpg_files:
        path = os.path.join(IMAGES_DIR, fname)
        colors = get_dominant_colors(path)
        lines.append(f"## {fname}\n")
        lines.append("| Swatch | Hex     | R   | G   | B   | Coverage |\n")
        lines.append("|--------|---------|-----|-----|-----|----------|\n")
        for hex_val, r, g, b, pct in colors:
            lines.append(f"| {make_swatch(hex_val)} `{hex_val}` | {r:3d} | {g:3d} | {b:3d} | {pct:5.1f}%  |\n")
            all_colors.add(hex_val)
        lines.append("\n")

    lines.append("---\n\n")
    lines.append(f"## All Unique Colors ({len(all_colors)} total)\n\n")
    for c in sorted(all_colors):
        lines.append(f"- {make_swatch(c)} `{c}`\n")

    with open(OUTPUT_FILE, "w") as f:
        f.writelines(lines)

    print(f"Done. {len(jpg_files)} images processed, {len(all_colors)} unique colors found.")
    print(f"Output: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
