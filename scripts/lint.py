#!/usr/bin/env python3
"""
GLSL Shader Linter using glslangValidator for Minecraft Shaderpacks (Iris / OptiFine).

Validates GLSL shaders by flattening `#include` directives, injecting Iris/DH runtime
definitions, mapping compiler diagnostics to original files/lines, and running
glslangValidator in parallel.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, List, Optional, Set, Tuple

# ANSI color codes
USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_GRAY = "\033[90m" if USE_COLOR else ""

# Built-in definitions injected by Iris and Distant Horizons at runtime
try:
    from scripts.mc_builtins import IRIS_DH_BUILTINS_VERT, IRIS_DH_BUILTINS_FRAG
except ImportError:
    from mc_builtins import IRIS_DH_BUILTINS_VERT, IRIS_DH_BUILTINS_FRAG

STAGE_MAP = {
    ".fsh": "frag",
    ".vsh": "vert",
    ".csh": "comp",
    ".gsh": "geom",
}


def resolve_include(include_str: str, current_dir: str, shaders_root: str) -> str:
    """Resolve an include directive string to an absolute filesystem path."""
    clean_include = include_str.strip().strip("\"<>'")
    if clean_include.startswith("/"):
        return os.path.normpath(os.path.join(shaders_root, clean_include.lstrip("/")))
    return os.path.normpath(os.path.join(current_dir, clean_include))


def _handle_version_directive(line: str, line_num: int, file_id: int, stage: str) -> List[str]:
    """Emit #version followed by runtime builtins and accurate line directive."""
    builtins = IRIS_DH_BUILTINS_VERT if stage == "vert" else IRIS_DH_BUILTINS_FRAG
    return [line, builtins, f"#line {line_num + 1} {file_id}\n"]


def _handle_include_directive(
    include_target: str,
    current_dir: str,
    shaders_root: str,
    file_table: Dict[str, int],
    stage: str,
    visited: Set[str],
    line_num: int,
    file_id: int,
) -> List[str]:
    """Process a matched #include directive recursively."""
    inc_path = resolve_include(include_target, current_dir, shaders_root)
    if not os.path.exists(inc_path):
        return [f'#error Include file not found: "{include_target}"\n']

    inc_id = file_table.setdefault(inc_path, len(file_table) + 1)
    nested_code = preprocess_shader(inc_path, file_table, stage, shaders_root, visited, is_root=False)
    return [f"\n#line 1 {inc_id}\n", nested_code, f"\n#line {line_num + 1} {file_id}\n"]


