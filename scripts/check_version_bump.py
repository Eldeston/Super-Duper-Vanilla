#!/usr/bin/env python3
"""
Version Bump Detection Utility for CI/CD.
Determines whether the current commit represents a new, untagged version.
"""

import argparse
import os
import re
import subprocess
import sys


def get_current_version(root_dir: str) -> str:
    """Read version from shaders/lang/en_US.lang."""
    lang_file = os.path.join(root_dir, "shaders", "lang", "en_US.lang")
    if not os.path.isfile(lang_file):
        raise FileNotFoundError(f"Missing language file: {lang_file}")

    with open(lang_file, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^screen\.DEBUG\s*=\s*HyperDuper Vanilla v?([0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*)", line)
            if m:
                return m.group(1)
    return "1.0.0"


def set_github_output(key: str, value: str) -> None:
    """Set output for GitHub Actions step."""
    output_file = os.environ.get("GITHUB_OUTPUT")
    if output_file:
        with open(output_file, "a", encoding="utf-8") as f:
            f.write(f"{key}={value}\n")
    print(f"[CI Output] {key}={value}")


def tag_exists(tag: str, root_dir: str) -> bool:
    """Check if tag exists locally or in fetched remote references."""
    res = subprocess.run(["git", "tag", "-l", tag], cwd=root_dir, capture_output=True, text=True)
    return tag in res.stdout.split()


def main() -> int:
    parser = argparse.ArgumentParser(description="Check if version has been bumped and needs a release.")
    parser.add_argument("--create-tag", action="store_true", help="Create and push the git tag if it does not exist.")
    parser.add_argument("--force", action="store_true", help="Force release regardless of tag existence.")
    args = parser.parse_args()

    root_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
    version = get_current_version(root_dir)
    tag = f"v{version.lstrip('v')}"

    print(f"Current version in codebase: {version} (tag: {tag})")

    # Fetch tags to ensure we have latest remote tags
    subprocess.run(["git", "fetch", "--tags"], cwd=root_dir, capture_output=True)

    exists = tag_exists(tag, root_dir)
    event_name = os.environ.get("GITHUB_EVENT_NAME", "")
    ref = os.environ.get("GITHUB_REF", "")

    should_release = False

    if args.force or event_name == "workflow_dispatch" or ref.startswith("refs/tags/"):
        should_release = True
        print("Release explicitly requested via tag push or manual dispatch.")
    elif not exists:
        should_release = True
        print(f"Version bump detected: Tag '{tag}' does not exist yet.")
        if args.create_tag:
            print(f"Creating and pushing tag '{tag}'...")
            subprocess.run(["git", "tag", "-a", tag, "-m", f"HyperDuper Vanilla {tag}"], cwd=root_dir, check=True)
            subprocess.run(["git", "push", "origin", tag], cwd=root_dir, check=True)
            print(f"✓ Tag '{tag}' pushed to remote.")
    else:
        # Tag already exists
        # Check if the tag points to HEAD
        tag_commit = subprocess.run(["git", "rev-list", "-n", "1", tag], cwd=root_dir, capture_output=True, text=True).stdout.strip()
        head_commit = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root_dir, capture_output=True, text=True).stdout.strip()
        if tag_commit == head_commit:
            print(f"Tag '{tag}' exists and points to current HEAD.")
            should_release = True
        else:
            print(f"Tag '{tag}' already exists on commit {tag_commit[:8]} (HEAD is {head_commit[:8]}). Skipping release.")
            should_release = False

    set_github_output("version", version)
    set_github_output("tag", tag)
    set_github_output("should_release", "true" if should_release else "false")
    return 0


if __name__ == "__main__":
    sys.exit(main())
