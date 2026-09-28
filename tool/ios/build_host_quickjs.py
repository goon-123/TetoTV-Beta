#!/usr/bin/env python3
"""Compile the iOS QuickJS translation units for Linux-hosted Dart tests.

This checks the shared C/C++ bridge and supplies an up-to-date test library;
it does not cross-compile or claim to validate Apple's SDK/linker.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "third_party/flutter_js/ios/Classes/QuickJS"
OUTPUT = ROOT / "build/ios-port-tests"


def build(source: Path) -> Path:
    cpp = source.suffix == ".cpp"
    obj = OUTPUT / (source.stem + ".o")
    subprocess.run([
        os.environ.get("CXX" if cpp else "CC", "g++" if cpp else "gcc"),
        "-std=c++17" if cpp else "-std=gnu11", "-fPIC", "-O2",
        '-DCONFIG_VERSION="2026-06-04"', "-D_GNU_SOURCE",
        "-c", str(source), "-o", str(obj),
    ], check=True)
    return obj


def main() -> None:
    if not sys.platform.startswith("linux"):
        raise SystemExit("Use Linux for this host test library; use Xcode for iOS.")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sources = sorted(SOURCE.glob("*.c")) + sorted(SOURCE.glob("*.cpp"))
    with ThreadPoolExecutor(max_workers=min(4, len(sources))) as pool:
        objects = list(pool.map(build, sources))
    library = OUTPUT / "libtetotv_quickjs.so"
    subprocess.run([
        os.environ.get("CXX", "g++"), "-shared", *map(str, objects),
        "-lm", "-pthread", "-o", str(library),
    ], check=True)
    print(library)


if __name__ == "__main__":
    main()
