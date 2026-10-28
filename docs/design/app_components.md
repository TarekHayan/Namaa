# Namaa UI components

Shared presentation code lives in `lib/app/theme/` and `lib/app/widgets/`.
Feature logic and localization stay with each feature; callers pass translated
labels and messages into the components.
The architecture check classifies these shared theme and widget files, plus
generated localization resources under `lib/app/l10n/generated/`, as
presentation resources. Feature views may import them; app composition,
navigation wiring, and data adapters remain outside feature presentation.
The architecture check classifies these shared theme and widget files, plus
generated localization resources under `lib/app/l10n/generated/`, as
presentation resources. Feature views may import them; app composition,
navigation wiring, and data adapters remain outside feature presentation.

## Theme and type

- `AppColors` holds the approved light and dark palette. Feature widgets read
  the active palette from `Theme.of(context).brightness`.
- `AppTheme` supplies the default Scaffold background, AppBar, buttons, dialogs,
  menus, progress indicators, and SnackBars. A feature can override these only
  when its prototype has a distinct surface, such as the Dashboard's transparent
  scrolling header or the Mind Map canvas.
- `AppTypography` defines semantic text sizes and weights. The app root updates
  the `TextTheme` at width breakpoints below 360, 600, and 1024 logical pixels.
  Flutter's user text scaling applies separately. Prefer `AppText` with an
  `AppTextRole`, or `Theme.of(context).textTheme`, over literal font sizes.

## Reusable controls

- `AppButton` has primary, secondary, outline, text, and danger variants; small,
  medium, and large sizes; optional icon, loading state, and full-width layout.
  Use it for feature actions unless the prototype calls for a distinct control.
- `AppSelectField` is the shared form selector; popup menus inherit
  `AppMenuDesign` through the app theme.
- `AppStatusView.loading`, `.error`, and `.success` render consistent feedback.
  Error and success views can expose an action. Callers supply localized text.
- Buttons inherit animated hover/focus feedback from `AppTheme`; `AppButton`
  keeps the same behavior for its intent variants. Use `AppHoverSurface` for
  interactive cards and navigation rows that need a subtle emerald edge and
  glow. Its decoration must not change the card's bounds, so nearby content
  stays still. A touch does not activate hover; disabled actions stay quiet.

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
