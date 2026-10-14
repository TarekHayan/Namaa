#!/usr/bin/env bash
set -euo pipefail

for test_file in integration_test/*_test.dart; do
  adb -s emulator-5554 wait-for-device
  adb -s emulator-5554 reverse tcp:54321 tcp:54321
  flutter test --no-pub --no-dds \
    --dart-define="NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY=$NAMAA_LOCAL_SUPABASE_PUBLISHABLE_KEY" \
    --dart-define="NAMAA_SUPABASE_URL=$NAMAA_STAGING_SUPABASE_URL" \
    --dart-define="NAMAA_SUPABASE_PUBLISHABLE_KEY=$NAMAA_STAGING_SUPABASE_PUBLISHABLE_KEY" \
    --dart-define="NAMAA_STAGING_TEST_USER_A_EMAIL=$NAMAA_STAGING_TEST_USER_A_EMAIL" \
    --dart-define="NAMAA_STAGING_TEST_USER_A_PASSWORD=$NAMAA_STAGING_TEST_USER_A_PASSWORD" \
    --dart-define="NAMAA_STAGING_TEST_USER_B_EMAIL=$NAMAA_STAGING_TEST_USER_B_EMAIL" \
    --dart-define="NAMAA_STAGING_TEST_USER_B_PASSWORD=$NAMAA_STAGING_TEST_USER_B_PASSWORD" \
    -d emulator-5554 "$test_file" --reporter expanded
done
