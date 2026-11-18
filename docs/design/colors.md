# Namaa application colors

The default is **Emerald / الزمرد الملكي**, imported from
`prototype.zip` → `src/utils/personalization.ts` (`COLOR_PALETTES`, `emerald`).
`src/index.css` confirms the default dark tokens; `DESIGN_SYSTEM_COLORS.md`
documents both modes and the semantic information colors.

| Role | Light | Dark |
| --- | --- | --- |
| Primary / accent / success | `#059669` | `#10B981` |
| Secondary | `#047857` | `#059669` |
| Scaffold background | `#F8FAF8` | `#050805` |
| Surface / card | `#FFFFFF` | `#0A0F0C` |
| Secondary surface | `#F0F4F1` | `#111A14` |
| Main text | `#0D1410` | `#FFFFFF` |
| Secondary text | `#374151` | white at 72% |
| Muted text | `#6B7280` | white at 42% |
| Decorative border | black at 8% | white at 10% |
| Soft accent | primary at 12% | primary at 16% |
| Input background | `#F3F4F6` | `#0A0D0B` |
| Input border | black at 12% | white at 10% |
| Navigation background | white at 94% | `#0A0F0C` at 92% |
| Card glow | primary at 15% | primary at 25% |
| Warning | `#D97706` | `#F59E0B` |
| Error | `#DC2626` | `#EF4444` |
| Information | `#2563EB` | `#3B82F6` |

### Design tokens added with the Adhkar design

These come from the approved 2026-11 design and are read through
`AppColors.of(context)` by the shared components in `lib/app/widgets/`.

| Role | Light | Dark |
| --- | --- | --- |
| Accent for text, icons and filled actions (`accentStrong`) | `#047857` | `#10B981` |
| Text and icons on it (`onAccentStrong`) | `#FFFFFF` | `#050805` |
| Progress ring track (`track`) | primary at 16% | primary at 20% |
| Soft warning fill (`warningSoft`) | warning at 12% | warning at 14% |
| Soft error fill (`errorSoft`) | error at 8% | error at 14% |
| Error text on a surface (`errorText`) | `#B91C1C` | `#F87171` |
| Text and icons on a filled error (`onError`) | `#FFFFFF` | `#050805` |
| Scrim behind sheets and dialogs (`scrim`) | `#0D1410` at 42% | black at 66% |
| Glow color (`glow`) | primary at 12% | primary at 14% |

`cardShadow` is the soft glow around raised cards, sheets and floating
controls; `buttonShadow` is the stronger glow under a filled accent button.
Both differ between the two modes (an offset blur in light, a ring plus blur
in dark), so they are tokens and not computed in features.

## Flutter reference for future screens

All values are stored as immutable tokens in `lib/app/theme/app_colors.dart`:
`AppColors.light.primary`, `AppColors.dark.background`, etc. Accent equals
`primary`; card equals `surface`, matching the source aliases.

The Today dashboard now uses these tokens for its own light and dark layout.
They are not connected to global `AppTheme`, so other screens retain their
existing appearance. The UI is integrated one screen at a time.

When building a screen, choose text/background pairs with sufficient contrast;
the prototype's translucent muted/border colors are not substitutes for readable
body text or visible interactive outlines. The older `cardGlow` and navigation alpha
values are reference tokens; the shadow tokens above are the ones the shared
components draw.
