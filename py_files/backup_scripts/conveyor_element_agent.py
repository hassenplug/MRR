"""
conveyor_element_agent.py — Claude API agent for generating OpenSCAD files for
MRR conveyor belt tile Elements 10–16.

Uses ELEMENT_NOTES.md + element10.scad + element11.scad as cached system context.
Runs an agentic tool-use loop to generate, write, and visually verify each SCAD file.

Usage:
    python conveyor_element_agent.py [--elements 12,13,14,15,16] [--dry-run]

Requirements:
    pip install anthropic
    ANTHROPIC_API_KEY must be set in the environment.
"""

import os
import sys
import argparse
import subprocess
import anthropic
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO_ROOT    = Path(__file__).parent.parent
SCAD_DIR     = REPO_ROOT / "scad"
IMG_DIR      = REPO_ROOT / "Images"
PY_DIR       = REPO_ROOT / "py_files"

NOTES_PATH   = PY_DIR  / "ELEMENT_NOTES.md"
ELEM10_PATH  = SCAD_DIR / "element10.scad"
ELEM11_PATH  = SCAD_DIR / "element11.scad"
BUILDER_PATH = PY_DIR  / "element_builder_agent.py"

# ── Element definitions (straight, left_turn, right_turn) ─────────────────────
ELEMENTS = {
    10: (True,  False, False),
    11: (False, False, True),
    12: (False, True,  False),
    13: (True,  True,  False),
    14: (True,  False, True),
    15: (True,  True,  True),
    16: (False, True,  True),
}

# ═══════════════════════════════════════════════════════════════════════════════
#  Tool implementations
# ═══════════════════════════════════════════════════════════════════════════════

def _load_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return f"[File not found: {path}]"


def tool_read_file(path: str) -> str:
    p = Path(path)
    if not p.is_absolute():
        p = REPO_ROOT / p
    if not p.exists():
        return f"Error: file not found: {path}"
    return p.read_text(encoding="utf-8")


def tool_write_scad_file(path: str, content: str) -> str:
    p = Path(path)
    if not p.is_absolute():
        p = SCAD_DIR / p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    return f"Written {p.stat().st_size} bytes to {p}"


def tool_generate_preview(element: int, step: int = 5) -> str:
    """Run element_builder_agent.py to generate a JPG preview."""
    if element not in ELEMENTS:
        return f"Error: unknown element {element}"
    if not BUILDER_PATH.exists():
        return f"Error: builder not found at {BUILDER_PATH}"
    cmd = [
        sys.executable, str(BUILDER_PATH),
        "--elements", str(element),
        "--step", str(step),
        "--out", str(IMG_DIR),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if result.returncode != 0:
        return f"Error generating preview:\n{result.stderr}"
    imgs = sorted(IMG_DIR.glob(f"Element{element}_step{step}_*.jpg"))
    suffix = f"\nPreview: {imgs[-1].name}" if imgs else ""
    return (result.stdout.strip() or "Preview generated.") + suffix


def tool_list_scad_files(pattern: str = "element*.scad") -> str:
    files = sorted(SCAD_DIR.glob(pattern))
    if not files:
        return f"No files matching '{pattern}' in {SCAD_DIR}"
    return "\n".join(f.name for f in files)


# ── Tool dispatch ─────────────────────────────────────────────────────────────

def execute_tool(name: str, inp: dict) -> str:
    if name == "read_file":
        return tool_read_file(inp["path"])
    if name == "write_scad_file":
        return tool_write_scad_file(inp["path"], inp["content"])
    if name == "generate_preview":
        return tool_generate_preview(inp["element"], inp.get("step", 5))
    if name == "list_scad_files":
        return tool_list_scad_files(inp.get("pattern", "element*.scad"))
    return f"Unknown tool: {name}"


# ═══════════════════════════════════════════════════════════════════════════════
#  Tool schemas
# ═══════════════════════════════════════════════════════════════════════════════

TOOLS = [
    {
        "name": "read_file",
        "description": (
            "Read the contents of any file for reference "
            "(e.g. an existing SCAD file or notes)."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Repo-relative path (e.g. scad/element11.scad) or absolute path.",
                },
            },
            "required": ["path"],
        },
    },
    {
        "name": "write_scad_file",
        "description": (
            "Write a complete OpenSCAD source file to the scad/ directory. "
            "Always write the entire file — do not write partial content."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Filename only (e.g. element12.scad) or absolute path.",
                },
                "content": {
                    "type": "string",
                    "description": "Complete, valid OpenSCAD source code.",
                },
            },
            "required": ["path", "content"],
        },
    },
    {
        "name": "generate_preview",
        "description": (
            "Run the pixel-image builder to generate a JPG preview of an element tile. "
            "Use step=5 to see the complete tile (belt + rollers + rivets + arrow). "
            "Use step=1 or step=2 to check only the arrowhead / shaft geometry."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "element": {
                    "type": "integer",
                    "description": "Element number (10–16).",
                    "enum": list(ELEMENTS.keys()),
                },
                "step": {
                    "type": "integer",
                    "description": "Build step: 1=arrowhead, 2=+shafts, 3=+belt, 4=+rollers, 5=complete.",
                    "enum": [1, 2, 3, 4, 5],
                },
            },
            "required": ["element"],
        },
    },
    {
        "name": "list_scad_files",
        "description": "List SCAD files in the scad/ directory, optionally filtered by glob pattern.",
        "input_schema": {
            "type": "object",
            "properties": {
                "pattern": {
                    "type": "string",
                    "description": "Glob pattern, e.g. 'element1*.scad'. Defaults to 'element*.scad'.",
                },
            },
        },
    },
]


