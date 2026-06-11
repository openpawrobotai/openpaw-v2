# OpenPaw — Channels & Branding

One brand everywhere: **OpenPaw**. Two funnels: open-source credibility, and a commercial waitlist that converts to crowdfunding backers.

## Branding actions
- [ ] **Rename X @PawMe → @OpenPaw** (keeps followers + account age). Pin a "we're now OpenPaw, going open source" tweet.
- [ ] If `@OpenPaw` is taken, choose ONE fallback (`@OpenPawHQ` / `@OpenPawRobot` / `@getopenpaw`) and use it on every platform.
- [ ] Secure the name on X, Instagram, TikTok, YouTube, Telegram, Discord vanity (check with namechk).
- [ ] Register a domain (`openpaw.dev` / `.pet` / `.xyz`).
- [ ] Rename the Telegram board → OpenPaw (or `@OpenPawCommunity`).
- [ ] Create the OpenPaw **Discord** server (home of the build-log feed).

## Channel strategy

### Funnel A — open-source / maker credibility
| Channel | Automatable from git | Cadence |
|---|---|---|
| GitHub repos + Releases | ✅ fully | per release |
| Discord/Telegram build-log webhook | ✅ fully | per push |
| X (dev side) | ⚠️ auto-draft, human approves | ~daily |
| Hackaday.io / Hackster.io | ❌ manual | milestones |
| Reddit (r/robotics, r/esp32, r/embedded) | ❌ manual, milestone-only | every 2–3 wks |
| Hacker News (Show HN) | ❌ manual | rare, big moments |
| YouTube build logs | ❌ manual edit | per milestone |

### Funnel B — commercial / crowdfunding
| Channel | Note |
|---|---|
| **Email waitlist + landing** | 🔑 #1 predictor of crowdfunding success — build NOW (see openpaw-website) |
| Kickstarter/Indiegogo pre-launch page | reserve audience before launch |
| Instagram + TikTok | cute robot + pet = viral; drives signups |
| Facebook pet groups | where pet owners are |
| Pet-niche partners (groomers, vets, shops) | collabs, QR posters |
| Press / PR | spike at launch |

## Automation rule
Automate the **drumbeat** (dev progress → Discord + X drafts + Releases). Hand-craft the **spikes** (launches, Show HN, crowdfunding updates, viral video). Never automate Reddit/HN/Instagram — it gets you banned or looks like spam.

## What's wired up
- **Discord webhook:** `openpaw-firmware/.github/workflows/discord-notify.yml` (copy to each public repo; set `DISCORD_WEBHOOK_URL` secret).
- **Email waitlist:** `openpaw-website` (`/api/waitlist` + `WaitlistForm`); set `WAITLIST_WEBHOOK_URL`.
- **X devlog drafts:** `openpaw-marketing` (`[post]` commits / release tags → review queue → X).
