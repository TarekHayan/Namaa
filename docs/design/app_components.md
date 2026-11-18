# Namaa UI components

Shared presentation code lives in `lib/app/theme/` and `lib/app/widgets/`.
Feature logic and localization stay with each feature; callers pass translated
labels and messages into the components.
The architecture check classifies these shared theme and widget files, plus
generated localization resources under `lib/app/l10n/generated/`, as
presentation resources. Feature views may import them; app composition,
navigation wiring, and data adapters remain outside feature presentation.

## The rule

Anything generic goes in `lib/app/widgets/` (or `lib/app/theme/` for tokens
and helpers), with an `App` prefix, and every feature uses it. A feature keeps
only what is specific to it, such as a reader's page layout or how a dhikr is
drawn. Shared components:

- take their colors, radii, shadows and type from the theme tokens, never from
  feature code, so a redesign changes them in one place;
- take every visible text from the caller (translated), and hold no strings;
- carry a short doc comment saying what they are and when to use them;
- have a widget test in `test/widget/app/widgets/`, run in light and dark and
  in both text directions.

Before writing a card, pill, sheet, toast, menu, button or empty state in a
feature, check the lists below. Other features still use their own older
widgets; they move to these components when they are redesigned.

## Theme and type

- `AppColors` holds the approved light and dark palette. Feature widgets read
  the active palette with `AppColors.of(context)`. Besides the base colors it
  holds the design tokens `accentStrong` and `onAccentStrong` (text, icons and
  filled actions), `track`, `warningSoft`, `errorSoft`, `errorText`, `onError`,
  `scrim`, `glow`, and the shadows `cardShadow` and `buttonShadow`.
- `AppLayout` holds the wide breakpoint (720 px) and the readable column width;
  use `AppLayout.isWide(context)` instead of a feature constant.
- `AppTheme` supplies the default Scaffold background, AppBar, buttons, dialogs,
  menus, progress indicators, and SnackBars. A feature can override these only
  when its prototype has a distinct surface, such as the Dashboard's transparent
  scrolling header or the Mind Map canvas.
- `AppTypography` defines semantic text sizes and weights. The app root updates
  the `TextTheme` at width breakpoints below 360, 600, and 1024 logical pixels.
  Flutter's user text scaling applies separately. Prefer `AppText` with an
  `AppTextRole`, or `Theme.of(context).textTheme`, over literal font sizes.
  When a design fixes an exact size, use `AppTypography.fixed(size, weight,
  color, height:)`. `AppTypography.directionFor(text, fallback)` gives the
  direction of user-entered text.

## Reusable controls

- `AppButton` has primary, secondary, outline, text, and danger variants; small,
  medium, and large sizes; optional icon, loading state, and full-width layout.
  Use it for feature actions unless the prototype calls for a distinct control.
  `look: AppButtonLook.refined` is the approved 2026-11 design (accent fill
  with a soft glow, quiet buttons on the secondary surface, 48/52/58 px
  heights, wrapping labels, an optional `trailingIcon`). `classic` is the
  default and is what the older screens use. `tuning: AppButtonTuning(...)` is
  for a one-off radius, height, padding, weight or line height; every use is an
  exception to the system.
- `AppSelectField` is the shared form selector; popup menus inherit
  `AppMenuDesign` through the app theme.
- `AppStatusView.loading`, `.error`, and `.success` render consistent feedback.
  Error and success views can expose an action. Callers supply localized text.
- Buttons inherit animated hover/focus feedback from `AppTheme`; `AppButton`
  keeps the same behavior for its intent variants. Use `AppHoverSurface` for
  interactive cards and navigation rows that need a subtle emerald edge and
  glow. Its decoration must not change the card's bounds, so nearby content
  stays still. A touch does not activate hover; disabled actions stay quiet.

## Shared components

