#!/usr/bin/env python3
"""Bound a native XCTest run and require a nonempty, successful result bundle."""

import json
import os
import signal
import subprocess
import sys
import threading
from typing import Optional


ATTEMPT_TIMEOUT_SECONDS = 12 * 60
BUILD_TIMEOUT_SECONDS = 25 * 60


def run_attempt(
    command: list[str], *, timeout_seconds: int = ATTEMPT_TIMEOUT_SECONDS
) -> tuple[Optional[int], str]:
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
        return_code = process.wait(timeout=timeout_seconds)
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


def read_result_summary(result_bundle: str) -> Optional[dict]:
    try:
        summary = subprocess.run(
            ["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", result_bundle],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
        if summary.returncode != 0:
            print("Unable to read iOS XCTest result summary.", file=sys.stderr)
            return None
        result = json.loads(summary.stdout)
    except (OSError, subprocess.SubprocessError, ValueError):
        print("Unable to read iOS XCTest result summary.", file=sys.stderr)
        return None

    for failure in result.get("testFailures", []):
        print("iOS XCTest failure: " + json.dumps(failure, ensure_ascii=True), flush=True)
    return result


def main() -> int:
    if len(sys.argv) < 4 or sys.argv[2] != "--":
        print("Usage: run-ios-integration.py RESULT_BUNDLE|--build-only -- COMMAND...", file=sys.stderr)
        return 2

    result_bundle = sys.argv[1]
    command = sys.argv[3:]
    if result_bundle == "--build-only":
        return_code, _ = run_attempt(command, timeout_seconds=BUILD_TIMEOUT_SECONDS)
        if return_code is None:
            print("iOS build-for-testing timed out before XCTest execution.", file=sys.stderr)
            return 124
        return return_code
    return_code, _ = run_attempt(command)
    if return_code is None:
        print("iOS native integration run timed out.", file=sys.stderr)
        return 124
    # Even a quiet Xcode failure keeps its assertion/crash details in xcresult.
    # Print those details before propagating the original failure status.
    result = read_result_summary(result_bundle)
    if return_code != 0:
        return return_code
    if result is None:
        return 1
    total = result.get("totalTestCount", 0)
    passed = result.get("passedTests", 0)
    if total < 1 or passed != total or result.get("failedTests", 0) != 0:
        print("iOS result bundle has missing, skipped, or failed tests.", file=sys.stderr)
        return 1
    print(f"iOS XCTest verified: {passed}/{total} native tests passed.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
