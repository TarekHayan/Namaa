# Namaa — agent guide

Read this before you work on the repository. It applies to every coding agent:
Claude Code, Codex, Cursor, Copilot and the others. `CLAUDE.md` imports it.

## 1. Product in one paragraph

Namaa is one Flutter app for Android, iOS, Windows, macOS and Linux. It brings
together personal productivity (Tasks, Habits, Mind Maps), religious practice
(Prayer now; Quran, Dhikr and Qiyam later) and personal finance tracking, all
around a "Today" dashboard. The app is local-first: it works offline and syncs
each account across devices through Supabase. Arabic is the primary language
(RTL), and English is the second.

## 2. Sources of truth, in order

1. Explicit decisions the product owner made in conversation.
2. `.specify/memory/constitution.md`: nine binding principles plus the
   Definition of Done. Read it once per session.
3. `specs/NNN-*/`: the spec, plan, tasks, data model, contracts and
   verification for each feature.
4. `namaa_plan.md`: the full product plan (all areas and phases). Where it
   names a cloud provider other than Supabase, that text is legacy.
5. `docs/design/` (colors, components) and the local `prototype/` folder. The
   prototype is the reference web app and is not tracked in git.

If a requirement is unresolved or conflicts with the constitution, stop and
ask the product owner. Do not decide it in code.

## 3. Feature status

| Spec | Feature | State |
|---|---|---|
| 001 | Foundation: encrypted Drift DB, Supabase, sync engine, five-target CI | merged |
| 003 | Tasks | merged |
| 004 | Habits | merged (T075 human comprehension check deferred) |
| 005 | Mind Maps | merged |
| 006 | Today dashboard | merged (T074/T075 closure items left open) |
| 007 | Dashboard prototype UI | merged (T049 final audit open) |
| 008 | Prayer experience (location-only, statuses, sync, XP) | merged 2026-11-09, PR #11 |
| 009 | Authentication / per-account data | proposed next, not started |

Not built yet: Quran, Dhikr, Qiyam, Pomodoro, Finance, Notifications,
Analytics, Settings. The Finance tab currently opens a "coming soon" page.

When you close a feature, update this table in the same PR.

## 4. Workflow

- **Spec Kit.** Each feature runs `speckit-specify`, then `clarify`, `plan`,
  `tasks` and `implement`. The skills live in `.claude/skills/` and
  `.agents/skills/`. The active feature is set in `.specify/feature.json`.
- **Branches.**
  - Feature work goes on `namaa/NNN-short-name`, cut from `develop`.
  - Every PR targets `develop` and merges with a merge commit, only after the
    product owner says to.
  - `main` has not been updated since the start and is far behind `develop`.
    Do not touch `main` unless asked.
- **Commits.** Use conventional messages: `feat(prayer): …`, `fix(…)`,
  `test(…)`, `ci(ios): …`, `docs(008): …`, `chore(…)`.
- **Evidence.** Record each result in `specs/NNN-*/verification.md` with the
  real command, target, date and run URL.
  - Tick a task in `tasks.md` only when there is evidence for it.
  - Never record a pass you did not observe.
- **Product-owner testing.** The owner tests on a real Android phone (CPH2481,
  Cairo) and on Windows desktop. Human checks are theirs to report. Do not
  claim them yourself.

## 5. Architecture

Every feature under `lib/features/<feature>/` follows the same Clean
Architecture layout. `test/architecture/` enforces the dependency rules, so a
wrong import fails the tests:

| Layer | May import |
|---|---|
| `domain/` | domain only |
| `application/` (ports, commands, services) | domain, application |
| `data/` and `core/platform` (Drift, Supabase, Dio, geolocator adapters) | domain, application, data |
| `presentation/` (Cubit and widgets) | domain, application, presentation |
| `lib/app/` (composition root, router, l10n, theme) | anything |

Other rules:
- **Shared code.** `lib/core/` holds the shared domain values,
  failures/results, local DB, cloud and sync code. A feature never reaches
  into another feature's storage or UI. Cross-feature effects such as XP and
  Today go through explicit application services.
- **Dependency injection.** It is manual GetIt registration in
  `lib/app/composition/configure_dependencies.dart`, with no injectable
  codegen. Debug "preview" adapters live next to it.
- **State.** Use BLoC/Cubit only.
- **Navigation.**
  - GoRouter lives in `lib/app/routing/app_router.dart`, with top-level
    sibling routes `/`, `/tasks`, `/habits`, `/mind-maps` and `/prayer`.
  - The shell is `TodayNavigationShell`, which behaves as tabs. Sections are
    switched with `go`, and pages never stack.
  - Overlay sections (track, finance, preview) replace one another.
  - There is no app-bar back arrow. Device back returns to Home.
- **Local DB.** It is an encrypted Drift/SQLite database,
  `lib/core/data/local/foundation_database.dart`, now at
  `kFoundationSchemaVersion = 9`.
  - Every schema change needs an automatic migration that keeps existing data,
    and a migration test.
  - Generated `*.g.dart` files are committed. Regenerate them with
    `dart run build_runner build --delete-conflicting-outputs`.
- **Sync.**
  - Every write is applied locally first, then queued.
  - Server writes go through versioned RPCs that are idempotent per
    `(owner, operation_id)`.
  - Conflicts keep the newest version and leave the losing one visible as a
    conflict record.
  - XP awards are idempotent, with one authority.
