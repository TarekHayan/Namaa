import importlib.util
from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "ios_runner", ROOT / ".github/scripts/run-ios-integration.py"
)
ios_runner = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ios_runner)


class IosResultsTest(unittest.TestCase):
    def run_main(self, status, summary=None, summary_status=0):
        completed = subprocess.CompletedProcess([], summary_status, json.dumps(summary or {}))
        with (
            patch.object(sys, "argv", ["runner", "results.xcresult", "--", "xcodebuild"]),
            patch.object(ios_runner, "run_attempt", return_value=(status, "")),
            patch.object(ios_runner.subprocess, "run", return_value=completed) as read_result,
        ):
            result = ios_runner.main()
        return result, read_result.call_count

    def test_requires_successful_nonempty_native_results(self):
        self.assertEqual(
            self.run_main(0, {"totalTestCount": 1, "passedTests": 1, "failedTests": 0}),
            (0, 1),
        )

    def test_rejects_empty_results(self):
        self.assertEqual(self.run_main(0, {"totalTestCount": 0}), (1, 1))

    def test_rejects_failed_or_skipped_results(self):
        for failures in (0, 1):
            with self.subTest(failures=failures):
                self.assertEqual(
                    self.run_main(
                        0, {"totalTestCount": 2, "passedTests": 1, "failedTests": failures}
                    ),
                    (1, 1),
                )

    def test_propagates_xcode_failure_without_retrying(self):
        output = io.StringIO()
        with redirect_stdout(output):
            result = self.run_main(
                65, {"testFailures": [{"failureText": "credential-vault assertion failed"}]}
            )
        self.assertEqual(result, (65, 1))
        self.assertIn("credential-vault assertion failed", output.getvalue())

    def test_unreadable_bundle_does_not_hide_xcode_failure(self):
        self.assertEqual(self.run_main(65, summary_status=1), (65, 1))

    def test_xcode_success_requires_readable_bundle(self):
        self.assertEqual(self.run_main(0, summary_status=1), (1, 1))

    def test_timeout_cannot_pass(self):
        self.assertEqual(self.run_main(None), (124, 0))


class AndroidRetryTest(unittest.TestCase):
    def run_probe(self, scenario):
        bash = (
            r"C:\Program Files\Git\bin\bash.exe"
            if os.name == "nt"
            else shutil.which("bash")
        )
        if not bash or not Path(bash).is_file():
            self.skipTest("Bash is unavailable")
        with tempfile.TemporaryDirectory(prefix="namaa_ci_probe_") as directory:
            probe = Path(directory)
            def bash_path(path):
                value = path.as_posix()
                return "/" + value[0].lower() + value[2:] if os.name == "nt" else value

            scripts = {
                "adb": "exit 0\n",
                "timeout": 'while [[ "$1" == -* ]]; do shift; done\nshift\n"$@"\n',
                "flutter": '''echo "$*" >> "$PROBE_CALLS"
if [[ ! -f "$PROBE_MARKER" ]]; then
  touch "$PROBE_MARKER"
  if [[ "$PROBE_SCENARIO" != startup-kill ]]; then
    echo 'VMServiceFlutterDriver: Connected to Flutter application.'
  fi
  if [[ "$PROBE_SCENARIO" == assertion ]]; then
    echo 'Failure Details: assertion failed'
    exit 1
  fi
  exit 137
fi
echo 'All tests passed'
''',
            }
            for name, contents in scripts.items():
                stub = probe / name
                stub.write_text("#!/usr/bin/env bash\n" + contents, encoding="utf-8")
                stub.chmod(0o755)
            env = dict(os.environ)
            env.update(
                ANDROID_SUITE="foundation-tasks",
                PROBE_BIN=bash_path(probe),
                PROBE_CALLS=bash_path(probe / "calls"),
                PROBE_MARKER=bash_path(probe / "marker"),
                PROBE_SCRIPT=bash_path(ROOT / ".github/scripts/run-android-integration.sh"),
                PROBE_SCENARIO=scenario,
            )
            for name in (
                "LOCAL_SUPABASE_PUBLISHABLE_KEY", "STAGING_SUPABASE_URL",
                "STAGING_SUPABASE_PUBLISHABLE_KEY", "STAGING_TEST_USER_A_EMAIL",
                "STAGING_TEST_USER_A_PASSWORD", "STAGING_TEST_USER_B_EMAIL",
                "STAGING_TEST_USER_B_PASSWORD",
            ):
                env["NAMAA_" + name] = "probe"
            result = subprocess.run(
                [bash, "-c", 'export PATH="$PROBE_BIN:$PATH"; exec bash "$PROBE_SCRIPT"'],
                cwd=ROOT, env=env, capture_output=True, text=True, timeout=90,
            )
            calls_file = probe / "calls"
            self.assertTrue(calls_file.is_file(), result.stdout + result.stderr)
            calls = calls_file.read_text().splitlines()
        return result, calls

    def test_sigkill_before_test_retries_once_then_runs_suite(self):
        result, calls = self.run_probe("startup-kill")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(calls), 11)
        self.assertEqual(calls[0], calls[1])

    def test_real_test_failure_is_not_retried(self):
        result, calls = self.run_probe("assertion")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(len(calls), 1)

    def test_timeout_after_test_started_is_not_retried(self):
        result, calls = self.run_probe("test-kill")
        self.assertEqual(result.returncode, 137, result.stdout + result.stderr)
        self.assertEqual(len(calls), 1)


if __name__ == "__main__":
    unittest.main()