# ═══════════════════════════════════════════════════════════════════════════════
#  System prompt — stable reference material (cached)
# ═══════════════════════════════════════════════════════════════════════════════

def build_system_prompt() -> list[dict]:
    notes  = _load_file(NOTES_PATH)
    elem10 = _load_file(ELEM10_PATH)
    elem11 = _load_file(ELEM11_PATH)

    system_text = f"""You are an expert OpenSCAD engineer for the Mega Robo Rally (MRR) project.
Your job is to generate correct, clean OpenSCAD (.scad) files for conveyor belt tile elements 10–16.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DESIGN NOTES (ELEMENT_NOTES.md)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{notes}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REFERENCE: element10.scad (STRAIGHT belt — simplest case)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```scad
{elem10}
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REFERENCE: element11.scad (RIGHT-TURN arc — single arc case)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```scad
{elem11}
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ENGINEERING RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Element combinations (straight, left_turn, right_turn):
  10: (T, F, F)  — straight only          → element10.scad (already exists)
  11: (F, F, T)  — right-turn only        → element11.scad (already exists)
  12: (F, T, F)  — left-turn only         → mirror of element11 (arc center top-LEFT)
  13: (T, T, F)  — straight + left-turn
  14: (T, F, T)  — straight + right-turn
  15: (T, T, T)  — straight + left + right
  16: (F, T, T)  — left + right, no straight

Arc geometry for LEFT-TURN (element12, 13, 15, 16):
  - Arc center: (0, plate_d)  — top-LEFT corner
  - Arc sweeps from 270° (bottom) to 0° (right, i.e. plate center top)
  - Belt exits tile at LEFT edge (x=0) and TOP edge — symmetric to element11

Combined belt cutouts: union of all active belt shapes.
Combined belt shapes: union of all active belt polygons.
Combined roller slots: depend on which sides have arc entries (see ELEMENT_NOTES.md).

For self-contained SCAD files:
  - Copy/adapt the shared variables and modules (rivet_holes, frame, etc.) from element10.scad.
  - Add the relevant belt_cutout() and belt() modules for the combination.
  - Keep the same module naming convention: plate(), rollers(), rivets(), belt(), frame(), main assembly.
  - Each file must render correctly as a standalone OpenSCAD file (no `include` or `use`).

After writing each file, call generate_preview(element=N, step=5) to visually verify the result.
The preview image uses the Python pixel-geometry engine (element_builder_agent.py), which
independently implements the same geometry — if the preview looks wrong, the SCAD is likely wrong.
"""

    return [
        {
            "type": "text",
            "text": system_text,
            "cache_control": {"type": "ephemeral"},
        }
    ]


# ═══════════════════════════════════════════════════════════════════════════════
#  Agent loop
# ═══════════════════════════════════════════════════════════════════════════════

