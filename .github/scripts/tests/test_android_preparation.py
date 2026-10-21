import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "android_preparation", ROOT / ".github/scripts/prepare-android-emulator.py"
)
preparation = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(preparation)


class AndroidPreparationTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="namaa_android_setup_")
        self.addCleanup(directory.cleanup)
        self.sdk = Path(directory.name)
        manager = self.sdk / "cmdline-tools/latest/bin/sdkmanager"
        manager.parent.mkdir(parents=True)
        manager.touch()
        self.version = subprocess.CompletedProcess(
            [], 0, "Android emulator version 37.2.12.0 (build_id 16428233)", ""
        )

    def test_corrupt_download_retries_installation_before_version_check(self):
        with (
            patch.object(preparation.subprocess, "run", side_effect=[
                subprocess.CalledProcessError(1, "sdkmanager"),
                subprocess.CompletedProcess([], 0), self.version,
            ]) as run,
            patch.object(preparation.time, "sleep"),
        ):
            preparation.prepare(self.sdk)
        self.assertEqual(run.call_count, 3)
        self.assertEqual(run.call_args_list[0], run.call_args_list[1])
        self.assertEqual(run.call_args_list[2].args[0][-1], "-version")

    def test_persistent_install_failure_stops_after_three_attempts(self):
        with (
            patch.object(preparation.subprocess, "run", side_effect=
                         subprocess.CalledProcessError(1, "sdkmanager")) as run,
            patch.object(preparation.time, "sleep"),
        ):
            with self.assertRaises(subprocess.CalledProcessError):
                preparation.prepare(self.sdk)
        self.assertEqual(run.call_count, 3)
        self.assertTrue(all("--install" in call.args[0] for call in run.call_args_list))

    def test_timeout_is_bounded_and_cannot_report_success(self):
        with (
            patch.object(preparation.subprocess, "run", side_effect=
                         subprocess.TimeoutExpired("sdkmanager", 120)) as run,
            patch.object(preparation.time, "sleep"),
        ):
            with self.assertRaises(subprocess.TimeoutExpired):
                preparation.prepare(self.sdk)
        self.assertEqual(run.call_count, 3)
        self.assertTrue(all(call.kwargs["timeout"] == 120 for call in run.call_args_list))

    def test_invalid_binary_cannot_pass_successful_installer(self):
        with (
            patch.object(preparation.subprocess, "run", side_effect=[
                subprocess.CompletedProcess([], 0), subprocess.CompletedProcess([], 0, "", ""),
            ] * 3),
            patch.object(preparation.time, "sleep"),
        ):
            with self.assertRaisesRegex(ValueError, "valid version"):
                preparation.prepare(self.sdk)


if __name__ == "__main__":
    unittest.main()
