#!/usr/bin/env python3
"""
i18n & Translation Linter for Minecraft Shaderpacks (Iris / OptiFine).

Validates:
1. Syntax correctness of all `.lang` files (key=value format, no malformed lines).
2. Duplicate key prevention across all `.lang` files.
3. Canonical base completeness: Every screen and option declared in `shaders.properties`
   must have corresponding `screen.<name>` and `option.<name>` entries in `en_US.lang`.
4. Translation consistency: Checks for format version matching, orphan/obsolete keys,
   and translation coverage statistics.
"""

import argparse
import collections
import os
import re
import subprocess
import sys
from typing import Dict, List, Optional, Set, Tuple

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_GRAY = "\033[90m" if USE_COLOR else ""

FORMAT_VERSION_RE = re.compile(r"^\s*##\s*Language\s+format\s+(v[0-9a-zA-Z\.\-]+)", re.IGNORECASE)


def parse_lang_file(filepath: str) -> Tuple[Dict[str, Tuple[int, str]], List[Tuple[int, str]], Dict[str, List[int]], Optional[str]]:
    """Parses a Minecraft .lang file into keys, syntax errors, duplicates, and format version."""
    keys: Dict[str, Tuple[int, str]] = {}
    syntax_errors: List[Tuple[int, str]] = []
    key_occurrences: Dict[str, List[int]] = collections.defaultdict(list)
    format_version: Optional[str] = None

    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError as err:
        return {}, [(0, f"Cannot read file: {err}")], {}, None

    for line_num, line in enumerate(lines, 1):
        raw = line.strip()
        if not raw:
            continue

        vm = FORMAT_VERSION_RE.match(raw)
        if vm and not format_version:
            format_version = vm.group(1)
            continue

        if raw.startswith("#"):
            continue

        if "=" not in raw:
            syntax_errors.append((line_num, f"Malformed line missing '=' delimiter: '{raw}'"))
            continue

        k, v = raw.split("=", 1)
        key = k.strip()
        val = v.strip()

        if not key:
            syntax_errors.append((line_num, f"Empty key before '=': '{raw}'"))
            continue

        key_occurrences[key].append(line_num)
        keys[key] = (line_num, val)

    duplicates = {k: lines for k, lines in key_occurrences.items() if len(lines) > 1}
    return keys, syntax_errors, duplicates, format_version


def _collect_tokens(raw_line: str, screens: Set[str], options: Set[str]) -> None:
    """Parse tokens from screen line and categorize as screens or options."""
    for tok in raw_line.replace("\\", " ").split():
        tok = tok.strip()
        if tok.startswith("[") and tok.endswith("]"):
            screens.add(tok[1:-1])
        elif not (tok.startswith("<") or tok.startswith("profile") or tok.startswith("!") or ":" in tok):
            options.add(tok)


def extract_shader_properties_items(properties_path: str) -> Tuple[Set[str], Set[str]]:
    """Extracts all screen names and option names defined in `shaders/shaders.properties`."""
    screens: Set[str] = set()
    options: Set[str] = set()

    if not os.path.isfile(properties_path):
        return screens, options

    try:
        with open(properties_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return screens, options

    in_screen_block = False
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if stripped.startswith(("screen.", "screen =", "screen=")):
            in_screen_block = True
            if "=" in stripped:
                left, right = stripped.split("=", 1)
                left_clean = left.strip()
                if left_clean.startswith("screen."):
                    screens.add(left_clean[7:].strip())
                _collect_tokens(right, screens, options)
        elif in_screen_block:
            if "=" in stripped:
                in_screen_block = False
            else:
                _collect_tokens(stripped, screens, options)

    return screens, options


def get_staged_lang_files(workspace_root: str) -> List[str]:
    """Retrieve list of staged .lang or shaders.properties files from git."""
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
            if f.strip().endswith((".lang", "shaders.properties"))
        ]
    except Exception:
        return []


def _validate_canonical_base(
    canon_file: str,
    props_path: str,
    quiet: bool,
) -> Tuple[Dict[str, Tuple[int, str]], Optional[str], bool]:
    """Validates the canonical en_US.lang file against shaders.properties."""
    canon_keys, canon_errors, canon_dupes, canon_version = parse_lang_file(canon_file)
    canon_filename = os.path.basename(canon_file)
    has_errors = False

    if not quiet:
        print(f"{CLR_CYAN}{CLR_BOLD}━━━ i18n Translation & Consistency Check ━━━{CLR_RESET}")
        print(f"Canonical language: {CLR_BOLD}{canon_filename}{CLR_RESET} (Format: {canon_version or 'unknown'}, Keys: {len(canon_keys)})")

    for lnum, msg in canon_errors:
        print(f"{CLR_RED}Syntax error in {canon_filename}:{lnum}: {msg}{CLR_RESET}")
        has_errors = True

    for k, lnums in canon_dupes.items():
        print(f"{CLR_RED}Duplicate key in {canon_filename}: '{k}' on lines {lnums}{CLR_RESET}")
        has_errors = True

    if os.path.isfile(props_path):
        screens, options = extract_shader_properties_items(props_path)
        missing_screens = [s for s in screens if f"screen.{s}" not in canon_keys]
        missing_options = [o for o in options if f"option.{o}" not in canon_keys]

        for s in sorted(missing_screens):
            print(f"{CLR_RED}Missing screen translation in {canon_filename}: screen.{s}{CLR_RESET}")
            has_errors = True
        for o in sorted(missing_options):
            print(f"{CLR_RED}Missing option translation in {canon_filename}: option.{o}{CLR_RESET}")
            has_errors = True

        if not (missing_screens or missing_options) and not quiet:
            print(f"{CLR_GREEN}✓ All {len(screens)} screens and {len(options)} options from shaders.properties are defined in {canon_filename}.{CLR_RESET}")

    return canon_keys, canon_version, has_errors