| Component | Use it for |
| --- | --- |
| `AppCard` | Any boxed block. Tones: surface, secondary, accent, warning, error; optional glow. |
| `AppIconBadge` | A round icon: an empty, finished or error mark, or a leading list icon. |
| `AppPill` | A small rounded label (a count, a tag, a "deleted" mark, a notice chip), with an optional icon. Tones: accent, neutral, filled, error, warning; `iconColor` and `radius` for a chip whose label wraps. |
| `AppFilterChip` | One selectable choice in a multi-select group. |
| `AppChoiceChip` | One choice of a single-select group (a 56 x 48 px pill, the selected one soft accent with an accent outline); the rak'ah choices of Qiyam. |
| `AppSwitchTile` | A label with an on/off switch in the theme's colors, at least 48 px tall. |
| `AppTimeField` | A 24-hour time the user never types: the whole field is a read-only tap target (a tap, Enter or Space) that opens the Material clock dial, dial only with no keyboard entry, and shows the choice in the locale's format, always left to right. The caller passes the `value`, `onPicked`, the translated name, hint and placeholder, and an optional `validator`: a message refuses the pick, which is then not passed on and shows under the field. `AppTimeWindow` (start, end, may cross midnight) gives the caller `contains`, `offsetOf` and `shifted` to build that validator. |
| `AppSegmentedControl` | The page-level tab switch (a tray of equal choices). |
| `AppInkSurface` | The base of a tappable rounded row, tab or tile. |
| `AppActionTile` | A bordered tappable row with an icon, a label and a chevron. |
| `AppBackLink` | The text link that goes back one level inside a page (there is no app-bar back arrow). |
| `AppSurfaceIconButton` | A square or round icon button on a bordered surface; `raised` adds the glow. |
| `AppMenuButton` | The three-dot overflow menu with the shared menu design. |
| `AppProgressRing`, `AppLinearProgress` | Circular and thin linear progress from the progress tokens. |
| `AppInlineNote` | A line of warning or error text with an icon (limits, field errors). |
| `AppBanner` | A tinted notice with an icon, a message and an optional action button. Tones: warning, accent (an informative state). |
| `AppConflictsPage`, `AppConflictEntryCard`, `AppConflictVersionCard`, `appConflictStamp` | The read-only "Sync differences" page: back link, title, one card per entry with the active and the saved version (stacked on a phone, side by side when wide), the footer; Adhkar and Qiyam compose it with their own version content. |
| `AppEmptyState` | A centered empty state: badge, title, body, action. |
| `AppToast` | A short confirmation toast. Capture with `AppToast.of(context)` before an `await`. |
| `showAppAdaptiveSheet` | Opens a form as a bottom sheet on phones and a dialog from 720 px. Build its content with `AppFormSheet`. |
| `showAppBottomSheet`, `showAppDialog`, `AppSheetPanel`, `AppSheetHandle` | The sheet and dialog hosts and their surface, for content that is not a form. |
| `showAppConfirmDialog` | A confirmation dialog with a destructive confirm button. |
| `AppInlineConfirmation` | A delete confirmation that replaces a row in place. |
| `AppButtonPair` | Two actions side by side, stacked when narrow. |
| `AppLabeledField`, `appCountedFieldDecoration` | A form field with its label above it, and the filled input look with a counter. |
| `AppTextScaleClamp` | Caps the text scale for a banner or chip so it wraps instead of clipping. |
| `AppKeyCap` | A keyboard key cap for shortcut hints on desktop. |

Keep existing widget keys when replacing a control so navigation and action
tests continue to locate the same behavior. Check narrow Arabic and English
screens at enlarged text sizes before adopting a new shared component broadly.

## Content-first sizing

User-authored primary text must remain readable in full. Measure it with the
active font, locale, and text scale, then let its card or custom shape grow or
wrap the text inside a sensible maximum width. Do not use a fixed height or
ellipsis to hide a title, description, or other content the user entered.
Decorative controls need their own space and must not overlap the text. When a
custom shape changes size, use the same measured bounds for hit testing,
connections, and canvas layout. Verify short and long Arabic and English text
at enlarged accessibility text sizes.
