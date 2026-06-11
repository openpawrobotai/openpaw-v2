"""Load config files and resolve paths. No secrets live here — those come from env."""
from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

import yaml

# repo root = two levels up from this file's package dir (src/openpaw_marketing/..)
ROOT = Path(__file__).resolve().parents[2]
CONFIG_DIR = ROOT / "config"
QUEUE_FILE = ROOT / "queue" / "queue.jsonl"
PROMPT_FILE = CONFIG_DIR / "prompt.md"


@lru_cache(maxsize=1)
def settings() -> dict:
    return yaml.safe_load((CONFIG_DIR / "settings.yml").read_text())


@lru_cache(maxsize=1)
def templates() -> dict:
    return yaml.safe_load((CONFIG_DIR / "templates.yml").read_text())


@lru_cache(maxsize=1)
def allowlist() -> set[str]:
    lines = (CONFIG_DIR / "repos.allowlist").read_text().splitlines()
    return {
        ln.strip()
        for ln in lines
        if ln.strip() and not ln.lstrip().startswith("#")
    }


@lru_cache(maxsize=1)
def prompt() -> str:
    return PROMPT_FILE.read_text()


def hashtags() -> str:
    return " ".join(settings().get("hashtags", []))


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()
