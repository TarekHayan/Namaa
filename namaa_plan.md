# Namaa Project Plan

## 1. Project Overview

**Namaa** is a Flutter application for Mobile and Desktop that brings
personal productivity, religious practice, and personal finance tracking
into one organized experience.

The application is designed around a daily experience where the user can
see what needs to be done today, track recurring practices, manage Quran
reading, monitor prayer and religious activities, organize money, and
review progress.

Namaa is **not a banking application**. Its Finance area is a personal
money-organization and tracking system.

The existing web prototype and project documentation are the primary
behavioral references for rebuilding the application in Flutter.

------------------------------------------------------------------------

# 2. Product Areas

The application consists of the following main areas:

``` text
Namaa
│
├── Dashboard / Today
│
├── Tasks
├── Habits
├── Mind Maps
│
├── Prayer
├── Quran
├── Dhikr
├── Qiyam
│
├── Pomodoro
│
├── Finance
│
├── Gamification
├── Notifications
├── Analytics
│
└── Settings
```

Each area has its own responsibility while selected areas can integrate
with each other.

------------------------------------------------------------------------

# 3. Core User Experience

The Dashboard represents the user's current day.

The user should be able to open Namaa and understand:

-   What they need to do today.
-   What they have completed.
-   Their daily progress.
-   Their religious activities.
-   Their productivity progress.
-   Relevant financial information.
-   Their overall progress and motivation.

The Dashboard is an aggregation of information owned by the individual
domains.

It does not become the source of truth for those domains.

------------------------------------------------------------------------

# 4. Tasks

Tasks represent finite pieces of work.

A Task can contain supported information such as:

-   Name
-   Description/details
-   Date
-   Time
-   Deadline
-   Category
-   Eisenhower quadrant
-   Estimated duration
-   Checklist/subtasks
-   Completion state

Tasks can be:

-   Created
-   Edited
-   Completed
-   Deleted
-   Reviewed through history/overdue views

A completed Task awards its configured XP only once.

If the user changes a Task back to incomplete and completes it again, it
does not receive the same Task XP again.

Tasks can also participate in the Mind Map system.

------------------------------------------------------------------------

# 5. Habits

Habits represent recurring behaviors.

A Habit is separate from a Task.

A Habit can have:

-   Name
-   Selected days
-   Optional reminder
-   Daily completion state
-   Individual streak

The Habit streak belongs to that specific Habit.

The user can have multiple Habits, each with its own streak.

The user can edit supported Habit information or delete the Habit.

------------------------------------------------------------------------

# 6. Mind Maps

Mind Maps provide a visual way to organize ideas and work.

The existing prototype supports:

-   Mind Map creation
-   Editing
-   Deletion
-   Nodes
-   Connections/edges
-   Different node types
-   Node status
-   Layouts
-   Map settings
-   Task-related nodes

A Mind Map node can be connected to a real Task.

The relationship is shared rather than duplicated:

``` text
Mind Map Node
      ↕
   Real Task
```

If the Task is completed from either the Task area or the Mind Map, the
other side reflects the same state.

------------------------------------------------------------------------

# 7. Today / Daily Experience

Today is the central daily view.

It brings together relevant information from:

-   Tasks
-   Habits
-   Prayer
-   Quran
-   Dhikr
-   Qiyam
-   Pomodoro
-   Finance
-   Gamification

The user can see today's state without needing to manually open every
feature.

The visual design should initially follow the existing prototype.

Visual refinement can happen after the core application behavior is
implemented.

------------------------------------------------------------------------

# 8. Prayer

Prayer tracks the five daily prayers:

-   Fajr
-   Dhuhr
-   Asr
-   Maghrib
-   Isha

The application calculates prayer times separately from prayer
completion.

Each prayer has a daily state such as:

-   Pending
-   Completed on time
-   Completed late
-   Missed

The application must not assume that a user failed to pray simply
because they did not confirm it in Namaa.

Prayer notifications can be configured by the user.

