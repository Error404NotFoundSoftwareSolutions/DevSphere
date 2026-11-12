# Capability: CAP-API-STORAGE. Tests: TC-STORE-01..
# Implemented here: the storage behind app/db/memory.py. By default the collections are plain in-process dicts (dev and
# tests). With DEVSPHERE_DATABASE=firestore the same objects keep their data in Cloud Firestore instead, so it survives
# restarts and is shared by every instance. The routers are unchanged: each request works on its own copy of the
# documents it touches (a "unit of work"), and the changes are written back when the request ends successfully.

import json
import urllib.parse
from collections.abc import Iterator, MutableMapping
from contextvars import ContextVar, Token
from typing import Any, Protocol

_DELETED = object()
_session: ContextVar[dict | None] = ContextVar("db_session", default=None)


class Backend(Protocol):
    def get(self, collection: str, doc_id: str) -> dict | None: ...
    def list_ids(self, collection: str) -> list[str]: ...
    def query(self, collection: str, field: str, value: Any) -> list[tuple[str, dict]]: ...
    def set_many(self, collection: str, docs: dict[str, dict]) -> None: ...
    def delete_many(self, collection: str, doc_ids: list[str]) -> None: ...
    def clear(self, collection: str) -> None: ...


class MemoryBackend:
    """A backend that keeps documents in a dict. Used by tests to check the unit-of-work behaviour without Google."""

    def __init__(self) -> None:
        self.data: dict[str, dict[str, str]] = {}
        self.writes = 0

    def get(self, collection: str, doc_id: str) -> dict | None:
        raw = self.data.get(collection, {}).get(doc_id)
        return None if raw is None else json.loads(raw)

    def list_ids(self, collection: str) -> list[str]:
        return list(self.data.get(collection, {}))

    def query(self, collection: str, field: str, value: Any) -> list[tuple[str, dict]]:
        found = []
        for doc_id, raw in self.data.get(collection, {}).items():
            doc = json.loads(raw)
            if doc.get(field) == value:
                found.append((doc_id, doc))
        return found

    def set_many(self, collection: str, docs: dict[str, dict]) -> None:
        for doc_id, doc in docs.items():
            self.data.setdefault(collection, {})[doc_id] = json.dumps(doc)
            self.writes += 1

    def delete_many(self, collection: str, doc_ids: list[str]) -> None:
        for doc_id in doc_ids:
            self.data.get(collection, {}).pop(doc_id, None)

    def clear(self, collection: str) -> None:
        self.data.pop(collection, None)


class FirestoreBackend:
    """Cloud Firestore. Uses the service identity on Google Cloud, or the developer's login locally."""

    def __init__(self, project: str, database: str = "(default)", prefix: str = "") -> None:
        from google.cloud import firestore  # imported here so tests and dev never need the library

        self._db = firestore.Client(project=project or None, database=database)
        self._prefix = prefix

    def _col(self, collection: str):
        return self._db.collection(self._prefix + collection)

    def get(self, collection: str, doc_id: str) -> dict | None:
        snap = self._col(collection).document(doc_id).get()
        return snap.to_dict() if snap.exists else None

    def list_ids(self, collection: str) -> list[str]:
        return [d.id for d in self._col(collection).select([]).stream()]

    def query(self, collection: str, field: str, value: Any) -> list[tuple[str, dict]]:
        # Equality on one field needs no extra index in Firestore.
        return [(d.id, d.to_dict()) for d in self._col(collection).where(field, "==", value).stream()]

    def set_many(self, collection: str, docs: dict[str, dict]) -> None:
        batch = self._db.batch()
        for n, (doc_id, doc) in enumerate(docs.items(), 1):
            batch.set(self._col(collection).document(doc_id), doc)
            if n % 400 == 0:  # a batch holds at most 500 writes
                batch.commit()
                batch = self._db.batch()
        batch.commit()

    def delete_many(self, collection: str, doc_ids: list[str]) -> None:
        batch = self._db.batch()
        for doc_id in doc_ids:
            batch.delete(self._col(collection).document(doc_id))
        batch.commit()

    def clear(self, collection: str) -> None:  # tests and reset only
        self.delete_many(collection, self.list_ids(collection))


_backend: Backend | None = None


def configure(backend: Backend | None) -> None:
    global _backend
    _backend = backend


def enabled() -> bool:
    return _backend is not None


def _doc_id(key: Any) -> str:
    parts = key if isinstance(key, tuple) else (key,)
    return "|".join(urllib.parse.quote(str(p), safe="") for p in parts)


def _wrap(value: Any) -> dict:
    """Firestore documents are maps: dicts are stored as they are (JSON-safe), anything else under `_value`."""
    if isinstance(value, dict):
        return json.loads(json.dumps(value, default=str))
    return {"_value": value}


