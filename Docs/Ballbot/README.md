<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:00d4ff,50:7c3aed,100:06b6d4&height=200&section=header&text=OpenPaw%20BallBot&fontSize=52&fontColor=ffffff&fontAlignY=38&desc=Open-Source%20ESP32%20Spherical%20Self-Balancing%20Robot&descAlignY=58&descSize=18&animation=fadeIn" alt="OpenPaw BallBot Header"/>

<br/>

<!-- Badges -->
<p>
  <img src="https://img.shields.io/badge/License-MIT-00d4ff?style=for-the-badge&logo=open-source-initiative&logoColor=white" alt="MIT License"/>
  <img src="https://img.shields.io/badge/Status-Research%20%26%20Development-f59e0b?style=for-the-badge&logo=statuspage&logoColor=white" alt="Status"/>
  <img src="https://img.shields.io/badge/Platform-ESP32-7c3aed?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32"/>
  <img src="https://img.shields.io/badge/PRs-Welcome-34d399?style=for-the-badge&logo=github&logoColor=white" alt="PRs Welcome"/>
  <img src="https://img.shields.io/badge/Made%20with-❤️-f472b6?style=for-the-badge" alt="Made with love"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Firmware-ESP32%20FreeRTOS-ff6b6b?style=flat-square&logo=freertos" alt="FreeRTOS"/>
  <img src="https://img.shields.io/badge/Control-PID%20%7C%20Kalman-00d4ff?style=flat-square" alt="Control"/>
  <img src="https://img.shields.io/badge/Connectivity-WiFi%20%7C%20BLE%20%7C%20OTA-818cf8?style=flat-square" alt="Connectivity"/>
  <img src="https://img.shields.io/badge/Mobile-Cross%20Platform-34d399?style=flat-square&logo=flutter" alt="Mobile"/>
</p>

<br/>

> **🤖 A low-cost, modular, and extensible open-source spherical robotics platform**  
> *combining modern control systems, wireless connectivity, sensor fusion, and future AI capabilities.*

<br/>

<p>
  <a href="#-project-vision">Vision</a> •
  <a href="#-planned-features">Features</a> •
  <a href="#-high-level-architecture">Architecture</a> •
  <a href="#-repository-structure">Structure</a> •
  <a href="#-documentation">Docs</a> •
  <a href="#-current-status">Status</a> •
  <a href="#-contributing">Contributing</a>
</p>

</div>

---

## 🚀 Project Vision

**OpenPaw BallBot** is an open-source, ESP32-powered, self-balancing spherical robot designed as a complete, extensible research and learning platform.

The goal is to create an accessible robotics platform that allows developers, students, and researchers to explore:

| Domain | Focus Areas |
|--------|-------------|
| 🤖 **Robotics** | Self-balancing, motion control, sensor fusion |
| 💻 **Embedded** | ESP32 architecture, real-time systems, RTOS |
| 📡 **Connectivity** | WiFi, Bluetooth, OTA, remote monitoring |
| 🗺️ **Navigation** | Autonomous movement, localization, SLAM |
| 🧠 **AI** | Neural networks, reinforcement learning, vision |

---

## ✨ Planned Features

<details>
<summary><b>🎯 Core Robotics</b></summary>

```
✅ Self-balancing control system (PID)
✅ ESP32 dual-core 240MHz architecture
✅ Real-time sensor processing (FreeRTOS)
✅ Motor control and stabilization
✅ Wireless communication stack
```

</details>

<details>
<summary><b>📡 Connectivity</b></summary>

```
✅ WiFi control interface
✅ Bluetooth setup and pairing
✅ OTA (Over-the-Air) firmware updates
✅ Remote monitoring dashboard
```

</details>

<details>
<summary><b>📱 Mobile Experience</b></summary>

```
✅ Cross-platform mobile application
✅ Live telemetry dashboard
✅ Robot configuration tools
🔜 Future mapping interface
```

</details>

<details>
<summary><b>🔬 Research & Development</b></summary>

```
🔜 Localization systems (SLAM)
🔜 Autonomous navigation
🔜 Sensor fusion algorithms (Kalman)
🔜 Computer vision experiments
🔜 AI-assisted autonomous behavior
```

</details>

---

## 📂 Repository Structure

```
openpaw-ballbot/
│
├── 📱 app/           → Mobile application (React Native / Flutter)
├── 💻 firmware/      → ESP32 firmware (C++ / FreeRTOS)
├── ⚙️  hardware/      → Hardware documentation & BOM
├── 🔌 pcba/          → PCB schematic & layout files (KiCad)
├── 🔩 cad/           → Mechanical CAD models (STEP / STL)
├── 🎥 media/         → Images, renders, demo videos
├── 🔬 research/      → Research notes, papers, references
└── 📚 docs/          → Full project documentation
```

---

