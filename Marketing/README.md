# 🐾 openpaw-marketing

Build-in-public automation for **OpenPaw**: one `git push` becomes posts across
your channels. MIT licensed.

> Part of [OpenPaw](https://github.com/aeropriest). Maintainer: **@aeropriest**.

## Two channels, two trust levels

```
                          git push to main  /  release tag
                                     │
        ┌────────────────────────────┴───────────────────────────┐
        ▼                                                          ▼
 CHANNEL A  (instant, factual)                      CHANNEL B  (curated, approved)
 build-log.yml in each repo                         only on [post] commits / releases
        │                                                          │
   Discord + Telegram                            repository_dispatch ──► openpaw-marketing
   (raw commit/release facts,                                            │
    no LLM, no approval)                          devlog-draft.yml: Gemini drafts from
                                                  commit msg + file NAMES (never diffs)
                                                                         │
                                                  queue/queue.jsonl (status: pending)
                                                                         │
                                                  you review → `make approve ID` → commit
                                                                         │
                                                  devlog-post.yml (cron): posts ≤1/day to X,
                                                  marks posted
```

**Channel A** carries your own git facts to your own community channels, so it
posts immediately. **Channel B** is public-facing and curated — nothing reaches X
without a human approving the draft (a git edit).

## Rules
- **X never auto-posts.** Drafts are `pending` until you approve.
- **Channel B triggers only on** `[post]` commits or release tags — never every push.
- **Never send raw diffs** to the LLM — commit message + file NAMES only.
- **Moat guard:** only repos in `config/repos.allowlist` may feed content; `openpaw-app` / `openpaw-ai` / data repos never do (enforced in `draft.py`).
- **Kill switch:** `settings.enabled: false` halts all X posting.
- **Reddit/HN stay manual** (milestone-only) — not automated here.
- **Secrets via env / GitHub Secrets** — see `.env.example`, never committed.

## Layout
```
src/openpaw_marketing/
  notify.py   Discord + Telegram fan-out (Channel A, also usable locally)
  draft.py    commit context -> Gemini -> post text or SKIP (moat-guarded)
  queue.py    git-tracked JSONL review queue (pending→approved→posted)
  post_x.py   post approved drafts to X (OAuth1, daily cap)
  __main__.py CLI: notify | draft | list | approve | reject | post-due
config/       settings.yml · templates.yml · repos.allowlist · prompt.md
queue/        queue.jsonl (review queue; post text only, no secrets)
.github/workflows/  devlog-draft.yml (dispatch) · devlog-post.yml (cron)
scripts/      setup-channels.sh (interactive key collection)
docs/         getting-api-keys.md
```

## Setup
```bash
bash scripts/setup-channels.sh      # collect keys into gitignored .env
make install                        # pip install -e .
make list                           # see the (empty) queue
```

### CI secrets
**This repo** (`openpaw-marketing`) needs, as GitHub Secrets:
`GEMINI_API_KEY`, `X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_SECRET`.

**Each public source repo** (firmware, hardware, website, docs) needs:
`DISCORD_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` (Channel A) and
`MARKETING_DISPATCH_TOKEN` — a PAT with `repo` scope that can fire a
`repository_dispatch` to this repo (Channel B). Then drop `build-log.yml` into
that repo's `.github/workflows/`.

```bash
gh secret set DISCORD_WEBHOOK_URL --repo aeropriest/openpaw-firmware
gh secret set GEMINI_API_KEY      --repo aeropriest/openpaw-marketing
# ...etc (docs/getting-api-keys.md lists every key + where to get it)
```

## Daily use

### A) Hands-off drumbeat (CI)
```bash
# A change worth tweeting? add [post] to the commit subject:
git commit -m "[post] add OTA rollback so a bad update can't brick your pet"
git push                       # → Discord+Telegram instantly; X draft queued

make list                      # review pending drafts
make approve ID=ab12cd34ef     # then: git commit queue/queue.jsonl && push
# devlog-post.yml drips approved drafts to X (≤ max_posts_per_day)
```

### B) `announce` — community-building console (from your terminal)
Reads the work you've done from git and turns it into posts. **Auto** channels
(Discord/Telegram) post now; **X** is queued for approval; **manual** channels
(Reddit/HN/Hackaday/Instagram/LinkedIn) are drafted to `out/` as ready-to-paste
title + text, each in that platform's native voice.

```bash
bash scripts/announce.sh --repo openpaw-firmware            # interactive: pick type + channels
bash scripts/announce.sh --repo openpaw-firmware \
     --channels discord,telegram,x --type milestone         # scripted (cron-able)
bash scripts/announce.sh --repo openpaw-firmware \
     --channels reddit,hackernews --copy                    # draft manual posts, copy first to clipboard
```
- `--since v0.2.0` summarizes only work since a tag (default: last tag, else last 10 commits).
- Reads commit **subjects + file names only** — never diffs. Moat-guarded by `repos.allowlist`.
- Manual drafts land in `out/` (gitignored) — review, then paste.

## License
MIT © 2026 aeropriest
