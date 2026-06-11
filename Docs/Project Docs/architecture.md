# OpenPaw — Architecture

## Two-layer brain
Separate hard-real-time motion from heavier AI (the Petoi OpenCat pattern). Never run vision and motor control on the same core.

```
        ┌──────────────────────────────────────────────┐
        │            COGNITION (private)                │
        │ edge vision · health analysis · pet-AI model  │
        │       (openpaw-ai · cloud + on-device)        │
        └──────────────▲────────────────┬───────────────┘
                       │ sensor/img      │ high-level intents
        ┌──────────────┴────────────────▼───────────────┐
        │           INSTINCT — ESP-32 firmware            │
        │  gaits · servos · IMU · sensors · Wi-Fi · OTA   │
        │              (openpaw-firmware)                 │
        └──────────────▲────────────────┬───────────────┘
                       │ command proto   │ telemetry
        ┌──────────────┴────────────────▼───────────────┐
        │             Flutter app (openpaw-app)           │
        │   onboarding · control · live video             │
        └─────────────────────────────────────────────────┘
```

## Firmware components
| Component | Responsibility | Task |
|---|---|---|
| motion | gait-table engine + skill data | #14 |
| command | single-token dispatcher (k/m/i/d) over UART/BLE/Wi-Fi | #14, #22 |
| servo | LEDC/MCPWM or PCA9685 | #14 |
| imu | MPU6050 (I²C) | #14 |
| sensors | temperature, laser pointer | #17 |
| net | captive-portal Wi-Fi provisioning | #4 |
| ota | app-mediated OTA + rollback | #15 |

## Board-variant rule
`components/` is board-agnostic; per-revision config lives only in `boards/<variant>/`. ESP-32 Ball → HW v2 → OpenPaw is a build flag, not a rewrite.

## Protocol as contract
Tokens are defined once in `protocol.md` and implemented by both firmware and app. Change the doc first.

## OTA (app-mediated)
Phone pulls `manifest.json` + per-board `.bin` from GitHub Releases → verifies sha256 → streams to board over local link → board writes OTA slot, verifies, reboots, self-validates (else rollback). Board never needs the public internet.

## Data path (private)
Sensors + imagery → on-device buffer → consented upload → dataset in `openpaw-ai` → training → models served to the cognition layer. Schemas/models are not public.
