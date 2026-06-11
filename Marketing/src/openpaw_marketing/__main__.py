"""CLI: git push -> build-log + X draft -> approve -> post.

Examples:
  python -m openpaw_marketing notify --text "🐾 openpaw-firmware — added OTA"
  python -m openpaw_marketing draft  --repo openpaw-firmware --sha abc123 \
        --message "[post] add OTA rollback" --files ota.c,partitions.csv
  python -m openpaw_marketing list
  python -m openpaw_marketing approve <id>
  python -m openpaw_marketing reject  <id>
  python -m openpaw_marketing post-due [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import sys

from . import announce, config, draft, notify, platforms, post_x, queue


def _cmd_notify(a) -> int:
    notify.fan_out(a.text)
    return 0


def _cmd_draft(a) -> int:
    files = tuple(f.strip() for f in (a.files or "").split(",") if f.strip())
    ctx = draft.Context(
        repo=a.repo, sha=a.sha, message=a.message or "",
        tag=a.tag or "", event=a.event, files=files,
        post_type=a.type,
    )
    try:
        text = draft.generate(ctx)
    except draft.MoatViolation as e:
        print(f"draft: BLOCKED — {e}", file=sys.stderr)
        return 2
    if text is None:
        print("draft: model returned SKIP — nothing queued.")
        return 0
    row = queue.add(ctx.repo, ctx.sha, ctx.infer_type(), text)
    print(f"draft: queued {row['id']} ({row['type']}) — status pending\n\n{text}")
    return 0


def _cmd_list(a) -> int:
    rows = queue.all_rows()
    if a.json:
        print(json.dumps(rows, indent=2, ensure_ascii=False))
        return 0
    if not rows:
        print("(queue empty)")
        return 0
    for r in rows:
        mark = {"pending": "*", "approved": "+", "posted": "@", "rejected": "x"}.get(r["status"], "?")
        print(f"{mark} {r['id']}  [{r['status']:<8}] {r['repo']}  {r['text'][:70].replace(chr(10), ' ')}")
    return 0


def _cmd_approve(a) -> int:
    r = queue.set_status(a.id, queue.APPROVED)
    print(f"approved {a.id}" if r else f"no such id: {a.id}")
    return 0 if r else 1


def _cmd_reject(a) -> int:
    r = queue.set_status(a.id, queue.REJECTED)
    print(f"rejected {a.id}" if r else f"no such id: {a.id}")
    return 0 if r else 1


def _cmd_post_due(a) -> int:
    post_x.post_due(dry_run=a.dry_run)
    return 0


def _pick_channels_interactively() -> list[str]:
    keys = platforms.ALL_KEYS
    print("\nChannels:")
    for i, k in enumerate(keys, 1):
        kind = platforms.PLATFORMS[k]["kind"]
        print(f"  {i:>2}. {k:<12} ({kind})")
    print("  Shortcuts: 'all', 'auto', 'manual'")
    raw = input("Pick channels (numbers/names, comma-separated): ").strip().lower()
    if raw in ("all", ""):
        return keys
    if raw == "auto":
        return platforms.AUTO_KEYS
    if raw == "manual":
        return platforms.MANUAL_KEYS
    chosen = []
    for tok in raw.replace(" ", "").split(","):
        if tok.isdigit() and 1 <= int(tok) <= len(keys):
            chosen.append(keys[int(tok) - 1])
        elif tok in platforms.PLATFORMS:
            chosen.append(tok)
    return chosen or platforms.AUTO_KEYS


def _cmd_announce(a) -> int:
    channels = (
        [c.strip() for c in a.channels.split(",") if c.strip()]
        if a.channels else None
    )
    interactive = a.interactive or not channels
    post_type = a.type
    if interactive:
        if not a.type or a.type == "progress":
            t = input("Post type [progress|it_broke|milestone|before_after|ask] (progress): ").strip()
            post_type = t or "progress"
        if not channels:
            channels = _pick_channels_interactively()
    bad = [c for c in channels if c not in platforms.PLATFORMS]
    if bad:
        print(f"unknown channel(s): {', '.join(bad)} (valid: {', '.join(platforms.ALL_KEYS)})")
        return 1
    return announce.run(
        repo=a.repo, post_type=post_type, channels=channels,
        since=a.since, interactive=interactive, copy=a.copy,
    )


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="openpaw-marketing")
    sub = p.add_subparsers(dest="cmd", required=True)

    n = sub.add_parser("notify", help="fan out a build-log line to Discord+Telegram")
    n.add_argument("--text", required=True)
    n.set_defaults(fn=_cmd_notify)

    d = sub.add_parser("draft", help="generate an X draft from a commit/release")
    d.add_argument("--repo", required=True)
    d.add_argument("--sha", default="")
    d.add_argument("--message", default="")
    d.add_argument("--tag", default="")
    d.add_argument("--event", default="push")
    d.add_argument("--files", default="")
    d.add_argument("--type", default="progress")
    d.set_defaults(fn=_cmd_draft)

    ls = sub.add_parser("list", help="show the review queue")
    ls.add_argument("--json", action="store_true")
    ls.set_defaults(fn=_cmd_list)

    ap = sub.add_parser("approve", help="approve a draft by id")
    ap.add_argument("id")
    ap.set_defaults(fn=_cmd_approve)

    rj = sub.add_parser("reject", help="reject a draft by id")
    rj.add_argument("id")
    rj.set_defaults(fn=_cmd_reject)

    pd = sub.add_parser("post-due", help="post approved drafts up to the daily cap")
    pd.add_argument("--dry-run", action="store_true")
    pd.set_defaults(fn=_cmd_post_due)

    an = sub.add_parser(
        "announce",
        help="read work done from git -> post (auto) / draft to out/ (manual)",
    )
    an.add_argument("--repo", default="openpaw-firmware",
                    help="repo name (sibling dir) or path. Default: openpaw-firmware")
    an.add_argument("--since", default=None,
                    help="git ref/tag to summarize from (default: last tag, else last 10 commits)")
    an.add_argument("--channels", default=None,
                    help="comma list (e.g. discord,x,reddit). Omit for interactive picker.")
    an.add_argument("--type", default="progress",
                    help="progress|it_broke|milestone|before_after|ask")
    an.add_argument("-i", "--interactive", action="store_true",
                    help="prompt before posting each auto channel")
    an.add_argument("--copy", action="store_true",
                    help="copy the first manual draft to the clipboard (macOS pbcopy)")
    an.set_defaults(fn=_cmd_announce)

    a = p.parse_args(argv)
    return a.fn(a)


if __name__ == "__main__":
    raise SystemExit(main())
