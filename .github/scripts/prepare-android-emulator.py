#!/usr/bin/env python3
"""Finish emulator installation before the action's single-attempt SDK setup."""

import os
from pathlib import Path
import re
import subprocess
import time


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
            version = subprocess.run(
                [str(emulator), "-version"], check=True, timeout=30,
                capture_output=True, text=True,
            )
            output = version.stdout + version.stderr
            if not re.search(r"Android emulator version \d+\.\d+", output):
                raise ValueError("Installed emulator did not report a valid version.")
            print(output, flush=True)
            return
        except (OSError, subprocess.SubprocessError, ValueError):
            if attempt == 3:
                raise
            print("Emulator preparation failed; retrying installation only.", flush=True)
            time.sleep(5)


if __name__ == "__main__":
    prepare(Path(os.environ["ANDROID_HOME"]))
