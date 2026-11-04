# Session 2026-11-04: BuildLoop Flutter shell

Owner decision (ADR-018): Flutter app is the shell; name BuildLoop; design system supplied by owner (`docs/DESIGN_SYSTEM.md`).

## Done
- Tokens + light theme in `packages/ui` (5 tests), app shell (topbar 64, sidebar 220), Overview screen with continue card, three paths, roadmap timeline, insights panel (10 desktop tests incl. layout sizes and no overflow).
- Sign-in screen restyled; app renamed BuildLoop (window title, binary `buildloop`, app id `com.buildloop.app`).
- Inter bundled from the local `fonts-inter` package (OFL, licence file included). JetBrains Mono not bundled.
- Linux release build works (41 MB bundle, 16 MB tarball in `release/`, git-ignored). Needed a clang flag workaround (see LEARNINGS).
- Rendered the screen to PNG and reviewed it; fixed insights panel height, topbar spacing and card width.

## Not done / limits
- All data on Overview is SAMPLE and says so. No real sign-in, catalogue, progress, badges.
- Other sidebar sections are honest placeholders.
- Windows/macOS builds and installers need those OSes (CI). No signing, no auto-update.
- The in-app workspace (editor, terminal) is the old stub; editor choice for Flutter is an open risk (ADR-018).
- Not committed.

## Update: redesign to the Google-Skills pattern (owner screenshots)
Owner said the first layout was not what they meant. Rebuilt: 64px header with pill search and streak, 104px icon rail (Dashboard, Catalog, Paths, Credentials, Workspaces) with pale-blue pill, dashboard (hero, Activities/Paths tabs, 24px cards, right column), course page (navy header, chips, Start, progress, info banner) and lab page (breadcrumb, step dropdown, Practice score pill, setup panel). Layout pattern only; no Google assets or wording. 13 new layout tests, all pass; screenshots reviewed. Still sample data, no backend.
