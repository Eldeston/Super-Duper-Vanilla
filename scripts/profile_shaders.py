#!/usr/bin/env python3
"""
Shader Performance Profiler & Static Analysis Tool for Super Duper Vanilla.

Analyzes shader passes across all dimensions (Overworld, Nether, End) to quantify
GPU cost drivers: texture bandwidth, heavy mathematical operations, branching,
loops, and register/varying pressure.
"""

import argparse
import json
import os
import re
import sys
import time
from typing import Any, Dict, List, Optional, Set, Tuple

# Import include preprocessor from lint module
try:
    from scripts.lint import preprocess_shader, STAGE_MAP
except ImportError:
    from lint import preprocess_shader, STAGE_MAP

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_MAGENTA = "\033[35m" if USE_COLOR else ""
CLR_GRAY = "\033[90m" if USE_COLOR else ""

# Regex patterns for GPU cost analysis
RE_TEX_CALL = re.compile(
    r"\b(texture|texture2D|texture3D|textureLod|textureGrad|texelFetch|shadow2D|shadow2DProj|textureProj)\s*\("
)
RE_SAMPLER = re.compile(
    r"\b(texture|texture2D|texture3D|textureLod|textureGrad|texelFetch|shadow2D|shadow2DProj|textureProj)\s*\(\s*([a-zA-Z0-9_]+)"
)
RE_EXP_MATH = re.compile(r"\b(pow|exp|exp2|log|log2)\s*\(")
RE_TRIG_MATH = re.compile(r"\b(sin|cos|tan|asin|acos|atan)\s*\(")
RE_ROOT_MATH = re.compile(r"\b(sqrt|inversesqrt)\s*\(")
RE_MATRIX_MATH = re.compile(r"\b(inverse|determinant|transpose)\s*\(")
RE_LOOPS = re.compile(r"\b(for|while|do)\b")
RE_BRANCHES = re.compile(r"\b(if|else\s+if)\s*\(")
RE_TERNARY = re.compile(r"\?[^:;]+:")
RE_UNIFORMS = re.compile(r"^\s*uniform\s+[a-zA-Z0-9_]+\s+([a-zA-Z0-9_]+)", re.MULTILINE)
RE_VARYINGS = re.compile(r"^\s*(in|out|varying|attribute)\s+[a-zA-Z0-9_]+\s+([a-zA-Z0-9_]+)", re.MULTILINE)
RE_OUTPUTS = re.compile(r"\bgl_FragData\s*\[\s*(\d+)\s*\]")


def analyze_shader_code(code: str, stage: str) -> Dict[str, Any]:
    """Extract quantitative performance metrics and potential optimization flags."""
    lines = code.splitlines()
    total_lines = len(lines)

    # Strip comments to analyze only executable GLSL statements
    clean_code = re.sub(r"/\*.*?\*/", "", code, flags=re.DOTALL)
    clean_code = re.sub(r"//.*?$", "", clean_code, flags=re.MULTILINE)

    # Texture lookups & distinct samplers
    tex_calls = len(RE_TEX_CALL.findall(clean_code))
    samplers_used = sorted(list(set(m[1] for m in RE_SAMPLER.findall(clean_code))))

    # Mathematical operations
    exp_count = len(RE_EXP_MATH.findall(clean_code))
    trig_count = len(RE_TRIG_MATH.findall(clean_code))
    root_count = len(RE_ROOT_MATH.findall(clean_code))
    mat_count = len(RE_MATRIX_MATH.findall(clean_code))
    heavy_math = exp_count + trig_count + root_count + mat_count

    # Control flow
    loop_count = len(RE_LOOPS.findall(clean_code))
    branch_count = len(RE_BRANCHES.findall(clean_code)) + len(RE_TERNARY.findall(clean_code))

    # Interface
    uniforms = len(RE_UNIFORMS.findall(clean_code))
    varyings = len(RE_VARYINGS.findall(clean_code))
    frag_outputs = max([int(x) + 1 for x in RE_OUTPUTS.findall(clean_code)] + [1 if stage == "frag" else 0])

    # Optimization warnings / flags
    warnings = []
    if stage == "frag" and mat_count > 0:
        warnings.append(f"Matrix inverse/transpose in fragment stage ({mat_count} calls)")
    if stage == "frag" and tex_calls > 30:
        warnings.append(f"High texture fetch pressure ({tex_calls} calls)")
    if "pow(" in clean_code and re.search(r"\bpow\s*\(\s*[^,]+\s*,\s*2(?:\.0*)?\s*\)", clean_code):
        warnings.append("pow(x, 2.0) detected — consider x * x")

    # Estimated Cost Index:
    # Fragment stage runs per pixel (millions of invocations), weighted 3x over vertex stage
    stage_multiplier = 3.0 if stage == "frag" else 1.0
    cost_index = stage_multiplier * (
        (tex_calls * 12.0)
        + (heavy_math * 2.5)
        + (loop_count * 10.0)
        + (branch_count * 1.5)
        + (frag_outputs * 4.0)
        + (total_lines * 0.05)
    )

    return {
        "lines": total_lines,
        "stage": stage,
        "tex_calls": tex_calls,
        "samplers": samplers_used,
        "heavy_math": heavy_math,
        "exp_math": exp_count,
        "trig_math": trig_count,
        "root_math": root_count,
        "mat_math": mat_count,
        "loops": loop_count,
        "branches": branch_count,
        "uniforms": uniforms,
        "varyings": varyings,
        "outputs": frag_outputs,
        "cost_index": round(cost_index, 1),
        "warnings": warnings,
    }


