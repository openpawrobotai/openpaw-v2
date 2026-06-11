"""Instant, factual fan-out to Discord and Telegram.

These channels carry raw build-log facts (commit message, repo, link) to your OWN
community channels, so they post immediately with no LLM and no approval step.
Used by `notify` CLI and reusable locally; CI normally uses the build-log.yml curl
steps directly, but this keeps a single Python entry point too.
"""
from __future__ import annotations

import requests

from . import config

TIMEOUT = 15


def to_discord(content: str) -> bool:
    url = config.env("DISCORD_WEBHOOK_URL")
    if not url:
        print("notify: DISCORD_WEBHOOK_URL not set — skipping Discord.")
        return False
    r = requests.post(url, json={"content": content}, timeout=TIMEOUT)
    r.raise_for_status()
    return True


def to_telegram(text: str) -> bool:
    token = config.env("TELEGRAM_BOT_TOKEN")
    chat = config.env("TELEGRAM_CHAT_ID")
    if not (token and chat):
        print("notify: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID not set — skipping Telegram.")
        return False
    # Telegram Markdown uses single * for bold; normalise Discord's **.
    text = text.replace("**", "*")
    r = requests.post(
        f"https://api.telegram.org/bot{token}/sendMessage",
        data={"chat_id": chat, "text": text, "parse_mode": "Markdown"},
        timeout=TIMEOUT,
    )
    r.raise_for_status()
    return True


def fan_out(content: str) -> None:
    """Send the same build-log line to every configured instant channel."""
    sent = []
    if to_discord(content):
        sent.append("discord")
    if to_telegram(content):
        sent.append("telegram")
    print(f"notify: sent to {sent or 'nobody (no channels configured)'}")
