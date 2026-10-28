#!/usr/bin/env bash
# Run one feature group of iOS integration files on one booted simulator.
#
# The job sets up Flutter, boots the simulator and does the full native build
# once. Each file then gets its own entry point, an incremental build (only
# Dart recompiles: the Flutter Run Script phase is alwaysOutOfDate) and its own
# XCTest launch, with the app and Keychain cleared in between, so files stay as
# isolated as when each had a job of its own. Every file runs even after a
# failure, and the summary lists all failing files at once.
#
# Env: IOS_GROUP, IOS_DEVICE_ID, NAMAA_STAGING_* secrets.
# Optional IOS_SUITES: comma-separated suite names to run within the group.
set -euo pipefail

case "${IOS_GROUP:-}" in
  foundation)
    suites=(migration offline platform sync staging-supabase)
    ;;
  tasks)
    suites=(tasks-offline-sync tasks-completion-sync tasks-checklist-history tasks-localized-route)
    ;;
  habits)
    suites=(habits-offline-sync habits-streak-history habits-edit-delete habits-localized-route)
    ;;
  mind-maps)
    suites=(mind-maps-library mind-maps-editor mind-maps-task-link mind-maps-viewport
      mind-maps-offline-sync mind-maps-localized-route mind-maps-staging-sync)
    ;;
  today)
    suites=(today-dashboard today-sync)
    ;;
  *)
    echo "Unknown iOS integration group: ${IOS_GROUP:-<unset>}" >&2
    exit 2
    ;;
esac

if [[ -n "${IOS_SUITES:-}" ]]; then
  IFS=',' read -r -a wanted <<< "${IOS_SUITES// /}"
  selected=()
  for suite in "${suites[@]}"; do
    for want in "${wanted[@]}"; do
      if [[ "$suite" == "$want" ]]; then
        selected+=("$suite")
      fi
    done
  done
  if [[ "${#selected[@]}" -eq 0 ]]; then
    echo "No suite of group $IOS_GROUP matches IOS_SUITES=$IOS_SUITES; skipping."
    exit 0
  fi
  suites=("${selected[@]}")
fi

suite_file() {
  case "$1" in
    migration|offline|platform|sync|staging-supabase)
      echo "integration_test/foundation_${1//-/_}_test.dart"
      ;;
    tasks-*|habits-*|mind-maps-*|today-*)
      echo "integration_test/${1//-/_}_test.dart"
      ;;
    *) echo "Unknown iOS integration suite: $1" >&2; return 2 ;;
  esac
}

for suite in "${suites[@]}"; do
  test_file="$(suite_file "$suite")"
  if [[ ! -f "$test_file" ]]; then
    echo "iOS integration test is missing: $test_file" >&2
    exit 2
  fi
done

staging_defines=(
  --dart-define="NAMAA_SUPABASE_URL=$NAMAA_STAGING_SUPABASE_URL"
  --dart-define="NAMAA_SUPABASE_PUBLISHABLE_KEY=$NAMAA_STAGING_SUPABASE_PUBLISHABLE_KEY"
  --dart-define="NAMAA_STAGING_TEST_USER_A_EMAIL=$NAMAA_STAGING_TEST_USER_A_EMAIL"
  --dart-define="NAMAA_STAGING_TEST_USER_A_PASSWORD=$NAMAA_STAGING_TEST_USER_A_PASSWORD"
  --dart-define="NAMAA_STAGING_TEST_USER_B_EMAIL=$NAMAA_STAGING_TEST_USER_B_EMAIL"
  --dart-define="NAMAA_STAGING_TEST_USER_B_PASSWORD=$NAMAA_STAGING_TEST_USER_B_PASSWORD"
)
# Xcode logs can include the encoded Dart defines from Generated.xcconfig.
python3 - "${staging_defines[@]}" <<'PY'
import base64, sys
for argument in sys.argv[1:]:
    value = argument.removeprefix('--dart-define=')
    print('::add-mask::' + base64.b64encode(value.encode()).decode())
PY

bundle_id="com.example.nammaProject"
work="$PWD/build/ios_integration"
mkdir -p "$work"
failed=()

for suite in "${suites[@]}"; do
  test_file="$(suite_file "$suite")"
  echo "::group::iOS $IOS_GROUP / $suite ($test_file)"
  # XCTest can activate native accessibility after the first test begins.
  # Establish it before testWidgets records its semantics-handle baseline.
  # The entry point path stays fixed, so Generated.xcconfig does not change
  # between files and only Dart is rebuilt.
  cat > "$work/entrypoint.dart" <<DART
import 'package:integration_test/integration_test.dart';

import '../../$test_file' as scenario;
import '../../test/support/native_ios_test_binding.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  stabilizeNativeIosSemantics(binding);
  scenario.main();
}
DART
  status=0
  flutter build ios --simulator --debug --no-codesign --no-pub --config-only \
    "${staging_defines[@]}" --target=build/ios_integration/entrypoint.dart || status=$?
  if [[ "$status" -eq 0 ]]; then
    python3 .github/scripts/run-ios-integration.py --build-only -- \
      xcodebuild -quiet build-for-testing -workspace ios/Runner.xcworkspace -scheme Runner \
      -configuration Debug -sdk iphonesimulator \
      -destination "id=$IOS_DEVICE_ID" \
      -derivedDataPath "$work/DerivedData" \
      CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- ONLY_ACTIVE_ARCH=YES || status=$?
  fi
  if [[ "$status" -eq 0 ]]; then
    # Start each file from a clean app container and Keychain, as a fresh
    # simulator did when every file had a job of its own.
    xcrun simctl uninstall "$IOS_DEVICE_ID" "$bundle_id" >/dev/null 2>&1 || true
    xcrun simctl keychain "$IOS_DEVICE_ID" reset >/dev/null 2>&1 || true
    result_bundle="$work/results-$suite.xcresult"
    rm -rf "$result_bundle"
    # Native XCTest receives Dart results through the integration_test plugin;
    # it does not wait for discovery of a debugger VM-service URI.
    # Ad-hoc simulator signing preserves the host app's Keychain identity.
    python3 .github/scripts/run-ios-integration.py "$result_bundle" -- \
      xcodebuild -quiet test-without-building -workspace ios/Runner.xcworkspace -scheme Runner \
      -configuration Debug -sdk iphonesimulator \
      -derivedDataPath "$work/DerivedData" \
      -destination "id=$IOS_DEVICE_ID" -parallel-testing-enabled NO \
      -only-testing:RunnerTests/RunnerTests/testFlutterIntegration \
      -test-timeouts-enabled YES -default-test-execution-time-allowance 300 \
      -maximum-test-execution-time-allowance 600 \
      -resultBundlePath "$result_bundle" CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- ONLY_ACTIVE_ARCH=YES \
      || status=$?
  fi
  echo "::endgroup::"
  if [[ "$status" -ne 0 ]]; then
    echo "::error title=iOS $suite failed::$test_file exited with status $status"
    failed+=("$suite")
  else
    echo "iOS $suite passed."
  fi
done

if [[ "${#failed[@]}" -gt 0 ]]; then
  echo "iOS group $IOS_GROUP: ${#failed[@]} of ${#suites[@]} files failed: ${failed[*]}" >&2
  exit 1
fi
echo "iOS group $IOS_GROUP: all ${#suites[@]} files passed."
