import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]


class SupabasePortReservationTest(unittest.TestCase):
    def reserve(self, existing, write_status=0):
        bash = r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else shutil.which("bash")
        if not bash or not Path(bash).is_file():
            self.skipTest("Bash is unavailable")

        def bash_path(path):
            value = path.as_posix()
            return "/" + value[0].lower() + value[2:] if os.name == "nt" else value

        with tempfile.TemporaryDirectory(prefix="namaa_ports_probe_") as directory:
            probe = Path(directory)
            stubs = {
                "sudo": 'exec "$@"\n',
                "sysctl": '''if [[ "$1" == -n ]]; then
  printf '%s' "$RESERVED_EXISTING"
else
  printf '%s' "$2" > "$PROBE_WRITE"
  exit "$PROBE_WRITE_STATUS"
fi
''',
            }
            for name, body in stubs.items():
                path = probe / name
                path.write_text("#!/usr/bin/env bash\n" + body)
                path.chmod(0o755)
            env = dict(os.environ)
            env.update(
                PROBE_BIN=bash_path(probe),
                PROBE_SCRIPT=bash_path(ROOT / ".github/scripts/reserve-supabase-ports.sh"),
                PROBE_WRITE=bash_path(probe / "write"),
                RESERVED_EXISTING=existing,
                PROBE_WRITE_STATUS=str(write_status),
            )
            result = subprocess.run(
                [bash, "-c", 'export PATH="$PROBE_BIN:$PATH"; exec bash "$PROBE_SCRIPT"'],
                env=env, capture_output=True, text=True, timeout=15,
            )
            write = probe / "write"
            value = write.read_text() if write.exists() else None
        return result.returncode, value

    def test_reserves_fixed_ports_before_downloads_claim_them(self):
        self.assertEqual(self.reserve(""), (0, "net.ipv4.ip_local_reserved_ports=54320-54329"))

    def test_preserves_runner_reserved_ports(self):
        self.assertEqual(
            self.reserve("8080,45000-45010"),
            (0, "net.ipv4.ip_local_reserved_ports=8080,45000-45010,54320-54329"),
        )

    def test_cannot_report_success_if_reservation_fails(self):
        self.assertEqual(self.reserve("", 1)[0], 1)


if __name__ == "__main__":
    unittest.main()
