#!/usr/bin/env python3
"""Finish emulator installation before the action's single-attempt SDK setup.

The emulator action installs the emulator and the system image once each,
without retries. A corrupt download of either fails the whole job before any
test runs, so both are installed and verified here with bounded retries; the
action then finds them already installed.
"""

import os
from pathlib import Path
import re
import shutil
import subprocess
import time

# Must match api-level, target and arch of the emulator action in
# .github/workflows/foundation-ci.yml.
DEFAULT_SYSTEM_IMAGE = "system-images;android-35;google_apis;x86_64"
# A system image is large; one attempt may legitimately take minutes.
SYSTEM_IMAGE_TIMEOUT_SECONDS = 360


def prepare(sdk: Path) -> None:
    manager = sdk / "cmdline-tools/latest/bin/sdkmanager"
    emulator = sdk / "emulator/emulator"
    if not manager.is_file():
        raise FileNotFoundError(f"Missing SDK manager: {manager}")
    for attempt in range(1, 4):
        print(f"Preparing Android emulator (attempt {attempt}/3).", flush=True)
        try:
            subprocess.run(
                [str(manager), "--install", "emulator", "--channel=0"],
                check=True, timeout=120,
            )
            break
        except (OSError, subprocess.SubprocessError):
            if attempt == 3:
                raise
            print("Emulator preparation failed; retrying installation only.", flush=True)
            time.sleep(5)

    # Probe the same headless engine used by the CI launch, not its Qt GUI.
    version = subprocess.run(
        [str(emulator), "-no-window", "-version"], check=False, timeout=30,
        capture_output=True, text=True,
    )
    output = version.stdout + version.stderr
    print(output, flush=True)
    version.check_returncode()
    if not re.search(r"Android emulator version \d+\.\d+", output):
        raise ValueError("Installed emulator did not report a valid version.")


def system_image_dir(sdk: Path, package: str) -> Path:
    """`system-images;android-35;google_apis;x86_64` -> its SDK folder."""
    parts = package.split(";")
    if len(parts) != 4 or parts[0] != "system-images":
        raise ValueError(f"Not a system image package: {package}")
    return sdk.joinpath(*parts)


def _image_is_complete(image: Path) -> bool:
    return (image / "source.properties").is_file() and (image / "system.img").is_file()


def prepare_system_image(sdk: Path, package: str = DEFAULT_SYSTEM_IMAGE) -> None:
    manager = sdk / "cmdline-tools/latest/bin/sdkmanager"
    if not manager.is_file():
        raise FileNotFoundError(f"Missing SDK manager: {manager}")
    image = system_image_dir(sdk, package)
    if _image_is_complete(image):
        print(f"System image already installed: {package}", flush=True)
        return
    for attempt in range(1, 4):
        print(f"Preparing {package} (attempt {attempt}/3).", flush=True)
        try:
            subprocess.run(
                [str(manager), "--install", package, "--channel=0"],
                check=True, timeout=SYSTEM_IMAGE_TIMEOUT_SECONDS,
            )
            if _image_is_complete(image):
                return
            # sdkmanager can report success after a corrupt archive was
            # skipped ("Error reading Zip content"), leaving no usable image.
            print("System image is incomplete after installation.", flush=True)
        except (OSError, subprocess.SubprocessError) as error:
            print(f"System image installation failed: {error}", flush=True)
        # Drop the partial image and download leftovers so the retry fetches
        # a fresh archive instead of reusing the corrupt one.
        shutil.rmtree(image, ignore_errors=True)
        for leftover in (".temp", ".downloadIntermediates"):
            shutil.rmtree(sdk / leftover, ignore_errors=True)
        if attempt < 3:
            time.sleep(5)
    raise RuntimeError(f"{package} could not be installed after 3 attempts.")


if __name__ == "__main__":
    sdk_root = Path(os.environ["ANDROID_HOME"])
    prepare(sdk_root)
    prepare_system_image(
        sdk_root, os.environ.get("ANDROID_SYSTEM_IMAGE", DEFAULT_SYSTEM_IMAGE)
    )
