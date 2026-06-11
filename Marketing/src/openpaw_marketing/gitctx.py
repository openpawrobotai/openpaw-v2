"""Extract a SAFE summary of work done from a git repo.

We only ever read commit SUBJECTS and changed file NAMES — never diffs, never
file contents — so nothing secret can leak into a generated post.
"""
from __future__ import annotations

import subprocess
from dataclasses import dataclass, field
from pathlib import Path

from . import config


@dataclass
class WorkContext:
    repo: str
    path: Path
    sha: str
    range_desc: str
    messages: list[str] = field(default_factory=list)
    files: list[str] = field(default_factory=list)

    @property
    def empty(self) -> bool:
        return not self.messages


def _git(path: Path, *args: str) -> str:
    out = subprocess.run(
        ["git", "-C", str(path), *args],
        capture_output=True, text=True, check=False,
    )
    return out.stdout.strip()


def resolve_repo(name_or_path: str) -> Path:
    """Accept a path, or a sibling repo name (../<name> from the marketing repo)."""
    p = Path(name_or_path).expanduser()
    if p.is_dir() and (p / ".git").exists():
        return p.resolve()
    sibling = (config.ROOT.parent / name_or_path)
    if sibling.is_dir() and (sibling / ".git").exists():
        return sibling.resolve()
    raise FileNotFoundError(
        f"Could not find a git repo for {name_or_path!r} "
        f"(looked at {p} and {sibling})."
    )


def collect(name_or_path: str, since: str | None = None, max_commits: int = 10) -> WorkContext:
    path = resolve_repo(name_or_path)
    repo = path.name
    sha = _git(path, "rev-parse", "HEAD")

    if not since:
        # default range = since the most recent tag, else the last N commits
        last_tag = _git(path, "describe", "--tags", "--abbrev=0")
        since = last_tag or None

    if since:
        rng = f"{since}..HEAD"
        msgs = _git(path, "log", rng, "--format=%s")
        files = _git(path, "diff", "--name-only", rng)
        range_desc = f"since {since}"
    else:
        rng = f"-n{max_commits}"
        msgs = _git(path, "log", rng, "--format=%s")
        files = _git(path, "log", rng, "--name-only", "--format=")
        range_desc = f"last {max_commits} commits"

    messages = [m for m in msgs.splitlines() if m.strip()]
    files_list = sorted({f for f in files.splitlines() if f.strip()})
    return WorkContext(
        repo=repo, path=path, sha=sha, range_desc=range_desc,
        messages=messages, files=files_list,
    )
