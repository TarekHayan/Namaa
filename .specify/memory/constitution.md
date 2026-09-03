<!--
Sync Impact Report
- Version change: 1.0.0 -> 1.1.0
- Modified principles: I. Flutter Product Parity Across Targets; III. Local-First, Durable, and
  Synchronizable Data; IV. Account Data Integrity and Safe Cloud Synchronization.
- Added principles: IX. Protected Local Account Data.
- Added sections: none.
- Removed sections: none.
- Follow-up TODOs: none. The selected packages and Firebase support remain subject to required
  target verification before production lock-in.
-->
# Namaa Constitution

## Core Principles

### I. Flutter Product Parity Across Targets

Namaa MUST use Flutter and Dart for one product across Android, iOS, Windows, macOS, and Linux.
Presentation MAY adapt to platform form factors, input, and device capabilities, but business
rules and account-data semantics MUST remain the same. Platform-specific notification delivery
is an intentional exception: notification enablement and delivery are device-specific.

### II. Feature-First Clean Architecture and Explicit Ownership

The codebase MUST be organized by feature/domain using Clean Architecture boundaries. Each
domain owns its canonical data and invariants; presentation, application/use-case, domain, and
data concerns MUST not couple a domain to another domain's storage or UI. Dashboard, Analytics,
and other aggregators MUST consume owned data and MUST NOT become alternative sources of truth.
Cross-domain effects MUST use explicit relationships or application services, never duplicated
state or hidden storage coupling.

### III. Local-First, Durable, and Synchronizable Data

User actions MUST apply locally, persist durably, update the UI, and queue any required
synchronization without waiting for connectivity. Core product behavior MUST remain usable
offline after the initial authenticated synchronization. Local persistence is the authoritative
runtime path while offline; cloud synchronization reconciles account data across devices and
MUST be retry-safe. Persisted-schema changes MUST automatically migrate existing local data; on
failure, the prior data MUST be preserved with a recoverable failure path. The selected local
database and cloud services MUST be validated on Android, iOS, Windows, macOS, and Linux before
being treated as production-locked.

### IV. Account Data Integrity and Safe Cloud Synchronization

Authentication and cloud synchronization MUST preserve ownership, identity, and integrity of
one account's data across its devices. Cloud retries, reconnects, and duplicate deliveries MUST
be idempotent for all side effects, including XP and financial changes. Synchronization MUST NOT
silently discard a conflicting local or remote change. When versions of the same synchronized
record conflict, the newest timestamp MUST select the active version and the non-winning version
MUST remain a visible conflict record. Logout MUST only sign out, not delete local or cloud data;
account deletion and its recovery period MUST follow the approved product flow.

### V. Sacred and Financial Records Are Invariant-Protected

Verified canonical Quran Arabic text MUST be preserved exactly: it MUST NOT be generated,
reconstructed, or modified by display features. Tajweed MAY add visual markup only and MUST NOT
alter canonical text; Quran calculations MUST use Quran metadata. Finance MUST remain a personal
tracking system, not a banking or money-transfer system. Financial mutations MUST enforce the
approved balance invariants atomically: Total equals Available plus allocated sections;
allocation transfers value without changing Total; spending decreases Total; and a new allocation
MUST be rejected when Available is insufficient. Derived reports and dashboards MUST NOT become
financial truth.

### VI. State, XP, and Domain Events Are Single-Authority

BLoC/Cubit is the required presentation-state pattern unless an approved exception documents a
different pattern. Domain state, streaks, progress, and rewards MUST have one owning authority.
Streaks remain scoped to their domains and MUST NOT be implicitly merged. XP is centralized;
award operations MUST be idempotent and enforce one-time awards where the product defines them.
Cross-domain reactions MUST be traceable from an explicit domain event or application service,
rather than inferred from presentation state.

### VII. Arabic-First Localization and Accessible Directionality

All user-facing text MUST be localized through Flutter ARB/gen_l10n resources; Arabic and English
are the supported languages. Arabic screens MUST render with correct RTL direction, including
layout, navigation affordances, text alignment, and Quran presentation. Locale and directionality
MUST be verified on both mobile and desktop rather than assumed from a single-target implementation.

### VIII. Evidence-Driven Quality and Deliberate Simplicity

Every change MUST be the smallest maintainable implementation consistent with approved product
behavior. New layers, shared abstractions, dependencies, or platform integrations MUST have a
present, verified use case; speculative frameworks and feature invention are prohibited. Code
MUST pass static analysis and relevant automated tests. Unit tests MUST cover domain invariants
and use cases; widget tests MUST cover meaningful presentation behavior; integration tests MUST
cover persistence, offline/reconnect synchronization, cross-domain effects, and target-specific
behavior when affected. Agents MUST read applicable source documentation, specification, plan,
and existing code before implementation, state assumptions, preserve unrelated work, and stop
for product-owner approval when a required behavior is unresolved.

### IX. Protected Local Account Data

All account-scoped data persisted locally MUST be encrypted at rest. Credentials that access
protected data or cloud services MUST use operating-system protected storage and MUST NOT be
stored in general application preferences. This protects the local-first experience when a device
is lost or accessed by another person.

## Engineering Constraints

The current technology direction is Flutter/Dart, feature-first Clean Architecture, BLoC/Cubit,
Drift/SQLite, Firebase Auth, Cloud Firestore, custom local-first synchronization, get_it /
injectable, Freezed, json_serializable, go_router, Dio for required external APIs,
flutter_local_notifications with platform support, just_audio, ARB/gen_l10n, flutter_test,
bloc_test, and integration_test. These are the approved direction, not an unconditional
production lock: capability and compatibility on Android, iOS, Windows, macOS, and Linux MUST be
verified before adoption is finalized. Automated Firebase tests MUST use emulators; device
integration before production release MUST use an isolated non-production Firebase project.

Local data, sync metadata, and user-facing state MUST have clear ownership. Notifications MUST
respect per-device enablement and preferences and MUST NOT imply that an unconfirmed religious
practice was missed. Domain logic MUST remain independent of notification scheduling and platform
adapters.

## Delivery and Verification

Work MUST proceed incrementally: understand, specify, plan, implement, test, review, and
integrate one bounded domain or cross-domain change at a time. The existing prototype and
verified project documentation are the behavioral source of truth; the first implementation
phase targets functional and behavioral parity before visual redesign.

The Definition of Done for a change includes: approved behavior is specified; the owning domain
and cross-domain contracts are explicit; affected invariants and offline/sync behavior are
tested; local persistence and relevant target behavior are verified; localization/RTL and
accessibility are checked when UI changes; static analysis and relevant tests pass; and no
unresolved product decision has been concealed in code. A feature is not complete merely because
its screen renders or its happy path succeeds.

## Governance

This Constitution governs all Namaa planning, specifications, implementation, review, and
verification. It is subordinate only to explicitly approved product decisions that amend it.
Amendments require documented supporting evidence, product-owner approval where a product decision
changes, impact analysis for persisted data and synchronization, and an update to this file's
Sync Impact Report.

Versioning follows semantic intent: MAJOR for incompatible removal or redefinition of a
governance rule, MINOR for a new principle or material obligation, and PATCH for clarifications
that do not change obligations. Every plan, task list, implementation review, and release check
MUST assess compliance with the principles and Definition of Done. A conflict between this
Constitution and an unapproved feature requirement MUST be raised for resolution rather than
implemented by assumption.

**Version**: 1.1.0 | **Ratified**: 2026-09-03 | **Last Amended**: 2026-09-03
