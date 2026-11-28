# Design System

> Status: implemented (untested on devices). Code lives in `lib/ui/core/themes/` (tokens) and `lib/ui/core/ui/base/` (widgets).

The look is a **dark-first media app**, in the style of Spotify, Linear and Arc: deep near-black surfaces, one vivid gradient accent, big rounded cards, large thumbnails and generous spacing. Content (thumbnails, photos, video) is the colour on screen; the chrome stays quiet so it doesn't compete. Light mode is a full first-class theme, not an afterthought. The app follows the system setting, with an override in Settings.

## Table of Contents

- [Principles](#principles)
- [Colour](#colour)
- [Typography](#typography)
- [Spacing, Radius and Elevation](#spacing-radius-and-elevation)
- [Iconography](#iconography)
- [App Icon and Splash](#app-icon-and-splash)
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

**Icon beside wrapping text:** in a row with an icon and text that can wrap (large text sizes), align the icon to the first line (`crossAxisAlignment: .start`), not the middle of the block. Examples: the engine update banner, `LinkStatusPanel`, the Convert format rows.

## App Icon and Splash

- **App icon:** a clay-style icon. Sources in `assets/icon/`: `app_icon.png` (iOS, Android legacy), `app_icon_background.png` + `app_icon_foreground.png` (Android adaptive, `adaptive_icon_foreground_inset: 0`), `app_icon_monochrome.png` (Android 13 themed icon), `app_icon_macos.png` (macOS, its own rounded image). Generated with `flutter_launcher_icons` (config in `pubspec.yaml`; iOS with `remove_alpha_ios`).
- **Splash:** `flutter_native_splash` shows `assets/icon/splash.png` (Android 12+: `splash_android12.png`) on the `background` colour, `#F7F7FB` light / `#0B0B12` dark. Configured in `pubspec.yaml`, not generated yet.
- Regenerate after changing anything in `assets/icon/`: see [Development](../architecture/development.md#app-icon-and-splash).

## Motion

| Token | Duration | Curve | Use |
| --- | --- | --- | --- |
| `fast` | 150ms | `easeOutCubic` | Press states, chip selection |
| `normal` | 250ms | `easeOutCubic` | Sheet open, card expand, tab switch |
| `slow` | 400ms | `easeInOutCubicEmphasized` | Larger, emphasised transitions |

- A Library thumbnail flies (Hero) into the media viewer when you open it.
- Progress bars animate between values instead of jumping.
- Completed jobs pulse once with `success` and a light haptic (mobile).
- When `MediaQuery.disableAnimations` is on, drop to instant changes.

## Layout and Navigation

| Width | Layout |
| --- | --- |
| < 600 (phones) | Floating bottom nav bar (blurred, 5 tabs), single column |
| 600–839 (small tablets) | Bottom nav, wider grids |
| ≥ 840 (tablets, macOS) | Left sidebar (`AppSidebar`) with labels; screen content capped at a readable width (`AppSpacing.maxContentWidth`, 760) |

Five tabs, in this order: **Download**, **Library**, **Tools**, **System**, **Settings**. An engine update puts a badge dot on the Settings tab. Full-screen pages above the tabs: the Library media viewer and post page, Convert & Compress, each tool's screen, Settings → Cookies and Settings → About (and the debug-only design gallery).

The macOS window has a minimum size of 600 × 600 points, matching the narrowest supported layout. Drag and drop of links/files onto the Download and Convert screens and two-pane layouts are not built yet.

The screen-size breakpoint is tracked by a `ScreenTypeNotifier`, so only widgets that care rebuild when the window resizes.

## Components

All under `lib/ui/core/ui/base/<category>/`, plain props only (no providers), one widget per file.

| Category | Widgets |
| --- | --- |
| `buttons/` | `GradientButton` (primary), `TonalButton` (secondary), `GhostButton` (tertiary), `AppIconButton` (circle, 40px; the whole 48px box around it is tappable) |
| `cards/` | `AppCard`, `SourceTile` (icon tile + title + subtitle, a big tappable row: pick sources, the Tools hub's Convert card), `MediaCard` (thumbnail + title + metadata + badge; long-press / right-click for actions), `JobCard` (thumbnail + stage + progress + actions; pulses with a light haptic when done) |
| `media/` | `MediaThumbnail` (local or remote, rounded, duration pill, saved check, kind icon fallback incl. a PDF icon, optional Hero tag), `SiteBadge`, `PhotoGrid` (selectable, numbered checks) |
| `progress/` | `GradientProgressBar`, `StageLabel` (Queued / Downloading / Processing / Saving / Done / Failed) |
| `chips/` | `SelectChip` (quality, format, filter), `ChipRow` (horizontal scroll) |
| `form/` | `AppTextField` (plain labelled field: Unlock PDF's password, Split's ranges), `LinkField` (big rounded field with Paste button and site icon that appears when the URL is recognised), `AppSlider`, `AppSwitchTile`, `SegmentedPicker` (Video / Audio / Photos; labels fill the track and centre against the sliding pill, and the whole segment is tappable) |
| `sheets/` | `AppBottomSheet` (drag handle, `xl` radius, scrim, keyboard-aware; optional `bottomAction` pinned under the scrolling body), `ActionSheet` (list of icon + label actions) |
| `dialog/` | `ConfirmDialog` (title, body, destructive variant), `SavedRemovePrompt` (the "Saved. Remove from app?" dialog with "Don't ask again") |
| `states/` | `EmptyState` (icon + title + body + action), `ErrorState` (message + Retry), `ShimmerBox` (loading placeholder matching the final layout) |
| `layout/` | `ScreenScrollView` (safe area, side padding by breakpoint, max content width, room for the floating nav; optional `bottomAction`), `PinnedActionBar` (holds the primary action at the bottom under the scrolling content, with a short fade above it), `ScreenHeader` (large title + subtitle), `ScreenBackButton` (pushed screens), `AuroraGlow` (header glow) |
| `icons/` | `GradientIconTile` (Aurora-painted icon on a tinted square) |
| `text/` | `SectionHeader` (section title + optional trailing widget) |

**Pinned primary actions.** A screen's or sheet's main button (Download in the preview sheet, Convert, the media viewer's actions) never scrolls away: pass it as `bottomAction` to `ScreenScrollView` / `AppBottomSheet`, which wrap it in a `PinnedActionBar` above the nav bar or home indicator.

Messages use `ToastUtil` on top of `flutter_sliding_toast`, never a raw `SnackBar`. Toasts slide in at the top, stack like notifications, are coloured by kind (info `primary`, `success`, `warning`, `error`), show text capped at **4 lines** (ellipsis), stay 2.5 s, and an identical toast isn't repeated while it's still showing.

**Design gallery** (Settings, debug builds only): every base widget in its states — controls, jobs, library cards, overlays, empty/error/loading states, and a **Toasts** section that fires each toast kind through `ToastUtil.showStateMessage`.

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
│  ⬇   ▦   ⇄   ◔   ⚙               │  blurred nav (5 tabs)
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
│ [      ⬇  Download 310 MB     ]  │  GradientButton, pinned
└──────────────────────────────────┘
```

Photo posts show a `PhotoGrid` instead of the player, all images pre-selected, with "Select all / none" and a count on the button ("Download 6 photos").

### Library

Grid of `MediaCard`s (2 columns on phones, adaptive on wider screens), filter chips on top (All · Videos · Audio · Photos · PDFs, then site chips), search in the app bar, sort menu (Newest, Oldest, Largest). Long-press (or right-click on macOS) opens an `ActionSheet`: Save to Photos, Save to Files, Share, Convert, Delete. Items already saved show a small ✓ on the thumbnail. Tapping an item opens the full-screen media viewer; tapping a grouped post opens its post page (header, Save all / Share all / Delete all, grid of items). See [Library](../features/library.md).

### Tools

A hub: the **Convert & compress** card on top, then sections **PDF**, **GIF & video** and **Image**, each a list of tool cards. A tool's screen follows one pattern: **1. Pick** (From Library · From Photos · From Files tiles; a reorderable list once picked) → **2. Options** (`ChoiceSection` chip rows, sliders, switches; a note when something needs fixing; the start button pinned at the bottom) → **3. Run** (`JobCard`) → **4. Result** inline (thumbnails, size before → after, Open / Share / Done). See [Tools](../features/tools.md).

### Convert

Pushed from the Tools hub. A three-step flow in one screen: **1. Pick** (three big tiles: From Library · From Photos · From Files) → **2. Choose** (`SegmentedPicker`: Convert / Compress, then format chips or preset chips + slider; **Convert** pinned at the bottom) → **3. Result** shown inline (before → after size with the change in percent, Save to Photos / Save to Files / Share / Done). See [Convert](../features/convert.md).

### System

Cards for the metrics this device can report, in this order: network, battery, RAM, CPU, GPU, storage. Network, RAM, CPU and GPU show their current value and a 60-second sparkline; battery and storage show a bar with detail rows. See [System](../features/system.md).

## Accessibility

- Touch targets at least 48×48.
- Text scales to 200% without clipping; cards grow taller, chips wrap.
- Every icon-only button has a semantic label from the message catalog.
- Colour is never the only signal: stages have text labels, saved items have an icon.
- Focus rings on macOS. Keyboard shortcuts (⌘V to paste a link anywhere, ⌘⌫ to delete, Space to play/pause) are not built yet.

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
