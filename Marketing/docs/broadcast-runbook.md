# 📣 OpenPaw Broadcast Runbook (do this every other day)

This is the routine for turning the work we've shipped into posts across our
channels. It takes **~15 minutes**. You do **not** need to understand the code —
just follow the steps.

> **The golden rule:** the tool drafts; **a human always reviews before anything
> goes public.** Auto channels (Discord/Telegram) are our own community, so those
> can post directly. X and everything else you eyeball first.

---

## 0. One-time setup (skip if already done on your machine)

```bash
cd ~/Development/Ayvalabs/openpaw-marketing
python3 -m venv .venv && . .venv/bin/activate && pip install -e .
bash scripts/setup-channels.sh      # paste the API keys (ask the lead for them)
```
You're set when `bash scripts/announce.sh --repo openpaw-firmware` runs without a
"GEMINI_API_KEY not set" error.

---

## 1. See what we shipped

The post should reflect real work. Pick the repo that had the most activity since
last time (usually `openpaw-firmware`). Channels we can post about:
`openpaw-firmware`, `openpaw-hardware`, `openpaw-website`, `openpaw-docs`.

> 🚫 **Never** announce `openpaw-app` or anything AI/data — that's our private moat.
> The tool blocks it automatically, but don't try.

---

## 2. Run the broadcast tool (interactive)

```bash
cd ~/Development/Ayvalabs/openpaw-marketing
bash scripts/announce.sh --repo openpaw-firmware
```

It will ask you three things:

1. **Post type** — pick one:
   - `progress` — normal "we added X" update (most common)
   - `it_broke` — we hit a bug and fixed it (people love honesty)
   - `milestone` — something big works / a release (use for releases)
   - `before_after` — visible improvement
   - `ask` — asking the community a question
2. **Channels** — type `auto` for the every-other-day routine (Discord + Telegram + X).
   Type `all` or list specific ones (e.g. `discord,x,reddit`) only on big days.
3. For each **auto** channel it shows a preview and asks `Post now? [y/N]`.

---

## 3. Review every draft before saying `y`

Read each preview and check:
- ✅ Is it **true**? (matches what we actually did)
- ✅ Is it **clear** to a normal person, not just engineers?
- ✅ No secrets, URLs to internal stuff, keys, or private/app/AI details.
- ✅ Reads naturally (fix awkward AI phrasing — you can re-run if it's bad).

If a draft is good → type `y`. If not → type `N` and re-run (LLM gives a new draft),
or skip that channel.

---

## 4. What happens to each channel

| Channel | What the tool does | Your follow-up |
|---|---|---|
| **Discord** | posts immediately on `y` | none |
| **Telegram** | posts immediately on `y` | none |
| **X (Twitter)** | **queues** a draft (never auto-posts) | approve it, see step 5 |
| Reddit / HN / Hackaday / Instagram / LinkedIn | writes a file to `out/` | open, review, paste manually |

---

## 5. Approve the X post

X posts wait in a queue so we never spam. To send the one you just drafted:

```bash
make list                       # shows drafts; copy the id of the new one
make approve ID=<that-id>
git add queue/queue.jsonl && git commit -m "approve devlog" && git push
```
A scheduled job posts approved drafts (max 1/day). That's it — don't post to X by hand.

---

## 6. Manual channels (only on milestone days, ~once a week)

If you chose Reddit/HN/etc., the tool saved ready-to-paste drafts in `out/`:
```bash
ls out/                         # e.g. reddit-ab12cd34.md
open out/reddit-ab12cd34.md     # read it, tweak the voice, then paste to Reddit
```
> Post these **by hand**. Auto-posting to Reddit/HN/Instagram gets us banned or
> flagged as spam. Space them out — don't blast all on the same day.

---

## Every-other-day checklist (TL;DR)

- [ ] `cd ~/Development/Ayvalabs/openpaw-marketing`
- [ ] `bash scripts/announce.sh --repo <busiest repo>`
- [ ] type `auto`, pick the post type
- [ ] review each preview → `y` to post (Discord/Telegram)
- [ ] `make list` → `make approve ID=…` → commit & push (X)
- [ ] (milestone weeks only) review `out/` files and paste manually

## If something looks wrong
- **"GEMINI_API_KEY not set"** → run `bash scripts/setup-channels.sh`, or you forgot the `.venv`.
- **"BLOCKED: … not in repos.allowlist"** → you picked a private repo. Use a public one.
- **"Nothing to announce"** → no new commits since the last tag; use `--since HEAD~10`.
- **A draft is off / cringe** → re-run; never post something you wouldn't say yourself.
- **Unsure about anything public** → ask the lead before posting. When in doubt, don't.
