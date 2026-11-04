# Code style rules (STY)

Tools decide formatting; humans decide design. If a formatter or linter disagrees with this file, the tool wins and this file gets fixed.

## All languages
- STY-01 MUST: Comments explain *why*, not *what*. Every source file keeps its header naming the user story and requirement IDs (Track A) or capability ID (Tracks B-D).
- STY-02 MUST: Functions do one thing; prefer under ~40 lines; no boolean flag parameters that switch behaviour (make two functions).
- STY-03 MUST: Errors are values or typed exceptions with a user-safe message and a developer detail. Never swallow an error silently.
- STY-04 MUST: User-facing text says what happened and what to do next, in plain language (no stack traces, no jargon).
- STY-05 SHOULD: Names are full words. No abbreviations except the glossary (`docs/GLOSSARY.md`).
- STY-06 MUST: No dead code, no commented-out code, no TODO without a story ID.

## Dart / Flutter
- Strict analysis (`strict-casts`, `strict-inference`, `strict-raw-types`). `dart analyze` clean.
- UI layer: no `dart:io`. State via Riverpod; navigation via go_router; widgets small and `const` where possible.
- Public APIs of packages exported only from `lib/<package>.dart`; implementation in `lib/src/`.

## Python 3.12
- Ruff (lint + format) and mypy strict on `services/*`. Pydantic v2 models at every boundary. No bare `except`.
- No import-time side effects. Async only where I/O is involved.

## TypeScript (Track B/C, Code-OSS side)
- Follow the upstream VS Code conventions in files we patch (tabs, their layering rules, `vs/` import restrictions) so patches stay small and mergeable.
- Our own additive code: strict TS, `readonly` by default, no `any`, disposables registered and disposed (`DisposableStore`), no global state.
- Use upstream services via dependency injection; never reach into private internals of core files.

## Commit-level hygiene
- Formatter-only changes go in their own commit (or not at all in patched upstream files; they destroy rebases).
