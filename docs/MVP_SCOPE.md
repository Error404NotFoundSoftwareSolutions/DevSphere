# MVP scope

The MVP is one vertical slice, piloted with 10 to 20 students: sign in, pick a Python lab, check and prepare the environment, follow guided steps, write code, run practice checks, ask the tutor, submit for verified grading, keep progress.

## In

| Area | What |
|---|---|
| Accounts | Google sign-in, minimal private profile, consent and age check |
| Catalogue | 3 to 5 Python labs as immutable, versioned bundles |
| Environment | Detect OS, Python, uv, Git; consented setup; isolated project environment |
| Workspace | Native Dart code editor (`re_editor`), terminal, task runner |
| Guide | Ordered steps, copyable snippets, practice and understanding checks |
| Tutor | Text tutor through the backend proxy, progressive hints, context controls, redaction |
| Grading | Practice results (local) and Verified results (server sandbox) |
| Progress | Saved locally, synced at-least-once, works offline on cached labs |
| Content | Labs as files, validated and published by CI |
| Platforms | Windows, Linux (Ubuntu LTS), and macOS |

## Out (see SRS section 5.14)

Admin web portal, local LLM and hardware profiling, leaderboards and achievements, voice, Jupyter and SQL workspaces, a developer-services module (these are ordinary labs later), database-server installation, instructor features, arbitrary public repositories, automatic account creation.

## Never

Replacing general-purpose IDEs, running student code with unrestricted privilege, auto-merging pull requests, promising that a third-party service is free, promising AI correctness.

## Release gate

All MVP requirements verified or formally excepted, plus the nine items of SRS section 10.1. The backlog assigns every MVP requirement to a story and sprint.