Notification delivery is device-specific.

The user may choose supported notification behavior such as Adhan or a
normal system notification.

------------------------------------------------------------------------

# 9. Quran

Quran is a major independent area of Namaa.

It contains:

``` text
Quran
│
├── Reader
├── Wird
├── Audio
├── Memorization
├── Tajweed
├── Bookmarks
├── Reading Position
└── History
```

## 9.1 Quran Reader

The Reader supports:

-   Surah selection
-   Ayah navigation
-   Translation
-   Tafsir
-   Tajweed
-   Bookmarks
-   Audio
-   Memorization
-   Reader settings
-   Distraction-free mode

Translation, Tafsir, and Tajweed are independent controls.

The user can enable or disable each one separately.

## 9.2 Quran Integrity

The Quran text must remain verified and canonical.

The application must:

-   Preserve the verified Arabic text.
-   Support RTL.
-   Avoid generating or reconstructing Quran text.
-   Keep Tajweed as visual markup only.
-   Never change the canonical text through Tajweed rendering.

Quran metadata must be used for relevant Quran calculations.

## 9.3 Quran Wird

Wird is a Quran-specific daily reading system.

It is separate from Habits.

Supported target concepts include:

-   Surah/Ayah
-   Pages
-   Juz
-   Hizb
-   Custom

Supported modes include:

-   Fixed
-   Sequential

Wird tracks:

-   Daily progress
-   Completion
-   History
-   Streak

The Wird streak is specific to Quran Wird.

## 9.4 Quran Audio

Audio supports the existing product behavior including:

-   Reciter selection
-   Single Ayah
-   Continuous playback
-   Surah playback
-   Wird playback
-   Queue
-   Next/Previous
-   Mini player

## 9.5 Quran Memorization

Memorization supports repetition modes including:

-   Repeat Ayah
-   Repeat Page
-   Repeat Quarter
-   Repeat Range

## 9.6 Bookmarks and History

Bookmarks can be created for:

-   Ayah
-   Page
-   Surah

Bookmarks can contain optional notes.

Reading Position is used to resume the user's last reading location.

Reading History records previous reading/Wird progress.

These concepts remain separate.

------------------------------------------------------------------------

# 10. Dhikr

Dhikr is an independent religious area.

It includes:

-   Morning Adhkar
-   Evening Adhkar

Each Dhikr item can contain:

-   Arabic text
-   English translation
-   Target count
-   Current count
-   Benefits/references
-   Category
-   Completion state

The user progresses through the configured count.

Dhikr remains independent from generic Habits.

------------------------------------------------------------------------

# 11. Qiyam

Qiyam is an optional religious practice.

It can be tracked independently.

The user can use it to follow their progress and streak.

Reminder functionality can be enabled by the user.

When Qiyam reminders are enabled, the valid reminder window is:

``` text
Isha → Fajr
```

The application calculates this window from the prayer times.

The user cannot select an arbitrary daytime time for Qiyam reminders.

Qiyam can have a time and can be represented in History.

Where supported by the existing product flow, Qiyam can optionally be
associated with a Task.

------------------------------------------------------------------------

# 12. Pomodoro

Pomodoro is a focus feature.

It provides:

-   Focus sessions
-   Break sessions
-   Completed session history
-   Focus statistics
-   Optional Task association
-   XP integration

A Pomodoro session can exist without a Task.

------------------------------------------------------------------------

# 13. Finance

Finance helps the user organize and understand their money.

Namaa does not currently:

-   Hold money.
-   Receive money.
-   Transfer money between real bank accounts.

The Finance system is a tracking and organization layer.

## 13.1 Total Balance

Total represents all tracked money across the user's financial sections.

``` text
Total
=
Available
+
All Allocated Sections
```

## 13.2 Available Balance

Available represents money the user can currently spend.

Example:

``` text
Income = 10,000

Available = 10,000
Total     = 10,000
```

If the user allocates 2,000 to Savings:

``` text
Available = 8,000
Savings   = 2,000
Total     = 10,000
```

