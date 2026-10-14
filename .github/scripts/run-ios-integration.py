#!/usr/bin/env python3
"""Retry only an iOS integration-test startup stall, not a failed test."""

import os
import signal
import subprocess
import sys
import threading
from typing import Optional


ATTEMPT_TIMEOUT_SECONDS = 12 * 60


def run_attempt(command: list[str]) -> tuple[Optional[int], str]:
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
        start_new_session=True,
    )
    output: list[str] = []

    def relay_output() -> None:
        assert process.stdout is not None
        for line in process.stdout:
            output.append(line)
            print(line, end="", flush=True)

    reader = threading.Thread(target=relay_output, daemon=True)
    reader.start()
    try:
        return_code = process.wait(timeout=ATTEMPT_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
        reader.join(timeout=5)
        return None, "".join(output)

    reader.join(timeout=5)
    return return_code, "".join(output)


def main() -> int:
    if len(sys.argv) < 4 or sys.argv[2] != "--":
        print("Usage: run-ios-integration.py DEVICE_ID -- COMMAND...", file=sys.stderr)
        return 2

    device_id = sys.argv[1]
    command = sys.argv[3:]
    for attempt in (1, 2):
        print(f"iOS integration attempt {attempt}/2", flush=True)
        return_code, output = run_attempt(command)
        if return_code is not None:
            return return_code

        started_tests = (
            "VMServiceFlutterDriver: Connected to Flutter application." in output
            or "All tests passed" in output
            or "Failure Details:" in output
        )
        if started_tests or attempt == 2:
            print("iOS integration timed out; not treating it as a pass.", file=sys.stderr)
            return 124

        print("iOS test did not start; rebooting simulator for one retry.", flush=True)
        subprocess.run(["xcrun", "simctl", "shutdown", device_id], check=False)
        subprocess.run(["xcrun", "simctl", "boot", device_id], check=True)
        subprocess.run(["xcrun", "simctl", "bootstatus", device_id, "-b"], check=True)

    return 124


if __name__ == "__main__":
    sys.exit(main())
