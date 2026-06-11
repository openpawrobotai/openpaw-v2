# OpenPaw — Hardware Revisions & Compatibility

## Revision log
| Rev | Status | Basis | Notes |
|---|---|---|---|
| `hw-v1.0` (esp32_ball_v1) | reference | ESP-32 camera ball (open source) | replication target (#14) |
| `hw-v2.0` | in progress | v1 + laser pointer + temp sensors | #17/#18 |
| `openpaw` | planned | final robot chassis | #20 |

## Compatibility matrix
Each firmware build embeds its supported `hw_rev` and refuses to run/OTA onto an incompatible board.

| Firmware | Hardware rev | Min app |
|---|---|---|
| fw 1.0.x | hw-v1.0 | 1.0.0 |
| fw 1.1.x | hw-v1.0, hw-v2.0 | 1.1.0 |
| fw 1.2.x | hw-v2.0, openpaw | 1.3.0 |

## Versioning
- Hardware: `hw-vMAJOR.MINOR` — MAJOR = re-fab/new spin, MINOR = rework.
- Firmware: semver; MAJOR = breaking protocol/hardware change.
- App: semver; declares min firmware.