The allocated money remains part of Total.

## 13.3 Financial Sections

Money can be organized into sections such as:

-   Savings
-   Goals
-   Investment tracking
-   Other supported allocations

Each section has its own balance.

If money is allocated:

``` text
Available ↓
Section   ↑
Total     unchanged
```

If the user spends directly from Available:

``` text
Available ↓
Total     ↓
History   + transaction
```

If the user spends money from an allocated section:

``` text
Section   ↓
Total     ↓
Available unchanged
```

The spent amount does not return to Available.

## 13.4 Savings Goals

A Savings area can contain multiple goals.

Each goal tracks its own:

-   Target amount
-   Saved amount
-   Progress
-   Remaining amount
-   Completion state

When a goal is completed and its money is spent to purchase the target:

-   The corresponding amount is removed from the Savings balance.
-   Total decreases.
-   The amount does not return to Available.

If other Savings goals exist, their balances remain unchanged.

## 13.5 Available Balance Protection

The user cannot allocate more money than the current Available Balance.

Example:

``` text
Available = 2,000

Request allocation = 3,000

Result:
Reject allocation
Inform user that Available Balance is insufficient
```

Total is not used as a substitute for Available when checking whether a
new allocation is possible.

## 13.6 Recurring Income

The user can define recurring income such as a monthly salary.

They can specify:

-   Amount
-   Expected date/day
-   Source/details

When the configured income becomes due, the amount can be added
automatically to Available according to the product behavior.

The user receives a notification that the income was added.

## 13.7 Recurring Obligations

The user can configure recurring financial obligations/installments.

When due:

-   The amount is deducted from Available.
-   The financial record is stored in History.
-   The user receives a notification explaining the deduction.

## 13.8 Budget

Budget is a tracking mechanism over financial transactions.

It does not create a separate balance and does not reserve money.

It can track:

-   Spending limit
-   Category
-   Period
-   Spent amount
-   Remaining amount
-   Alert threshold

## 13.9 Reports

Reports are derived from financial records.

They provide analysis and summaries without becoming a separate source
of financial truth.

------------------------------------------------------------------------

# 14. Gamification

Gamification motivates continued progress.

XP is centralized as a shared capability.

XP can be awarded for supported activities such as:

-   Task completion
-   Pomodoro completion
-   Prayer completion
-   Quran Wird
-   Morning/Evening Dhikr
-   Qiyam
-   Savings progress

A Task awards its XP only once.

Duplicate synchronization/retry operations must not duplicate XP.

Streaks remain specific to the domain that owns them.

For example:

``` text
Habit Streak
Quran Wird Streak
Qiyam Streak
```

These are not automatically merged into one domain-specific streak.

------------------------------------------------------------------------

# 15. Notifications

Notifications are configurable.

The user chooses what they want to receive.

Notifications are delivered on the device where they are enabled.

This allows scenarios such as:

``` text
Mobile
Notifications OFF

Desktop
Notifications ON
```

The user does not have to keep both devices active for notifications.

Supported notification types include relevant product areas such as:

-   Prayer
-   Qiyam
-   Habits
-   Tasks
-   Finance recurring income
-   Finance obligations

Notification sound/presentation can vary by type.

Prayer may use Adhan.

Other notifications can use normal system notification behavior or
supported custom behavior.

------------------------------------------------------------------------

# 16. Authentication and Account

Authentication is required for the account-based experience.

Supported authentication behavior includes the authentication options
defined by the existing product.

After successful login, the application synchronizes the user's data.

After the initial authenticated synchronization, the user can continue
using the application offline.

## Logout

Logout only signs the user out.

It does not delete data.

## Delete Account

Delete Account starts a three-day recovery period.

During the three-day period:

-   The user can recover the account.
-   The user's data remains recoverable.

After three days:

-   The account is permanently deleted.
-   All associated data is permanently deleted.
-   Recovery is no longer possible.

------------------------------------------------------------------------

