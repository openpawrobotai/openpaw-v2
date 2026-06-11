#!/usr/bin/env bash
# OpenPaw — announce work done across channels.
#
# Interactive (asks post type + channels, previews before posting):
#   bash scripts/announce.sh --repo openpaw-firmware
#
# Scripted / cron (no prompts):
#   bash scripts/announce.sh --repo openpaw-firmware --channels discord,telegram,x --type progress
#   bash scripts/announce.sh --repo openpaw-firmware --channels reddit,hackernews --copy
#
# Auto channels (discord/telegram) post immediately; X is queued for approval;
# manual channels (reddit/hackernews/hackaday/instagram/linkedin) are written to out/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# activate venv if present
[ -d .venv ] && . .venv/bin/activate || true
# load secrets (GEMINI/DISCORD/TELEGRAM/X) from .env if present
if [ -f .env ]; then set -a; . ./.env; set +a; fi

if ! python -c "import openpaw_marketing" 2>/dev/null; then
  echo "Installing package (first run)…"; pip install -q -e .
fi

exec python -m openpaw_marketing announce "$@"
