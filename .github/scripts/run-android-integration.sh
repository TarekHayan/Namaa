#!/usr/bin/env bash
set -euo pipefail

for test_file in integration_test/*_test.dart; do
  for attempt in 1 2; do
    adb -s emulator-5554 wait-for-device
    adb -s emulator-5554 reverse tcp:54321 tcp:54321
    log_file="$(mktemp)"
    set +e
    flutter test --no-pub \
      --dart-define="NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY=$NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY" \
      --dart-define="NAMAA_SUPABASE_URL=$NAMAA_STAGING_SUPABASE_URL" \
      --dart-define="NAMAA_SUPABASE_PUBLISHABLE_KEY=$NAMAA_STAGING_SUPABASE_PUBLISHABLE_KEY" \
      --dart-define="NAMAA_STAGING_TEST_USER_A_EMAIL=$NAMAA_STAGING_TEST_USER_A_EMAIL" \
      --dart-define="NAMAA_STAGING_TEST_USER_A_PASSWORD=$NAMAA_STAGING_TEST_USER_A_PASSWORD" \
      --dart-define="NAMAA_STAGING_TEST_USER_B_EMAIL=$NAMAA_STAGING_TEST_USER_B_EMAIL" \
      --dart-define="NAMAA_STAGING_TEST_USER_B_PASSWORD=$NAMAA_STAGING_TEST_USER_B_PASSWORD" \
      -d emulator-5554 "$test_file" --reporter expanded 2>&1 | tee "$log_file"
    test_status="${PIPESTATUS[0]}"
    set -e

    if [[ "$test_status" -eq 0 ]]; then
      rm -f -- "$log_file"
      break
    fi
    if [[ "$attempt" -eq 1 ]] &&
      grep -Fq 'Failed to load' "$log_file" &&
      grep -Fq 'Failed to start Dart Development Service' "$log_file"; then
      echo "Android test service failed before $test_file started; retrying once."
      rm -f -- "$log_file"
      continue
    fi
    rm -f -- "$log_file"
    exit "$test_status"
  done
done
