"""
Extract colors from all JPGs, cluster similar colors together,
and write colors_reduced.md with a merged palette.

Uses pure Python + PIL only (no numpy/scipy required).
Clustering: greedy merge in RGB space — colors within `THRESHOLD`
Euclidean distance of an existing cluster centroid are merged into it.
"""

import os
import math
from PIL import Image
from collections import Counter, defaultdict

IMAGES_DIR  = "c:/Users/hasse/OneDrive/Documents/git/MRR/images"
OUTPUT_FILE = "c:/Users/hasse/OneDrive/Documents/git/MRR/colors_reduced.md"
TOP_N       = 5
QUANTIZE    = 16
THRESHOLD   = 100   # Euclidean RGB distance to merge colors


# ── helpers ──────────────────────────────────────────────────────────────────

def rgb_to_hex(r, g, b):
    return f"#{r:02X}{g:02X}{b:02X}"

def hex_to_rgb(h):
    h = h.lstrip('#')
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

def color_dist(a, b):
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))

def make_swatch(hex_val):
    color = hex_val.replace('#', '%23')
    svg = (f"data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22"
           f" width=%2216%22 height=%2216%22 style=%22background:{color}%22%3E%3C/svg%3E")
    return f'<img src="{svg}">'


# ── color extraction ──────────────────────────────────────────────────────────

def get_dominant_colors(path):
    img = Image.open(path).convert("RGB")
    quantized = img.quantize(colors=QUANTIZE, method=Image.Quantize.MEDIANCUT)
    palette_data = quantized.getpalette()
    pixel_counts = Counter(quantized.get_flattened_data())
    total = sum(pixel_counts.values())
    results = []
    for idx, count in pixel_counts.most_common(TOP_N):
        r = palette_data[idx * 3]
        g = palette_data[idx * 3 + 1]
        b = palette_data[idx * 3 + 2]
        pct = count / total * 100
        results.append((rgb_to_hex(r, g, b), r, g, b, pct))
    return results


# ── clustering ────────────────────────────────────────────────────────────────

def build_clusters(all_hex_colors, color_usage):
    """
    Greedy single-pass clustering. Processes colors most-used first so
    the representative of each cluster is the highest-coverage color.
    Returns a dict mapping every input hex color to its cluster's
    representative hex color.
    """
    # centroids stored as float tuples, members as list of RGB tuples
    centroids = []   # list of [float_r, float_g, float_b]
    members   = []   # list of list-of-rgb-tuples

    # Sort by descending usage so most-common colors seed the clusters
    for h in sorted(all_hex_colors, key=lambda x: -color_usage.get(x, 0)):
        rgb = hex_to_rgb(h)
        best_i, best_d = -1, float('inf')
        for i, c in enumerate(centroids):
            d = color_dist(rgb, c)
            if d < best_d:
                best_d, best_i = d, i

        if best_i >= 0 and best_d <= THRESHOLD:
            members[best_i].append(rgb)
            n = len(members[best_i])
            centroids[best_i] = [
                centroids[best_i][ch] + (rgb[ch] - centroids[best_i][ch]) / n
                for ch in range(3)
            ]
        else:
            centroids.append(list(float(v) for v in rgb))
            members.append([rgb])

    # build mapping: original hex -> representative hex
    mapping = {}
    for i, mlist in enumerate(members):
        rep_rgb = tuple(round(v) for v in centroids[i])
        rep_hex = rgb_to_hex(*rep_rgb)
        for rgb in mlist:
            mapping[rgb_to_hex(*rgb)] = (rep_hex, rep_rgb)

    return mapping


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    jpg_files = sorted(
        f for f in os.listdir(IMAGES_DIR)
        if f.lower().endswith(".jpg")
    )

    # First pass: collect every dominant color across all images
    # also accumulate total coverage per hex color across all images
    image_colors = {}
    all_hex = set()
    color_usage = {}   # hex -> sum of coverage% across all images
    for fname in jpg_files:
        path = os.path.join(IMAGES_DIR, fname)
        cols = get_dominant_colors(path)
        image_colors[fname] = cols
        for hex_val, r, g, b, pct in cols:
            all_hex.add(hex_val)
            color_usage[hex_val] = color_usage.get(hex_val, 0) + pct

    print(f"Extracted {len(all_hex)} unique colors from {len(jpg_files)} images.")

    # Build global cluster mapping (most-used colors seed the clusters)
    mapping = build_clusters(all_hex, color_usage)

    # Accumulate total usage per representative color
    rep_usage = {}
    for orig_hex, (rep_hex, rep_rgb) in mapping.items():
        rep_usage[rep_hex] = rep_usage.get(rep_hex, 0) + color_usage.get(orig_hex, 0)

    reduced = set(rep_usage.keys())
    print(f"Reduced to {len(reduced)} colors with threshold={THRESHOLD}.")

    lines = [
        "# Reduced Color List\n",
        f"Colors extracted from {len(jpg_files)} images, merged from "
        f"{len(all_hex)} to **{len(reduced)} colors** "
        f"(merge threshold: Euclidean RGB ≤ {THRESHOLD}).\n\n",
    ]

    for fname in jpg_files:
        cols = image_colors[fname]
        # Deduplicate by representative (preserve coverage order, sum pcts)
        seen = {}
        for hex_val, r, g, b, pct in cols:
            rep_hex, rep_rgb = mapping[hex_val]
            if rep_hex not in seen:
                seen[rep_hex] = [rep_rgb, pct, hex_val]
            else:
                seen[rep_hex][1] += pct   # accumulate coverage

        lines.append(f"## {fname}\n")
        lines.append("| Swatch | Hex | R | G | B | Coverage |\n")
        lines.append("|--------|-----|---|---|---|----------|\n")
        for rep_hex, (rep_rgb, pct, _) in seen.items():
            r, g, b = rep_rgb
            lines.append(
                f"| {make_swatch(rep_hex)} `{rep_hex}` "
                f"| {r:3d} | {g:3d} | {b:3d} | {pct:5.1f}%  |\n"
            )
        lines.append("\n")

    lines.append("---\n\n")
    lines.append(f"## All Reduced Colors ({len(reduced)} total, sorted by usage)\n\n")
    lines.append("| Swatch | Hex | Total Coverage |\n")
    lines.append("|--------|-----|----------------|\n")
    for h, usage in sorted(rep_usage.items(), key=lambda x: -x[1]):
        lines.append(f"| {make_swatch(h)} `{h}` | {usage:.1f}% |\n")

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(f"Output: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