def collect_shader_profiles(shaders_root: str, target_stage: Optional[str] = None) -> List[Dict[str, Any]]:
    """Scan and profile all root shader programs."""
    results = []
    dimensions = ["world0", "world-1", "world1"]

    for dim in dimensions:
        dim_dir = os.path.join(shaders_root, dim)
        if not os.path.isdir(dim_dir):
            continue

        for fname in sorted(os.listdir(dim_dir)):
            ext = os.path.splitext(fname)[1]
            if ext not in STAGE_MAP:
                continue

            stage = STAGE_MAP[ext]
            if target_stage and stage != target_stage:
                continue

            file_path = os.path.join(dim_dir, fname)
            rel_path = os.path.relpath(file_path, shaders_root)

            file_table: Dict[str, int] = {}
            code = preprocess_shader(file_path, file_table, stage, shaders_root)
            metrics = analyze_shader_code(code, stage)
            metrics["file"] = rel_path
            metrics["dimension"] = dim
            metrics["program"] = os.path.splitext(fname)[0]
            metrics["includes_count"] = len(file_table)
            results.append(metrics)

    results.sort(key=lambda x: x["cost_index"], reverse=True)
    return results


def print_table_header() -> None:
    """Print the formatted results table header."""
    header = (
        f"{CLR_BOLD}{'Shader Program / Pass':<35} "
        f"{'Stage':<6} "
        f"{'Cost':>8} "
        f"{'Tex':>6} "
        f"{'Math':>6} "
        f"{'Loop':>5} "
        f"{'Brch':>5} "
        f"{'Lines':>7} "
        f"{'Samplers':<18}{CLR_RESET}"
    )
    print(header)
    print("─" * 98)


def print_profile_row(item: Dict[str, Any]) -> None:
    """Format and print a single shader profile row."""
    cost = item["cost_index"]
    cost_clr = CLR_RED if cost > 500 else (CLR_YELLOW if cost > 200 else CLR_GREEN)

    samplers_str = ",".join(item["samplers"][:3])
    if len(item["samplers"]) > 3:
        samplers_str += f"+{len(item['samplers']) - 3}"

    row = (
        f"{item['file']:<35} "
        f"{item['stage']:<6} "
        f"{cost_clr}{cost:>8.1f}{CLR_RESET} "
        f"{item['tex_calls']:>6} "
        f"{item['heavy_math']:>6} "
        f"{item['loops']:>5} "
        f"{item['branches']:>5} "
        f"{item['lines']:>7} "
        f"{CLR_GRAY}{samplers_str:<18}{CLR_RESET}"
    )
    print(row)


