# Quickstart: validating Adhkar and Qiyam

This guide is for after implementation. The commands assume the file names planned in [plan.md](plan.md), and they only become runnable once tasks.md is implemented. Record every result, with its command, target, date and run URL, in `verification.md`.

## Prerequisites

- Docker Desktop running, then `supabase start -x mailpit`. Local migration 0016 is applied by `supabase db reset` in the local stack only.
- A Prayer location saved on the device or emulator (for the timed paths). For the no-schedule paths, deny location instead.
- `flutter pub get`. Regenerate Drift code after any schema change with `dart run build_runner build --delete-conflicting-outputs`.

## Fast local gate (before every push)

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
supabase test db
python -m unittest discover -s .github/scripts/tests -p "test_*.py"
```

What each step must show:
- **`flutter test`**:
  - the domain tests: `AdhkarClock`, `QiyamNight` and both streak walks;
  - the commands: day and period guards, the transactions and award idempotency;
  - the catalog validation;
  - the v10 migration from every historical fixture;
  - the Cubits and widgets, in AR/EN, light/dark, at 320 px and 200%;
  - the architecture boundaries.
- **`supabase test db`**: all the proofs in [contracts/adhkar-qiyam-sync.md](contracts/adhkar-qiyam-sync.md).

## Scenarios to validate

| # | Scenario | Expected result | Spec |
|---|---|---|---|
| 1 | A Morning item with target 3, tapped 4 times | 3/3, Completed, and the 4th tap is ignored | US1 AS2 |
| 2 | Complete all of Morning, reset one item, complete it again | One award of 15 XP | FR-007, SC-004 |
| 3 | At 21:00 with a schedule, open Adhkar | Evening is selected; Morning is read-only with "starts at Fajr" | FR-006a, SC-008 |
| 4 | Count Evening at 00:30, then at 01:00 | It stays on the same Adhkar day | FR-006 |
| 5 | Location denied | Both lists are countable, the day is calendar-based, and a setup prompt shows | US1 AS10 |
| 6 | Both lists done 3 days running; today only Morning is done | Streak 3; it becomes 4 after Evening | FR-006b, SC-007 |
| 7 | Qiyam Yes at 03:00 Thursday, then reopen at 10:00 | Recorded for Wednesday night and still editable until Maghrib | FR-011, FR-011a |
| 8 | Yes → No → Yes | One award of 30 XP; the details are cleared when No | FR-010 |
| 9 | The last third on Qiyam versus the Prayer screen for the same night | Identical | SC-005 |
| 10 | Offline, then restart 10 times | Counts and nights are unchanged | SC-003 |
| 11 | Two devices count different Morning items offline, then reconnect | The set completes on both; one award | SC-004 |
| 12 | Two devices change the same item or night offline | One active version and one visible "Sync difference" | FR-017 |
| 13 | Home and Track versus the screens | The same x/N values and Qiyam state | SC-006 |
| 14 | My Adhkar: add a dhikr with target 33, count to 33, restart, edit the text, lower the target to 10 | Count kept through the edit, then shown as 10 of 10; no XP and no streak change | FR-022…026 |
| 15 | My Adhkar on two devices: add on A, sync, delete on B, edit on A offline, reconnect | The item is gone on both; the edit is a visible "Sync difference" | FR-025, FR-027 |
| 16 | My Adhkar with the Prayer schedule unavailable | Items visible, counting locked | FR-024 |

## Device integration (planned files)

```bash
flutter test integration_test/adhkar_qiyam_flow_test.dart -d windows
flutter test integration_test/adhkar_qiyam_offline_sync_test.dart -d windows
flutter test integration_test/adhkar_qiyam_localized_route_test.dart -d windows
```

- These files join the existing `prayer` Android suite and iOS group, and the desktop lists in `foundation-ci.yml`.
- Hosted runs use the staging test users, run-tagged operation IDs and random past days. Pushing migration 0016 to staging needs the product owner's approval first.

## Human checks (the product owner reports these)

- On the named phone (CPH2481) and on Windows desktop:
  - the Morning and Evening journeys by touch and keyboard;
  - Qiyam recorded in under 30 seconds;
  - Arabic tashkeel rendering in Amiri;
  - visual parity with the prototype's order of groups.
- **The product owner reviews and approves `content-sources.md`.** No item ships unless it is marked approved.