# 17. Settings and Personalization

Initial identity information includes:

-   Name
-   Gender
-   Birth date

These are collected initially and are not treated as normal editable
settings in the current product direction.

Editable preferences include:

-   Language
-   Theme
-   Notification preferences
-   Personalization

Supported languages:

-   Arabic
-   English

Arabic requires proper RTL behavior.

Theme supports:

-   Light
-   Dark
-   System

Future seasonal themes may be added later, such as Ramadan or Eid
themes.

------------------------------------------------------------------------

# 18. Offline-First and Multi-Device Experience

Namaa is designed to work normally offline.

Core behavior should not stop because the user temporarily has no
internet.

The application should:

1.  Apply the user action locally.
2.  Persist it.
3.  Update the UI immediately.
4.  Queue synchronization when required.
5.  Synchronize with the server when connectivity returns.

Example:

``` text
Offline
User completes Task
        ↓
Local state updated
        ↓
XP updated
        ↓
UI updated
        ↓
Sync queued
        ↓
Internet returns
        ↓
Server synchronized
```

The same user account can be used on Mobile and Desktop.

After synchronization:

``` text
Mobile
   ↕
Server
   ↕
Desktop
```

The user should see the same synchronized product data on their devices.

------------------------------------------------------------------------

# 19. Data Ownership

Each domain owns its own canonical data.

Examples:

``` text
Tasks       → Task data
Habits      → Habit data
Prayer      → Prayer data
Quran       → Quran progress/bookmarks/history
Finance     → Financial records
Pomodoro    → Focus sessions
```

Cross-domain features consume data through explicit relationships or
application services.

The Dashboard and Analytics do not become alternative sources of truth.

------------------------------------------------------------------------

# 20. Cross-Domain Integrations

Namaa intentionally connects some domains.

Examples:

``` text
Task
 ↓
Mind Map
```

``` text
Task Completion
 ↓
XP
 ↓
Celebration
```

``` text
Prayer Times
 ↓
Prayer
 ↓
Qiyam Window
```

``` text
Quran Wird
 ↓
Progress
 ↓
Streak
 ↓
XP
```

``` text
Finance
 ↓
Dashboard
 ↓
Analytics
```

These integrations should preserve domain ownership.

------------------------------------------------------------------------

# 21. Design and UI Direction

The first implementation should reproduce the existing prototype
behavior and general UI structure.

The goal of the first implementation phase is **functional and
behavioral parity**, not redesign.

After the application is working:

-   Review the current UI.
-   Identify what should change.
-   Apply the Namaa Design System.
-   Improve responsive behavior.
-   Improve Mobile/Desktop layouts.
-   Refine typography, spacing, components, animations, and visual
    hierarchy.

UI decisions should be made after the complete product behavior is
understood.

------------------------------------------------------------------------

# 22. Mobile and Desktop

The same Namaa product should work across:

-   Mobile
-   Desktop

The experience should adapt to the platform rather than simply
stretching the mobile UI.

However, platform adaptation must not change the underlying business
rules.

Examples:

``` text
Same data
Same business rules
Different presentation where necessary
```

Notifications can intentionally differ by device.

------------------------------------------------------------------------

# 23. Future Integrations

Future integrations may include bank-message/bank-data synchronization.

For example, a future integration could detect:

``` text
Income received
Expense detected
Transfer detected
```

and synchronize the corresponding tracking information into Namaa.

This is future scope.

The current application does not perform real banking transactions.

------------------------------------------------------------------------

# 24. Project Phases

## Phase 1 --- Understand and Lock Product

-   Review all project sources.
-   Understand the existing prototype.
-   Confirm product behavior.
-   Record explicit product decisions.
-   Identify unresolved source gaps.
-   Establish the project Constitution.

## Phase 2 --- Foundation

Build and verify:

-   Flutter project
-   Architecture
-   Local database
-   Firebase integration
-   Authentication infrastructure
-   Sync foundation
-   Dependency injection
-   Routing
-   Localization
-   RTL
-   Theme
-   Testing foundation