def print_summary_report(profiles: List[Dict[str, Any]], top_n: int, show_all: bool = False) -> None:
    """Render terminal report with summary statistics and top hotspots."""
    total_shaders = len(profiles)
    total_tex = sum(p["tex_calls"] for p in profiles)
    total_math = sum(p["heavy_math"] for p in profiles)
    total_cost = sum(p["cost_index"] for p in profiles)

    print(f"\n{CLR_BOLD}╔══════════════════════════════════════════════════════════════════════════════╗{CLR_RESET}")
    print(f"{CLR_BOLD}║           SUPER DUPER VANILLA — SHADER PERFORMANCE PROFILER                  ║{CLR_RESET}")
    print(f"{CLR_BOLD}╚══════════════════════════════════════════════════════════════════════════════╝{CLR_RESET}\n")

    print(f"Inspected {CLR_CYAN}{total_shaders}{CLR_RESET} shader stages across dimensions.")
    print(f"Cumulative Metrics: {CLR_YELLOW}{total_tex}{CLR_RESET} texture calls, {CLR_YELLOW}{total_math}{CLR_RESET} heavy math ops, Total Cost: {CLR_BOLD}{total_cost:,.1f}{CLR_RESET}\n")

    print_table_header()
    for item in profiles[:top_n]:
        print_profile_row(item)
    print("─" * 98)

    # Highlight actionable warnings
    flagged = [p for p in profiles if p["warnings"]]
    if flagged:
        print(f"\n{CLR_BOLD}{CLR_YELLOW}Optimization Opportunities & Warnings ({len(flagged)} files):{CLR_RESET}")
        display_flagged = flagged if show_all else flagged[:8]
        for p in display_flagged:
            for w in p["warnings"]:
                print(f"  • {CLR_CYAN}{p['file']}{CLR_RESET}: {w}")
        if len(flagged) > len(display_flagged):
            print(f"  {CLR_GRAY}... and {len(flagged) - len(display_flagged)} more notices (run with --all to view).{CLR_RESET}")
    print()


def compare_profiles(file1: str, file2: str) -> None:
    """Compare two JSON profile runs to track optimization improvements."""
    with open(file1, "r", encoding="utf-8") as f:
        data1 = {p["file"]: p for p in json.load(f)}
    with open(file2, "r", encoding="utf-8") as f:
        data2 = {p["file"]: p for p in json.load(f)}

    print(f"\n{CLR_BOLD}Comparing Profile Baseline ({file1}) vs Current ({file2}):{CLR_RESET}\n")
    print(f"{'Shader File':<35} {'Baseline Cost':>15} {'Current Cost':>15} {'Delta':>15}")
    print("─" * 84)

    total_baseline = 0.0
    total_current = 0.0

    for fpath, p2 in sorted(data2.items(), key=lambda x: x[1]["cost_index"], reverse=True):
        if fpath in data1:
            p1 = data1[fpath]
            c1 = p1["cost_index"]
            c2 = p2["cost_index"]
            delta = c2 - c1
            pct = (delta / c1 * 100.0) if c1 > 0 else 0.0
            clr = CLR_GREEN if delta < -0.1 else (CLR_RED if delta > 0.1 else CLR_RESET)
            total_baseline += c1
            total_current += c2
            print(f"{fpath:<35} {c1:>15.1f} {c2:>15.1f} {clr}{delta:>+10.1f} ({pct:>+5.1f}%){CLR_RESET}")

    total_delta = total_current - total_baseline
    tot_clr = CLR_GREEN if total_delta < 0 else (CLR_RED if total_delta > 0 else CLR_RESET)
    print("─" * 84)
    print(f"{'TOTAL':<35} {total_baseline:>15.1f} {total_current:>15.1f} {tot_clr}{total_delta:>+10.1f}{CLR_RESET}\n")


def parse_args() -> argparse.Namespace:
    """Parse CLI options for shader profiler."""
    parser = argparse.ArgumentParser(
        description="Profile Super Duper Vanilla shaders for performance cost, texture lookups, and math ops."
    )
    parser.add_argument("--shaders-dir", default="shaders", help="Path to shaders directory")
    parser.add_argument("--top", type=int, default=15, help="Number of top costly shaders to display (default: 15)")
    parser.add_argument("--stage", choices=["frag", "vert"], help="Filter by stage (frag or vert)")
    parser.add_argument("--all", action="store_true", help="Display all shaders without truncation")
    parser.add_argument("--json", dest="json_out", help="Export profile metrics to specified JSON file")
    parser.add_argument("--compare", nargs=2, metavar=("BASE", "CURR"), help="Compare two profile JSON files")
    return parser.parse_args()


def main() -> int:
    """Main CLI entrypoint."""
    args = parse_args()

    if args.compare:
        compare_profiles(args.compare[0], args.compare[1])
        return 0

    shaders_root = os.path.abspath(args.shaders_dir)
    if not os.path.isdir(shaders_root):
        print(f"Error: Shaders directory not found at {shaders_root}", file=sys.stderr)
        return 1

    start_t = time.perf_counter()
    profiles = collect_shader_profiles(shaders_root, target_stage=args.stage)
    duration = time.perf_counter() - start_t

    top_n = len(profiles) if args.all else args.top
    print_summary_report(profiles, top_n, show_all=args.all)
    print(f"{CLR_GRAY}Analysis completed in {duration:.2f}s.{CLR_RESET}\n")

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(profiles, f, indent=2)
        print(f"✓ Saved full profile dataset to {args.json_out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
