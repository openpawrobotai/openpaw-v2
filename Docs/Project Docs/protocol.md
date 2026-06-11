# OpenPaw — Device ↔ App Command Protocol

A single-byte **token** + payload, parsed in the firmware command loop. Implemented identically by `openpaw-firmware/components/command/` and `openpaw-app/lib/services/`. Same protocol over UART (bench), BLE, and Wi-Fi. Modelled on Petoi OpenCat.

## Tokens
| Token | Meaning | Example |
|---|---|---|
| `k` | run a **skill/gait** by name (suffix dropped) | `ksit`, `kbalance`, `kwkF` (walk fwd), `kwkL`/`kwkR`, `ktrL` |
| `m` | move **one joint**: `m<index> <angle>` (chainable) | `m0 30`, `m8 40 8 -35` |
| `i` | indexed multi-servo set | `i 0 30 8 -15` |
| `c` | calibration mode (combined with `m`) | `c` |
| `d` | rest / shutdown servos · also returns device info | `d` |
| `b` | beep / buzzer | `b` |
| `g` | toggle gyro (IMU balance) | `g` |

## Device info response (for OTA)
`d` returns JSON so the app knows what firmware/board it's talking to:
```json
{ "board": "openpaw", "fw_version": "1.2.0", "hw_rev": "hw-v2.0" }
```
The app uses this to pick the right `.bin` from the OTA manifest and decide whether an update is needed.

## Rules
- The board rejects any OTA image whose `hw_rev` doesn't match its own.
- New tokens are added **here first**, then implemented on both sides.
