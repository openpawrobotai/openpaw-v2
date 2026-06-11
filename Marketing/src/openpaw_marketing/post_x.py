"""Post approved drafts to X (Twitter) via OAuth 1.0a user context.

Free-tier friendly: uses tweepy.Client.create_tweet, which needs the four
user-context credentials (consumer key/secret + access token/secret) with
Read+Write app permission.
"""
from __future__ import annotations

from . import config, queue


def _client():
    import tweepy

    keys = {
        "consumer_key": config.env("X_API_KEY"),
        "consumer_secret": config.env("X_API_SECRET"),
        "access_token": config.env("X_ACCESS_TOKEN"),
        "access_token_secret": config.env("X_ACCESS_SECRET"),
    }
    missing = [k for k, v in keys.items() if not v]
    if missing:
        raise RuntimeError(f"X credentials missing: {', '.join(missing)}")
    return tweepy.Client(**keys)


def post_text(text: str) -> str:
    """Post a single tweet, return its id (str)."""
    resp = _client().create_tweet(text=text)
    return str(resp.data["id"])


def post_due(dry_run: bool = False) -> int:
    """Post approved drafts up to the daily cap. Returns count posted."""
    s = config.settings()
    if not s.get("enabled", False):
        print("post: master kill switch (settings.enabled) is false — nothing posted.")
        return 0
    xcfg = s.get("channels", {}).get("x", {})
    if not xcfg.get("enabled", False):
        print("post: channels.x.enabled is false — nothing posted.")
        return 0

    cap = int(xcfg.get("max_posts_per_day", 1))
    already = queue.posted_today()
    budget = max(0, cap - already)
    if budget == 0:
        print(f"post: daily cap reached ({already}/{cap}).")
        return 0

    approved = queue.by_status(queue.APPROVED)
    if not approved:
        print("post: no approved drafts in the queue.")
        return 0

    done = 0
    for row in approved[:budget]:
        if dry_run:
            print(f"[dry-run] would post {row['id']}: {row['text'][:60]}...")
            done += 1
            continue
        tweet_id = post_text(row["text"])
        queue.set_status(row["id"], queue.POSTED)
        print(f"post: tweeted {row['id']} -> https://x.com/i/web/status/{tweet_id}")
        done += 1
    print(f"post: posted {done} (cap {cap}, already {already}).")
    return done
