# Goal

Build **DevSphere**: a desktop learning platform where a beginner builds a real Python project on their own computer, guided step by step, helped by an AI tutor that explains but does not judge, and checked by automated tests.

## The first milestone (MVP slice)

A student can: install the app and sign in, pick a Python lab, have their environment checked and prepared with consent, follow guided steps, write code and run local practice checks, ask the tutor for hints with visible context controls, submit for **verified** grading and see the result, and close and reopen the app without losing progress.

## Releases

1. **MVP**: Mode 1 (Build, Python), Windows and Ubuntu.
2. **R2**: Mode 2 (Debug): fix a bug in a curated codebase.
3. **R3**: Mode 3 (Contribute): Git and pull-request practice in per-student template repositories; macOS.

Do not build LATER items (admin portal, local LLM, voice, leaderboards, Jupyter/SQL) unless a change request promotes them.

## Non-negotiables

1. Only the server-side Grader produces official scores. Results computed on the student's machine are *Practice* and are always labelled so.
2. Protected tests and reference solutions never reach the app, the bundle, a log or an AI prompt.
3. No secrets in the app package, logs, telemetry or AI requests.
4. The tutor is advisory. It never runs commands or edits files without explicit approval, and it never decides pass or fail.
5. System changes on a student's machine need a visible plan and explicit consent.
