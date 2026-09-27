#!/usr/bin/env python3
"""
File Length & Cyclomatic Complexity Quality Gate for Super Duper Vanilla.
Enforces Single Responsibility Principle (SRP) and Keep It Simple, Stupid (KISS)
across both GLSL shader code and Python development tooling.
"""

import argparse
import ast
import json
import os
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional, Set, Tuple

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_GRAY = "\033[90m" if USE_COLOR else ""

DEFAULT_CONFIG: Dict[str, Any] = {
    "rules": {
        "max_file_lines": 400,
        "warn_file_lines": 300,
        "max_function_lines": 120,
        "warn_function_lines": 80,
        "max_cyclomatic_complexity": 20,
        "warn_cyclomatic_complexity": 15,
    },
    "file_overrides": {},
}

GLSL_FUNC_RE = re.compile(
    r"(?:^|\n)\s*(?:flat\s+|in\s+|out\s+)?([a-zA-Z0-9_]+)\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*\{"
)


def load_config(workspace_root: str) -> Dict[str, Any]:
    """Load .complexity.json if present, otherwise return defaults."""
    cfg_path = os.path.join(workspace_root, ".complexity.json")
    if os.path.isfile(cfg_path):
        try:
            with open(cfg_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                merged = dict(DEFAULT_CONFIG)
                merged["rules"] = {**DEFAULT_CONFIG["rules"], **data.get("rules", {})}
                merged["file_overrides"] = data.get("file_overrides", {})
                return merged
        except Exception as exc:
            print(f"{CLR_YELLOW}Warning: Failed to parse .complexity.json ({exc}). Using defaults.{CLR_RESET}", file=sys.stderr)
    return DEFAULT_CONFIG


def _extract_glsl_func_bounds(clean_content: str, start_brace: int) -> int:
    """Finds the matching closing brace for a function body."""
    brace_depth = 0
    for idx in range(start_brace, len(clean_content)):
        char = clean_content[idx]
        if char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth -= 1
            if brace_depth == 0:
                return idx + 1
    return len(clean_content)


def _calc_glsl_complexity(func_body: str) -> int:
    """Computes McCabe cyclomatic complexity for a GLSL function body."""
    keywords_count = len(re.findall(r"\b(if|for|while|case)\b", func_body))
    operators_count = len(re.findall(r"(&&|\|\||\?)", func_body))
    return 1 + keywords_count + operators_count


def analyze_glsl_file(filepath: str) -> Tuple[int, List[Dict[str, Any]]]:
    """Extract line count and functions with their cyclomatic complexity from GLSL."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
    except OSError:
        return 0, []

    file_lines = len(content.splitlines())

    def strip_comments(text: str) -> str:
        no_line_comments = re.sub(r"//.*", "", text)
        return re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), no_line_comments, flags=re.DOTALL)

    clean = strip_comments(content)
    functions: List[Dict[str, Any]] = []

    for m in GLSL_FUNC_RE.finditer(clean):
        ret_type, name, _ = m.groups()
        if ret_type in ("if", "for", "while", "switch", "return", "else"):
            continue
        start_idx = m.end() - 1
        end_idx = _extract_glsl_func_bounds(clean, start_idx)
        func_body = clean[start_idx:end_idx]
        line_num = content[:m.start()].count("\n") + 1
        flen = func_body.count("\n") + 1
        cc = _calc_glsl_complexity(func_body)
        functions.append({"name": name, "line": line_num, "lines": flen, "complexity": cc})

    return file_lines, functions


def _calc_py_ast_complexity(node: ast.AST) -> int:
    """Computes cyclomatic complexity for a Python function AST node."""
    complexity = 1
    for child in ast.walk(node):
        if isinstance(child, (ast.If, ast.While, ast.For, ast.AsyncFor, ast.ExceptHandler, ast.Assert)):
            complexity += 1
        elif isinstance(child, ast.BoolOp):
            complexity += len(child.values) - 1
        elif isinstance(child, (ast.comprehension, ast.IfExp)):
            complexity += 1
    return complexity


def analyze_python_file(filepath: str) -> Tuple[int, List[Dict[str, Any]]]:
    """Extract line count and functions with cyclomatic complexity from Python AST."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
    except OSError:
        return 0, []

    file_lines = len(content.splitlines())
    try:
        tree = ast.parse(content, filename=filepath)
    except SyntaxError:
        return file_lines, []

    functions: List[Dict[str, Any]] = []
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            flen = node.end_lineno - node.lineno + 1 if hasattr(node, "end_lineno") else 1
            cc = _calc_py_ast_complexity(node)
            functions.append({"name": node.name, "line": node.lineno, "lines": flen, "complexity": cc})

    return file_lines, functions


def get_git_staged_files(workspace_root: str) -> List[str]:
    """Retrieve staged GLSL and Python files from git."""
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
            if f.strip().endswith((".vsh", ".fsh", ".gsh", ".csh", ".glsl", ".py"))
        ]
    except Exception:
        return []


def collect_target_files(workspace_root: str, files_arg: List[str], staged: bool) -> List[str]:
    """Determines the list of files to check based on options."""
    if staged:
        return get_git_staged_files(workspace_root)
    if files_arg:
        res = []
        for f in files_arg:
            abs_p = os.path.normpath(os.path.abspath(f))
            if os.path.isfile(abs_p):
                res.append(abs_p)
            elif os.path.isdir(abs_p):
                for root, _, files in os.walk(abs_p):
                    for fn in files:
                        if fn.endswith((".vsh", ".fsh", ".gsh", ".csh", ".glsl", ".py")):
                            res.append(os.path.join(root, fn))
        return res

    targets: List[str] = []
    for dir_name in ("shaders", "scripts"):
        target_dir = os.path.join(workspace_root, dir_name)
        if os.path.isdir(target_dir):
            for root, _, files in os.walk(target_dir):
                for fn in files:
                    if fn.endswith((".vsh", ".fsh", ".gsh", ".csh", ".glsl", ".py")):
                        targets.append(os.path.normpath(os.path.join(root, fn)))
    return sorted(targets)


