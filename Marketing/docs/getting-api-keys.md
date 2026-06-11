# Getting the API keys for each marketing channel

Run `bash scripts/setup-channels.sh` to enter these interactively. This doc explains how to obtain each one. **Never commit keys** — the script writes them to gitignored `.env` files.

---

## 1. Gemini API key — drafts the build-in-public posts
1. Go to **https://aistudio.google.com/apikey** (Google AI Studio).
2. Sign in → **Create API key** → pick/Create a Google Cloud project.
3. Copy the key → `GEMINI_API_KEY`.
- Free tier is enough for drafting. Keep it server-side only.

## 2. X / Twitter API — auto-posts approved drafts
1. Apply at **https://developer.x.com** for a developer account (Free tier allows posting).
2. **Projects & Apps → create an App.**
3. **User authentication settings → enable OAuth 1.0a → App permissions: Read and Write.**
4. **Keys and tokens** tab:
   - **API Key / Secret** (a.k.a. Consumer Key/Secret) → `X_API_KEY`, `X_API_SECRET`
   - **Access Token / Secret** → `X_ACCESS_TOKEN`, `X_ACCESS_SECRET`
     (regenerate these *after* setting Read+Write, or they'll be read-only).
- Post from the **@OpenPaw** account (rename @PawMe first).

## 3. Discord webhook — live build-log feed
1. In your OpenPaw Discord: **Server Settings → Integrations → Webhooks → New Webhook.**
2. Choose the channel (e.g. `#build-log`), **Copy Webhook URL** → `DISCORD_WEBHOOK_URL`.
- For the GitHub Action: `gh secret set DISCORD_WEBHOOK_URL --repo ayvalabs/openpaw-firmware`.
- No-code alt: paste the URL into GitHub repo **Settings → Webhooks** with `/github` appended.

## 4. Telegram (optional) — second build-log channel
1. In Telegram, message **@BotFather → `/newbot`** → name it → copy the **bot token** → `TELEGRAM_BOT_TOKEN`.
2. Create a channel, **add the bot as admin**, post any message.
3. Open `https://api.telegram.org/bot<TOKEN>/getUpdates` → find `chat.id` → `TELEGRAM_CHAT_ID`.

## 5. Queue backend — where drafts wait for approval
Pick one:
- **Google Sheet (simplest):** create a sheet; the ID is the long string in
  `docs.google.com/spreadsheets/d/<THIS>/edit` → `GOOGLE_SHEET_ID`.
- **Firebase:** use your existing project; `FIREBASE_PROJECT_ID` from project settings.

## 6. Waitlist provider — email capture on the website
Easiest options (any URL that accepts `{ email, source, ts }` JSON):
- **Loops:** https://loops.so → **Settings → API → Incoming webhooks** → copy URL.
- **Zapier/Make:** create a "Catch Hook" / "Custom Webhook" trigger → copy URL.
- **ConvertKit / Mailchimp:** use their form/API endpoint.
Set as `WAITLIST_WEBHOOK_URL` (written to `openpaw-website/.env.local`).

---

## Where keys live
| Use | Location |
|---|---|
| Local scripts (marketing) | `openpaw-marketing/.env` (gitignored) |
| Website (waitlist) | `openpaw-website/.env.local` (gitignored) + Vercel env vars |
| GitHub Actions (Discord, X) | repo **Secrets** via `gh secret set …` |
| Production/shared | a secret manager (Google Secret Manager / Doppler / 1Password) |

## Security rules
- Never commit `.env*`. They're already gitignored.
- If a key leaks (commit, screenshot, log) — **rotate it immediately**.
- Give each key the **least** scope needed (X = Read+Write only, not elevated).
