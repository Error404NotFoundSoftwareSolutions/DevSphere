# Capability: Learning paths (docs/FEATURE_ROADMAP.md F-B11). Rules: AIR-01, AIR-08, SEC-10. Tests: TC-PATH-20..
# Implemented here: finds real YouTube videos for a step through the official YouTube Data API v3, so the model can
# only CHOOSE from videos that exist and may be embedded; it can never invent one. Results are filtered (embeddable,
# public, not live, 3 to 40 minutes) and cached for a week to stay inside the daily quota. The API key is read from
# Secret Manager (or the environment in development) and never leaves the server.

import json
import re
import time
import urllib.parse
import urllib.request
from typing import Protocol

from pydantic import BaseModel

from app.core.settings import settings
from app.db import memory

VIDEO_ID = re.compile(r"^[A-Za-z0-9_-]{11}$")
_DURATION = re.compile(r"^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$")
MIN_SECONDS, MAX_SECONDS = 180, 2400
CACHE_SECONDS = 7 * 24 * 3600


class VideoCandidate(BaseModel):
    video_id: str
    title: str
    channel: str
    duration_s: int
    published: str = ""
    description: str = ""


class VideoSearch(Protocol):
    def search(self, query: str, language: str = "en") -> list[VideoCandidate]: ...


class NoVideoSearch:
    """Used when no YouTube key is configured: steps are built without videos and say so."""

    def search(self, query: str, language: str = "en") -> list[VideoCandidate]:
        return []


def parse_duration(iso: str) -> int:
    m = _DURATION.match(iso or "")
    if not m:
        return 0
    h, mi, s = (int(x or 0) for x in m.groups())
    return h * 3600 + mi * 60 + s


class YouTubeDataApi:
    BASE = "https://www.googleapis.com/youtube/v3"

    def __init__(self, key: str, timeout_s: float = 8.0) -> None:
        self._key = key
        self._timeout = timeout_s

    def _get(self, path: str, params: dict) -> dict:
        url = f"{self.BASE}/{path}?" + urllib.parse.urlencode({**params, "key": self._key})
        with urllib.request.urlopen(url, timeout=self._timeout) as r:  # noqa: S310 (fixed https host)
            return json.loads(r.read().decode("utf-8"))

    def search(self, query: str, language: str = "en") -> list[VideoCandidate]:
        found = self._get(
            "search",
            {
                "part": "snippet",
                "type": "video",
                "q": query[:200],
                "maxResults": 12,
                "safeSearch": "strict",
                "videoEmbeddable": "true",
                "videoSyndicated": "true",
                "relevanceLanguage": language,
            },
        )
        ids = [
            i["id"]["videoId"]
            for i in found.get("items", [])
            if VIDEO_ID.match(i.get("id", {}).get("videoId", ""))
        ]
        if not ids:
            return []
        details = self._get(
            "videos", {"part": "snippet,contentDetails,status", "id": ",".join(ids)}
        )
        out: list[VideoCandidate] = []
        for v in details.get("items", []):
            sn, st, cd = v.get("snippet", {}), v.get("status", {}), v.get("contentDetails", {})
            seconds = parse_duration(cd.get("duration", ""))
            if (
                not st.get("embeddable")
                or st.get("privacyStatus") != "public"
                or sn.get("liveBroadcastContent", "none") != "none"
                or not MIN_SECONDS <= seconds <= MAX_SECONDS
            ):
                continue
            out.append(
                VideoCandidate(
                    video_id=v["id"],
                    title=str(sn.get("title", ""))[:150],
                    channel=str(sn.get("channelTitle", ""))[:80],
                    duration_s=seconds,
                    published=str(sn.get("publishedAt", ""))[:10],
                    description=str(sn.get("description", ""))[:300],
                )
            )
        return out


class CachedVideoSearch:
    """Keeps search results for a week (shared by everyone), so popular steps cost no quota."""

    def __init__(self, inner: VideoSearch) -> None:
        self._inner = inner

    def search(self, query: str, language: str = "en") -> list[VideoCandidate]:
        key = (query.strip().lower()[:200], language)
        hit = memory.VIDEO_CACHE.get(key)
        if hit and time.time() - hit.get("at", 0) < CACHE_SECONDS:
            return [VideoCandidate(**c) for c in hit.get("results", [])]
        results = self._inner.search(query, language)
        memory.VIDEO_CACHE[key] = {"at": time.time(), "results": [c.model_dump() for c in results]}
        return results


_override: VideoSearch | None = None
_key_cache: str | None = None


def set_video_search(search: VideoSearch | None) -> None:
    """Tests use this to plug in a stand-in."""
    global _override
    _override = search


def _api_key() -> str:
    global _key_cache
    if _key_cache is not None:
        return _key_cache
    key = settings.youtube_api_key.get_secret_value()
    if not key and settings.youtube_api_key_secret:
        try:
            from google.cloud import secretmanager

            client = secretmanager.SecretManagerServiceClient()
            key = client.access_secret_version(
                name=settings.youtube_api_key_secret
            ).payload.data.decode()
        except Exception:  # noqa: BLE001 - no key means no videos, never a crash
            key = ""
    _key_cache = key.strip()
    return _key_cache


def get_video_search() -> VideoSearch:
    if _override is not None:
        return _override
    key = _api_key()
    return CachedVideoSearch(YouTubeDataApi(key)) if key else NoVideoSearch()