## 🏗️ High-Level Architecture

```
                     OpenPaw BallBot
                            │
       ┌────────────────────┼─────────────────────┐
       │                    │                     │
       ▼                    ▼                     ▼
   Firmware            Mobile App           Documentation
  (ESP32)               (Client)             & Research
       │
       ▼
  ┌─────────────────────────────────────┐
  │            Sensor Layer             │
  │  ├─ IMU / Gyroscope (MPU6050)       │
  │  ├─ Wheel Encoders                  │
  │  ├─ Distance Sensors (ToF)          │
  │  └─ Power Monitor (INA219)          │
  └────────────────┬────────────────────┘
                   │
  ┌────────────────▼────────────────────┐
  │           Control Layer             │
  │  ├─ PID Controller                  │
  │  ├─ State Manager (FreeRTOS)        │
  │  ├─ Motion Planner                  │
  │  └─ Safety & Watchdog Systems       │
  └────────────────┬────────────────────┘
                   │
  ┌────────────────▼────────────────────┐
  │        Communication Layer          │
  │  ├─ WiFi (802.11 b/g/n)            │
  │  ├─ Bluetooth LE (BLE 5.0)         │
  │  ├─ REST / WebSocket APIs           │
  │  └─ OTA Firmware Updates            │
  └─────────────────────────────────────┘
```

---

## 📚 Documentation

All project documentation lives inside the `docs/` directory:

| Document | Description |
|----------|-------------|
| `roadmap.md` | Full project roadmap and milestones |
| `architecture.md` | System architecture overview |
| `hardware-arch.md` | Hardware architecture & component selection |
| `software-arch.md` | Software architecture & firmware design |
| `development-plan.md` | Development timeline & sprint planning |
| `milestones.md` | Project milestones and deliverables |

---

## 🎯 Current Status

> 🟡 **Research & Development Phase**

```
[██████████░░░░░░░░░░]  50%  Overall Progress

System Architecture  ████████████████░░░░  80%
Hardware Planning    ██████████████░░░░░░  70%
Firmware Foundation  ████████░░░░░░░░░░░░  40%
Documentation        ██████████░░░░░░░░░░  50%
Research & Proto     ████████░░░░░░░░░░░░  40%
PCB Design           ████░░░░░░░░░░░░░░░░  20%
Mobile App           ██░░░░░░░░░░░░░░░░░░  10%
```

**Active work areas:**
- 🔍 System architecture definition
- 🔧 Hardware component planning
- 💻 Firmware project scaffolding
- 📝 Documentation writing
- 🧪 Research and prototyping

---

## 🗺️ Roadmap

| Phase | Title | Status |
|-------|-------|--------|
| **Phase 1** | Research & Planning | 🟡 Active |
| **Phase 2** | Firmware Foundation | ⏳ Upcoming |
| **Phase 3** | Self-Balancing MVP | 🔮 Future |
| **Phase 4** | Autonomous Navigation | 🔮 Future |
| **Phase 5** | AI & Computer Vision | 🔮 Future |

---

## 🤝 Contributing

Contributions, ideas, discussions, and feedback are genuinely welcome!

### Areas to contribute:

```
🔌 Embedded Systems    → ESP32 firmware, HAL, drivers
📐 Control Algorithms  → PID tuning, Kalman, state machines
⚡ Electronics         → PCB design, schematics, power
🔩 Mechanical Design   → CAD, 3D printing, assembly
📱 Mobile Dev          → React Native / Flutter app
📚 Documentation       → Guides, tutorials, API docs
🧪 Testing             → Unit tests, HIL, CI/CD
🔬 Research            → Papers, algorithms, experiments
```

### How to contribute:

```bash
# 1. Fork the repository
git clone https://github.com/YOUR_USERNAME/openpaw-ballbot.git

# 2. Create a feature branch
git checkout -b feature/your-amazing-feature

# 3. Make your changes and commit
git commit -m "feat: add amazing feature"

# 4. Push and open a Pull Request
git push origin feature/your-amazing-feature
```

---

## 📜 License

This project is released under the **MIT License**.

```
MIT License — Copyright (c) 2024 OpenPaw BallBot Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

See [LICENSE](LICENSE) for full details.

---

## ⭐ Support the Project

If you find this project interesting or useful:

<div align="center">

| Action | Impact |
|--------|--------|
| ⭐ **Star** the repository | Increases visibility |
| 👁️ **Watch** for updates | Stay informed |
| 🍴 **Fork** and contribute | Grow the project |
| 💬 **Share** feedback | Improve direction |
| 🐛 **Report** issues | Improve quality |

**Together, we can build an accessible open-source robotics platform for learning, experimentation, and innovation.**

<br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:06b6d4,50:7c3aed,100:00d4ff&height=120&section=footer&animation=fadeIn" alt="Footer"/>

</div>