def _check_metrics(
    rel_path: str,
    file_lines: int,
    functions: List[Dict[str, Any]],
    rules: Dict[str, int],
    file_overrides: Dict[str, Any],
    strict: bool,
) -> Tuple[List[str], List[str]]:
    """Evaluates file and function metrics against configured thresholds."""
    errors: List[str] = []
    warnings: List[str] = []

    overrides = file_overrides.get(rel_path, {})
    max_file_lines = overrides.get("max_file_lines", rules["max_file_lines"])
    warn_file_lines = overrides.get("warn_file_lines", rules["warn_file_lines"])
    max_cc = overrides.get("max_cyclomatic_complexity", rules["max_cyclomatic_complexity"])
    warn_cc = overrides.get("warn_cyclomatic_complexity", rules["warn_cyclomatic_complexity"])
    max_flen = overrides.get("max_function_lines", rules["max_function_lines"])
    warn_flen = overrides.get("warn_function_lines", rules["warn_function_lines"])

    # File length check
    if file_lines > max_file_lines:
        errors.append(f"{rel_path}: File length ({file_lines} lines) exceeds max limit ({max_file_lines})")
    elif file_lines > warn_file_lines:
        warnings.append(f"{rel_path}: File length ({file_lines} lines) exceeds warning limit ({warn_file_lines})")

    # Functions check
    for fn in functions:
        fname = fn["name"]
        fline = fn["line"]
        cc = fn["complexity"]
        flen = fn["lines"]

        if cc > max_cc:
            errors.append(f"{rel_path}:{fline}: {fname}() cyclomatic complexity ({cc}) exceeds limit ({max_cc})")
        elif cc > warn_cc:
            warnings.append(f"{rel_path}:{fline}: {fname}() cyclomatic complexity ({cc}) exceeds warning limit ({warn_cc})")

        if flen > max_flen:
            errors.append(f"{rel_path}:{fline}: {fname}() length ({flen} lines) exceeds limit ({max_flen})")
        elif flen > warn_flen:
            warnings.append(f"{rel_path}:{fline}: {fname}() length ({flen} lines) exceeds warning limit ({warn_flen})")

    if strict and warnings:
        errors.extend(warnings)
        warnings.clear()

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description="Enforce file length gates and cyclomatic complexity limits (SRP & KISS).")
    parser.add_argument("files", nargs="*", help="Specific files or directories to inspect.")
    parser.add_argument("--staged", action="store_true", help="Analyze only git-staged changes.")
    parser.add_argument("--strict", action="store_true", help="Strict mode: treat complexity/length warnings as errors.")
    parser.add_argument("--quiet", "-q", action="store_true", help="Output only errors.")
    args = parser.parse_args()

    workspace_root = os.path.abspath(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    config = load_config(workspace_root)
    rules = config["rules"]
    file_overrides = config.get("file_overrides", {})

    target_files = collect_target_files(workspace_root, args.files, args.staged)
    if args.staged and not target_files:
        if not args.quiet:
            print(f"{CLR_GREEN}✓ No code files staged. Skipping complexity gates.{CLR_RESET}")
        return 0

    all_errors: List[str] = []
    all_warnings: List[str] = []
    total_funcs = 0
    max_observed_cc = 0

    for filepath in target_files:
        rel_path = os.path.relpath(filepath, workspace_root)
        if filepath.endswith(".py"):
            file_lines, funcs = analyze_python_file(filepath)
        else:
            file_lines, funcs = analyze_glsl_file(filepath)

        total_funcs += len(funcs)
        for fn in funcs:
            if fn["complexity"] > max_observed_cc:
                max_observed_cc = fn["complexity"]

        errs, warns = _check_metrics(rel_path, file_lines, funcs, rules, file_overrides, args.strict)
        all_errors.extend(errs)
        all_warnings.extend(warns)

    if not args.quiet:
        print(f"{CLR_CYAN}{CLR_BOLD}━━━ File Length & Cyclomatic Complexity Gate (SRP / KISS) ━━━{CLR_RESET}")
        print(f"Inspected {len(target_files)} files ({total_funcs} functions). Limits: File <= {rules['max_file_lines']} lines, Function CC <= {rules['max_cyclomatic_complexity']}")

    if all_warnings and not args.quiet:
        print(f"\n{CLR_YELLOW}{CLR_BOLD}Complexity & Length Notices ({len(all_warnings)}):{CLR_RESET}")
        for w in all_warnings[:10]:
            print(f"  {CLR_YELLOW}• {w}{CLR_RESET}")
        if len(all_warnings) > 10:
            print(f"  {CLR_GRAY}... and {len(all_warnings) - 10} more notices.{CLR_RESET}")

    if all_errors:
        print(f"\n{CLR_RED}{CLR_BOLD}FAILED: {len(all_errors)} Complexity/Length Violations:{CLR_RESET}")
        for e in all_errors:
            print(f"  {CLR_RED}✖ {e}{CLR_RESET}")
        print(f"\n{CLR_RED}✗ Quality gate failed: Encourage Single Responsibility Principle (SRP) by decomposing large units.{CLR_RESET}")
        return 1

    if not args.quiet:
        print(f"{CLR_GREEN}{CLR_BOLD}✓ All {len(target_files)} files pass file length & cyclomatic complexity gates!{CLR_RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
