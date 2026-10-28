import importlib.util
import json
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


tier = load("ci_tier", "select-ci-tier.py")
pub_get = load("pub_get_retry", "pub-get-with-retry.py")

ALL_GROUPS = ["foundation", "tasks", "habits", "mind-maps", "today"]


class TierSelectionTest(unittest.TestCase):
    def select(self, **env):
        return tier.select(env)

    def groups(self, outputs):
        return json.loads(outputs["ios_groups"])

    def test_ordinary_pr_push_runs_fast_tier_only(self):
        outputs = self.select(EVENT="pull_request", ACTION="synchronize", HAS_FULL_LABEL="false")
        self.assertEqual((outputs["run"], outputs["ios"]), ("true", "false"))

    def test_full_ci_label_adds_every_ios_group(self):
        for action in ("labeled", "synchronize"):
            with self.subTest(action=action):
                outputs = self.select(
                    EVENT="pull_request", ACTION=action,
                    ADDED_LABEL="full-ci", HAS_FULL_LABEL="true",
                )
                self.assertEqual(outputs["ios"], "true")
                self.assertEqual(self.groups(outputs), ALL_GROUPS)

    def test_another_label_runs_nothing(self):
        outputs = self.select(
            EVENT="pull_request", ACTION="labeled", ADDED_LABEL="docs", HAS_FULL_LABEL="false",
        )
        self.assertEqual((outputs["run"], outputs["ios"]), ("false", "false"))

    def test_manual_full_run_includes_ios(self):
        outputs = self.select(EVENT="workflow_dispatch", MOBILE_ONLY="false")
        self.assertEqual(outputs["ios"], "true")
        self.assertEqual(self.groups(outputs), ALL_GROUPS)

    def test_focused_run_selects_named_groups(self):
        outputs = self.select(
            EVENT="workflow_dispatch", MOBILE_ONLY="true", IOS_GROUPS='["today"]',
        )
        self.assertEqual((outputs["ios"], self.groups(outputs)), ("true", ["today"]))

    def test_focused_run_without_ios_keeps_a_valid_matrix(self):
        outputs = self.select(EVENT="workflow_dispatch", MOBILE_ONLY="true", IOS_GROUPS="[]")
        self.assertEqual(outputs["ios"], "false")
        # A skipped matrix job still needs a non-empty vector.
        self.assertTrue(self.groups(outputs))

    def test_unknown_group_is_rejected(self):
        with self.assertRaises(ValueError):
            self.select(EVENT="workflow_dispatch", MOBILE_ONLY="true", IOS_GROUPS='["ipad"]')

    def test_groups_match_the_ios_runner(self):
        script = (ROOT / ".github/scripts/run-ios-integration-group.sh").read_text()
        for group in tier.IOS_GROUPS:
            self.assertIn(f"\n  {group})\n", script)


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
