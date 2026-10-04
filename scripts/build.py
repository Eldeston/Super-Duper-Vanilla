#!/usr/bin/env python3
"""
Shaderpack Build Script for HyperDuper Vanilla (SDV Fork).
Packages the shaderpack into a clean, distributable ZIP archive for CI/CD and releases.
"""

import argparse
import hashlib
import os
import re
import sys
import zipfile
from typing import List, Tuple

USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
CLR_RESET = "\033[0m" if USE_COLOR else ""
CLR_BOLD = "\033[1m" if USE_COLOR else ""
CLR_GREEN = "\033[32m" if USE_COLOR else ""
CLR_CYAN = "\033[36m" if USE_COLOR else ""
CLR_YELLOW = "\033[33m" if USE_COLOR else ""
CLR_RED = "\033[31m" if USE_COLOR else ""

# Patterns to ignore when packaging release zip
EXCLUDE_PATTERNS = [
    r"^\.git(/|$)",
    r"^\.github(/|$)",
    r"^\.githooks(/|$)",
    r"^scripts(/|$)",
    r"^dist(/|$)",
    r"^build(/|$)",
    r"^__pycache__(/|$)",
    r"^.*\.pyc$",
    r"^.*\.py$",
    r"^.*\.zip$",
    r"^Taskfile\.ya?ml$",
    r"^\.pre-commit-config\.ya?ml$",
    r"^\.gitignore$",
    r"^\.gitattributes$",
    r"^\.DS_Store$",
    r"^Thumbs\.db$",
]


def get_version(workspace_root: str) -> str:
    """Extract version from shaders/shaders.properties or fallback."""
    props_path = os.path.join(workspace_root, "shaders", "shaders.properties")
    if os.path.isfile(props_path):
        try:
            with open(props_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
                m = re.search(r"(?:HyperDuper|Super\s+Duper)\s+Vanilla\s+(v[0-9a-zA-Z\.\-]+)", content, re.IGNORECASE)
                if m:
                    return m.group(1)
        except OSError:
            pass

    # Check shaders/lang/en_US.lang
    lang_path = os.path.join(workspace_root, "shaders", "lang", "en_US.lang")
    if os.path.isfile(lang_path):
        try:
            with open(lang_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
                m = re.search(r"screen\.DEBUG\s*=\s*(?:HyperDuper|Super\s+Duper)\s+Vanilla\s+(v[0-9a-zA-Z\.\-]+)", content, re.IGNORECASE)
                if m:
                    return m.group(1)
        except OSError:
            pass

    # Fallback to check composite_translucent.glsl
    composite_path = os.path.join(workspace_root, "shaders", "main", "composite_translucent.glsl")
    if not os.path.isfile(composite_path):
        composite_path = os.path.join(workspace_root, "shaders", "main", "composite.glsl")
    if os.path.isfile(composite_path):
        try:
            with open(composite_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
                m = re.search(r"(?:HyperDuper|Super\s+Duper)\s+Vanilla\s+(v[0-9a-zA-Z\.\-]+)", content, re.IGNORECASE)
                if m:
                    return m.group(1)
        except OSError:
            pass

    return "v1.0.0"


def is_excluded(rel_path: str) -> bool:
    """Check if relative path matches any exclusion pattern."""
    norm_path = rel_path.replace("\\", "/")
    for pattern in EXCLUDE_PATTERNS:
        if re.search(pattern, norm_path):
            return True
    return False


def compute_sha256(filepath: str) -> str:
    """Compute sha256 checksum of a file."""
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def build_shaderpack(
    workspace_root: str,
    output_dir: str,
    custom_name: str = None,
) -> Tuple[str, str, int]:
    """
    Builds the shaderpack zip package.
    Returns (zip_filepath, sha256_hash, file_count).
    """
    version = get_version(workspace_root)
    tag = version if version.startswith("v") else f"v{version}"
    base_name = custom_name or f"Hyper-Duper-Vanilla.{tag}.zip"
    os.makedirs(output_dir, exist_ok=True)
    zip_path = os.path.join(output_dir, base_name)

    # Collect files to include
    files_to_pack: List[Tuple[str, str]] = []  # (abs_path, arcname)

    # 1. Shaders folder (required)
    shaders_dir = os.path.join(workspace_root, "shaders")
    if not os.path.isdir(shaders_dir):
        raise RuntimeError(f"Shaders directory missing: {shaders_dir}")

    for root, _, files in os.walk(shaders_dir):
        for f in files:
            abs_p = os.path.join(root, f)
            rel_p = os.path.relpath(abs_p, workspace_root)
            if not is_excluded(rel_p):
                files_to_pack.append((abs_p, rel_p))

    # 2. Key root documentation & legal files
    for doc in ["LICENSE", "README.md", "DOCUMENTATION.md", "CONTRIBUTION.md", "CONTRIBUTORS.md", "TRANSLATORS.md"]:
        abs_doc = os.path.join(workspace_root, doc)
        if os.path.isfile(abs_doc):
            files_to_pack.append((abs_doc, doc))

    # Write zip file
    if os.path.exists(zip_path):
        os.remove(zip_path)

    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for abs_p, arcname in sorted(files_to_pack):
            zf.write(abs_p, arcname)

    sha256 = compute_sha256(zip_path)
    # Write checksum file
    sha_file = zip_path + ".sha256"
    with open(sha_file, "w", encoding="utf-8") as f:
        f.write(f"{sha256}  {os.path.basename(zip_path)}\n")

    return zip_path, sha256, len(files_to_pack)


def main() -> int:
    parser = argparse.ArgumentParser(description="Build and package HyperDuper Vanilla shaderpack.")
    parser.add_argument("--output-dir", default="dist", help="Output directory for build artifacts (default: dist).")
    parser.add_argument("--name", default=None, help="Custom filename for the output zip.")
    args = parser.parse_args()

    workspace_root = os.path.abspath(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    )
    output_dir = os.path.normpath(os.path.join(workspace_root, args.output_dir))

    print(f"{CLR_CYAN}{CLR_BOLD}━━━ Packaging HyperDuper Vanilla Shaderpack ━━━{CLR_RESET}")
    try:
        zip_path, sha256, count = build_shaderpack(workspace_root, output_dir, args.name)
        size_mb = os.path.getsize(zip_path) / (1024 * 1024)
        print(f"Archive:   {CLR_BOLD}{os.path.relpath(zip_path, workspace_root)}{CLR_RESET}")
        print(f"Size:      {size_mb:.2f} MB ({count} files)")
        print(f"SHA256:    {sha256}")
        print(f"{CLR_GREEN}{CLR_BOLD}✓ Build complete!{CLR_RESET}")
        return 0
    except Exception as exc:
        print(f"{CLR_RED}Build failed: {exc}{CLR_RESET}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
