---
title: "Watching videos"
description: "How videos play inside DevPilot, how the 80 percent rule is measured, and what happens when a video cannot play in the app."
section: Using DevPilot
order: 2
---

Every step of a learning path has a **Watch** tab. Videos play inside the app, so you do not have to leave it, and DevPilot can measure how much you really watched.

## The 80 percent rule

To finish the video checkpoint of a step you need to watch **80 percent** of the video. The tab shows your progress as *Watched 45% of 80% needed*.

## How it is measured

The player counts only seconds that were **actually played, in order**. This means:

- Skipping ahead does **not** count. Dragging the bar to the end gives you nothing.
- Pausing or leaving the video running with no one watching is not something DevPilot can detect. It measures play time, not attention.

While you watch, the player reports its progress to the DevPilot service every 4 seconds, under a random session number. The Watch tab reads it back every 3 seconds. The session number does not identify you.

## If the video cannot play inside the app

Videos play in an embedded Chromium browser. Two things can stop that:

- **The embedded browser did not start** within 20 seconds, or the service was unreachable.
- **A video uses a format the embedded browser cannot play.** The Chromium that comes with the app does not include the H.264 codec, so a few videos (or ads) fail.

In both cases DevPilot switches that video to the **DevPilot player window**, a small app-style window in your normal browser (Chrome or Edge), which plays every format. The tab tells you it did. The same fallback applies when a video has not started 30 seconds after loading.

The measuring works the same in the player window.

## Tips

- Use the **Watch** tab, not the YouTube website: only the app's player is measured.
- If a video is slow to start, wait for the fallback instead of reloading repeatedly.
- On Linux the embedded player uses more CPU than on Windows, because frames are copied in software.
