#!/usr/bin/env python3
"""
Release Orchestrator for HyperDuper Vanilla.
Validates quality gates, packages release ZIP, tags git repository, and prepares GitHub Release.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""


def get_version(root_dir: str) -> str:
    """Read version from shaders/lang/en_US.lang."""
    lang_file = os.path.join(root_dir, "shaders", "lang", "en_US.lang")
    with open(lang_file, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^screen\.DEBUG\s*=\s*HyperDuper Vanilla v?([0-9]+\.[0-9]+\.[0-9]+[a-zA-Z0-9\.\-]*)", line)
            if m:
                return m.group(1)
    return "1.0.0"


def run_command(cmd: list, cwd: str, desc: str) -> None:
    """Run a subprocess command with error handling."""
    print(f"\n{CLR_CYAN}{CLR_BOLD}▶ {desc}...{CLR_RESET}")
    res = subprocess.run(cmd, cwd=cwd)
    if res.returncode != 0:
        print(f"{CLR_RED}✖ Step failed with exit code {res.returncode}: {' '.join(cmd)}{CLR_RESET}", file=sys.stderr)
        sys.exit(res.returncode)


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a HyperDuper Vanilla release.")
    parser.add_argument("--skip-gate", action="store_true", help="Skip running the quality gate (not recommended).")
    parser.add_argument("--push", action="store_true", help="Push git tags and commits to remote origin.")
    parser.add_argument("--gh-release", action="store_true", help="Create GitHub release using gh CLI if installed.")
    args = parser.parse_args()

    root_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
    version = get_version(root_dir)
    tag_name = f"v{version.lstrip('v')}"
    zip_name = f"Hyper-Duper-Vanilla.{tag_name}.zip"
    zip_path = os.path.join(root_dir, "dist", zip_name)
    sha_path = zip_path + ".sha256"

    print(f"{CLR_CYAN}{CLR_BOLD}╔══════════════════════════════════════════════════════════════════╗{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}║          HYPERDUPER VANILLA — RELEASE ORCHESTRATION PIPELINE     ║{CLR_RESET}")
    print(f"{CLR_CYAN}{CLR_BOLD}╚══════════════════════════════════════════════════════════════════╝{CLR_RESET}")
    print(f"Target Release: {CLR_GREEN}{CLR_BOLD}{tag_name}{CLR_RESET}")
    print(f"Artifact Name:  {CLR_YELLOW}{zip_name}{CLR_RESET}")

    # 1. Quality Gate
    if not args.skip_gate:
        run_command([sys.executable, "scripts/quality_gate.py"], root_dir, "Step 1: Continuous Quality Gate")
    else:
        print(f"{CLR_YELLOW}⚠ Skipped quality gate check.{CLR_RESET}")

    # 2. Build Release Archive
    run_command([sys.executable, "scripts/build.py", "--output-dir", "dist"], root_dir, "Step 2: Building Release ZIP")

    if not os.path.isfile(zip_path):
        print(f"{CLR_RED}Error: Expected zip archive not found at: {zip_path}{CLR_RESET}", file=sys.stderr)
        return 1

    # 3. Git Tagging
    print(f"\n{CLR_CYAN}{CLR_BOLD}▶ Step 3: Git Tagging...{CLR_RESET}")
    tag_check = subprocess.run(["git", "tag", "-l", tag_name], cwd=root_dir, capture_output=True, text=True)
    if tag_name in tag_check.stdout.split():
        print(f"{CLR_YELLOW}Notice: Git tag '{tag_name}' already exists locally.{CLR_RESET}")
    else:
        tag_cmd = ["git", "tag", "-a", tag_name, "-m", f"HyperDuper Vanilla {tag_name}"]
        subprocess.run(tag_cmd, cwd=root_dir, check=True)
        print(f"{CLR_GREEN}✓ Tagged repository with {tag_name}{CLR_RESET}")

    # 4. Git Push
    if args.push:
        print(f"\n{CLR_CYAN}{CLR_BOLD}▶ Step 4: Pushing tags to remote origin...{CLR_RESET}")
        subprocess.run(["git", "push", "origin", "HEAD", "--tags"], cwd=root_dir, check=True)
        print(f"{CLR_GREEN}✓ Pushed to remote successfully!{CLR_RESET}")
    else:
        print(f"\n{CLR_YELLOW}Notice: Push skipped. Run with '--push' or push manually via:{CLR_RESET}")
        print(f"  git push origin HEAD --tags")

    # 5. GitHub Release (gh CLI)
    if args.gh_release:
        gh_bin = shutil.which("gh")
        if gh_bin:
            print(f"\n{CLR_CYAN}{CLR_BOLD}▶ Step 5: Publishing GitHub Release with gh CLI...{CLR_RESET}")
            gh_cmd = [
                gh_bin,
                "release",
                "create",
                tag_name,
                zip_path,
                sha_path,
                "--title",
                f"HyperDuper Vanilla {tag_name}",
                "--generate-notes",
            ]
            subprocess.run(gh_cmd, cwd=root_dir, check=True)
            print(f"{CLR_GREEN}✓ Published GitHub release {tag_name}!{CLR_RESET}")
        else:
            print(f"{CLR_YELLOW}Note: 'gh' CLI not found on PATH. Release can be created via GitHub Actions or web UI.{CLR_RESET}")

    print(f"\n{CLR_GREEN}{CLR_BOLD}══════════════════════════════════════════════════════════════════{CLR_RESET}")
    print(f"{CLR_GREEN}{CLR_BOLD}✔ RELEASE {tag_name} PREPARED SUCCESSFULLY!{CLR_RESET}")
    print(f"Artifact: {zip_path}")
    print(f"{CLR_GREEN}{CLR_BOLD}══════════════════════════════════════════════════════════════════{CLR_RESET}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
