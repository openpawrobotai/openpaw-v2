"""Turn a commit/release into a short X draft using Gemini.

SAFETY: we NEVER pass raw diffs. The model only sees the commit message, the
release tag, and (optionally) a list of changed file NAMES. The drafting prompt
also forbids leaking endpoints/keys/model details. If the change isn't interesting
to a general audience, the model returns SKIP and nothing is queued.
"""
from __future__ import annotations

from dataclasses import dataclass

from . import config


@dataclass
class Context:
    repo: str
    sha: str = ""
    message: str = ""
    tag: str = ""
    event: str = "push"
    files: tuple[str, ...] = ()
    post_type: str = "progress"  # progress|it_broke|before_after|milestone|ask

    def infer_type(self) -> str:
        if self.event == "release" or self.tag:
            return "milestone"
        m = self.message.lower()
        if any(w in m for w in ("fix", "bug", "broke", "crash", "regression")):
            return "it_broke"
        return self.post_type


class MoatViolation(Exception):
    """Raised if a non-allowlisted repo tries to feed content."""


def _build_input(ctx: Context) -> str:
    t = ctx.infer_type()
    tmpl = config.templates().get(t, config.templates().get("progress", ""))
    files = ", ".join(ctx.files[:20]) or "(file list not provided)"
    return (
        f"post type: {t}\n"
        f"repo: {ctx.repo}\n"
        f"event: {ctx.event}\n"
        f"release tag: {ctx.tag or '(none)'}\n"
        f"commit message(s):\n{ctx.message or '(none)'}\n"
        f"changed file NAMES only: {files}\n\n"
        f"template for this type:\n{tmpl}\n\n"
        f"hashtags to end with: {config.hashtags()}\n"
    )


def generate(ctx: Context) -> str | None:
    """Return draft text, or None if SKIP / not interesting. Raises MoatViolation."""
    if ctx.repo not in config.allowlist():
        raise MoatViolation(
            f"{ctx.repo!r} is not in config/repos.allowlist — refusing to draft "
            "(moat guard: app/ai/data repos never feed public content)."
        )

    import google.generativeai as genai

    api_key = config.env("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set.")
    genai.configure(api_key=api_key)

    model = genai.GenerativeModel(
        "gemini-1.5-flash",
        system_instruction=config.prompt(),
    )
    resp = model.generate_content(_build_input(ctx))
    text = (resp.text or "").strip()
    if not text or text.upper() == "SKIP":
        return None
    return text
