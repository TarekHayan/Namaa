#!/usr/bin/env python3
"""Prefetch the pinned encrypted SQLite artifact into its verified hook cache."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import urljoin, urlparse
from urllib.request import url2pathname


def artifact(project: Path, architecture: str) -> tuple[str, str, Path]:
    config = project / ".dart_tool/package_config.json"
    packages = json.loads(config.read_text())["packages"]
    package = next(p for p in packages if p["name"] == "sqlite3")
    uri = urlparse(urljoin(config.resolve().as_uri(), package["rootUri"]))
    if uri.scheme != "file":
        raise ValueError("Expected a local sqlite3 package after pub get.")
    package_root = Path(url2pathname(uri.path))
    manifest = (package_root / "lib/src/hook/asset_hashes.dart").read_text()
    tag = re.search(r"releaseTag = '(sqlite3-[0-9.]+)'", manifest).group(1)
    # The cache layout is documented by sqlite3 3.5.2 and verified by its hook.
    if tag != "sqlite3-3.5.2":
        raise ValueError("Revalidate the SQLite hook cache layout after upgrading sqlite3.")
    filename = f"libsqlite3mc.{architecture}.ios_sim.dylib"
    digest = re.search(r"'" + re.escape(filename) + r"': '([0-9a-f]{64})'", manifest).group(1)
    destination = (
        project / ".dart_tool/hooks_runner/shared/sqlite3/build"
        / f"download-{digest[:8]}" / "libsqlite3mc.dylib"
    )
    url = f"https://github.com/simolus3/sqlite3.dart/releases/download/{tag}/{filename}"
    return url, digest, destination


def verified_file(path: Path, digest: str) -> bool:
    return path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == digest


def prefetch(url: str, digest: str, destination: Path) -> None:
    if verified_file(destination, digest):
        print("Encrypted SQLite simulator artifact already verified.", flush=True)
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(".download")
    try:
        subprocess.run(
            ["curl", "--fail", "--location", "--show-error", "--silent",
             "--retry", "3", "--retry-all-errors", "--retry-delay", "2",
             "--retry-max-time", "240", "--connect-timeout", "10", "--max-time", "90",
             "--output", str(temporary), url],
            check=True, timeout=300,
        )
        if not verified_file(temporary, digest):
            raise ValueError("Encrypted SQLite artifact checksum mismatch.")
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    print("Encrypted SQLite simulator artifact downloaded and SHA-256 verified.", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--arch", type=str.lower, choices=("x64", "arm64"), required=True)
    args = parser.parse_args()
    prefetch(*artifact(Path.cwd(), args.arch))


if __name__ == "__main__":
    main()
