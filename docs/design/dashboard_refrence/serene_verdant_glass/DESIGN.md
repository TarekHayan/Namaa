---
name: Serene Verdant Glass
colors:
  surface: '#0f1511'
  surface-dim: '#0f1511'
  surface-bright: '#353a37'
  surface-container-lowest: '#0a0f0c'
  surface-container-low: '#181d19'
  surface-container: '#1c211d'
  surface-container-high: '#262b28'
  surface-container-highest: '#313632'
  on-surface: '#dfe4de'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dfe4de'
  inverse-on-surface: '#2c322e'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#68dba9'
  on-secondary: '#003825'
  secondary-container: '#25a475'
  on-secondary-container: '#00311f'
  tertiary: '#adc6ff'
  on-tertiary: '#002e6a'
  tertiary-container: '#71a1ff'
  on-tertiary-container: '#00367a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#85f8c4'
  secondary-fixed-dim: '#68dba9'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#005137'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#0f1511'
  on-background: '#dfe4de'
  surface-variant: '#313632'
typography:
  display-lg:
    fontFamily: IBM Plex Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 52px
  display-lg-mobile:
    fontFamily: IBM Plex Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 42px
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: IBM Plex Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 34px
  headline-sm:
    fontFamily: IBM Plex Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-md:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-lg:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: IBM Plex Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-lg: 1.5rem
  margin: 1rem
  margin-md: 1.5rem
  margin-lg: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system embodies intentionality, spiritual mindfulness, and disciplined personal stewardship. It is crafted for individuals seeking harmony across three core facets of daily life: spiritual practice (Islamic worship), mental clarity (personal productivity), and ethical growth (personal finance).

The visual language bridges organic tranquility with technical precision. It couples the contemplative serenity of nature with an Apple-inspired frosted glass aesthetic. Interfaces feel calm, uncluttered, and reverent—eschewing jarring alerts or hyperactive gamification in favor of measured progress, smooth spatial depth, and pristine bi-directional typographic legibility (with first-class RTL Arabic optimization).

Every view acts as a tranquil sanctuary:
- **Tone:** Grounded, contemplative, disciplined, trustworthy.
- **Visual Movement:** Translucent Glassmorphism with deep emerald undertones, microscopic interior hairline highlights, and muted atmospheric glows.
- **RTL Philosophy:** Native RTL-first mental model where temporal flows, progress states, and hierarchical stacks naturally mirror the rhythm of Arabic script without visual tension.

## Colors

The palette draws directly from lush botanical foliage and deep nighttime contemplation. The primary emerald green serves as an anchor of vitality, spiritual barakah, and sustained financial growth.

### Theme Modes

#### Dark Mode (Default)
- **Background:** `#050805` (Deep midnight forest substrate)
- **Surface Layer 1:** `#0A0F0C` (Elevated dark moss surface)
- **Surface Layer 2:** `#111A14` (Nested card/modal surface)
- **Glass Tint:** `rgba(16, 26, 20, 0.72)` with backdrop filter blur `20px`
- **Text Primary:** `#FFFFFF`
- **Text Secondary:** `rgba(255, 255, 255, 0.72)`
- **Text Muted:** `rgba(255, 255, 255, 0.44)`
- **Borders & Separators:** `rgba(255, 255, 255, 0.10)`
- **Glow & Highlights:** `rgba(16, 185, 129, 0.25)`

#### Light Mode
- **Background:** `#F8FAF8` (Soft morning mist)
- **Surface Layer 1:** `#FFFFFF` (Pure optic card)
- **Surface Layer 2:** `#F0F4F1` (Subtle tinted secondary ground)
- **Glass Tint:** `rgba(255, 255, 255, 0.82)` with backdrop filter blur `20px`
- **Primary Action:** `#059669`
- **Secondary Action:** `#047857`
- **Text Primary:** `#0D1410`
- **Text Secondary:** `#374151`
- **Text Muted:** `#6B7280`
- **Borders & Separators:** `rgba(0, 0, 0, 0.08)`
- **Glow & Highlights:** `rgba(5, 150, 105, 0.15)`

### Semantic Accents
- **Success:** `#10B981` (Completed prayer, financial gain, task achieved)
- **Warning:** `#F59E0B` (Approaching prayer time, budget threshold at 80%)
- **Error / Urgent:** `#EF4444` (Missed deadline, budget overspend)
- **Informative:** `#3B82F6` (Neutral reference, sync metadata)
- **Emerald Mist / Soft Pill Accent:** `rgba(16, 185, 129, 0.16)`

## Typography

Typographic hierarchy is engineered for balanced multilingual harmony, ensuring effortless baseline parity between Arabic and Latin scripts.

### Font Family Fallbacks
- Primary Font Stack: `IBM Plex Sans Arabic`, `Thmanyah Sans`, `Tajawal`, `IBM Plex Sans`, -apple-system, BlinkMacSystemFont, sans-serif.

### Behavioral Rules
- **Arabic Baselines:** Line heights are augmented by roughly 10–15% over standard Latin-only interfaces to prevent Arabic diacritics (harakat) and descenders from clipping.
- **Numerals:** Financial figures and daily counts default to tabular lining numbers (`font-variant-numeric: tabular-nums`) to preserve column alignment in budgeting tables and prayer schedules.
- **Weight Distribution:** Bold weights (`700`) are reserved for display statistics and hero balance counters. Section headers leverage Semi-Bold (`600`), while body and instructional labels utilize Medium (`500`) and Regular (`400`) to maintain a quiet, meditative posture.

## Layout & Spacing

