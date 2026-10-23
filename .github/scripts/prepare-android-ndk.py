#!/usr/bin/env python3
"""Install Flutter's NDK in an isolated download directory before Gradle runs."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time


def requested_version(flutter: Path) -> str:
    extension = flutter / "packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
    match = re.search(r'val ndkVersion: String = "([0-9.]+)"', extension.read_text())
    if not match:
        raise ValueError("Cannot determine the pinned Flutter NDK version")
    return match[1]


def verify(package: Path, version: str) -> None:
    properties = (package / "source.properties").read_text()
    if not re.search(rf"^Pkg.Revision\s*=\s*{re.escape(version)}\s*$", properties, re.M):
        raise ValueError("NDK revision does not match Flutter")
    clang = package / "toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
    subprocess.run([str(clang), "--version"], check=True, timeout=30)


def prepare(sdk: Path, version: str) -> None:
    sdk = sdk.resolve()
    target = sdk / "ndk" / version
    target.resolve().relative_to(sdk)
    try:
        verify(target, version)
        return
    except (OSError, ValueError, subprocess.SubprocessError):
        pass
    manager = sdk / "cmdline-tools/latest/bin/sdkmanager"
    if not manager.is_file():
        raise FileNotFoundError("Missing Android SDK manager")
    for attempt in range(1, 4):
        print(f"Preparing NDK {version} (attempt {attempt}/3).", flush=True)
        try:
            # Every attempt has a new SDK root, including its archive cache.
            with tempfile.TemporaryDirectory(prefix="namaa-ndk-") as directory:
                isolated = Path(directory)
                if (sdk / "licenses").is_dir():
                    shutil.copytree(sdk / "licenses", isolated / "licenses")
                subprocess.run(
                    [str(manager), f"--sdk_root={isolated}", "--install", f"ndk;{version}"],
                    check=True, timeout=180,
                )
                package = isolated / "ndk" / version
                verify(package, version)
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.exists():
                    shutil.rmtree(target)
                shutil.move(str(package), str(target))
                verify(target, version)
                return
        except (OSError, ValueError, subprocess.SubprocessError):
            if attempt == 3:
                raise
            print("NDK installation invalid; retrying with a fresh download directory.", flush=True)
            time.sleep(5)


if __name__ == "__main__":
    prepare(Path(os.environ["ANDROID_HOME"]), requested_version(Path(os.environ["FLUTTER_ROOT"])))
