#!/usr/bin/env bash
set -euo pipefail

case "${ANDROID_SUITE:-}" in
  foundation-tasks)
    tests=(
      integration_test/foundation_migration_test.dart
      integration_test/foundation_offline_test.dart
      integration_test/foundation_platform_test.dart
      integration_test/foundation_staging_supabase_test.dart
      integration_test/foundation_supabase_test.dart
      integration_test/foundation_sync_test.dart
      integration_test/tasks_checklist_history_test.dart
      integration_test/tasks_completion_sync_test.dart
      integration_test/tasks_localized_route_test.dart
      integration_test/tasks_offline_sync_test.dart
    )
    ;;
  habits-mind-maps)
    tests=(
      integration_test/habits_edit_delete_test.dart
      integration_test/habits_localized_route_test.dart
      integration_test/habits_offline_sync_test.dart
      integration_test/habits_streak_history_test.dart
      integration_test/mind_maps_editor_test.dart
      integration_test/mind_maps_library_test.dart
      integration_test/mind_maps_localized_route_test.dart
      integration_test/mind_maps_offline_sync_test.dart
      integration_test/mind_maps_staging_sync_test.dart
      integration_test/mind_maps_task_link_test.dart
      integration_test/mind_maps_viewport_test.dart
      integration_test/today_dashboard_test.dart
      integration_test/today_sync_test.dart
    )
    ;;
  *)
    echo "Unknown Android integration suite: ${ANDROID_SUITE:-<unset>}" >&2
    exit 2
    ;;
esac

for test_file in "${tests[@]}"; do
  if [[ ! -f "$test_file" ]]; then
    echo "Android integration test is missing: $test_file" >&2
    exit 2
  fi
  for attempt in 1 2; do
    if ! timeout 90s adb -s emulator-5554 wait-for-device ||
      ! adb -s emulator-5554 reverse tcp:54321 tcp:54321; then
      if [[ "$attempt" -eq 1 ]]; then
        echo "Android emulator disconnected before $test_file; resetting ADB and retrying once."
        adb kill-server || true
        adb start-server || true
        continue
      fi
      echo "Android emulator unavailable before $test_file after two attempts." >&2
      exit 1
    fi
    log_file="$(mktemp)"
    set +e
    timeout --signal=INT --kill-after=15s 12m flutter drive --no-pub --publish-port --no-dds --no-start-paused \
      --dart-define="NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY=$NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY" \
      --dart-define="NAMAA_SUPABASE_URL=$NAMAA_STAGING_SUPABASE_URL" \
      --dart-define="NAMAA_SUPABASE_PUBLISHABLE_KEY=$NAMAA_STAGING_SUPABASE_PUBLISHABLE_KEY" \
      --dart-define="NAMAA_STAGING_TEST_USER_A_EMAIL=$NAMAA_STAGING_TEST_USER_A_EMAIL" \
      --dart-define="NAMAA_STAGING_TEST_USER_A_PASSWORD=$NAMAA_STAGING_TEST_USER_A_PASSWORD" \
      --dart-define="NAMAA_STAGING_TEST_USER_B_EMAIL=$NAMAA_STAGING_TEST_USER_B_EMAIL" \
      --dart-define="NAMAA_STAGING_TEST_USER_B_PASSWORD=$NAMAA_STAGING_TEST_USER_B_PASSWORD" \
      -d emulator-5554 \
      --driver=test_driver/integration_test.dart \
      --target="$test_file" 2>&1 | tee "$log_file"
    test_status="${PIPESTATUS[0]}"
    set -e

    if [[ "$test_status" -eq 0 ]]; then
      rm -f -- "$log_file"
      break
    fi
    if [[ "$test_status" -eq 124 || "$test_status" -eq 137 ]]; then
      echo "Android integration timed out for $test_file."
      adb -s emulator-5554 logcat -d -t 100 -s AndroidRuntime:E flutter:E DartVM:E || true
    fi

    if [[ "$attempt" -eq 1 ]] &&
      { [[ "$test_status" -eq 124 || "$test_status" -eq 137 ]] ||
        grep -Eq 'Service has disappeared|adb: device offline|device offline' "$log_file" ||
        { grep -Fq 'Failed to load' "$log_file" &&
          grep -Fq 'Failed to start Dart Development Service' "$log_file"; }; } &&
      ! grep -Fq 'VMServiceFlutterDriver: Connected to Flutter application.' "$log_file"; then
      echo "Android test service failed before $test_file started; retrying once."
      rm -f -- "$log_file"
      adb -s emulator-5554 shell am force-stop com.example.namma_project || true
      adb kill-server || true
      adb start-server || true
      continue
    fi
    rm -f -- "$log_file"
    exit "$test_status"
  done
done
