import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("ndk", ROOT / ".github/scripts/prepare-android-ndk.py")
ndk = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ndk)
VERSION = "28.2.13676358"


def create_package(package):
    package.mkdir(parents=True, exist_ok=True)
    (package / "source.properties").write_text(f"Pkg.Revision = {VERSION}\n")
    clang = package / "toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
    clang.parent.mkdir(parents=True)
    clang.touch()


class NdkPreparationTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="namaa_ndk_test_")
        self.addCleanup(directory.cleanup)
        self.sdk = Path(directory.name)
        manager = self.sdk / "cmdline-tools/latest/bin/sdkmanager"
        manager.parent.mkdir(parents=True)
        manager.touch()

    def test_corrupt_archive_retries_in_a_fresh_directory_and_verifies_binary(self):
        roots = []
        probes = []
        def run(command, **kwargs):
            if "--install" in command:
                root = Path(command[1].split("=", 1)[1])
                roots.append(root)
                if len(roots) == 1:
                    (root / "corrupt.zip").touch()
                    raise subprocess.CalledProcessError(1, command)
                self.assertFalse((root / "corrupt.zip").exists())
                create_package(root / "ndk" / VERSION)
            else:
                probes.append(command)
            return subprocess.CompletedProcess(command, 0)
        with patch.object(ndk.subprocess, "run", side_effect=run), patch.object(ndk.time, "sleep"):
            ndk.prepare(self.sdk, VERSION)
        self.assertEqual(len(roots), 2)
        self.assertNotEqual(roots[0], roots[1])
        self.assertTrue(all(not root.exists() for root in roots))
        self.assertEqual(len(probes), 2)
        self.assertTrue((self.sdk / "ndk" / VERSION / "source.properties").is_file())

    def test_persistent_download_failure_stops_after_three_attempts(self):
        with patch.object(ndk.subprocess, "run", side_effect=subprocess.TimeoutExpired("sdkmanager", 180)) as run, patch.object(ndk.time, "sleep"):
            with self.assertRaises(subprocess.TimeoutExpired):
                ndk.prepare(self.sdk, VERSION)
        self.assertEqual(run.call_count, 3)
        self.assertTrue(all(call.kwargs["timeout"] == 180 for call in run.call_args_list))
        self.assertFalse((self.sdk / "ndk" / VERSION).exists())

    def test_invalid_installer_output_cannot_pass(self):
        with patch.object(ndk.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run, patch.object(ndk.time, "sleep"):
            with self.assertRaises(FileNotFoundError):
                ndk.prepare(self.sdk, VERSION)
        self.assertEqual(run.call_count, 3)

    def test_verified_preinstalled_ndk_is_reused(self):
        create_package(self.sdk / "ndk" / VERSION)
        with patch.object(ndk.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
            ndk.prepare(self.sdk, VERSION)
        self.assertEqual(run.call_count, 1)
        self.assertEqual(run.call_args.args[0][-1], "--version")

    def test_ndk_version_comes_from_the_checked_out_flutter_sdk(self):
        extension = self.sdk / "packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
        extension.parent.mkdir(parents=True)
        extension.write_text(f'val ndkVersion: String = "{VERSION}"')
        self.assertEqual(ndk.requested_version(self.sdk), VERSION)
        extension.write_text("unrecognized Flutter configuration")
        with self.assertRaises(ValueError):
            ndk.requested_version(self.sdk)


if __name__ == "__main__":
    unittest.main()
