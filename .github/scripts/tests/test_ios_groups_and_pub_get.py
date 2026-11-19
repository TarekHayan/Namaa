import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, ROOT / ".github/scripts" / file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


pub_get = load("pub_get_retry", "pub-get-with-retry.py")

ALL_GROUPS = ["foundation", "tasks", "habits", "mind-maps", "today", "prayer", "adhkar-qiyam"]


class IosGroupRegistrationTest(unittest.TestCase):
    def test_default_matrix_runs_every_group_of_the_runner(self):
        workflow = (ROOT / ".github/workflows/foundation-ci.yml").read_text()
        default = '[' + ','.join(f'"{g}"' for g in ALL_GROUPS) + ']'
        self.assertIn(default, workflow)
        self.assertIn("bash .github/scripts/run-ios-integration-group.sh", workflow)
        script = (ROOT / ".github/scripts/run-ios-integration-group.sh").read_text()
        for group in ALL_GROUPS:
            self.assertIn(f"\n  {group})\n", script)

    def test_pull_requests_run_the_full_five_target_gate(self):
        workflow = (ROOT / ".github/workflows/foundation-ci.yml").read_text()
        gate = workflow.split("  foundation-gate:", 1)[1]
        self.assertIn("- ios", gate)
        self.assertIn("IOS_RESULT", gate)
        self.assertNotIn("labeled", workflow)

    def test_prayer_files_are_in_every_desktop_gate(self):
        workflow = (ROOT / ".github/workflows/foundation-ci.yml").read_text()
        desktop_jobs = [
            workflow.split(f"\n  {name}:\n", 1)[1].split(f"\n  {next_name}:\n", 1)[0]
            for name, next_name in (("linux", "windows"), ("windows", "macos"),
                                    ("macos", "ios"))
        ]
        for suite in ("schedule", "reports", "offline_sync", "localized_route"):
            for job in desktop_jobs:
                self.assertIn(f"integration_test/prayer_{suite}_test.dart", job)
        self.assertIn("'specs/008-prayer-experience/**'", workflow)
        self.assertNotIn("\npush:", workflow)


    def test_adhkar_qiyam_files_are_in_every_desktop_gate(self):
        workflow = (ROOT / ".github/workflows/foundation-ci.yml").read_text()
        desktop_jobs = {
            name: workflow.split(f"\n  {name}:\n", 1)[1].split(f"\n  {next_name}:\n", 1)[0]
            for name, next_name in (("linux", "windows"), ("windows", "macos"),
                                    ("macos", "ios"))
        }
        for suite in ("flow", "offline_sync", "localized_route"):
            for name, job in desktop_jobs.items():
                self.assertEqual(
                    job.count(f"integration_test/adhkar_qiyam_{suite}_test.dart"),
                    # The hosted sync file is named once in the list and once in
                    # the per-file staging condition on Windows and macOS.
                    2 if suite == "offline_sync" and name != "linux" else 1,
                    f"{name} {suite}",
                )
        self.assertIn("'specs/009-adhkar-qiyam/**'", workflow)
        self.assertNotIn("\npush:", workflow)

    def test_hosted_adhkar_qiyam_sync_runs_on_non_production_staging(self):
        workflow = (ROOT / ".github/workflows/foundation-ci.yml").read_text()
        windows = workflow.split("\n  windows:\n", 1)[1].split("\n  macos:\n", 1)[0]
        macos = workflow.split("\n  macos:\n", 1)[1].split("\n  ios:\n", 1)[0]
        self.assertIn(
            "$test -eq 'integration_test/adhkar_qiyam_offline_sync_test.dart'", windows)
        self.assertIn(
            '"$test_file" == integration_test/adhkar_qiyam_offline_sync_test.dart', macos)
        for job in (windows, macos):
            self.assertIn("NAMAA_SUPABASE_ENV=non-production", job)

    def test_the_five_target_gate_still_depends_on_every_job(self):
        workflow = (ROOT / ".github/workflows/foundation-ci.yml").read_text()
        gate = workflow.split("  foundation-gate:", 1)[1]
        needs = gate.split("needs:", 1)[1].split("runs-on:", 1)[0]
        for job in ("quality", "database-security", "android", "linux", "windows",
                    "macos", "ios"):
            self.assertIn(f"- {job}\n", needs)
        for result in ("QUALITY_RESULT", "DATABASE_RESULT", "ANDROID_RESULT",
                       "LINUX_RESULT", "WINDOWS_RESULT", "MACOS_RESULT", "IOS_RESULT"):
            self.assertIn(f'"${result}"', gate)


