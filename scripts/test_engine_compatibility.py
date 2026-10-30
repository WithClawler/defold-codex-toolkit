#!/usr/bin/env python3
"""Compile current helper sources and exercise real Defold APIs on macOS."""
import argparse
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.14.0"
ENGINE_SHA = "d295ed4edff2e49072719835713e625f409849f1"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bob", type=Path, default=os.environ.get("BOB_JAR", ROOT / ".local/engine" / VERSION / "bob.jar"))
    args = parser.parse_args()
    bob = args.bob.resolve()
    version = subprocess.check_output(["java", "-jar", str(bob), "--version"], text=True)
    if not re.search(r"version: 1\.14\.0\s+sha1: " + ENGINE_SHA, version):
        parser.error("Bob must be Defold 1.14.0 stable " + ENGINE_SHA)
    if platform.system() != "Darwin":
        parser.error("This runner verifies the macOS headless engine only")
    native_platform = "arm64-macos" if platform.machine() == "arm64" else "x86_64-macos"
    (ROOT / ".local").mkdir(exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix="engine-smoke-", dir=ROOT / ".local"))
    project = run_dir / "project"
    shutil.copytree(ROOT / "tests/engine", project)
    shutil.copytree(ROOT / "defold_helper", project / "defold_helper")
    print("Smoke project:", project, flush=True)
    command = ["java", "-jar", str(bob), "--root", str(project), "--output", "build",
               "--platform", native_platform, "--variant", "headless", "--archive",
               "--bundle-output", str(run_dir / "bundle"), "resolve", "build", "bundle"]
    subprocess.run(command, check=True, timeout=300)
    executable = run_dir / "bundle/HelperEngineSmoke.app/Contents/MacOS/HelperEngineSmoke"
    try:
        result = subprocess.run([str(executable)], cwd=executable.parent, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or b""
        (run_dir / "runtime.log").write_bytes(output if isinstance(output, bytes) else output.encode())
        raise SystemExit("Engine smoke timed out; see " + str(run_dir / "runtime.log"))
    (run_dir / "runtime.log").write_text(result.stdout)
    print(result.stdout, end="")
    if result.returncode or f"DEFOLD_HELPER_ENGINE_SMOKE_OK {VERSION} {ENGINE_SHA}" not in result.stdout:
        raise SystemExit("Engine smoke failed; see " + str(run_dir / "runtime.log"))
    print("Engine compatibility verified:", run_dir)


if __name__ == "__main__":
    main()
