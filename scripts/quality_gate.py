#!/usr/bin/env python3
"""
Continuous Validation Quality Gate for HyperDuper Vanilla (SDV Fork).
Executes a multi-stage validation pipeline:
  [Gate 1] GLSL Shader Compilation & Syntax (glslangValidator)
  [Gate 2] i18n Translation & Consistency Check
  [Gate 3] File Length & Cyclomatic Complexity (SRP / KISS)
  [Gate 4] Shaderpack File Integrity & Include Verification
"""

import argparse
import os
import re
import subprocess
import sys
import time
from typing import List, Tuple

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_GRAY = "\033[90m" if USE_COLOR else ""


def check_includes_integrity(workspace_root: str) -> Tuple[bool, List[str]]:
    """Verify that every #include in every shader file resolves to an existing file."""
    shaders_dir = os.path.join(workspace_root, "shaders")
    broken: List[str] = []

    def resolve(inc: str, current_dir: str) -> str:
        clean = inc.strip().strip("\"<>'")
        if clean.startswith("/"):
            return os.path.normpath(os.path.join(shaders_dir, clean.lstrip("/")))
        return os.path.normpath(os.path.join(current_dir, clean))

    for root, _, files in os.walk(shaders_dir):
        for f in files:
            if f.endswith((".vsh", ".fsh", ".csh", ".gsh", ".glsl")):
                fpath = os.path.join(root, f)
                try:
                    with open(fpath, "r", encoding="utf-8", errors="replace") as fp:
                        for lnum, line in enumerate(fp, 1):
                            m = re.match(r'^\s*#\s*include\s+["<]([^">]+)[">]', line)
                            if m:
                                target = resolve(m.group(1), root)
                                if not os.path.isfile(target):
                                    rel_src = os.path.relpath(fpath, workspace_root)
                                    broken.append(f"{rel_src}:{lnum} -> '#include \"{m.group(1)}\"' (not found)")
                except OSError as err:
                    broken.append(f"Cannot read {fpath}: {err}")

    return len(broken) == 0, broken


def run_subcommand(cmd: List[str], cwd: str) -> Tuple[bool, float]:
    """Run a sub-process gate and return (success, duration)."""
    t0 = time.time()
    res = subprocess.run(cmd, cwd=cwd)
    return (res.returncode == 0), (time.time() - t0)


def _check_critical_files(workspace_root: str) -> List[str]:
    """Verify presence of key project files."""
    required = [
        "LICENSE",
        "README.md",
        "DOCUMENTATION.md",
        "shaders/shaders.properties",
        "shaders/lang/en_US.lang",
    ]
    return [rf for rf in required if not os.path.isfile(os.path.join(workspace_root, rf))]


def main() -> int:
    parser = argparse.ArgumentParser(description="Quality Gate validation pipeline for HyperDuper Vanilla.")
    parser.add_argument("--strict", action="store_true", help="Enforce strict quality gates (fail on warnings/orphans).")
    parser.add_argument("--staged", action="store_true", help="Validate only git-staged changes.")
    args = parser.parse_args()

    workspace_root = os.path.abspath(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    scripts_dir = os.path.join(workspace_root, "scripts")

    pipeline_start = time.time()
    gates_results: List[Tuple[str, bool, float, str]] = []

    print(f"\n{CLR_CYAN}{CLR_BOLD}╔══════════════════════════════════════════════════════════════════╗{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}║       HYPERDUPER VANILLA — CONTINUOUS QUALITY GATE PIPELINE      ║{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}╚══════════════════════════════════════════════════════════════════╝{CLR_RESET}\n")

    # Gate 1: GLSL Linting
    print(f"{CLR_BOLD}▶ Running Gate 1: GLSL Shader Compilation (glslangValidator)...{CLR_RESET}")
    lint_cmd = [sys.executable, os.path.join(scripts_dir, "lint.py")] + (["--staged"] if args.staged else [])
    ok1, d1 = run_subcommand(lint_cmd, workspace_root)
    gates_results.append(("GLSL Shaders (glslangValidator)", ok1, d1, "Checked shaders against OpenGL/Iris dialect"))

    # Gate 2: i18n Validation
    print(f"\n{CLR_BOLD}▶ Running Gate 2: i18n Translation & Consistency...{CLR_RESET}")
    i18n_cmd = [sys.executable, os.path.join(scripts_dir, "lint_i18n.py")]
    if args.strict:
        i18n_cmd.append("--strict")
    if args.staged:
        i18n_cmd.append("--staged")
    ok2, d2 = run_subcommand(i18n_cmd, workspace_root)
    gates_results.append(("i18n & Translation Consistency", ok2, d2, "Verified .lang syntax, duplicates & canonical coverage"))

    # Gate 3: File Length & Cyclomatic Complexity (SRP & KISS)
    print(f"\n{CLR_BOLD}▶ Running Gate 3: File Length & Cyclomatic Complexity (SRP / KISS)...{CLR_RESET}")
    comp_cmd = [sys.executable, os.path.join(scripts_dir, "complexity.py")]
    if args.strict:
        comp_cmd.append("--strict")
    if args.staged:
        comp_cmd.append("--staged")
    ok3, d3 = run_subcommand(comp_cmd, workspace_root)
    gates_results.append(("Complexity & Length (SRP / KISS)", ok3, d3, "Checked file length limits & McCabe cyclomatic complexity"))

    # Gate 4: Structure & Include Integrity
    print(f"\n{CLR_BOLD}▶ Running Gate 4: Shaderpack Structure & Include Integrity...{CLR_RESET}")
    t0 = time.time()
    missing_files = _check_critical_files(workspace_root)
    inc_ok, broken_inc = check_includes_integrity(workspace_root)
    integrity_ok = (len(missing_files) == 0 and inc_ok)
    d4 = time.time() - t0

    if integrity_ok:
        print(f"{CLR_GREEN}✓ All critical files and #include references verified successfully.{CLR_RESET}")
    else:
        for mf in missing_files:
            print(f"{CLR_RED}Missing required file: {mf}{CLR_RESET}")
        for bi in broken_inc:
            print(f"{CLR_RED}Broken include: {bi}{CLR_RESET}")

    gates_results.append(("Structure & Include Integrity", integrity_ok, d4, "Checked essential files and resolved all #includes"))

    # Pipeline Summary
    total_time = time.time() - pipeline_start
    all_passed = all(ok for _, ok, _, _ in gates_results)

    print(f"\n{CLR_CYAN}{CLR_BOLD}────────────────────────────────────────────────────────────────────{CLR_RESET}")
    print(f"{CLR_BOLD}QUALITY GATE PIPELINE SUMMARY{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}────────────────────────────────────────────────────────────────────{CLR_RESET}")
    for name, ok, dur, desc in gates_results:
        badge = f"{CLR_GREEN}[PASS]{CLR_RESET}" if ok else f"{CLR_RED}[FAIL]{CLR_RESET}"
        print(f"  {badge} {name:<35} ({dur:.2f}s) — {CLR_GRAY}{desc}{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}────────────────────────────────────────────────────────────────────{CLR_RESET}")

    if all_passed:
        print(f"{CLR_GREEN}{CLR_BOLD}✔ ALL QUALITY GATES PASSED in {total_time:.2f}s! Ready for commit/release.{CLR_RESET}\n")
        return 0

    print(f"{CLR_RED}{CLR_BOLD}✖ QUALITY GATE FAILED in {total_time:.2f}s. Please resolve issues above.{CLR_RESET}\n")
    return 1


if __name__ == "__main__":
    sys.exit(main())
