# Design System

> Status: decided 2026-11-25, not built yet. Code lives in `lib/ui/core/themes/` (tokens) and `lib/ui/core/ui/base/` (widgets).

The look is a **dark-first media app**, in the style of Spotify, Linear and Arc: deep near-black surfaces, one vivid gradient accent, big rounded cards, large thumbnails and generous spacing. Content (thumbnails, photos, video) is the colour on screen; the chrome stays quiet so it doesn't compete. Light mode is a full first-class theme, not an afterthought. The app follows the system setting, with an override in Settings.

## Table of Contents

- [Principles](#principles)
- [Colour](#colour)
- [Typography](#typography)
- [Spacing, Radius and Elevation](#spacing-radius-and-elevation)
- [Iconography](#iconography)
- [Motion](#motion)
- [Layout and Navigation](#layout-and-navigation)
- [Components](#components)
- [Key Screens](#key-screens)
- [Accessibility](#accessibility)
- [Code Structure](#code-structure)

## Principles

1. **Paste and go.** The download screen opens ready to paste. One tap on **Paste** reads the clipboard, detects the site and opens the preview. Nothing else is needed for the common case.
2. **Content first.** Thumbnails are big, with rounded corners and no borders. Text sits under or over them, never boxed in.
3. **One accent.** The Aurora gradient marks the one primary action on a screen (Download, Convert, Save), progress and the active tab. Everything else is neutral.
4. **Calm progress.** Progress is a thin gradient bar with numbers (percent, speed, ETA) in tabular figures, so digits don't jump while they change.
5. **Undoable, or asked.** Removing a file always confirms; nothing destructive happens on a single tap.

## Colour

### Brand gradient: "Aurora"

| Stop | Hex | Use |
| --- | --- | --- |
| 0% | `#6A4CF5` (violet) | Start of every gradient; solid primary when a gradient doesn't fit |
| 50% | `#B44CF0` (orchid) | Middle stop |
| 100% | `#FF4D8D` (pink) | End stop |

Used for: primary buttons, progress bars, the active nav indicator, the selected quality chip, and a soft blurred glow (about 20% opacity) behind the download screen's header. Never as a full-screen background and never behind body text.

### Theme tokens

All colours come from `AppColors` (a `ThemeExtension`). Never write a hex value in a widget.

| Token | Dark (default) | Light | Use |
| --- | --- | --- | --- |
| `background` | `#0B0B12` | `#F7F7FB` | Scaffold |
| `surface` | `#14141F` | `#FFFFFF` | Cards, sheets |
| `surfaceRaised` | `#1C1C2A` | `#F0F0F7` | Inputs, chips, nested cards |
| `outline` | `#2A2A3C` | `#E2E2EC` | 1px borders, dividers |
| `textPrimary` | `#F5F5FA` | `#0F0F1A` | Titles, body |
| `textSecondary` | `#A1A1B5` | `#5B5B70` | Metadata (uploader, size, date) |
| `textMuted` | `#6B6B80` | `#8E8EA3` | Placeholders, disabled |
| `primary` | `#6A4CF5` | `#6A4CF5` | Solid fills with white text (5.3:1 contrast) |
| `primaryText` | `#8B73FF` | `#5A3DE6` | Links, icons and accent text on the background |
| `secondary` | `#22D3EE` | `#0891B2` | Secondary highlights: "processing" stage, info badges |
| `success` | `#22C55E` | `#16A34A` | Completed, saved |
| `warning` | `#F5A524` | `#D97706` | Needs cookies, engine update available |
| `error` | `#F43F5E` | `#E11D48` | Failed, delete |
| `scrim` | `#000000` at 60% | `#0F0F1A` at 40% | Behind sheets and dialogs |

Contrast is checked against WCAG AA: body text on `background` and `surface` is above 7:1 in both themes, `textSecondary` above 4.5:1, white on `primary` is 5.3:1. `#7C5CFF` was rejected for fills (4.3:1 with white text).

### Site colours

Each site gets a small badge (a 20px rounded square with its glyph) on thumbnails and job cards. Only the badge uses the site colour; the rest of the card stays neutral.

| Site | Badge colour |
| --- | --- |
| YouTube | `#FF0033` |
| Facebook | `#0866FF` |
| Instagram | gradient `#FEDA75` → `#D62976` → `#4F5BD5` |
| TikTok | `#000000` with `#25F4EE` / `#FE2C55` glyph |
| X | `#000000` (dark mode: `#FFFFFF` badge, black glyph) |
| Threads | `#000000` (dark mode: `#FFFFFF` badge, black glyph) |

Use simple, generic glyphs that we draw ourselves (play triangle, camera, note, etc.), not the companies' logo files.

## Typography

Two bundled fonts (SIL Open Font License, shipped in `assets/fonts/`, no runtime download):

- **Plus Jakarta Sans** for display and headings: friendly, rounded, distinctive.
- **Inter** for body, labels and numbers, with `FontFeature.tabularFigures()` on every number that updates live (percent, speed, ETA, sizes).

| Style | Font | Size / line height | Weight | Use |
| --- | --- | --- | --- | --- |
| `display` | Jakarta | 32 / 40 | 800 | Download screen header ("Paste a link") |
| `title` | Jakarta | 22 / 28 | 700 | Screen titles, preview title |
| `headline` | Jakarta | 18 / 24 | 700 | Section headers, card titles |
| `body` | Inter | 15 / 22 | 400 | Body text |
| `bodyStrong` | Inter | 15 / 22 | 600 | Emphasis, button labels |
| `label` | Inter | 13 / 18 | 500 | Chips, metadata |
| `caption` | Inter | 12 / 16 | 500 | Badges, timestamps |
| `numeric` | Inter tabular | 13 / 18 | 600 | Progress numbers, file sizes |

Titles from sites can be long or non-Latin (Hindi, Arabic, emoji). Always set `maxLines` + ellipsis, and let the platform fall back to system fonts for scripts Inter doesn't cover.

## Spacing, Radius and Elevation

- **Spacing:** 4pt grid. Tokens `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`, `xxxl 48`. Screen side padding 16 on phones, 24 on tablets and macOS.
- **Radius:** `sm 8` (badges, small chips), `md 12` (inputs, buttons), `lg 16` (cards, thumbnails), `xl 24` (bottom sheets, dialogs), `full` (pills, avatars).
- **Elevation:** no heavy shadows. Cards separate from the background by colour (`surface` on `background`) plus a 1px `outline` border in light mode. Floating things (bottom nav, mini player, toasts) use a backdrop blur (sigma 20) over `surface` at 80% opacity.

## Iconography

Material Symbols **Rounded**, weight 400, filled for the selected state, outlined otherwise. Sizes 20 (inline), 24 (default), 28 (nav). The icon set is the only one used; don't mix in another set.

## Motion

| Token | Duration | Curve | Use |
| --- | --- | --- | --- |
| `fast` | 150ms | `easeOutCubic` | Press states, chip selection |
| `normal` | 250ms | `easeOutCubic` | Sheet open, card expand, tab switch |
| `slow` | 400ms | `easeInOutCubicEmphasized` | Hero thumbnail from preview to queue card |

- The preview thumbnail flies (Hero) into its job card when you tap **Download**.
- Progress bars animate between values instead of jumping.
- Completed jobs pulse once with `success` and a light haptic (mobile).
- When `MediaQuery.disableAnimations` is on, drop to instant changes.

## Layout and Navigation

| Width | Layout |
| --- | --- |
| < 600 (phones) | Bottom nav bar (blurred, 4 tabs), single column |
| 600–839 (small tablets) | Bottom nav, 2-column grids |
| ≥ 840 (tablets, macOS) | Left sidebar (NavigationRail, expanded with labels on macOS), two panes where it helps: Library grid + detail, Download queue + preview |

Four tabs, in this order: **Download**, **Library**, **Convert**, **Settings**. On macOS the window has a minimum size of 900×600 and the whole Download and Convert screens accept dropped links and files.

The screen-size breakpoint is tracked by a `ScreenTypeNotifier` (same idea as vAIolin's `ScreenObserverNotifier`), so only widgets that care rebuild when the window resizes.

## Components

All under `lib/ui/core/ui/base/<category>/`, plain props only (no providers), one widget per file.

| Category | Widgets |
| --- | --- |
| `buttons/` | `GradientButton` (primary), `TonalButton` (secondary), `GhostButton` (tertiary), `AppIconButton` (circle, 40px) |
| `cards/` | `AppCard`, `MediaCard` (thumbnail + title + metadata + badge), `JobCard` (MediaCard + progress + actions) |
| `media/` | `MediaThumbnail` (local or remote, rounded, duration pill, kind icon), `SiteBadge`, `PreviewPlayer` (inline video with play/pause/scrub), `PhotoGrid` (selectable) |
| `progress/` | `GradientProgressBar`, `StageLabel` (Queued / Downloading / Processing / Saving / Done / Failed) |
| `chips/` | `SelectChip` (quality, format, filter), `ChipRow` (horizontal scroll) |
| `form/` | `LinkField` (big rounded field with Paste button and site icon that appears when the URL is recognised), `AppSlider`, `AppSwitchTile`, `SegmentedPicker` (Video / Audio / Photos) |
| `sheets/` | `AppBottomSheet` (drag handle, `xl` radius, blurred scrim), `ActionSheet` (list of icon + label actions) |
| `dialog/` | `ConfirmDialog` (title, body, destructive variant), `SavedRemovePrompt` (the "Saved. Remove from app?" dialog with "Don't ask again") |
| `states/` | `EmptyState` (illustration + title + action), `ErrorState` (message + Retry), `ShimmerBox` (loading placeholder matching the final layout) |

Messages use `ToastUtil` on top of `flutter_sliding_toast` (the same setup as vAIolin), never a raw `SnackBar`.

## Key Screens

### Download

```
┌──────────────────────────────────┐
│  (soft Aurora glow)              │
│  Paste a link                    │  display
│  YouTube · Facebook · Instagram… │  site badges row
│ ┌──────────────────────────────┐ │
│ │ 🔗 https://…        [ Paste ]│ │  LinkField
│ └──────────────────────────────┘ │
│                                  │
│  In progress                     │  headline
│ ┌──────────────────────────────┐ │
│ │ [thumb] Title of video…   ▶  │ │  JobCard
│ │ ▓▓▓▓▓▓▓▓▓░░░░ 64% · 3.2 MB/s │ │
│ │ 1080p MP4 · 45 s left    [✕] │ │
│ └──────────────────────────────┘ │
│  Finished                        │
│ ┌──────────────────────────────┐ │
│ │ [thumb] Another title     ✓  │ │
│ │ 720p MP4 · 84 MB  [Share][🗑] │ │  Share / Remove
│ └──────────────────────────────┘ │
├──────────────────────────────────┤
│  ⬇ Download  ▦ Library  ⇄  ⚙    │  blurred nav
└──────────────────────────────────┘
```

### Preview sheet (after Paste)

```
┌──────────────────────────────────┐
│            ───                   │
│ ┌──────────────────────────────┐ │
│ │      big thumbnail / player  │ │  tap ▶ to preview in app
│ │                        12:34 │ │
│ └──────────────────────────────┘ │
│ Title of the video, two lines…   │
│ ▣ Uploader name · YouTube        │
│                                  │
│ [ Video ][ Audio ][ Photos ]     │  SegmentedPicker
│ (Best)(4K 1.2GB)(1080p 310MB)…   │  quality chips with sizes
│ iPhone-compatible  ●──           │
│                                  │
│ [      ⬇  Download 310 MB     ]  │  GradientButton
└──────────────────────────────────┘
```

Photo posts show a `PhotoGrid` instead of the player, all images pre-selected, with "Select all / none" and a count on the button ("Download 6 photos").

### Library

Grid of `MediaCard`s (2 columns on phones, adaptive on wider screens), filter chips on top (All · Videos · Audio · Photos, then site chips), search in the app bar, sort menu (Newest, Oldest, Largest). Long-press (or right-click on macOS) opens an `ActionSheet`: Save to Photos, Save to Files, Share, Convert, Delete. Items already saved show a small ✓ on the thumbnail.

### Convert

A three-step flow in one screen: **1. Pick** (three big tiles: From Library · From Photos · From Files; drop zone on macOS) → **2. Choose** (`SegmentedPicker`: Convert / Compress, then format chips or preset chips + slider) → **3. Result** (before → after size, with a "−62%" badge in `success`, Save / Share / Keep in Library).

## Accessibility

- Touch targets at least 48×48.
- Text scales to 200% without clipping; cards grow taller, chips wrap.
- Every icon-only button has a semantic label from the message catalog.
- Colour is never the only signal: stages have text labels, saved items have an icon.
- Focus rings and keyboard shortcuts on macOS: ⌘V pastes a link anywhere, ⌘⌫ deletes the selected Library item (with confirm), Space plays/pauses a preview.

## Code Structure

```
lib/ui/core/themes/
  app_colors.dart        # AppColors ThemeExtension (dark + light)
  app_gradients.dart     # Aurora + site gradients
  app_typography.dart    # TextTheme + numeric style
  app_spacing.dart       # spacing + radius tokens
  app_motion.dart        # durations + curves
  theme_data.dart        # buildTheme(Brightness) -> ThemeData (Material 3)
  theme.dart             # BuildContext extensions: context.colors, context.text, context.spacing
```

`ThemeData` is Material 3 (`material_ui` package), with the `ColorScheme` filled from the tokens above so stock widgets (dialogs, switches, sliders) match without extra styling.