class PubGetRetryTest(unittest.TestCase):
    def run_main(self, side_effect):
        with (
            patch.object(pub_get.shutil, "which", return_value="flutter"),
            patch.object(pub_get.subprocess, "run", side_effect=side_effect) as run,
            patch.object(pub_get.time, "sleep"),
        ):
            return pub_get.main(), run

    def test_stalled_download_is_retried(self):
        result, run = self.run_main([
            subprocess.TimeoutExpired("flutter", 240), subprocess.CompletedProcess([], 0),
        ])
        self.assertEqual(result, 0)
        self.assertEqual(run.call_count, 2)
        self.assertTrue(all(c.kwargs["timeout"] == 240 for c in run.call_args_list))

    def test_persistent_failure_stops_after_three_attempts(self):
        result, run = self.run_main(subprocess.CalledProcessError(1, "flutter"))
        self.assertEqual(result, 1)
        self.assertEqual(run.call_count, 3)


class IosGroupRunnerTest(unittest.TestCase):
    """Drives run-ios-integration-group.sh with stub flutter/python3/xcrun."""

    def run_group(self, group, fail_test=(), fail_build=(), suites=""):
        bash = (
            r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else shutil.which("bash")
        )
        if not bash or not Path(bash).is_file():
            self.skipTest("Bash is unavailable")

        def bash_path(path):
            value = path.as_posix()
            return "/" + value[0].lower() + value[2:] if os.name == "nt" else value

        with tempfile.TemporaryDirectory(prefix="namaa_ios_group_") as directory:
            probe = Path(directory)
            stubs = {
                "flutter": 'echo "flutter $*" >> "$PROBE_CALLS"\n',
                "xcrun": 'echo "xcrun $*" >> "$PROBE_CALLS"\n',
                # The entry point names the file under test; stubs read it to
                # decide which file is being built or run.
                "python3": r'''if [[ "$1" == - ]]; then cat >/dev/null; exit 0; fi
current="$(sed -n "s#^import '../../integration_test/\(.*\)_test.dart' as scenario;#\1#p" build/ios_integration/entrypoint.dart)"
if [[ "$2" == --build-only ]]; then
  echo "build $current" >> "$PROBE_CALLS"
  [[ " $PROBE_FAIL_BUILD " == *" $current "* ]] && exit 65
  exit 0
fi
echo "test $current" >> "$PROBE_CALLS"
[[ " $PROBE_FAIL_TEST " == *" $current "* ]] && exit 65
exit 0
''',
            }
            for name, body in stubs.items():
                stub = probe / name
                stub.write_text("#!/usr/bin/env bash\n" + body, encoding="utf-8")
                stub.chmod(0o755)
            env = dict(os.environ)
            env.update(
                IOS_GROUP=group, IOS_DEVICE_ID="SIM-1", IOS_SUITES=suites,
                PROBE_BIN=bash_path(probe), PROBE_CALLS=bash_path(probe / "calls"),
                PROBE_FAIL_TEST=" ".join(fail_test), PROBE_FAIL_BUILD=" ".join(fail_build),
                PROBE_SCRIPT=bash_path(ROOT / ".github/scripts/run-ios-integration-group.sh"),
            )
            for name in (
                "SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "TEST_USER_A_EMAIL",
                "TEST_USER_A_PASSWORD", "TEST_USER_B_EMAIL", "TEST_USER_B_PASSWORD",
            ):
                env["NAMAA_STAGING_" + name] = "probe"
            result = subprocess.run(
                [bash, "-c", 'export PATH="$PROBE_BIN:$PATH"; exec bash "$PROBE_SCRIPT"'],
                cwd=ROOT, env=env, capture_output=True, text=True, timeout=120,
            )
            calls_file = probe / "calls"
            calls = calls_file.read_text().splitlines() if calls_file.is_file() else []
        return result, calls

    def test_each_file_builds_resets_and_runs_in_order(self):
        result, calls = self.run_group("today")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            [c for c in calls if c.startswith(("build", "test"))],
            ["build today_dashboard", "test today_dashboard",
             "build today_sync", "test today_sync"],
        )
        resets = [c for c in calls if c.startswith("xcrun simctl")]
        self.assertEqual(len(resets), 4, calls)
        self.assertIn("xcrun simctl keychain SIM-1 reset", resets)
        self.assertIn("all 2 files passed", result.stdout)

    def test_failing_file_does_not_stop_the_rest(self):
        result, calls = self.run_group("tasks", fail_test=("tasks_completion_sync",))
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len([c for c in calls if c.startswith("test ")]), 4)
        self.assertIn("1 of 4 files failed: tasks-completion-sync", result.stderr)

    def test_build_failure_skips_only_that_files_run(self):
        result, calls = self.run_group("habits", fail_build=("habits_edit_delete",))
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("test habits_edit_delete", calls)
        self.assertEqual(len([c for c in calls if c.startswith("test ")]), 3)

    def test_suite_filter_runs_only_the_named_file(self):
        result, calls = self.run_group("today", suites="today-dashboard")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual([c for c in calls if c.startswith("test ")], ["test today_dashboard"])

    def test_prayer_group_runs_all_its_entries_in_order(self):
        result, calls = self.run_group("prayer")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            [c for c in calls if c.startswith("test ")],
            ["test prayer_schedule", "test prayer_reports", "test prayer_offline_sync",
             "test prayer_localized_route"],
        )
        self.assertIn("all 4 files passed", result.stdout)

    def test_adhkar_qiyam_group_runs_its_own_three_files_in_order(self):
        # Its own group, so a stalled Prayer file can no longer spend the
        # shared step budget and cut these files off (run 44403651913).
        result, calls = self.run_group("adhkar-qiyam")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            [c for c in calls if c.startswith("test ")],
            ["test adhkar_qiyam_flow", "test adhkar_qiyam_offline_sync",
             "test adhkar_qiyam_localized_route"],
        )
        self.assertIn("all 3 files passed", result.stdout)

    def test_adhkar_qiyam_focused_selection_and_failure_reporting(self):
        result, calls = self.run_group("adhkar-qiyam", suites="adhkar-qiyam-flow")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual([c for c in calls if c.startswith("test ")],
                         ["test adhkar_qiyam_flow"])
        # A failing file is reported by name and never retried or hidden.
        result, calls = self.run_group(
            "adhkar-qiyam", suites="adhkar-qiyam-flow,adhkar-qiyam-localized-route",
            fail_test=("adhkar_qiyam_flow",))
        self.assertEqual(result.returncode, 1)
        self.assertEqual(
            [c for c in calls if c.startswith("test ")],
            ["test adhkar_qiyam_flow", "test adhkar_qiyam_localized_route"])
        self.assertIn("1 of 2 files failed: adhkar-qiyam-flow", result.stderr)
        result, calls = self.run_group("adhkar-qiyam", suites="adhkar-qiyam-typo")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(calls, [])

    def test_prayer_focused_selection_and_unknown_suite(self):
        result, calls = self.run_group("prayer", suites="prayer-reports")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual([c for c in calls if c.startswith("test ")], ["test prayer_reports"])
        result, calls = self.run_group("prayer", suites="prayer-reports,prayer-typo")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(calls, [])
        result, calls = self.run_group("prayer", suites="prayer-reports,")
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(calls, [])

    def test_unknown_group_fails_before_running(self):
        result, calls = self.run_group("ipad")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(calls, [])

    def test_every_previous_ios_file_is_still_covered(self):
        script = (ROOT / ".github/scripts/run-ios-integration-group.sh").read_text()
        previous = [
            "migration", "offline", "platform", "sync", "staging-supabase",
            "tasks-offline-sync", "tasks-completion-sync", "tasks-checklist-history",
            "tasks-localized-route", "habits-offline-sync", "habits-streak-history",
            "habits-edit-delete", "habits-localized-route", "mind-maps-library",
            "mind-maps-editor", "mind-maps-task-link", "mind-maps-viewport",
            "mind-maps-offline-sync", "mind-maps-localized-route", "mind-maps-staging-sync",
            "today-dashboard", "today-sync",
        ]
        groups = script.split("case \"${IOS_GROUP:-}\" in", 1)[1].split("esac", 1)[0]
        listed = [w for line in groups.splitlines() for w in line.replace("(", " ").replace(")", " ").split()]
        for suite in previous:
            self.assertEqual(listed.count(suite), 1, suite)


if __name__ == "__main__":
    unittest.main()
