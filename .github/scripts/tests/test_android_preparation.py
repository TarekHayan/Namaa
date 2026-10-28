import importlib.util
from contextlib import redirect_stdout
import io
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
        self.assertIn("-no-window", run.call_args_list[2].args[0])

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
            ]) as run,
            patch.object(preparation.time, "sleep"),
        ):
            with self.assertRaisesRegex(ValueError, "valid version"):
                preparation.prepare(self.sdk)
        self.assertEqual(run.call_count, 2)

    def test_binary_error_is_visible_and_does_not_repeat_installation(self):
        output = io.StringIO()
        with (
            patch.object(preparation.subprocess, "run", side_effect=[
                subprocess.CompletedProcess([], 0),
                subprocess.CompletedProcess([], 127, "", "Missing runtime library"),
            ]) as run,
            redirect_stdout(output),
        ):
            with self.assertRaises(subprocess.CalledProcessError):
                preparation.prepare(self.sdk)
        self.assertEqual(run.call_count, 2)
        self.assertIn("Missing runtime library", output.getvalue())


class SystemImagePreparationTest(unittest.TestCase):
    PACKAGE = "system-images;android-35;google_apis;x86_64"

    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="namaa_android_image_")
        self.addCleanup(directory.cleanup)
        self.sdk = Path(directory.name)
        manager = self.sdk / "cmdline-tools/latest/bin/sdkmanager"
        manager.parent.mkdir(parents=True)
        manager.touch()
        self.image = self.sdk / "system-images/android-35/google_apis/x86_64"

    def install_image(self, *_args, **_kwargs):
        self.image.mkdir(parents=True, exist_ok=True)
        (self.image / "source.properties").write_text("Pkg.Revision=1\n")
        (self.image / "system.img").write_bytes(b"img")
        return subprocess.CompletedProcess([], 0)

    def test_installed_image_is_not_downloaded_again(self):
        self.install_image()
        with patch.object(preparation.subprocess, "run") as run:
            preparation.prepare_system_image(self.sdk, self.PACKAGE)
        run.assert_not_called()

    def test_corrupt_download_is_removed_and_retried(self):
        def corrupt(*_args, **_kwargs):
            # The CI failure: sdkmanager skips a corrupt archive, exits 0,
            # and leaves a partial folder with no system.img.
            self.image.mkdir(parents=True, exist_ok=True)
            (self.image / "source.properties").write_text("partial\n")
            (self.sdk / ".temp").mkdir(exist_ok=True)
            return subprocess.CompletedProcess([], 0)

        attempts = iter([corrupt, self.install_image])
        with (
            patch.object(preparation.subprocess, "run",
                         side_effect=lambda *a, **k: next(attempts)(*a, **k)) as run,
            patch.object(preparation.time, "sleep"),
        ):
            preparation.prepare_system_image(self.sdk, self.PACKAGE)
        self.assertEqual(run.call_count, 2)
        first = run.call_args_list[0]
        self.assertEqual(first.args[0][1:], ["--install", self.PACKAGE, "--channel=0"])
        self.assertEqual(first.kwargs["timeout"], preparation.SYSTEM_IMAGE_TIMEOUT_SECONDS)
        self.assertTrue((self.image / "system.img").is_file())
        self.assertFalse((self.sdk / ".temp").exists())

    def test_persistent_failure_stops_after_three_attempts(self):
        with (
            patch.object(preparation.subprocess, "run", side_effect=
                         subprocess.CalledProcessError(1, "sdkmanager")) as run,
            patch.object(preparation.time, "sleep"),
        ):
            with self.assertRaisesRegex(RuntimeError, "after 3 attempts"):
                preparation.prepare_system_image(self.sdk, self.PACKAGE)
        self.assertEqual(run.call_count, 3)

    def test_timeout_is_bounded_and_retried(self):
        timeouts = iter([subprocess.TimeoutExpired("sdkmanager", 360)] * 2)

        def attempt(*args, **kwargs):
            error = next(timeouts, None)
            if error is not None:
                raise error
            return self.install_image()

        with (
            patch.object(preparation.subprocess, "run", side_effect=attempt) as run,
            patch.object(preparation.time, "sleep"),
        ):
            preparation.prepare_system_image(self.sdk, self.PACKAGE)
        self.assertEqual(run.call_count, 3)
        self.assertTrue((self.image / "system.img").is_file())

    def test_rejects_a_package_that_is_not_a_system_image(self):
        with self.assertRaisesRegex(ValueError, "Not a system image"):
            preparation.prepare_system_image(self.sdk, "platforms;android-35")


if __name__ == "__main__":
    unittest.main()
