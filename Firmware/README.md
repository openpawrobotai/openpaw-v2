# 🐾 openpaw-firmware

ESP-IDF firmware for the **OpenPaw** robot companion — motion, sensors, Wi-Fi provisioning, and OTA. Open source (MIT).

> Part of the [OpenPaw](https://github.com/ayvalabs) project by Ayva Labs. Maintainer: **@aeropriest**.

## What this is
The **instinct layer** of OpenPaw: hard-real-time motion and sensor control on the ESP-32. Vision and the pet-health AI run elsewhere (private `openpaw-ai`) — never on this MCU.

## Architecture (two-layer brain)
- Board-agnostic logic lives in `components/`.
- Per-revision pin maps & config live in `boards/<variant>/`.
- Switching ESP-32 Ball → HW v2 → OpenPaw is a build-config change, not a rewrite.

```
firmware/
├── main/app_main.c        entry point
├── components/
│   ├── motion/            gait-table engine + skill data (walk, sit, balance)
│   ├── command/           single-token command dispatcher (k/m/i/d …)
│   ├── servo/             LEDC/MCPWM or PCA9685 driver
│   ├── imu/               MPU6050 (I²C)
│   ├── sensors/           temperature, laser pointer
│   ├── net/               captive-portal Wi-Fi provisioning
│   └── ota/               app-mediated OTA + rollback
├── boards/                esp32_ball_v1 · hw_v2 · openpaw
└── partitions.csv         dual OTA slots + otadata
```

## Build
```bash
. $IDF_PATH/export.sh
idf.py set-target esp32
idf.py -DOPENPAW_BOARD=esp32_ball_v1 build flash monitor
```
Select the board with `-DOPENPAW_BOARD=<esp32_ball_v1|hw_v2|openpaw>`.

## Command protocol
Single-byte token + payload (mirrors Petoi OpenCat, shared with the app). See `../openpaw-docs/protocol.md`.
| Token | Meaning |
|---|---|
| `k` | run skill/gait (`ksit`, `kbalance`, `kwkF`) |
| `m` | move joint(s) `m<idx> <angle>` |
| `i` | indexed multi-servo set |
| `d` | rest / info |

## OTA (app-mediated)
The phone pulls `manifest.json` + the per-board `.bin` from GitHub Releases, verifies sha256, and streams it to the board over the local link. Board writes to an OTA slot, verifies, reboots, self-validates (else auto-rollback). See `.github/workflows/firmware-release.yml`.

## Roadmap
Tasks #14–#21: replicate ESP-32 Ball → OTA → extend sensors → validate per hardware revision → run on OpenPaw. Full list in `../openpaw-docs/roadmap.md`.

## License
MIT © 2026 aeropriest