def _unwrap(doc: dict) -> Any:
    return doc["_value"] if set(doc) == {"_value"} else doc


def _dump(value: Any) -> str:
    return json.dumps(value, sort_keys=True, default=str)


def begin() -> Token:
    return _session.set({})


def end(token: Token) -> None:
    _session.reset(token)


def flush() -> None:
    """Write back everything this request changed. Unchanged documents are not written."""
    sess = _session.get()
    if not sess or _backend is None:
        return
    for name, entries in sess.items():
        writes: dict[str, dict] = {}
        deletes: list[str] = []
        for doc_id, (_key, value, original) in entries.items():
            if value is _DELETED:
                deletes.append(doc_id)
            elif original is None or _dump(value) != original:
                writes[doc_id] = _wrap(value)
        if writes:
            _backend.set_many(name, writes)
        if deletes:
            _backend.delete_many(name, deletes)
        entries.clear()


class Collection(MutableMapping):
    """A dict-like collection. In-process by default; Firestore-backed when a backend is configured."""

    def __init__(self, name: str) -> None:
        self.name = name
        self._mem: dict = {}

    # -- helpers ------------------------------------------------------------------------------------------------
    def _entries(self) -> dict | None:
        sess = _session.get()
        return None if sess is None else sess.setdefault(self.name, {})

    # -- mapping interface --------------------------------------------------------------------------------------
    def __getitem__(self, key: Any) -> Any:
        if _backend is None:
            return self._mem[key]
        doc_id = _doc_id(key)
        entries = self._entries()
        if entries is not None and doc_id in entries:
            value = entries[doc_id][1]
            if value is _DELETED:
                raise KeyError(key)
            return value
        doc = _backend.get(self.name, doc_id)
        if doc is None:
            raise KeyError(key)
        value = _unwrap(doc)
        if entries is not None:
            entries[doc_id] = [key, value, _dump(value)]
        return value

    def __setitem__(self, key: Any, value: Any) -> None:
        if _backend is None:
            self._mem[key] = value
            return
        doc_id = _doc_id(key)
        entries = self._entries()
        if entries is None:
            _backend.set_many(self.name, {doc_id: _wrap(value)})
        else:
            entries[doc_id] = [key, value, None]

    def __delitem__(self, key: Any) -> None:
        if _backend is None:
            del self._mem[key]
            return
        self[key]  # raises KeyError when it is not there
        doc_id = _doc_id(key)
        entries = self._entries()
        if entries is None:
            _backend.delete_many(self.name, [doc_id])
        else:
            entries[doc_id] = [key, _DELETED, None]

    def __iter__(self) -> Iterator:
        if _backend is None:
            return iter(list(self._mem))
        ids = set(_backend.list_ids(self.name))
        entries = self._entries() or {}
        for doc_id, entry in entries.items():
            if entry[1] is _DELETED:
                ids.discard(doc_id)
            else:
                ids.add(doc_id)
        return iter(sorted(urllib.parse.unquote(i) for i in ids))

    def __len__(self) -> int:
        return len(list(iter(self)))

    def __contains__(self, key: Any) -> bool:
        try:
            self[key]
        except KeyError:
            return False
        return True

    def find(self, field: str, value: Any) -> list:
        """The values (dict documents) whose `field` equals `value`. Uses a Firestore query, not a scan."""
        if _backend is None:
            return [v for v in list(self._mem.values()) if isinstance(v, dict) and v.get(field) == value]
        entries = self._entries()
        found: dict[str, Any] = {}
        for doc_id, doc in _backend.query(self.name, field, value):
            if entries is not None and doc_id in entries:
                continue  # this request already holds its own copy
            val = _unwrap(doc)
            if entries is not None:
                entries[doc_id] = [urllib.parse.unquote(doc_id), val, _dump(val)]
            found[doc_id] = val
        for doc_id, entry in (entries or {}).items():
            val = entry[1]
            if val is not _DELETED and isinstance(val, dict) and val.get(field) == value:
                found[doc_id] = val
        return list(found.values())

    def clear(self) -> None:
        self._mem.clear()
        if _backend is not None:
            _backend.clear(self.name)
            entries = self._entries()
            if entries is not None:
                entries.clear()


class SetCollection:
    """A set of strings (for example revoked token ids), kept in a Collection."""

    def __init__(self, name: str) -> None:
        self._c = Collection(name)

    def add(self, item: str) -> None:
        self._c[item] = {"member": True}

    def discard(self, item: str) -> None:
        if item in self._c:
            del self._c[item]

    def __contains__(self, item: object) -> bool:
        return item in self._c

    def __iter__(self) -> Iterator:
        return iter(self._c)

    def __len__(self) -> int:
        return len(self._c)

    def clear(self) -> None:
        self._c.clear()
