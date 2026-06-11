# 🐾 OpenPaw — Intern Guide: Document Your Work Daily

Welcome! Your job isn't just to build — it's to build **in public**. Every day you
leave a visible trail of what you did. This is how OpenPaw grows a community.

## ⭐ The one rule: every day ends with a DEMO

> **If it's not demoed, it didn't happen.**

Whatever you touched today — firmware blinking an LED, the app showing a video frame,
a servo moving — capture **10–45 seconds** of it working (or failing!). A clip, a GIF,
or a screenshot. No demo = the work is invisible. This is the single most important
habit. Show, don't tell.

---

## 🗓️ Your daily rhythm (~15 min of "documenting", spread across the day)

**While you work** — the moment something *works*, capture it right then (it's
hardest to recreate later). Keep your screen-recorder shortcut ready.

**End of each day — 4 steps:**

1. **Commit** your work with a clear message. If it's interesting to share, start the
   subject with `[post]`:
   ```bash
   git commit -m "[post] servo now sweeps 0-180° on command — first movement!"
   git push
   ```
   → This auto-posts a build-log line to **Discord + Telegram** and queues an **X** draft.

2. **Capture the demo** (see "How to capture" below) and **drop it in Discord `#build-log`**
   (drag-and-drop the video — instant, no editing needed).

3. **Write today's devlog entry** — copy [`devlog/TEMPLATE.md`](devlog/TEMPLATE.md) to
   `devlog/YYYY-MM-DD.md`, fill it in (2 minutes), commit it. This is your public diary.

4. **Approve the X post** if the tool queued one:
   ```bash
   cd openpaw-marketing && make list
   make approve ID=<id> && git add queue/queue.jsonl && git commit -m "approve devlog" && git push
   ```

That's it. Build → show → log → share.

---

## 📡 What goes on which channel

| Channel | What you put there | How often | Auto? |
|---|---|---|---|
| **Git commits** | every change, clear messages | constant | — |
| **`devlog/` in openpaw-docs** | a dated entry: what you did + demo link | **daily** | you write it |
| **Discord `#build-log`** | the build-log line **+ your demo clip** | **daily** | line is auto; clip you drop |
| **X / Twitter** | the best 1 thing that day, with the demo | when share-worthy | drafted, you approve |
| **Telegram** | mirror of the build-log | auto | ✅ |
| **YouTube** | longer milestone demo videos | per milestone | you upload |

> 🚫 **Never post:** secrets/API keys, internal URLs, anything from the private
> `openpaw-app` or AI/data repos. The tools block the private repos automatically —
> don't try to work around it.

---

## 🎥 How to capture a demo (do this every day)

**Screen / app / firmware logs (macOS):**
- `Cmd + Shift + 5` → record a region or whole screen → stop → drag the clip into Discord.
- GIFs: [Kap](https://getkap.co) or Gifox — great for short loops in the devlog.

**The physical robot / hardware:**
- Just film it with your **phone**, 15–30 sec, landscape. Show the thing moving/working.
- Narrate one sentence: "today the laser module turns on from a serial command."

**Keep it honest:** broken stuff is great content. A clip captioned *"spent 3 hrs on
this gait, here's it faceplanting 😅"* gets more love than a polished nothing.

**Where demo media lives:**
- **Discord** = the daily home (drag-drop, no size fuss).
- **Milestone videos** → upload to **YouTube** (link it in the devlog + X).
- **GIFs/screenshots for the devlog** → put small ones in `openpaw-docs/devlog/media/`.
- **Raw/large footage** → the shared **Google Drive → "OpenPaw Demos"** folder (ask the lead for the link).

---

## 🔧 Channels still to set up (do these once, early)

Some channels aren't wired yet. Work through this with the lead:

### A. Social accounts
Follow [`social-handles-setup.md`](social-handles-setup.md) to create/claim the
**OpenPaw** (dev) handles. (Instagram/TikTok stay on **PawMe** — not your job.)

### B. Automation secrets (so `git push` actually posts)
```bash
cd openpaw-marketing
bash scripts/setup-channels.sh          # paste keys when prompted (ask the lead)
```
Then add the same values as **GitHub repo secrets** so the Actions can post:
```bash
# Discord build-log feed:
gh secret set DISCORD_WEBHOOK_URL --repo ayvalabs/openpaw-firmware
# Telegram build-log feed:
gh secret set TELEGRAM_BOT_TOKEN  --repo ayvalabs/openpaw-firmware
gh secret set TELEGRAM_CHAT_ID    --repo ayvalabs/openpaw-firmware
# (repeat for openpaw-hardware, openpaw-website, openpaw-docs)

# X drafting (only on the marketing repo):
gh secret set GEMINI_API_KEY  --repo ayvalabs/openpaw-marketing
gh secret set X_API_KEY       --repo ayvalabs/openpaw-marketing
gh secret set X_API_SECRET    --repo ayvalabs/openpaw-marketing
gh secret set X_ACCESS_TOKEN  --repo ayvalabs/openpaw-marketing
gh secret set X_ACCESS_SECRET --repo ayvalabs/openpaw-marketing
```
Where to get each key: [`openpaw-marketing/docs/getting-api-keys.md`](https://github.com/ayvalabs/openpaw-marketing/blob/main/docs/getting-api-keys.md).

### C. Demo media home
- Create the shared **Google Drive → "OpenPaw Demos"** folder (lead shares it with you).
- Make sure the **YouTube** channel exists (in the handles doc) for milestone videos.

### D. Test it works
Push a tiny commit with `[post]` and confirm a message lands in Discord `#build-log`.
If nothing shows, the secret isn't set — re-check step B.

---

## 🧾 Daily devlog entry — what good looks like

Copy [`devlog/TEMPLATE.md`](devlog/TEMPLATE.md). A great entry is short and has a demo:

```markdown
# 2026-06-02 — Servo control over serial

**Did:** Wired the 'm' serial command to drive servo 1 to an angle. First real movement.
**Demo:** ![servo sweep](media/2026-06-02-servo.gif)  (also in Discord #build-log)
**Blocked / learned:** PWM jittered until I moved init out of the loop.
**Next:** map all 4 legs to the gait table.
```

---

## ✅ End-of-day checklist (pin this)

- [ ] Code committed & pushed (used `[post]` if share-worthy)
- [ ] **Demo captured** and dropped in Discord `#build-log`
- [ ] `devlog/YYYY-MM-DD.md` written & committed
- [ ] X draft approved (if one was queued)
- [ ] Anything secret/private kept OUT of all of the above

## When in doubt
Ask the lead before posting anything you're unsure about. And remember the rule:
**ship a demo every single day.** 🐾
