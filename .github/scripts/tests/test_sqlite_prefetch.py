import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("sqlite_prefetch", ROOT / ".github/scripts/prefetch-ios-sqlite.py")
prefetch = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(prefetch)


class SqlitePrefetchTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="namaa_sqlite_probe_")
        self.addCleanup(self.directory.cleanup)
        self.project = Path(self.directory.name)
        self.payload = b"test encrypted artifact bytes"
        self.digest = hashlib.sha256(self.payload).hexdigest()
        self.destination = self.project / "cache/libsqlite3mc.dylib"
        self.url = "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/probe"

    def download(self, command, **kwargs):
        Path(command[command.index("--output") + 1]).write_bytes(self.payload)
        return subprocess.CompletedProcess(command, 0)

    def test_valid_cache_requires_no_network(self):
        self.destination.parent.mkdir()
        self.destination.write_bytes(self.payload)
        with patch.object(prefetch.subprocess, "run") as download:
            prefetch.prefetch(self.url, self.digest, self.destination)
        download.assert_not_called()

    def test_corrupt_cache_is_replaced_only_after_verified_download(self):
        self.destination.parent.mkdir()
        self.destination.write_bytes(b"corrupt")
        with patch.object(prefetch.subprocess, "run", side_effect=self.download):
            prefetch.prefetch(self.url, self.digest, self.destination)
        self.assertEqual(self.destination.read_bytes(), self.payload)

    def test_checksum_mismatch_cannot_populate_hook_cache(self):
        with patch.object(prefetch.subprocess, "run", side_effect=self.download):
            with self.assertRaisesRegex(ValueError, "checksum mismatch"):
                prefetch.prefetch(self.url, "0" * 64, self.destination)
        self.assertFalse(self.destination.exists())
        self.assertFalse(self.destination.with_suffix(".download").exists())

    def test_download_failure_cannot_populate_hook_cache(self):
        with patch.object(prefetch.subprocess, "run", side_effect=subprocess.TimeoutExpired("curl", 300)):
            with self.assertRaises(subprocess.TimeoutExpired):
                prefetch.prefetch(self.url, self.digest, self.destination)
        self.assertFalse(self.destination.exists())

    def test_uses_hash_and_release_from_resolved_package(self):
        package = self.project / "sqlite-package"
        manifest = package / "lib/src/hook/asset_hashes.dart"
        manifest.parent.mkdir(parents=True)
        manifest.write_text(
            "const String? releaseTag = 'sqlite3-3.5.2';\n"
            f"const hashes = {{'libsqlite3mc.x64.ios_sim.dylib': '{self.digest}'}};"
        )
        config = self.project / ".dart_tool/package_config.json"
        config.parent.mkdir()
        config.write_text(json.dumps({"packages": [{"name": "sqlite3", "rootUri": package.as_uri()}]}))
        url, digest, destination = prefetch.artifact(self.project, "x64")
        self.assertTrue(url.endswith("sqlite3-3.5.2/libsqlite3mc.x64.ios_sim.dylib"))
        self.assertEqual(digest, self.digest)
        self.assertEqual(destination.name, "libsqlite3mc.dylib")
        self.assertEqual(destination.parent.name, "download-" + self.digest[:8])


if __name__ == "__main__":
    unittest.main()
