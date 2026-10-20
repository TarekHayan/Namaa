#!/usr/bin/env bash
set -euo pipefail

case "${ANDROID_SUITE:-}" in
  foundation-tasks)
    tests=(integration_test/foundation_*_test.dart integration_test/tasks_*_test.dart)
    ;;
  habits-mind-maps)
    tests=(integration_test/habits_*_test.dart integration_test/mind_maps_*_test.dart)
    ;;
  *)
    echo "Unknown Android integration suite: ${ANDROID_SUITE:-<unset>}" >&2
    exit 2
    ;;
esac

for test_file in "${tests[@]}"; do
  for attempt in 1 2; do
    adb -s emulator-5554 wait-for-device
    adb -s emulator-5554 reverse tcp:54321 tcp:54321
    log_file="$(mktemp)"
    set +e
    timeout --signal=INT --kill-after=15s 12m flutter drive --no-pub --publish-port \
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
    if [[ "$test_status" -eq 124 ]]; then
      echo "Android integration timed out for $test_file."
      adb -s emulator-5554 logcat -d -t 100 -s AndroidRuntime:E flutter:E DartVM:E || true
    fi

    if [[ "$attempt" -eq 1 ]] &&
      { [[ "$test_status" -eq 124 ]] ||
        { grep -Fq 'Failed to load' "$log_file" &&
          grep -Fq 'Failed to start Dart Development Service' "$log_file"; }; } &&
      ! grep -Fq 'VMServiceFlutterDriver: Connected to Flutter application.' "$log_file"; then
      echo "Android test service failed before $test_file started; retrying once."
      rm -f -- "$log_file"
      adb -s emulator-5554 shell am force-stop com.example.namma_project || true
      adb kill-server
      adb start-server
      continue
    fi
    rm -f -- "$log_file"
    exit "$test_status"
  done
done
