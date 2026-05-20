# Mega Robo Rally — Project Guide

## Overview

3D-printable conveyor belt tile generator for the Mega Robo Rally board game.
Tiles are 3" × 3" × 1/8", designed in OpenSCAD and rendered to 500 × 500 px JPG previews by Python.

## Key Files

| File | Purpose |
|------|---------|
| `py_files/element_builder_agent.py` | Main image generator for Elements 10–16 (conveyor belt arrow tiles) |
| `py_files/ELEMENT_NOTES.md` | Detailed geometry reference for Elements 10–16 |
| `scad/element10.scad` | SCAD source of truth: straight belt tile |
| `scad/element11.scad` | SCAD source of truth: right-turn arc tile |
| `md/elements.md` | High-level element requirements for all tile types |
| `Images/drawings/` | Output JPGs from element_builder_agent.py |

## Running the Image Generator

```
pip install -r requirements.txt
python py_files/element_builder_agent.py                        # all elements
python py_files/element_builder_agent.py --elements 11,12       # specific elements
python py_files/element_builder_agent.py --out path/to/dir      # custom output dir
```

Output: `Images/drawings/Element{N}.jpg`

## Coordinate System

All geometry originates from the SCAD files (inches). The Python renderer converts to pixels:

- `S = 500 / (3.0 * 25.4)` ≈ 6.561 px/mm
- `_in(inches)` → pixels (float)
- **SCAD Y** increases upward from tile bottom
- **PIL Y** increases downward from tile top → `PIL_Y = SIZE - SCAD_Y`

Tile: 500 × 500 px total. Plate inset by `BORDER = _in(1/16")` ≈ 10 px on each side.

## Elements 10–16 (Conveyor Belt Tiles)

| # | Straight | Left turn | Right turn |
|---|----------|-----------|------------|
| 10 | ✓ | | |
| 11 | | | ✓ |
| 12 | | ✓ | |
| 13 | ✓ | ✓ | |
| 14 | ✓ | | ✓ |
| 15 | ✓ | ✓ | ✓ |
| 16 | | ✓ | ✓ |

Drawing order (later layers paint over earlier ones):
1. Dark gray background
2. Light gray rivets
3. Green rollers
4. Black belt
5. Green arrow outline
6. Black arrow interior
7. Black frame

## Working Style

- If you have restarted or rethought an approach more than 2 times on the same problem, stop and ask a clarifying question instead of trying again.
- If you second-guess yourself on any decision, stop and ask for clarification instead of proceeding.

## Coding Conventions

- All geometry constants are derived from SCAD source values — edit the inch constants at the top of `element_builder_agent.py`, not the derived pixel values.
- Masks are NumPy boolean arrays (500 × 500). Pixel grids `XX`, `YY` use 0.5-offset centers.
- No comments explaining *what* code does — only comments for non-obvious *why* (hidden constraints, coordinate system gotchas, SCAD-specific quirks).
- `_rx_start` / `_rx_end` / `_ry_step` define the roller grid; entry bars and top-section bars both use these for consistent spacing and inset.
