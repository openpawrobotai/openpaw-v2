"""Review queue, stored as a git-tracked JSONL file.

Why git, not a DB: the queue holds only post TEXT (no secrets), so tracking it in
the repo gives free history, review, and "approval = a commit". Each line:

    {"id","created","repo","sha","type","text","status","posted_at"}

status: pending -> approved -> posted   (or -> rejected)

Swap-in adapters for Google Sheet / Firebase can implement the same read/write
surface later; QUEUE_BACKEND=local (default) uses this file.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Iterable

from . import config

PENDING, APPROVED, POSTED, REJECTED = "pending", "approved", "posted", "rejected"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _read() -> list[dict]:
    f = config.QUEUE_FILE
    if not f.exists():
        return []
    return [json.loads(ln) for ln in f.read_text().splitlines() if ln.strip()]


def _write(rows: Iterable[dict]) -> None:
    f = config.QUEUE_FILE
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows))


def add(repo: str, sha: str, post_type: str, text: str) -> dict:
    rows = _read()
    rid = hashlib.sha1(f"{sha}{text}{_now()}".encode()).hexdigest()[:10]
    row = {
        "id": rid,
        "created": _now(),
        "repo": repo,
        "sha": sha[:12],
        "type": post_type,
        "text": text,
        "status": PENDING,
        "posted_at": None,
    }
    rows.append(row)
    _write(rows)
    return row


def set_status(rid: str, status: str) -> dict | None:
    rows = _read()
    hit = None
    for r in rows:
        if r["id"] == rid:
            r["status"] = status
            if status == POSTED:
                r["posted_at"] = _now()
            hit = r
    if hit:
        _write(rows)
    return hit


def by_status(status: str) -> list[dict]:
    return [r for r in _read() if r["status"] == status]


def posted_today() -> int:
    today = datetime.now(timezone.utc).date().isoformat()
    return sum(
        1 for r in _read()
        if r["status"] == POSTED and (r.get("posted_at") or "").startswith(today)
    )


def all_rows() -> list[dict]:
    return _read()