Layouts adhere to an 8pt base grid with an inner 4pt sub-unit for tight micro-alignments (such as icons, status dots, and indicator badges).

### Breakpoints & Layout Adapters
- **Mobile (< 768px):** Single column fluid container. Edge margins: `16px` (`margin`). Column gutter: `16px` (`gutter`). Bottom safe zones are reserved for navigation bars and sticky action triggers.
- **Tablet (768px - 1024px):** 8-column layout. Edge margins: `24px` (`margin-md`). Sidebar unfolds for secondary tools (prayer compass, budget split-ups).
- **Desktop (> 1024px):** 12-column layout with a maximum centered container width of `1280px`. Edge margins: `40px` (`margin-lg`). Two-to-three pane views allow concurrent interaction with the daily calendar, habit checklist, and ledger ledger balance.

### Spacing Principles
- Never pack interactive modules edge-to-edge. Group them within distinct glass containers spaced by `space-lg` (`1.5rem`) to afford intellectual breathing room.
- Component internal padding strictly uses `space-md` (`1rem`) on compact cards and `space-lg` (`1.5rem`) on primary summary widgets.

## Elevation & Depth

Visual hierarchy uses frosted optical glass physics rather than opaque drop shadows. Surfaces appear suspended over a deep emerald-black atmospheric canvas.

### The Glass Layering Model
1. **Base Layer (Canvas):** Pure dark substrate (`#050805`) with ambient radial blurs of emerald tint (`rgba(16, 185, 129, 0.08)`) placed behind primary focal areas.
2. **Surface Layer (Standard Cards):** Translucent fill `rgba(10, 15, 12, 0.70)` overlaid with `backdrop-filter: blur(24px) saturate(180%)`. Border: hairline `1px solid rgba(255, 255, 255, 0.08)`.
3. **Elevated Layer (Modals & Flyouts):** Translucent fill `rgba(17, 26, 20, 0.85)` with `backdrop-filter: blur(32px)`. Subtle outer drop shadow: `0 20px 40px -15px rgba(0, 0, 0, 0.6)`.
4. **Hero Accent Glow:** Selected cards (such as the active prayer or today's central financial target) receive an outer atmospheric bleed: `box-shadow: 0 0 30px -5px rgba(16, 185, 129, 0.25)`.
5. **Inner Specular Edge:** Glass containers possess an inner subtle top border highlight (`box-shadow: inset 0 1px 0 0 rgba(255, 255, 255, 0.12)`) simulating the beveled rim of a precision-cut lens.

## Shapes

The geometric signature uses smooth, squircular curvature reminiscent of Apple hardware and natural pebble forms.

- **Base Radius:** `0.5rem` (`8px`) for compact items: badges, inner inputs, tags, and sub-selectors.
- **Card Radius (`rounded-lg`):** `1rem` (`16px`) for structural panels, daily prayer status tiles, and habit checklists.
- **Modal & Sheet Radius (`rounded-xl`):** `1.5rem` (`24px`) for full-view cards, bottom drawers, and dialog surfaces.
- **Pill / Circular:** Full curvature (`rounded-full`) is applied strictly to primary call-to-action buttons, quick filter chips, step dots, and prayer cycle indicators.

## Components

### Buttons
- **Primary Action:** Solid emerald fill (`#10B981` Dark / `#059669` Light) with high-contrast text (`#050805` in Dark, `#FFFFFF` in Light). Subtle inner glow and smooth scale feedback (`active:scale-[0.98]`). Full pill shape.
- **Glass / Secondary:** `rgba(255, 255, 255, 0.06)` background with a `1px` border of `rgba(255, 255, 255, 0.10)`. Text primary. Hover shifts background to `rgba(255, 255, 255, 0.12)`.
- **Ghost:** Borderless, zero fill. Emerald text hover state with `space-sm` horizontal padding.

### Chips & Badges
- Pill-shaped (`rounded-full`) containing category tags, prayer state tags (e.g., "Fajr - Done"), or financial classifications.
- Background: `rgba(16, 185, 129, 0.16)` with text color `#10B981`. Inactive chips use `rgba(255, 255, 255, 0.05)` with `rgba(255, 255, 255, 0.72)` text.

### Cards & Glass Panels
- Constructed using the Surface Layer glass formula.
- Cards maintain internal content padding of `1.25rem` to `1.5rem`.
- In RTL, trailing status icons, action chevrons, and numerical metrics are pinned seamlessly to the visual left, maintaining proper reading orientation.

### Input Fields & Controls
- **Text Inputs:** Backplate fill `rgba(255, 255, 255, 0.04)` with `1px` border of `rgba(255, 255, 255, 0.10)`. Focused state shifts the border to `#10B981` paired with a soft glow: `box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.20)`. Text aligns to the right when Arabic locale is detected.
- **Checkboxes & Habit Toggles:** Soft rounded squircle (`6px`) with emerald fill on checked state featuring a micro spring-bounce animation. Unchecked presents a quiet `rgba(255, 255, 255, 0.20)` border frame.

### Lists
- Dividers between list items use hairline rules (`rgba(255, 255, 255, 0.06)`).
- Hover transitions in lists apply a gentle surface highlight (`rgba(255, 255, 255, 0.03)`).

### Specialized Domain Components
- **Prayer Progress Timeline:** Horizontal glass pill track with active glowing node (`#10B981`) marking the current solar quadrant and next upcoming prayer window.
- **Financial Vault Bar:** Split-colored bar using low-saturation translucent segments with the emerald accent representing saved/surplus funds.
- **Daily Dhikr / Counter Dial:** Frosted circular stepper button triggering responsive tactile haptic states and visual ripple feedback.