def _check_translation_file(
    filepath: str,
    canon_keys: Dict[str, Tuple[int, str]],
    canon_version: Optional[str],
    strict: bool,
    quiet: bool,
) -> Tuple[Dict, bool, bool]:
    """Check a single translation file for syntax, version match, and orphan keys."""
    fname = os.path.basename(filepath)
    keys, errs, dupes, version = parse_lang_file(filepath)
    file_errors = False
    file_warnings = False

    for lnum, msg in errs:
        print(f"{CLR_RED}Syntax error in {fname}:{lnum}: {msg}{CLR_RESET}")
        file_errors = True

    for k, lnums in dupes.items():
        print(f"{CLR_RED}Duplicate key in {fname}: '{k}' on lines {lnums}{CLR_RESET}")
        file_errors = True

    if canon_version and version != canon_version:
        msg = f"Format version mismatch in {fname}: got '{version or 'none'}', expected '{canon_version}'"
        if strict:
            print(f"{CLR_RED}Error: {msg}{CLR_RESET}")
            file_errors = True
        elif not quiet:
            print(f"{CLR_YELLOW}Warning: {msg}{CLR_RESET}")
            file_warnings = True

    orphan_keys = set(keys.keys()) - set(canon_keys.keys())
    if orphan_keys:
        msg = f"{fname} contains {len(orphan_keys)} obsolete/orphan key(s) not in canonical: {list(orphan_keys)[:5]}"
        if strict:
            print(f"{CLR_RED}Error: {msg}{CLR_RESET}")
            file_errors = True
        elif not quiet:
            print(f"{CLR_YELLOW}Notice: {msg}{CLR_RESET}")
            file_warnings = True

    return {"keys": keys, "version": version}, file_errors, file_warnings


def _print_coverage_table(all_data: Dict[str, Dict], canon_filename: str, canon_count: int) -> None:
    """Print clean summary table of translation coverage."""
    print(f"\n{CLR_BOLD}{'Language File':<16} {'Version':<10} {'Translated':<12} {'Missing':<10} {'Coverage':<10}{CLR_RESET}")
    print("─" * 60)

    for fname in sorted(all_data.keys()):
        data = all_data[fname]
        cnt = len(data["keys"])
        ver = data["version"] or "N/A"
        if fname == canon_filename:
            print(f"{CLR_GREEN}{fname:<16} {ver:<10} {cnt:<12} {'0':<10} {'100.0%':<10}{CLR_RESET}")
        else:
            missing_cnt = canon_count - len(set(data["keys"].keys()) & set(all_data[canon_filename]["keys"].keys()))
            cov = ((canon_count - missing_cnt) / canon_count) * 100 if canon_count else 0
            color = CLR_GREEN if cov >= 95 else (CLR_YELLOW if cov >= 50 else CLR_RED)
            print(f"{fname:<16} {ver:<10} {cnt:<12} {missing_cnt:<10} {color}{cov:.1f}%{CLR_RESET}")
    print("─" * 60)


def main() -> int:
    parser = argparse.ArgumentParser(description="i18n & Translation consistency validator for Minecraft shaderpacks.")
    parser.add_argument("--lang-dir", default="shaders/lang", help="Directory with .lang files.")
    parser.add_argument("--properties-file", default="shaders/shaders.properties", help="Path to shaders.properties.")
    parser.add_argument("--canonical", default="en_US.lang", help="Base canonical language file.")
    parser.add_argument("--strict", action="store_true", help="Fail on orphan keys, missing translations, or version mismatches.")
    parser.add_argument("--staged", action="store_true", help="Validate only if staged in git.")
    parser.add_argument("--quiet", "-q", action="store_true", help="Only display errors.")
    args = parser.parse_args()

    workspace_root = os.path.abspath(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    lang_dir = os.path.normpath(os.path.join(workspace_root, args.lang_dir))
    props_path = os.path.normpath(os.path.join(workspace_root, args.properties_file))

    if args.staged and not get_staged_lang_files(workspace_root):
        if not args.quiet:
            print(f"{CLR_GREEN}✓ No language or property files staged. Skipping i18n validation.{CLR_RESET}")
        return 0

    canonical_file = os.path.join(lang_dir, args.canonical)
    if not os.path.isfile(canonical_file):
        print(f"{CLR_RED}Error: Canonical file not found at {canonical_file}{CLR_RESET}", file=sys.stderr)
        return 1

    canon_keys, canon_version, has_errors = _validate_canonical_base(canonical_file, props_path, args.quiet)
    canon_filename = os.path.basename(canonical_file)
    all_data = {canon_filename: {"keys": canon_keys, "version": canon_version}}
    has_warnings = False

    for fname in sorted(os.listdir(lang_dir)):
        if fname.endswith(".lang") and fname != canon_filename:
            data, file_err, file_warn = _check_translation_file(
                os.path.join(lang_dir, fname), canon_keys, canon_version, args.strict, args.quiet
            )
            all_data[fname] = data
            has_errors = has_errors or file_err
            has_warnings = has_warnings or file_warn

    if not args.quiet:
        _print_coverage_table(all_data, canon_filename, len(canon_keys))

    if has_errors or (args.strict and has_warnings):
        print(f"\n{CLR_RED}{CLR_BOLD}✗ i18n validation failed!{CLR_RESET}")
        return 1

    if not args.quiet:
        print(f"\n{CLR_GREEN}{CLR_BOLD}✓ i18n validation passed successfully!{CLR_RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
