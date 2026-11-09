# DevPilot design system ("Quiet Engineering")

Status: Accepted 2026-11-04 (supplied by the owner). Code: `packages/ui/lib/src/tokens.dart` and `dev_pilot_theme.dart`. Product name: **DevPilot**. Tagline: **Learn by building. Grow by contributing.**

Direction: simplicity of Google Skills, usability of a professional developer tool, structure of a technical learning platform. Trustworthy, focused, mature. Not gamified, not a generic SaaS dashboard. Content over decoration; practical work over gamification; consistency over novelty.

## Colour (light first; blue is the interaction colour, not decoration)
| Token | Value | Use |
|---|---|---|
| background / canvas | #F4F6FA | App background |
| surface | #FFFFFF | Cards, sidebar, topbar |
| surface-muted | #F1F4F8 | Search field, table headers |
| surface-selected / primary-soft | #EAF1FF | Selected nav item |
| primary | #2457C5 (hover #1D49A5) | Buttons, links, progress |
| navy | #183153 | Tooltips, wordmark |
| text-primary | #17243B | Text |
| text-secondary | #64748B | Secondary text |
| text-disabled | #94A3B8 | Disabled |
| border | #E2E8F0 | 1px borders |
| success / warning / danger / info | #16845B / #B7791F / #C24141 / #2457C5 | Semantic only |

Rule: Build, Debug and Contribute share the same blue. Differentiate by icon and content.

## Typography
Inter for UI, JetBrains Mono for code, commands, terminal, file names. Page heading 26-30 / 650, section 19-22 / 600, card heading 16-18 / 600, body 14 / 400, secondary 13, labels 12 / 500, code 13. (Flutter has no 650 weight without a variable font; 600 is used.) Fonts must be bundled with the app (no runtime download, SEC-20); until added, a system sans-serif fallback is used.

## Layout pattern: Google Skills style (owner screenshots, 2026-11-04) - SUPERSEDES the layout section below
The owner's reference is the structure of Google Skills. We copy the **structure and interaction pattern only**, never Google's logo, wording, illustrations or badges. Colours, type and name stay DevPilot.
- **Header (64px, white):** hamburger, DevPilot wordmark, wide pill search ("What do you want to learn today?"), streak chip, help, language, avatar. No points.
- **Left icon rail (104px, white):** icon above a small label; selected item has a pale-blue pill behind the icon. Items: Dashboard, Catalog, Paths, Credentials, Workspaces. Build / Debug / Contribute become filters in Catalog.
- **Dashboard:** a hero card (illustration left, breadcrumb links, unit title, primary Start/Resume); tabs **Activities | Paths** with text and blue underline; a 3-column grid of activity cards (chips Featured / Path / Course / Lab, 20px title, 3-line description, duration with clock, round arrow button). Right column: Badges and Skills summary cards, weekly goal card with seven day circles, Achievements with progress bars.
- **Course page:** dark navy header band with title, chips (credits-free: level, duration, type), Start button and progress bar; a dropdown for the version; a dismissible info banner; content below.
- **Lab page (guided run):** breadcrumb bar; toolbar with a step dropdown pill, a **Practice score** pill (green tint), and Check my work; instructions in the centre; right panel "Lab setup and access" with copyable values; a notice that only Verified results earn badges.
- Radius: cards 24px, pills fully rounded, buttons 9px kept for dialogs. Page background stays pale (#F4F6FA).

## Layout (older, 1440 x 900 reference) - superseded where it conflicts with the pattern above
Topbar 64px (white, fixed): wordmark, search, environment status, notifications, profile. Sidebar 220px white with pale-blue selected state, no dark sidebar: Overview, Explore, My Learning, Build, Debug, Contribute, Workspaces, Progress. Content flexible. Insights panel 290-310px on the right (hidden on narrow windows).

## Components
Cards: white, 16px radius, 1px border, for independent activities only. Primary button blue, 9px radius, 40px high. Secondary: white with neutral border. Search: pale gray-blue. Progress: blue on light gray. Tabs: text with blue underline. Dialogs: white, subtle shadow. Tooltips: navy. Code workspace: dedicated dark editor theme with its own preference.
Don't make every feature a card: cards for independent activities, tables for structured information, timelines for workflows, panels for persistent tools.

## Motion
Functional only: hover tint, 150ms colour transitions, subtle border change on cards, skeleton loaders matching content size, no animation while typing or running code.

## Geometry
Radius 6 / 10 / 16. Spacing 4, 8, 12, 16, 24, 32.

## Theme strategy
Dashboard and catalogue default light. Code editor defaults dark, independent preference.
