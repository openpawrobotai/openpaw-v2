#!/usr/bin/env bash
# OpenPaw — marketing channel setup
# Interactively collects API keys/tokens for each channel and writes them to
# the right .env files. Nothing is committed (.env files are gitignored).
# Secret values are read WITHOUT echoing to the terminal.
#
# Full step-by-step for obtaining each key: docs/getting-api-keys.md
#
# Usage:  bash scripts/setup-channels.sh
# License: MIT (c) 2026 aeropriest

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
WEBSITE_ENV="$ROOT/../openpaw-website/.env.local"

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
dim()  { printf "\033[2m%s\033[0m\n" "$1"; }
hr()   { printf -- "----------------------------------------------------------------\n"; }

# ask VAR "Prompt" "how-to hint"  (visible input)
ask() {
  local __var="$1" __prompt="$2" __hint="${3:-}"
  [ -n "$__hint" ] && dim "  $__hint"
  read -r -p "  $__prompt (blank to skip): " __val || true
  printf -v "$__var" '%s' "$__val"
}

# asksecret VAR "Prompt" "how-to hint"  (hidden input)
asksecret() {
  local __var="$1" __prompt="$2" __hint="${3:-}"
  [ -n "$__hint" ] && dim "  $__hint"
  read -r -s -p "  $__prompt (hidden, blank to skip): " __val || true
  echo
  printf -v "$__var" '%s' "$__val"
}

# write_kv FILE KEY VALUE  (only if VALUE non-empty; replaces existing line)
write_kv() {
  local file="$1" key="$2" val="$3"
  [ -z "$val" ] && return 0
  touch "$file"
  # remove any existing line for this key, then append
  grep -v "^${key}=" "$file" > "${file}.tmp" 2>/dev/null || true
  mv "${file}.tmp" "$file"
  printf '%s=%s\n' "$key" "$val" >> "$file"
}

clear || true
bold "🐾 OpenPaw — marketing channel setup"
dim  "Press Enter to skip any value you don't have yet. Re-run anytime to add more."
dim  "Detailed how-to: openpaw-marketing/docs/getting-api-keys.md"
hr

bold "1) Gemini (drafts build-in-public posts)"
asksecret GEMINI_API_KEY "GEMINI_API_KEY" \
  "Get it free at https://aistudio.google.com/apikey (Google AI Studio → Create API key)."
hr

bold "2) X / Twitter (auto-posts approved devlog drafts)"
dim  "Create an app at https://developer.x.com → Projects & Apps → Keys and tokens."
dim  "You need Read+Write permission, then generate all four below."
asksecret X_API_KEY        "X_API_KEY (Consumer API Key)"
asksecret X_API_SECRET     "X_API_SECRET (Consumer API Secret)"
asksecret X_ACCESS_TOKEN   "X_ACCESS_TOKEN"
asksecret X_ACCESS_SECRET  "X_ACCESS_SECRET"
hr

bold "3) Discord (live build-log feed on every push/release)"
asksecret DISCORD_WEBHOOK_URL "DISCORD_WEBHOOK_URL" \
  "Discord → Server Settings → Integrations → Webhooks → New Webhook → Copy URL."
hr

bold "4) Telegram (optional second build-log channel)"
asksecret TELEGRAM_BOT_TOKEN "TELEGRAM_BOT_TOKEN" \
  "Message @BotFather → /newbot → copy the token."
ask       TELEGRAM_CHAT_ID   "TELEGRAM_CHAT_ID" \
  "Add the bot to your channel, post once, then open https://api.telegram.org/bot<TOKEN>/getUpdates and copy chat.id."
hr

bold "5) Queue backend (where drafts wait for your approval)"
ask QUEUE_BACKEND "QUEUE_BACKEND [sheet|firebase] (default: sheet)"
QUEUE_BACKEND="${QUEUE_BACKEND:-sheet}"
if [ "$QUEUE_BACKEND" = "sheet" ]; then
  ask GOOGLE_SHEET_ID "GOOGLE_SHEET_ID" \
    "The long ID in your Google Sheet URL: docs.google.com/spreadsheets/d/<THIS>/edit"
else
  ask FIREBASE_PROJECT_ID "FIREBASE_PROJECT_ID" "From the Firebase console project settings."
fi
hr

bold "6) Waitlist provider (email capture on the website)"
dim  "Easiest: a Loops 'incoming webhook' or a Zapier/Make catch-hook URL."
ask WAITLIST_WEBHOOK_URL "WAITLIST_WEBHOOK_URL" \
  "Loops: https://loops.so → Settings → API → Incoming webhooks. Or any catch-hook URL."
hr

# --- write files ---
write_kv "$ENV_FILE" GEMINI_API_KEY        "${GEMINI_API_KEY:-}"
write_kv "$ENV_FILE" X_API_KEY             "${X_API_KEY:-}"
write_kv "$ENV_FILE" X_API_SECRET          "${X_API_SECRET:-}"
write_kv "$ENV_FILE" X_ACCESS_TOKEN        "${X_ACCESS_TOKEN:-}"
write_kv "$ENV_FILE" X_ACCESS_SECRET       "${X_ACCESS_SECRET:-}"
write_kv "$ENV_FILE" DISCORD_WEBHOOK_URL   "${DISCORD_WEBHOOK_URL:-}"
write_kv "$ENV_FILE" TELEGRAM_BOT_TOKEN    "${TELEGRAM_BOT_TOKEN:-}"
write_kv "$ENV_FILE" TELEGRAM_CHAT_ID      "${TELEGRAM_CHAT_ID:-}"
write_kv "$ENV_FILE" QUEUE_BACKEND         "${QUEUE_BACKEND:-}"
write_kv "$ENV_FILE" GOOGLE_SHEET_ID       "${GOOGLE_SHEET_ID:-}"
write_kv "$ENV_FILE" FIREBASE_PROJECT_ID   "${FIREBASE_PROJECT_ID:-}"
chmod 600 "$ENV_FILE" 2>/dev/null || true

if [ -n "${WAITLIST_WEBHOOK_URL:-}" ]; then
  write_kv "$WEBSITE_ENV" WAITLIST_WEBHOOK_URL "$WAITLIST_WEBHOOK_URL"
  chmod 600 "$WEBSITE_ENV" 2>/dev/null || true
fi

hr
bold "✅ Done."
echo "  Wrote: $ENV_FILE"
[ -n "${WAITLIST_WEBHOOK_URL:-}" ] && echo "  Wrote: $WEBSITE_ENV"
echo
dim "Next steps:"
dim "  • These .env files are gitignored — never commit them."
dim "  • For GitHub Actions (Discord webhook, X poster), add the same values as"
dim "    repo Secrets:  gh secret set DISCORD_WEBHOOK_URL --repo <owner>/openpaw-firmware"
dim "  • Rotate any key immediately if it ever lands in a commit or screenshot."
