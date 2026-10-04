#!/usr/bin/env python3
"""
Version Bump Tool for HyperDuper Vanilla.
Increments semantic versions across language files, documentation, and metadata.
"""

import argparse
import os
import re
import subprocess
import sys
from typing import Optional, Tuple

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""


def get_current_version(root_dir: str) -> str:
    """Extract the current semver from shaders/lang/en_US.lang."""
    lang_file = os.path.join(root_dir, "shaders", "lang", "en_US.lang")
    if not os.path.isfile(lang_file):
        raise FileNotFoundError(f"Missing language file: {lang_file}")

    with open(lang_file, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^screen\.DEBUG\s*=\s*HyperDuper Vanilla v?([0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*)", line)
            if m:
                return m.group(1)

    raise ValueError("Could not find current version in en_US.lang screen.DEBUG entry.")


def calculate_next_version(current: str, bump_type: str) -> str:
    """Calculate the next semver string based on bump type or explicit version."""
    clean_current = current.lstrip("v")
    m = re.match(r"^([0-9]+)\.([0-9]+)\.([0-9]+)(.*)$", clean_current)

    bump_lower = bump_type.lower()
    if bump_lower in ("patch", "minor", "major"):
        if not m:
            raise ValueError(f"Cannot bump non-standard semver: '{current}'")
        major, minor, patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if bump_lower == "patch":
            patch += 1
        elif bump_lower == "minor":
            minor += 1
            patch = 0
        elif bump_lower == "major":
            major += 1
            minor = 0
            patch = 0
        return f"{major}.{minor}.{patch}"

    # Explicit version passed (e.g. "1.0.1", "v1.0.1")
    target = bump_type.lstrip("v")
    if not re.match(r"^[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*$", target):
        raise ValueError(f"Invalid version format: '{bump_type}'")
    return target


def replace_in_file(filepath: str, pattern: str, replacement: str, dry_run: bool = False) -> bool:
    """Safely replace text pattern in a file, returning True if modified."""
    if not os.path.isfile(filepath):
        return False

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    new_content, count = re.subn(pattern, replacement, content)
    if count > 0 and content != new_content:
        if not dry_run:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
        return True
    return False


def bump_all_files(root_dir: str, old_ver: str, new_ver: str, dry_run: bool = False) -> list:
    """Apply version changes to all relevant files in the repository."""
    v_old = f"v{old_ver.lstrip('v')}"
    v_new = f"v{new_ver.lstrip('v')}"
    raw_old = old_ver.lstrip("v")
    raw_new = new_ver.lstrip("v")

    modified_files = []

    # 1. Update all language files
    lang_dir = os.path.join(root_dir, "shaders", "lang")
    for lang in ["en_US.lang", "fr_FR.lang", "zh_CN.lang", "pt_BR.lang"]:
        p = os.path.join(lang_dir, lang)
        changed = False

        # screen.DEBUG = HyperDuper Vanilla vX.Y.Z
        if replace_in_file(
            p,
            r"(screen\.DEBUG\s*=\s*HyperDuper Vanilla\s+)v?[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*",
            rf"\g<1>{v_new}",
            dry_run,
        ):
            changed = True

        # screen.DEBUG.comment = ... HyperDuper Vanilla vX.Y.Z ...
        if replace_in_file(
            p,
            r"(HyperDuper Vanilla\s+)v?[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*",
            rf"\g<1>{v_new}",
            dry_run,
        ):
            changed = True

        if changed:
            modified_files.append(os.path.relpath(p, root_dir))

    # 2. README.md
    readme_path = os.path.join(root_dir, "README.md")
    r_changed = False
    # Title: # HyperDuper Vanilla 🌟 (vX.Y.Z)
    if replace_in_file(readme_path, r"(#\s+HyperDuper Vanilla\s+🌟\s+\()v?[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*(\))", rf"\g<1>{v_new}\g<2>", dry_run):
        r_changed = True
    # Badge: [Version: vX.Y.Z]
    if replace_in_file(readme_path, r"(Version-)v?[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*(-success\.svg)", rf"\g<1>{v_new}\g<2>", dry_run):
        r_changed = True
    # Download zip link in instructions: Hyper-Duper-Vanilla.vX.Y.Z.zip
    if replace_in_file(readme_path, r"(Hyper-Duper-Vanilla\.)v?[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*(\.zip)", rf"\g<1>{v_new}\g<2>", dry_run):
        r_changed = True
    if r_changed:
        modified_files.append("README.md")

    # 3. DOCUMENTATION.md
    doc_path = os.path.join(root_dir, "DOCUMENTATION.md")
    if replace_in_file(doc_path, r"(#\s+HyperDuper Vanilla\s+)v?[0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*(\s+—)", rf"\g<1>{v_new}\g<2>", dry_run):
        modified_files.append("DOCUMENTATION.md")

    return modified_files


def git_commit_and_tag(root_dir: str, new_ver: str, tag: bool = False, push: bool = False) -> None:
    """Commit changes and optionally tag and push."""
    v_str = f"v{new_ver.lstrip('v')}"
    cmd_add = ["git", "add", "shaders/lang/", "README.md", "DOCUMENTATION.md"]
    subprocess.run(cmd_add, cwd=root_dir, check=True)

    commit_msg = f"chore(release): bump version to {v_str}"
    cmd_commit = ["git", "commit", "-m", commit_msg]
    subprocess.run(cmd_commit, cwd=root_dir, check=True)
    print(f"{CLR_GREEN}✓ Created commit: {commit_msg}{CLR_RESET}")

    if tag:
        tag_msg = f"Release {v_str}"
        subprocess.run(["git", "tag", "-a", v_str, "-m", tag_msg], cwd=root_dir, check=True)
        print(f"{CLR_GREEN}✓ Created git tag: {v_str}{CLR_RESET}")

    if push:
        subprocess.run(["git", "push", "origin", "HEAD", "--tags"], cwd=root_dir, check=True)
        print(f"{CLR_GREEN}✓ Pushed commits and tags to remote origin.{CLR_RESET}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Bump HyperDuper Vanilla version.")
    parser.add_argument(
        "target",
        nargs="?",
        default="patch",
        help="Target bump ('patch', 'minor', 'major', or specific version like '1.1.0'). Default: patch.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without modifying files.")
    parser.add_argument("--commit", action="store_true", help="Create a git commit with bumped files.")
    parser.add_argument("--tag", action="store_true", help="Create an annotated git tag v<version>.")
    parser.add_argument("--push", action="store_true", help="Push commit and tags to origin.")
    args = parser.parse_args()

    root_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))

    try:
        current_ver = get_current_version(root_dir)
        next_ver = calculate_next_version(current_ver, args.target)
    except Exception as exc:
        print(f"{CLR_RED}Error: {exc}{CLR_RESET}", file=sys.stderr)
        return 1

    print(f"{CLR_CYAN}{CLR_BOLD}━━━ HyperDuper Vanilla Version Bump ━━━{CLR_RESET}")
    print(f"Current: {CLR_YELLOW}v{current_ver.lstrip('v')}{CLR_RESET}")
    print(f"Target:  {CLR_GREEN}{CLR_BOLD}v{next_ver.lstrip('v')}{CLR_RESET}")

    if current_ver == next_ver:
        print(f"{CLR_YELLOW}Notice: Current and target versions are identical. No files modified.{CLR_RESET}")
        return 0

    modified = bump_all_files(root_dir, current_ver, next_ver, dry_run=args.dry_run)

    if args.dry_run:
        print(f"\n{CLR_YELLOW}[DRY-RUN] Files that would be updated ({len(modified)}):{CLR_RESET}")
    else:
        print(f"\n{CLR_GREEN}✓ Updated {len(modified)} file(s):{CLR_RESET}")

    for f in modified:
        print(f"  • {f}")

    if not args.dry_run and (args.commit or args.tag or args.push):
        try:
            git_commit_and_tag(root_dir, next_ver, tag=args.tag, push=args.push)
        except subprocess.CalledProcessError as err:
            print(f"{CLR_RED}Git error: {err}{CLR_RESET}", file=sys.stderr)
            return 1

    print(f"\n{CLR_GREEN}{CLR_BOLD}✓ Bump to v{next_ver.lstrip('v')} complete!{CLR_RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
