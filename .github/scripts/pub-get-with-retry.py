#!/usr/bin/env python3
"""Run `flutter pub get` with bounded retries.

Hosted macOS runners sometimes stall downloading packages; one stalled attempt
used to time out the whole iOS job before any test ran.
"""

import shutil
import subprocess
import sys
import time

ATTEMPTS = 3
ATTEMPT_TIMEOUT_SECONDS = 4 * 60


def main() -> int:
    flutter = shutil.which("flutter")
    if flutter is None:
        print("flutter is not on PATH.", file=sys.stderr)
        return 2
    for attempt in range(1, ATTEMPTS + 1):
        print(f"flutter pub get (attempt {attempt}/{ATTEMPTS})", flush=True)
        try:
            subprocess.run(
                [flutter, "pub", "get"], check=True, timeout=ATTEMPT_TIMEOUT_SECONDS
            )
            return 0
        except (OSError, subprocess.SubprocessError) as error:
            print(f"flutter pub get failed: {error}", flush=True)
            if attempt < ATTEMPTS:
                time.sleep(15)
    print(f"flutter pub get failed after {ATTEMPTS} attempts.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