def run_agent(elements: list[int], dry_run: bool = False) -> None:
    client = anthropic.Anthropic()
    system = build_system_prompt()

    elem_lines = "\n".join(
        f"  Element {n}: straight={ELEMENTS[n][0]}, left_turn={ELEMENTS[n][1]}, right_turn={ELEMENTS[n][2]}"
        for n in elements
    )

    user_msg = f"""Please generate OpenSCAD SCAD files for these conveyor belt tile elements:

{elem_lines}

Workflow for each element (in ascending order):
1. Call list_scad_files to see what already exists (avoid overwriting finished files).
2. Design the SCAD file — combine the correct belt paths and modules for this element's variant.
3. Write the file using write_scad_file (filename: elementN.scad).
4. Call generate_preview(element=N, step=5) to confirm the complete tile renders correctly.
5. Note any issues and fix them before moving to the next element.

Be thorough and verify each file before continuing. All files must be self-contained
(no `include` or `use` statements — copy shared modules inline).
"""

    messages: list[dict] = [{"role": "user", "content": user_msg}]

    print(f"\nGenerating SCAD for element(s): {elements}")
    print("=" * 60)

    while True:
        response = client.messages.create(
            model="claude-opus-4-7",
            max_tokens=16000,
            thinking={"type": "adaptive"},
            system=system,
            tools=TOOLS,
            messages=messages,
        )

        # Usage summary
        u = response.usage
        cache_read  = getattr(u, "cache_read_input_tokens", 0)
        cache_write = getattr(u, "cache_creation_input_tokens", 0)
        print(
            f"\n[tokens] in={u.input_tokens}  out={u.output_tokens}"
            f"  cache_read={cache_read}  cache_write={cache_write}"
        )

        # Append full response (preserves tool_use blocks and thinking blocks)
        messages.append({"role": "assistant", "content": response.content})

        # Print any text Claude produced
        for block in response.content:
            if hasattr(block, "type") and block.type == "text":
                print(f"\n[Claude]\n{block.text}")

        if response.stop_reason == "end_turn":
            print("\n[Done] Agent completed.")
            break

        if response.stop_reason != "tool_use":
            print(f"\n[Stopped] reason={response.stop_reason}")
            break

        # Execute each tool call
        tool_results = []
        for block in response.content:
            if not (hasattr(block, "type") and block.type == "tool_use"):
                continue

            print(f"\n[Tool] {block.name}")
            # Show args compactly (truncate large 'content' fields for readability)
            display_input = {
                k: (v[:120] + "…") if isinstance(v, str) and len(v) > 120 else v
                for k, v in block.input.items()
            }
            print(f"  args: {display_input}")

            if dry_run and block.name == "write_scad_file":
                n_chars = len(block.input.get("content", ""))
                result = f"[dry-run] would write {n_chars} chars to {block.input.get('path')}"
            else:
                result = execute_tool(block.name, block.input)

            print(f"  → {result[:300]}{'…' if len(result) > 300 else ''}")

            tool_results.append({
                "type": "tool_result",
                "tool_use_id": block.id,
                "content": result,
            })

        messages.append({"role": "user", "content": tool_results})


# ═══════════════════════════════════════════════════════════════════════════════
#  Entry point
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Claude API agent: generate OpenSCAD files for MRR conveyor elements 10–16.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python conveyor_element_agent.py                      # generate elements 12–16
  python conveyor_element_agent.py --elements 12        # generate element 12 only
  python conveyor_element_agent.py --elements 13,14     # generate 13 and 14
  python conveyor_element_agent.py --elements 15 --dry-run  # preview without writing
        """,
    )
    parser.add_argument(
        "--elements",
        default="12,13,14,15,16",
        help="Comma-separated element numbers (default: 12,13,14,15,16)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Execute all tools except write_scad_file (safe preview mode)",
    )
    args = parser.parse_args()

    nums = [int(x.strip()) for x in args.elements.split(",")]
    invalid = [n for n in nums if n not in ELEMENTS]
    if invalid:
        parser.error(f"Unknown element(s): {invalid}. Valid: {sorted(ELEMENTS)}")

    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("Error: ANTHROPIC_API_KEY environment variable is not set.")

    run_agent(nums, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
