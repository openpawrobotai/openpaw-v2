# 🐾 OpenPaw Robot — V2 (Custom Rolling Robot, Sep 2025 – Jan 2026)

The second generation of the **OpenPaw / PawMe** robot: still a rolling sphere robot like
[V1](https://github.com/openpawrobotai/openpaw-v1), but **fully re-engineered in-house** —
from-scratch mechanical design and a custom PCBA with an expanded sensor suite.
**Ten units were built, tested and shipped.**

## 📖 What Was Done (Development History)

**Timeline: 20 Sep 2025 → ~Jan 2026.**

- **20 Sep 2025** — after V1's upstream CAD proved unusable, the team decided to redesign
  every mechanical part from scratch. New 3D-printed parts arrived 23 Sep.
- **27 Sep – 2 Oct 2025** — custom PCBA designed in Fusion 360: ESP32-Sense MCU, camera,
  microphone, speaker connector, laser, distance sensor (VL53-type) and temperature sensor
  (I2C) on one board. Layout finished 27 Sep; PCBs and components ordered 30 Sep.
- **14 Oct 2025** — first custom unit assembled and running — much more stable than V1.
- **23 Oct 2025** — 🎉 **all 10 units assembled and tested.**
- **28–29 Oct 2025** — dedicated I2C sensor verification firmware (distance in cm,
  temperature in °C streamed to console).
- **Nov 2025** — a ~36-minute professional documentation video series was shot covering the
  full build: firmware development, electronics design, mechanical design, manufacturing &
  assembly, OpenAI-QA testing, SD-card setup and final cut (published on the PawMe YouTube
  channel). Units shipped to Hong Kong and Delhi. PawMe branding, social channels and
  website went live Oct–Dec.
- **21 Nov 2025** — mobile app development started (WebView app around the robot's onboard
  web server; later shipped to the Play Store as `ai.ayvalabs.pawme`, 21 Feb 2026).
- **9 Jan 2026** — consolidated firmware repo (`ESP_ROBOT_FIRMWARE`) delivered.
- **Why V2 ended (strategy, not failure):** from 17 Nov 2025 an industrial designer was
  brought in to design a product aimed squarely at the Kickstarter demographic. The concept
  work converged on a desktop companion with an expressive face, tilting head and charging
  dock. On 9 Jan 2026 the team confirmed the new industrial design could no longer fit a
  transparent ball — the sphere was formally retired
  → [V3](https://github.com/openpawrobotai/openpaw-v3).

### Engineering notes worth keeping

- Camera mount clashed with the SD-card slot — foam-spacer workaround (2 Nov 2025).
- SD-card-based firmware workflow (s60sc-style data files on SD) used throughout.
- Sensor firmware acceptance lesson: "basic comms" ≠ "real readings" — verification scope
  must be explicit (28 Oct 2025).

## 📁 Repository Layout

| Folder | Contents |
|:---|:---|
| `Mechanical/` | From-scratch mechanical design *(CAD pending import — see Missing Files)* |
| `Electrical/PCBA Placement Renders/` | Fusion 360 component-placement renders of the custom PCBA (2 Oct 2025) |
| `Firmware/` | *(pending import — see Missing Files)* |
| `Design/` | Industrial design & renders |
| `Docs/Project Docs/` | Vision, architecture, protocol, roadmap, hardware revisions, devlog & intern guide (from `openpaw-docs`) |
| `Docs/Ballbot/` | Ball-robot architecture, milestones, development plan & self-balancing research (from `openpaw-ballbot`) |
| `Docs/ML Knowledge/` | Canine health indicators & signal-to-sensor mapping (from `openpaw-ml`) |
| `Marketing/` | Build-in-public automation: git push → Discord/Telegram/X posts (from `openpaw-marketing`) |
| `Web/openpaw-website (skeleton)/` | Early Next.js waitlist-site skeleton (superseded by `openpaw-website_v1`) |

## ⚠️ Missing Files (known to exist, not yet in this repo)

- **PCBA design source** — the custom board lives in **Fusion 360 cloud**
  (`a360.co/47TX3L1`, shared 2 Oct 2025). No native project, schematics or **Gerbers**
  are archived anywhere in the chat export — they were sent to manufacturing directly.
- **Mechanical CAD** — the from-scratch V2 part designs (3D-print files) were never shared
  in the chat; they're with the mechanical team.
- **Firmware** — lives in two external repos, not yet mirrored:
  - `github.com/Lalith1011/I2C_SENSORS_DATA` (sensor verification firmware, 29 Oct 2025)
  - `github.com/Lalith1011/ESP_ROBOT_FIRMWARE` (consolidated V2 firmware, 9 Jan 2026) —
    presumed ancestor of V3's `PAWME_FIRMWARE_2`
- **BOM** — no final V2 bill of materials was archived.
- **Documentation video series** — the full Nov 2025 video set (~50 clips + 36-min master
  cut) is archived in the team Google Drive
  (`5. Product/History/WhatsApp Chat - Rolling Robot - Pawme/studio/`) and on YouTube;
  raw footage in a separate Drive folder (14 Nov 2025).
- **Mobile app source** — the WebView app (Play Store `ai.ayvalabs.pawme`) source was never
  shared in the chat.

## 🤖 Other Versions

- [openpaw-v1](https://github.com/openpawrobotai/openpaw-v1) — ESP-ROLL replica (spherical ball-bot)
- [openpaw-v3](https://github.com/openpawrobotai/openpaw-v3) — **current generation** (two-wheeled expressive companion)

---

*Part of the OpenPaw project — open-source AI companion robot for the whole family.*