def preprocess_shader(
    file_path: str,
    file_table: Dict[str, int],
    stage: str,
    shaders_root: str,
    visited: Optional[Set[str]] = None,
    is_root: bool = True,
) -> str:
    """Preprocess a shader file by inlining `#include` files recursively."""
    if visited is None:
        visited = set()

    norm_path = os.path.normpath(file_path)
    if norm_path in visited:
        return ""
    visited.add(norm_path)

    if norm_path not in file_table:
        file_table[norm_path] = len(file_table) + 1
    file_id = file_table[norm_path]

    current_dir = os.path.dirname(norm_path)
    try:
        with open(norm_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError as err:
        return f"#error [Linter] Cannot read file {norm_path}: {err}\n"

    out: List[str] = []
    has_seen_version = False

    for line_num, line in enumerate(lines, 1):
        if is_root and not has_seen_version and line.strip().startswith("#version"):
            has_seen_version = True
            out.extend(_handle_version_directive(line, line_num, file_id, stage))
            continue

        m = re.match(r'^\s*#\s*include\s+["<]([^">]+)[">]', line)
        if m:
            out.extend(_handle_include_directive(
                m.group(1), current_dir, shaders_root, file_table, stage, visited, line_num, file_id
            ))
        elif not is_root and line.strip().startswith("#version"):
            out.append(f"// [Linter] Ignored nested #version: {line}")
        else:
            out.append(line)

    return "".join(out)


def _scan_file_includes(
    file_path: str,
    root_owner: str,
    shaders_root: str,
    includes_map: Dict[str, Set[str]],
    visited: Set[str],
) -> None:
    """Recursively scan an included file and map its dependencies."""
    norm = os.path.normpath(file_path)
    if norm in visited:
        return
    visited.add(norm)
    if norm != root_owner:
        includes_map.setdefault(norm, set()).add(root_owner)

    current_dir = os.path.dirname(norm)
    try:
        with open(norm, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return

    for line in lines:
        m = re.match(r'^\s*#\s*include\s+["<]([^">]+)[">]', line)
        if m:
            inc_path = resolve_include(m.group(1), current_dir, shaders_root)
            if os.path.exists(inc_path):
                _scan_file_includes(inc_path, root_owner, shaders_root, includes_map, visited)


def build_dependency_graph(shaders_root: str) -> Tuple[List[str], Dict[str, Set[str]]]:
    """Build root shaders list and reverse mapping from includes to root shaders."""
    root_shaders: List[str] = []
    includes_map: Dict[str, Set[str]] = {}

    for dirpath, _, filenames in os.walk(shaders_root):
        for fname in filenames:
            ext = os.path.splitext(fname)[1]
            if ext in STAGE_MAP:
                root_shaders.append(os.path.normpath(os.path.join(dirpath, fname)))

    for root_shader in root_shaders:
        visited: Set[str] = set()
        _scan_file_includes(root_shader, root_shader, shaders_root, includes_map, visited)

    return root_shaders, includes_map


def _format_compiler_error(raw_output: str, file_table: Dict[str, int], workspace_root: str) -> str:
    """Replaces numeric file IDs with user-facing relative paths."""
    formatted_lines: List[str] = []
    for line in raw_output.splitlines():
        if not line.strip() or line.strip() == "stdin":
            continue
        for path, fid in file_table.items():
            rel_inc = os.path.relpath(path, workspace_root)
            line = re.sub(rf"\b{fid}:(\d+)", f"{rel_inc}:\\1", line)
        formatted_lines.append(line)
    return "\n".join(formatted_lines)


def validate_single_shader(
    shader_path: str,
    validator_bin: str,
    shaders_root: str,
    workspace_root: str,
) -> Tuple[bool, str, Optional[str]]:
    """Validates a single root shader with glslangValidator."""
    ext = os.path.splitext(shader_path)[1]
    stage = STAGE_MAP.get(ext, "frag")
    file_table: Dict[str, int] = {}

    preprocessed_code = preprocess_shader(shader_path, file_table, stage, shaders_root)
    rel_shader_path = os.path.relpath(shader_path, workspace_root)

    cmd = [validator_bin, "--stdin", "-S", stage]
    try:
        proc = subprocess.run(
            cmd,
            input=preprocessed_code,
            text=True,
            capture_output=True,
            timeout=30,
        )
    except subprocess.TimeoutExpired:
        return False, rel_shader_path, "Error: Validation timed out after 30 seconds."
    except Exception as exc:
        return False, rel_shader_path, f"Error launching {validator_bin}: {exc}"

    if proc.returncode != 0:
        err_msg = _format_compiler_error(proc.stdout + proc.stderr, file_table, workspace_root)
        return False, rel_shader_path, err_msg

    return True, rel_shader_path, None


def get_git_staged_shaders(workspace_root: str) -> List[str]:
    """Retrieve list of staged shader files from git."""
    try:
        res = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
            cwd=workspace_root,
            text=True,
            capture_output=True,
            check=True,
        )
        return [
            os.path.normpath(os.path.join(workspace_root, f.strip()))
            for f in res.stdout.splitlines()
            if f.strip().endswith((".vsh", ".fsh", ".gsh", ".csh", ".glsl"))
        ]
    except Exception as exc:
        print(f"{CLR_YELLOW}Warning: Failed to query git staged files: {exc}{CLR_RESET}", file=sys.stderr)
        return []


def _resolve_cli_targets(
    files: List[str],
    all_root_shaders: List[str],
    includes_map: Dict[str, Set[str]],
) -> Set[str]:
    """Resolve specific CLI files/directories to corresponding root shaders."""
    targets: Set[str] = set()
    for f in files:
        abs_f = os.path.normpath(os.path.abspath(f))
        if os.path.isdir(abs_f):
            targets.update(rs for rs in all_root_shaders if rs.startswith(abs_f))
        elif os.path.isfile(abs_f):
            ext = os.path.splitext(abs_f)[1]
            if ext in STAGE_MAP:
                targets.add(abs_f)
            elif ext == ".glsl":
                targets.update(includes_map.get(abs_f, set()))
        else:
            print(f"{CLR_YELLOW}Warning: File not found: {f}{CLR_RESET}", file=sys.stderr)
    return targets


def _resolve_staged_targets(
    workspace_root: str,
    includes_map: Dict[str, Set[str]],
) -> Optional[Set[str]]:
    """Collect root shaders associated with git staged files."""
    staged_files = get_git_staged_shaders(workspace_root)
    if not staged_files:
        return None
    targets: Set[str] = set()
    for f in staged_files:
        ext = os.path.splitext(f)[1]
        if ext in STAGE_MAP:
            targets.add(f)
        elif ext == ".glsl":
            targets.update(includes_map.get(os.path.normpath(f), set()))
    return targets


def check_validator_executable(validator_name: str) -> Optional[str]:
    """Verify validator is present in PATH or print installation instructions."""
    path = shutil.which(validator_name)
    if not path:
        print(
            f"{CLR_RED}Error: '{validator_name}' not found in PATH.{CLR_RESET}\n"
            f"Please install glslangValidator:\n"
            f"  • Arch Linux:    sudo pacman -S glslang\n"
            f"  • Debian/Ubuntu: sudo apt install glslang-tools\n"
            f"  • Fedora:        sudo dnf install glslang\n"
            f"  • macOS:         brew install glslang\n"
            f"  • Or Vulkan SDK: https://vulkan.lunarg.com/",
            file=sys.stderr,
        )
    return path


def run_parallel_validation(
    targets: List[str],
    validator_path: str,
    shaders_root: str,
    workspace_root: str,
    workers: int,
) -> Tuple[List[Tuple[str, str]], float]:
    """Executes validation in thread pool and records failures."""
    start_time = time.time()
    failures: List[Tuple[str, str]] = []

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [
            executor.submit(validate_single_shader, sf, validator_path, shaders_root, workspace_root)
            for sf in targets
        ]
        for fut in futures:
            success, rel_path, err_msg = fut.result()
            if not success:
                failures.append((rel_path, err_msg or "Unknown compilation error"))

    duration = time.time() - start_time
    return failures, duration


def print_results(failures: List[Tuple[str, str]], total_count: int, duration: float, quiet: bool) -> int:
    """Print clean summary and return appropriate process exit code."""
    passed_count = total_count - len(failures)
    if failures:
        print(f"\n{CLR_RED}{CLR_BOLD}FAILED: {len(failures)} shader(s) failed validation:{CLR_RESET}\n")
        for rel_path, err in failures:
            print(f"{CLR_BOLD}{CLR_RED}━━━ {rel_path} ━━━{CLR_RESET}")
            print(err)
            print()
        print(f"{CLR_RED}✗ Validation failed: {passed_count}/{total_count} passed in {duration:.2f}s.{CLR_RESET}")
        return 1

    if not quiet:
        print(f"{CLR_GREEN}{CLR_BOLD}✓ All {total_count} shaders passed validation in {duration:.2f}s!{CLR_RESET}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="GLSL shader linter for Minecraft shaderpacks using glslangValidator.")
    parser.add_argument("files", nargs="*", help="Specific shader files or directories to lint.")
    parser.add_argument("--staged", action="store_true", help="Lint files currently staged in git.")
    parser.add_argument("--all", action="store_true", help="Force linting all root shaders.")
    parser.add_argument("--validator", default=os.environ.get("GLSLANG_VALIDATOR", "glslangValidator"), help="Path to validator.")
    parser.add_argument("--shaders-dir", default="shaders", help="Shaders directory path.")
    parser.add_argument("--workers", type=int, default=os.cpu_count() or 4, help="Worker threads.")
    parser.add_argument("--quiet", "-q", action="store_true", help="Only output errors.")
    args = parser.parse_args()

    workspace_root = os.path.abspath(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    shaders_root = os.path.normpath(os.path.join(workspace_root, args.shaders_dir))

    if not os.path.isdir(shaders_root):
        print(f"{CLR_RED}Error: Shaders directory not found at {shaders_root}{CLR_RESET}", file=sys.stderr)
        return 1

    validator_path = check_validator_executable(args.validator)
    if not validator_path:
        return 1

    all_root_shaders, includes_map = build_dependency_graph(shaders_root)

    if args.staged:
        targets = _resolve_staged_targets(workspace_root, includes_map)
        if targets is None:
            if not args.quiet:
                print(f"{CLR_GREEN}✓ No staged shader files found. Nothing to lint.{CLR_RESET}")
            return 0
    elif args.files and not args.all:
        targets = _resolve_cli_targets(args.files, all_root_shaders, includes_map)
    else:
        targets = set(all_root_shaders)

    if not targets:
        if not args.quiet:
            print(f"{CLR_YELLOW}No root shaders matched for validation.{CLR_RESET}")
        return 0

    sorted_targets = sorted(targets)
    if not args.quiet:
        print(f"{CLR_CYAN}Linting {len(sorted_targets)} shader(s) using {os.path.basename(validator_path)} ({args.workers} workers)...{CLR_RESET}")

    failures, duration = run_parallel_validation(sorted_targets, validator_path, shaders_root, workspace_root, args.workers)
    return print_results(failures, len(sorted_targets), duration, args.quiet)


if __name__ == "__main__":
    sys.exit(main())
