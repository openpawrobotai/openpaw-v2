"""The `announce` flow: work done (git) -> per-platform posts.

  auto channels (discord/telegram)  -> posted now (after confirm in interactive mode)
  auto X                            -> queued as a pending draft (approve later)
  manual channels                   -> written to out/ as ready-to-paste title+text

Moat guard: only repos in config/repos.allowlist may be announced.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

from . import config, draft, notify, platforms, queue
from .gitctx import WorkContext, collect

OUT_DIR = config.ROOT / "out"


def _context_block(ctx: WorkContext) -> str:
    files = ", ".join(ctx.files[:25]) or "(none)"
    msgs = "\n".join(f"- {m}" for m in ctx.messages[:30]) or "(none)"
    return (
        f"repo: {ctx.repo}\n"
        f"range: {ctx.range_desc}\n"
        f"commit subjects:\n{msgs}\n"
        f"changed file NAMES only: {files}\n"
    )


def _gen(ctx: WorkContext, key: str, post_type: str) -> dict:
    """Return {'title': str|None, 'body': str} for one platform via Gemini."""
    import google.generativeai as genai

    api_key = config.env("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set (source your .env first).")
    genai.configure(api_key=api_key)

    p = platforms.PLATFORMS[key]
    tmpl = config.templates().get(post_type, "")
    want_title = p["title"]
    tags = config.hashtags() if p["hashtags"] else "(no hashtags)"

    instruction = (
        f"{config.prompt()}\n\n"
        f"PLATFORM: {key}\n"
        f"PLATFORM STYLE: {p['style']}\n"
        f"MAX LENGTH for the body: {p['max']} characters.\n"
        f"post type: {post_type} (loose template: {tmpl!r})\n"
        f"hashtags: {tags}\n\n"
        "Output EXACTLY this format and nothing else:\n"
        "TITLE: <one-line title, or NONE if this platform needs no title>\n"
        "---\n"
        "<the post body>\n\n"
        "If the work isn't worth posting to a general audience, output only: SKIP"
    )
    model = genai.GenerativeModel("gemini-1.5-flash", system_instruction=instruction)
    resp = model.generate_content(_context_block(ctx))
    text = (resp.text or "").strip()
    if text.upper() == "SKIP" or not text:
        return {"title": None, "body": "", "skip": True}

    title, body = None, text
    if "---" in text:
        head, _, rest = text.partition("---")
        body = rest.strip()
        for line in head.splitlines():
            if line.strip().upper().startswith("TITLE:"):
                t = line.split(":", 1)[1].strip()
                title = None if t.upper() == "NONE" or not t else t
    if not want_title:
        title = None
    return {"title": title, "body": body, "skip": False}


def _pbcopy(text: str) -> bool:
    try:
        subprocess.run(["pbcopy"], input=text.encode(), check=True)
        return True
    except Exception:
        return False


def _write_manual(ctx: WorkContext, key: str, gen: dict) -> Path:
    OUT_DIR.mkdir(exist_ok=True)
    fp = OUT_DIR / f"{key}-{ctx.sha[:8]}.md"
    parts = []
    if gen["title"]:
        parts.append(f"# {gen['title']}\n")
    parts.append(gen["body"])
    fp.write_text("\n".join(parts) + "\n")
    return fp


def run(repo: str, post_type: str, channels: list[str], since: str | None,
        interactive: bool, copy: bool) -> int:
    ctx = collect(repo, since=since)
    if ctx.repo not in config.allowlist():
        print(f"BLOCKED: {ctx.repo!r} is not in config/repos.allowlist (moat guard).")
        return 2
    if ctx.empty:
        print(f"Nothing to announce in {ctx.repo} ({ctx.range_desc}).")
        return 0

    print(f"\n📋 {ctx.repo} — {ctx.range_desc} — {len(ctx.messages)} commit(s):")
    for m in ctx.messages[:10]:
        print(f"   • {m}")
    print()

    auto_done, manual_files, copied = [], [], None
    for key in channels:
        p = platforms.PLATFORMS[key]
        try:
            gen = _gen(ctx, key, post_type)
        except Exception as e:
            print(f"  [{key}] generation failed: {e}")
            continue
        if gen.get("skip"):
            print(f"  [{key}] model said SKIP — not worth a post.")
            continue

        preview = (f"TITLE: {gen['title']}\n" if gen["title"] else "") + gen["body"]
        print(f"\n=== {key} ({p['kind']}) ===\n{preview}\n")

        if p["kind"] == platforms.AUTO:
            if key == "x":
                row = queue.add(ctx.repo, ctx.sha, post_type, gen["body"])
                print(f"  → queued X draft {row['id']} (approve with: make approve ID={row['id']})")
                auto_done.append("x(queued)")
                continue
            go = True
            if interactive:
                go = input(f"  Post to {key} now? [y/N] ").strip().lower() == "y"
            if go:
                (notify.to_discord if key == "discord" else notify.to_telegram)(gen["body"])
                auto_done.append(key)
            else:
                print(f"  skipped {key}.")
        else:  # manual
            fp = _write_manual(ctx, key, gen)
            manual_files.append(fp)
            print(f"  → saved: {fp}")
            if copy and copied is None:
                if _pbcopy(preview):
                    copied = key
                    print(f"  → copied {key} to clipboard.")

    print("\n──────── summary ────────")
    print(f"  posted/queued: {', '.join(auto_done) or 'none'}")
    if manual_files:
        print("  drafted for manual posting:")
        for fp in manual_files:
            print(f"    - {fp}")
        print("  (open each file, review, and paste to the platform)")
    return 0
