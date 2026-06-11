# 🐾 OpenPaw — Social Handle Setup Checklist

## Two brand tracks (read first)

We deliberately run **two** brands for **two** audiences:

| Brand | Audience | Channels |
|---|---|---|
| **OpenPaw** | tech / dev / maker (open-source credibility) | GitHub, **X devlog**, Discord, Telegram, Reddit, Hacker News, Hackaday, YouTube build logs |
| **PawMe** | consumer / pet owners (crowdfunding funnel) | **Instagram, TikTok, Facebook** — *already live, keep as-is, not part of this rollout* |

This checklist is the **OpenPaw (dev)** rollout only. Claim it under one signup
email with identical branding; ~45–60 min.

> ⚠️ **Name collision:** there's an unrelated crypto token also called "OpenPaw"
> ($PAW, openpaw.net) that holds `@openpaw` on **Telegram** and likely elsewhere.
> Do **not** use bare `openpaw` where it's taken — use a fallback below so a
> pet-robot project is never confused with a memecoin. Display name stays "OpenPaw 🐾".

## Shared settings (use the SAME everywhere)

| Field | Value |
|---|---|
| **Signup email** | `pawme+openpaw@ayvalabs.com` (delivers to pawme@ayvalabs.com). If a site rejects `+`, use `pawme@ayvalabs.com`. |
| **Handle (1st choice)** | `OpenPaw` |
| **Handle (fallbacks, in order)** | `OpenPawHQ` → `OpenPawRobot` → `getopenpaw` → `OpenPaw_` |
| **Display name** | `OpenPaw` |
| **Link** | `https://github.com/ayvalabs/openpaw` (swap to the website once the domain is live) |
| **Avatar** | the green dog+cat logo (same PNG everywhere) |
| **Bio (short, ≤160 chars)** | `OpenPaw 🐾 open-source AI companion robot for pets. Building in public: firmware · hardware · app · ML. ⭐ github.com/ayvalabs/openpaw` |
| **Bio (long)** | `We're building an open-source robot that keeps pets company and watches over their wellbeing — and we're doing the whole thing in public. Follow the build, star the repos, join the community.` |

> **First step:** go to **https://namechk.com** (or namecheckr.com), search `openpaw`,
> and note which platforms are free. Lock your final handle choice from the
> fallbacks above, then use that ONE handle everywhere for consistency.

---

## Priority order

### 1. X / Twitter — RENAME (don't make a new one)
Keeps your followers + account age.
1. Log into **@PawMe** → **Settings → Your account → Account information → Username** → change to `OpenPaw`.
2. Update **display name** → OpenPaw, **bio**, **website link** (the GitHub hub), **avatar**, **header**.
3. Post a **pinned tweet**: *"We're now @OpenPaw 🐾 and going fully open source. Building an AI companion robot for pets — in public. ⭐ github.com/ayvalabs/openpaw"*

### 2. Discord — create the server (home of the build-log feed)
1. Discord → **+ (Add a Server) → Create My Own → For a club or community**.
2. Name it **OpenPaw**. Create channels: `#announcements`, `#build-log`, `#general`, `#help`, `#hardware`, `#firmware`.
3. **Server Settings → Enable Community** (gets you a vanity invite later + better moderation).
4. **Make the build-log webhook:** Server Settings → **Integrations → Webhooks → New Webhook** → channel `#build-log` → **Copy Webhook URL**. ➜ this is `DISCORD_WEBHOOK_URL` for our automation.
5. Create a permanent invite link (Invite People → Edit invite → **Never expire**).

### 3. Telegram — channel + the build-log bot
1. **Channel:** New Channel → name **OpenPaw** → public link `@OpenPaw` (or `@OpenPawCommunity` if taken).
2. **Bot (for automation):** message **@BotFather → `/newbot`** → name `OpenPaw` → username `OpenPawBot` → copy the **token** ➜ `TELEGRAM_BOT_TOKEN`.
3. Add the bot to the channel **as admin**, post one message, then open
   `https://api.telegram.org/bot<TOKEN>/getUpdates` and copy `chat.id` ➜ `TELEGRAM_CHAT_ID`.

### 4. Instagram / TikTok / Facebook — STAY ON PawMe
These are the **consumer / pet-owner** track and already live under **PawMe**.
Keep them as-is — *not* part of the OpenPaw dev rollout. (Cute robot+pet content
lives here; dev build-logs do not.)

### 5. YouTube — build-log videos (OpenPaw)
1. Create a **channel** named **OpenPaw** (use a Brand Account so it's not tied to a personal name: youtube.com → Settings → **Add or manage your channel(s) → Create a channel**).
2. Set handle `@openpaw`, banner, description, link.

### 7. LinkedIn — company page (credibility / press / B2B)
1. **linkedin.com/company/setup/new** → page name **OpenPaw** (under Ayva Labs Limited).
2. Tagline, logo, website link.

### 8. Reserve the name (even if you won't post yet)
- **Reddit:** **post from your existing, aged account** (karma + history = posts don't get auto-filtered). A brand-new `u/OpenPaw` account would look like marketing and get removed. Optionally register `u/OpenPaw` just to *hold* the name, but don't post promo from it. Always disclose you're the maker, per each subreddit's self-promo rules.
- **Hackaday.io / Hackster.io:** create the project under the OpenPaw name.
- **GitHub:** ✅ already `github.com/ayvalabs/openpaw`.

### 9. Domain (recommended)
Register **openpaw.dev** (or `.pet` / `.xyz`). Point it at the website later and
update every "link" field from the GitHub hub to the domain.

---

## After you've created them — wire up + update

1. **Feed the automation** (Discord + Telegram are auto-post channels):
   ```bash
   cd openpaw-marketing && bash scripts/setup-channels.sh
   # paste DISCORD_WEBHOOK_URL, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
   gh secret set DISCORD_WEBHOOK_URL --repo ayvalabs/openpaw-firmware
   gh secret set TELEGRAM_BOT_TOKEN  --repo ayvalabs/openpaw-firmware
   gh secret set TELEGRAM_CHAT_ID    --repo ayvalabs/openpaw-firmware
   # repeat for openpaw-hardware / -website / -docs
   ```
2. **Tell the team** to use the real handles in the [broadcast runbook](https://github.com/ayvalabs/openpaw-marketing/blob/main/docs/broadcast-runbook.md).
3. **Update the badges/links** in `github.com/ayvalabs/openpaw` and the profile
   README: flip `@PawMe` → `@OpenPaw`, and turn the "coming soon" Discord/Telegram/
   Instagram/YouTube badges into real links. *(Ping me and I'll do this in one pass
   once you give me the final URLs.)*

## Consistency checklist (tick before you call it done)
- [ ] Same **handle** on every platform (or the agreed fallback)
- [ ] Same **avatar** image everywhere
- [ ] Same **bio** text
- [ ] Same **link** (GitHub hub, later the domain)
- [ ] All created under `pawme+openpaw@ayvalabs.com`
- [ ] Discord webhook + Telegram bot token saved into automation
- [ ] README badges + profile links updated to the live handles