- **Localization.**
  - All UI text lives in `lib/app/l10n/app_ar.arb` and `app_en.arb`. The
    generated output is gitignored and comes from `flutter gen-l10n` or a
    build.
  - Edit ARB files line by line. Never re-serialize them with a JSON tool,
    because that rewrites the whole file.
  - Verify RTL on both phone and desktop widths.

## 6. Supabase environments (safety-critical)

| Environment | Use |
|---|---|
| Local (`supabase start -x mailpit`, needs Docker Desktop) | Every automated test. SQL tests: `supabase test db` |
| Staging `namaa_satging` (ref `qfjwybbmqhpxxikubhuh`, free tier, auto-pauses) | Device and hosted CI tests with the two staging test users |
| Production `Namaa Project` (ref `rngnesbyoomuywfvncoe`) | **Never** touch it (migrations, data, settings) without the owner's explicit approval in that conversation |

- **Migrations.** They are numbered files in `supabase/migrations/`; the
  latest is `0015_prayer_reports_and_rewards.sql`.
  - Each one needs pgTAP coverage in `supabase/tests/`: account isolation,
    operation integrity, conflict and XP.
  - Pushing a migration to staging needs the owner's approval too.
- **Clients.** They ship only the publishable key. Service-role and secret
  keys never enter the app, the repo or logs.
  `test/architecture/client_secret_scan_test.dart` checks this.
- **Staging values.**
  - Locally they live in `.secrets/namaa-staging.env`, which is gitignored and
    follows `.secrets/namaa-staging.env.example`.
  - In CI they come from GitHub secrets.
  - Agents never type passwords.
- **Public repository.** Never upload xcresult bundles, simulator logs or
  other artifacts that could contain staging data.

## 7. Commands

```bash
python .github/scripts/pub-get-with-retry.py   # or: flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test                                   # unit + widget + architecture, ~6 min
python -m unittest discover -s .github/scripts/tests -p "test_*.py"   # CI script tests
supabase start -x mailpit && supabase test db  # SQL/RLS tests (Docker)
flutter test integration_test/<file>_test.dart -d windows   # one device suite locally
flutter run                                    # debug = local trial without account
```

Debug run flags (`--dart-define`):
- `NAMAA_TASKS_PREVIEW=false` puts the real account boundary on a debug run.
- `NAMAA_DEVICE_PREVIEW=true` turns on the DevicePreview toolbar. Use it only
  for the final multi-screen review.
- `NAMAA_SUPABASE_URL` and `NAMAA_SUPABASE_PUBLISHABLE_KEY` point a run at
  staging.

Run format, analyze and the relevant tests locally before every push.

## 8. CI (`.github/workflows/foundation-ci.yml`)

- **Triggers.**
  - It runs on PRs to `develop` that touch `lib/`, `integration_test/`,
    platform folders, `pubspec.*`, the workflow or `.github/scripts/**`. It can
    also be started by hand. Changes only to `test/`, `specs/` or docs do not
    start it.
  - The `paths` filter looks at the whole PR diff, so even a docs-only commit
    on such a PR starts the full run again. Put closing docs in before the
    final gate run.
- **Full run.** It covers quality, Supabase/RLS, the Android groups
  (foundation, tasks, habits-today, mind-maps, prayer), the iOS simulator
  groups (foundation, tasks, habits, mind-maps, today, prayer), Windows, macOS
  and Linux. "Foundation and feature five-target gate" passes only when all of
  them pass.
- **Runners.** Mobile runs go through `.github/scripts/run-android-integration.sh`,
  `run-ios-integration-group.sh` and `run-ios-integration.py`. These have
  bounded retries for infrastructure faults only (ADB drops, a wedged
  simulator, an unreadable xcresult). Never add retries that hide a real test
  failure.
- **Infrastructure failures.**
  - iOS simulator runs are flaky on the hosted runners: SpringBoard crashes,
    DNS failures, hangs.
  - Read the job log first. If the cause is infrastructure, use **Re-run
    failed jobs** on the same head.
  - Fix the code only for real failures.
- **Hosted tests.** Tests against staging share two test accounts across
  every platform and run. Use per-run unique fixtures (a random past day, and
  operation IDs tagged with the run). The server rejects reused IDs that carry
  different content, and dates more than two days ahead.
- **Closing a feature.**
  1. Record the green run URL and SHA in `verification.md`.
  2. Get the owner's go.
  3. Merge.

## 9. Product-owner preferences

- Talk to the owner in **Egyptian Arabic**, including summaries and questions.
  Code, commits and docs stay in English.
- Keep changes minimal (constitution VIII). Don't invent features. Remove
  scope the owner rejects. For example, Prayer uses only the device location,
  with no city search and no paid geocoding service.
- Ask before:
  - merging, pushing a migration, deleting branches or data, or touching
    production;
  - any outward-facing or hard-to-reverse action.
- Local, account-independent material stays out of the repo:
  `docs/explainers/`, `.agents/skills/spec-teach/`, `prototype/` and scratch
  screenshots.

## 10. Known pitfalls

- **Windows.** A stuck `namma_project.exe` from an earlier run makes
  integration tests hang. Kill it, then rerun.
- **Prayer days.** The Prayer day follows the location's time zone, not the
  device's. Home and Prayer can show different civil dates on an emulator
  whose zone differs from its GPS location, and this is correct.
- **iOS deployment target.** The pods warn about `IPHONEOS_DEPLOYMENT_TARGET
  11.0` (geolocator). The warning is harmless.
- **Package name.** The Dart package is `namma_project` (with this spelling).
  The app ID is `com.example.nammaProject`.
