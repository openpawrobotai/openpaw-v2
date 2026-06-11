"""Channel definitions: which post automatically, which need a human, and the
voice/format each one expects. The `style` text is fed to the LLM so each post
reads native to its platform instead of one-size-fits-all."""
from __future__ import annotations

AUTO = "auto"      # the tool can post these for you
MANUAL = "manual"  # the tool drafts; you paste (auto-posting = bans/spam)

PLATFORMS: dict[str, dict] = {
    # ---- automated ----
    "discord": {
        "kind": AUTO, "title": False, "max": 1800, "hashtags": False,
        "style": "Friendly community update for our Discord. 1-3 sentences, "
                 "an emoji or two, conversational. No hashtags.",
    },
    "telegram": {
        "kind": AUTO, "title": False, "max": 1800, "hashtags": False,
        "style": "Short Telegram channel update. Plain, warm, 1-3 sentences.",
    },
    "x": {
        "kind": AUTO, "title": False, "max": 270, "hashtags": True,
        "style": "A single X/Twitter post UNDER 270 characters. Punchy, human, "
                 "build-in-public energy. End with the configured hashtags.",
    },
    # ---- manual (drafted for copy-paste) ----
    "reddit": {
        "kind": MANUAL, "title": True, "max": 4000, "hashtags": False,
        "style": "A Reddit post for r/robotics or r/esp32. Honest, technical, "
                 "humble — makers HATE marketing speak. Give real detail about "
                 "what changed and why. No hashtags, no emojis spam. Provide a "
                 "specific, non-clickbait TITLE.",
    },
    "hackernews": {
        "kind": MANUAL, "title": True, "max": 1200, "hashtags": False,
        "style": "A 'Show HN' submission. TITLE must start with 'Show HN: ' and "
                 "be plain and factual (<= 80 chars). Body is a short, no-hype "
                 "paragraph explaining what it is and inviting feedback.",
    },
    "hackaday": {
        "kind": MANUAL, "title": True, "max": 3000, "hashtags": False,
        "style": "A Hackaday.io project LOG entry. Technical build-log tone, "
                 "describes progress and decisions. Give a short TITLE for the log.",
    },
    "instagram": {
        "kind": MANUAL, "title": False, "max": 2000, "hashtags": True,
        "style": "An Instagram/TikTok caption. A scroll-stopping first line (hook), "
                 "then 1-2 lines, playful, pet-owner audience (not engineers). "
                 "End with a block of relevant hashtags.",
    },
    "linkedin": {
        "kind": MANUAL, "title": False, "max": 2500, "hashtags": True,
        "style": "A LinkedIn post. Professional, story-driven, founder voice. "
                 "Short paragraphs/line breaks. A few tasteful hashtags at the end.",
    },
}

AUTO_KEYS = [k for k, v in PLATFORMS.items() if v["kind"] == AUTO]
MANUAL_KEYS = [k for k, v in PLATFORMS.items() if v["kind"] == MANUAL]
ALL_KEYS = list(PLATFORMS.keys())
