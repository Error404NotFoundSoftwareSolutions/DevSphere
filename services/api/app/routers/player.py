# Capability: Learning paths (docs/FEATURE_ROADMAP.md F-B11). Rules: SEC-05, PRIV-01. Tests: TC-PATH-30..
# Implemented here: the DevPilot player. The app opens this page in its own small window (a browser in app mode) to
# play one YouTube video through the privacy-enhanced youtube-nocookie.com player. The page measures how much was
# really watched (only seconds played in order count, so skipping ahead does not) and sends it here every few
# seconds under a random session id; the app reads it back. Serving the page from the API gives YouTube a proper
# web origin, which embedded players need.

import re
import secrets
import time

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, ConfigDict, Field

from app.ai.youtube import VIDEO_ID
from app.core.auth import User, current_user
from app.db import memory

SESSION = re.compile(r"^[0-9a-f]{32}$")
SESSION_SECONDS = 6 * 3600

router = APIRouter()

_PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin"><title></title>
<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}#p{position:fixed;inset:0;width:100%;height:100%;border:0}</style>
</head><body><div id="p"></div>
<script>
var VID = "__VID__", SID = "__SID__", watched = {}, last = null, player = null, timer = null, sent = 0;
function send(o) {
  try { if (window.DevPilot && DevPilot.postMessage) DevPilot.postMessage(JSON.stringify(o)); } catch (e) {}
  if (!SID || o.type !== "progress") return;
  var now = Date.now();
  if (!o.ended && now - sent < 4000) return;  // at most every 4 seconds, and always at the end
  sent = now;
  try {
    fetch("/player/progress", {method: "POST", headers: {"Content-Type": "application/json"}, keepalive: true,
      body: JSON.stringify({s: SID, v: VID, watched: o.watched, duration: o.duration, ended: o.ended})});
  } catch (e) {}
}
function report(ended) {
  if (!player || !player.getDuration) return;
  send({type: "progress", watched: Object.keys(watched).length, duration: player.getDuration() || 0, ended: !!ended});
}
function tick() {
  if (!player || !player.getPlayerState) return;
  var st = player.getPlayerState(), t = player.getCurrentTime() || 0;
  if (st === 1) {
    if (last !== null && t > last && t - last <= 2.5) { for (var s = Math.floor(last); s < Math.floor(t); s++) watched[s] = 1; }
    last = t;
  } else { last = (st === 2) ? t : null; }
  report(false);
}
function onYouTubeIframeAPIReady() {
  player = new YT.Player("p", {
    host: "https://www.youtube-nocookie.com", videoId: VID,
    playerVars: {rel: 0, playsinline: 1, autoplay: 1, origin: location.origin},
    events: {
      onReady: function () {
        // No hover hint over the video: the embedded browser would show the frame's title as a tooltip.
        try { var f = player.getIframe(); f.removeAttribute("title"); f.setAttribute("aria-label", "Video player"); } catch (e) {}
        send({type: "ready", duration: player.getDuration() || 0});
      },
      onStateChange: function (e) { if (e.data === 0) report(true); },
      onError: function (e) {
        send({type: "error", code: e.data});
        // Tell the app too, so it can switch this video to the player window (some formats cannot play here).
        if (SID) { try { fetch("/player/progress", {method: "POST", headers: {"Content-Type": "application/json"}, keepalive: true,
          body: JSON.stringify({s: SID, v: VID, watched: 0, duration: 0, ended: false, error: Number(e.data) || 1})}); } catch (x) {} }
      }
    }
  });
  timer = setInterval(tick, 1000);
}
</script>
<script src="https://www.youtube.com/iframe_api"></script>
</body></html>"""


def _not_found() -> HTTPException:
    return HTTPException(
        404, detail={"code": "not_found", "message": "Unknown video.", "recovery": ""}
    )


@router.get("/player", response_class=HTMLResponse)
def player(v: str = "", s: str = "") -> HTMLResponse:
    if not VIDEO_ID.match(v) or (s and not SESSION.match(s)):
        raise _not_found()
    return HTMLResponse(
        _PAGE.replace("__VID__", v).replace("__SID__", s),
        headers={
            "Content-Security-Policy": (
                "default-src 'none'; script-src 'unsafe-inline' https://www.youtube.com https://s.ytimg.com; "
                "connect-src 'self'; "
                "frame-src https://www.youtube-nocookie.com https://www.youtube.com; img-src https://i.ytimg.com; "
                "style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"
            ),
            "X-Content-Type-Options": "nosniff",
            "Cache-Control": "no-store",
        },
    )


class NewSession(BaseModel):
    model_config = ConfigDict(extra="forbid")
    video_id: str = Field(pattern=r"^[A-Za-z0-9_-]{11}$")


class Progress(BaseModel):
    model_config = ConfigDict(extra="forbid")
    s: str = Field(pattern=r"^[0-9a-f]{32}$")
    v: str = Field(pattern=r"^[A-Za-z0-9_-]{11}$")
    watched: float = Field(ge=0, le=36000)
    duration: float = Field(ge=0, le=36000)
    ended: bool = False
    error: int | None = Field(default=None, ge=0, le=9999)  # a YouTube player error code


@router.post("/v1/player/sessions", status_code=201)
def new_session(body: NewSession, user: User = Depends(current_user)) -> dict:
    """The app asks for a session before it opens the player window; the window reports under this id."""
    sid = secrets.token_hex(16)
    memory.PLAYER_SESSIONS[sid] = {
        "user_id": user.user_id,
        "video_id": body.video_id,
        "watched": 0.0,
        "duration": 0.0,
        "ended": False,
        "error": None,
        "at": time.time(),
    }
    return {"session": sid}


@router.post("/player/progress", status_code=204)
def report_progress(body: Progress) -> None:
    """Called by the player page (no sign-in in that window; the random session id is the key)."""
    sess = memory.PLAYER_SESSIONS.get(body.s)
    if not sess or sess["video_id"] != body.v or time.time() - sess["at"] > SESSION_SECONDS:
        raise _not_found()
    if body.duration > 0:
        sess["duration"] = body.duration
    # Watched time only grows and can never be more than the video is long.
    limit = sess["duration"] or body.watched
    sess["watched"] = max(sess["watched"], min(body.watched, limit))
    sess["ended"] = sess["ended"] or body.ended
    if body.error is not None:
        sess["error"] = body.error


@router.get("/v1/player/sessions/{sid}")
def read_progress(sid: str, user: User = Depends(current_user)) -> dict:
    sess = memory.PLAYER_SESSIONS.get(sid) if SESSION.match(sid) else None
    if not sess or sess["user_id"] != user.user_id:
        raise _not_found()
    return {k: sess.get(k) for k in ("video_id", "watched", "duration", "ended", "error")}
