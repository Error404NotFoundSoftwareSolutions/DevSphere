# DevPilot design system

Status: Accepted 2026-11-11. The owner rejected three earlier directions (a Google-Skills-like layout, a dark-navy-and-cards template, a terminal style) and then chose: **keep the familiar layout, make it polished and original, light by default with a dark theme and a switch, and a professional, trustworthy feel** (friendly, clean, premium and bold at once). Code: `packages/ui/lib/src/tokens.dart` and `dev_pilot_theme.dart`, `apps/desktop/lib/ui/kit.dart`, `app_shell.dart`, `motion.dart`. Product name: **DevPilot**.

## What it is
A calm, modern product interface in a trustworthy blue. Structure is familiar so people know where things are; the character comes from craft: a deep-blue "continue" card with a progress ring, cards with tinted icons and soft shadows, a week chart, a timeline for roadmaps, soft status chips, generous spacing. Nothing is copied from another product: the layout pattern is generic, and the colours, icons, wording and wordmark are DevPilot's own.

## Rules
1. **One brand colour.** Blue leads. Violet, teal and amber appear only as small tints behind icons and on the odd chip. Never as page colours.
2. **Depth from soft shadows in light, hairlines in dark.** One deep-blue gradient (the continue card and course banner) is the only gradient.
3. **Status is a soft chip** (tinted background, text of the same hue). Progress is a rounded bar or a ring, never a table of numbers.
4. **Honest labels.** Practice results are called practice. Nothing implies a badge without a Verified result.
5. **Readable first.** Text colours meet WCAG AA contrast (4.5:1) on their surfaces in both themes, and a test enforces it.
6. **Motion is one-shot and short**, and turns off when the system asks for reduced motion.

## Light and dark
`BL.dark` selects the palette. The colour tokens are getters, so every screen follows the switch. The moon or sun button in the header flips it, the app rebuilds, and the choice is saved in `~/.devpilot/prefs.json` (this computer, not per person). A missing or damaged file means light. The landing and sign-in screens follow the theme too; their blue promo card stays deep blue in both.

| Token | Light | Dark |
|---|---|---|
| background | #F5F7FB | #0A0F1C |
| surface | #FFFFFF | #111A2E |
| surface-muted | #EEF2F8 | #17213A |
| primary | #2459E6 (hover #1B47C2) | #6B93FF (hover #8AABFF) |
| navy / hero start | #0E2148 | #14264F |
| text primary / secondary | #0F1B33 / #5A6882 | #E8EEFB / #9AA8C6 |
| border / strong | #E3E8F1 / #CFD7E5 | #1F2C48 / #2B3B5E |
| success / warning / danger | #0A7D56 / #9A5B00 / #C02F2F | #34D399 / #F2B84B / #FF7A7A |

Category tints for icon tiles: blue, violet (#7C5CFC), teal (#12B5A6), amber (#E59A0E), rose (#E5486E).

## Layout
- **Header** (64px): back, the wordmark with its mark, a wide search pill that opens the command palette (`Ctrl K`), the streak chip, the theme switch, the avatar menu.
- **Rail** (104px): five items with the icon above a small label; the selected one has a pale-blue pill. `Ctrl 1` to `Ctrl 5` jump between pages.
- **Status bar** (28px): service online or offline, VS Code found or not, this week's checks. Real values only.
- **Content**: max width 1200, 32px side padding, 48px between sections.
- **Dashboard**: a greeting, the continue card, the Activities and Paths tabs over a card grid, and a side column with badges, skills, the week at a glance and the path as a timeline. Under 1040px the side column moves below.
- **Lab cards** (`activity_table.dart`) are used everywhere labs are listed: tinted kind icon, status chip, title, two lines of description, time and level, an arrow.
- **Course page**: a deep-blue banner with the facts, progress and Start or Resume, then what the lab is about, what you will do, the skills.
- **Credentials**: four stat cards, a plain note about verification, completed labs, in progress, skills.
- **Tutor**: chat bubbles. **Roadmaps** and the person's path: a timeline.

## Typography
Inter for everything, with tabular figures for numbers. JetBrains Mono (bundled, subset) only for real code and folder paths. Page title 28 / 600 with tight tracking, section 18, card title 15, body 14, secondary 13, small labels 11.5 to 12.5. Fonts are bundled (SEC-20).

## Geometry, spacing, motion
Radius 6 / 10 / 14 / 20, cards 16, buttons 10 (never pills). Spacing on an 8-point grid: 4, 8, 12, 16, 24, 32, 48. Motion (`motion.dart`): staggered fade-and-rise on first appearance, count-up numbers, bars and rings that fill once, a lift on card hover. Nothing loops.

## Reviewing the design
`apps/desktop/test/shots/shots_test.dart` renders the main screens to PNG files with the real fonts and seeded data:
```
SHOTS_DIR=/tmp/shots SHOTS_SIZE=1440x900 flutter test test/shots/shots_test.dart
SHOTS_DARK=1 SHOTS_DIR=/tmp/shots-dark flutter test test/shots/shots_test.dart
```
Without `SHOTS_DIR` it does nothing. `SHOTS_ONLY=dashboard,catalog` limits the pages.

## Depth and motion (effects kit, `lib/ui/fx.dart`)
Drawn in code, no downloaded art. Each effect uses one controller and one painter, runs only in the real app, and stops in tests and with reduced motion (`fxOn`).
- **AuroraBackdrop**: a slow moving mesh of coloured light behind hero areas (dashboard hero, the prompt card banner).
- **IsoStack**: a floating isometric stack of glass layers, the hero illustration; the progress ring floats above it.
- **TiltCard** (every `Panel(lift: true)`, for example lab cards): tilts in 3D towards the pointer with a moving glare and a deeper shadow.
- **GlowFrame**: a light that travels around the prompt card's border.
- **Journey map** (learning path): the steps as a winding road; finished stretches are green, the current step pulses (`PulseRing`), locked steps are greyed.
- **Confetti** when a step is finished; **ShimmerBox** placeholders while a step is being prepared.
Rules: effects decorate, they never carry meaning (every state also has text or an icon); keep them subtle in dark mode; never run them in a list of many items.

## Sign-in screen
Split layout from 900 px wide: a deep-blue brand panel (slides, each with a small product preview) and the form. Below 900 px only the form with a small brand header. Fields use a floating label, a leading icon and a focus ring; errors are an animated banner; dialogs for terms and password reset. Everything uses the tokens, so it works in light and dark. Keys the tests use start with `auth_`.

## Known gaps
- The logo (`assets/images/logo.png`, a transparent 512 px DP mark) is used through `BrandMark`; the app window and installer icons still need it.
- The consent and profile screens (built by a teammate) use the theme but have not been designed individually.
- Windows and macOS text rendering has not been reviewed.