## Phase 3 --- Core Productivity

Implement:

-   Tasks
-   Habits
-   Mind Maps
-   Dashboard / Today

## Phase 4 --- Religious Experience

Implement:

-   Prayer
-   Quran Reader
-   Quran Wird
-   Quran Audio
-   Quran Memorization
-   Quran Bookmarks / History
-   Dhikr
-   Qiyam

## Phase 5 --- Focus

Implement:

-   Pomodoro

## Phase 6 --- Finance

Implement:

-   Income
-   Expenses
-   Available / Total
-   Financial Sections
-   Savings Goals
-   Recurring income
-   Recurring obligations
-   Budgets
-   Reports
-   Finance history

## Phase 7 --- Motivation and Communication

Implement:

-   Gamification
-   XP
-   Streaks
-   Celebrations
-   Notifications

## Phase 8 --- Account and Personalization

Implement:

-   Settings
-   Language
-   RTL
-   Theme
-   Notification preferences
-   Logout
-   Delete Account / recovery

## Phase 9 --- Analytics

Implement cross-domain analytics and progress views.

## Phase 10 --- Integration

Verify interactions between domains.

## Phase 11 --- UI Refinement

Review and refine the UI after functional behavior is stable.

## Phase 12 --- Full Verification

Verify:

-   Functional behavior
-   Persistence
-   Offline operation
-   Synchronization
-   Multi-device behavior
-   Data integrity
-   Quran integrity
-   Finance calculations
-   Notifications
-   Localization
-   Mobile
-   Desktop
-   Regression
-   Performance

------------------------------------------------------------------------

# 25. Current Technology Direction

The application will be built with:

-   Flutter
-   Dart
-   Clean Architecture
-   Feature-first organization
-   BLoC/Cubit
-   Drift / SQLite
-   Firebase Auth
-   Cloud Firestore
-   Custom local-first synchronization
-   get_it / injectable
-   Freezed
-   json_serializable
-   go_router
-   Dio where external APIs are required
-   flutter_local_notifications with platform-specific support where
    required
-   just_audio for Quran audio
-   Flutter localization using ARB/gen_l10n
-   flutter_test
-   bloc_test
-   integration_test

Technology choices must be verified for the required Mobile and Desktop
targets before being treated as production-locked.

------------------------------------------------------------------------

# 26. Development Strategy

Namaa should be built incrementally.

Do not implement the entire application in one pass.

For each domain:

``` text
Understand
   ↓
Specify
   ↓
Plan
   ↓
Implement
   ↓
Test
   ↓
Review
   ↓
Integrate
```

A feature is considered complete only after its behavior and integration
have been verified.

------------------------------------------------------------------------

# 27. First Implementation Target

The immediate development target is the **Foundation**.

The first implementation should establish the project skeleton and
infrastructure needed for all later domains.

After the foundation is verified, development proceeds domain by domain.

The next product implementation target is:

``` text
Tasks
```

followed by:

``` text
Habits
Mind Maps
Dashboard / Today
Prayer
Quran
Dhikr
Qiyam
Pomodoro
Finance
Gamification
Notifications
Settings
Analytics
Cross-domain Integration
```

------------------------------------------------------------------------

# 28. Project Success Criteria

Namaa is successful when the user can use the application naturally
across Mobile and Desktop while:

-   Working offline.
-   Synchronizing safely when online.
-   Managing tasks and habits.
-   Connecting Mind Maps with Tasks.
-   Tracking prayers and religious practices.
-   Reading and memorizing Quran.
-   Tracking Quran Wird and its streak.
-   Managing personal finances without treating Namaa as a bank.
-   Tracking focus sessions.
-   Receiving configurable notifications on the devices they choose.
-   Seeing meaningful daily progress.
-   Seeing motivation through XP, streaks, and achievements.
-   Keeping the same account data synchronized across devices.
-   Trusting that important data, especially Quran and Finance records,
    remains correct.
