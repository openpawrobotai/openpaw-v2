# 🔧 Hardware Architecture

## Overview

This document describes the hardware architecture of the OpenPaw BallBot platform.

The system is designed around an ESP32 microcontroller and integrates sensing, motion control, power management, and communication subsystems required for stable balancing and future autonomous capabilities.

---

# System Architecture

```text
                    OpenPaw BallBot
                           │
 ┌─────────────────────────┼─────────────────────────┐
 │                         │                         │
 ▼                         ▼                         ▼
Control Unit          Motion System          Power System
   ESP32              Motors & Drivers       Battery Pack
```

---

# Hardware Subsystems

## 1. Control Unit

The control unit serves as the central processing component of the robot.

### Responsibilities

* Sensor data acquisition
* State estimation
* Balance control
* Motor command generation
* Wireless communication

### Primary Controller

| Component | Description          |
| --------- | -------------------- |
| ESP32     | Main processing unit |

---

## 2. Sensor System

The sensor system provides real-time information about the robot's orientation and environment.

### IMU Sensors

| Sensor           | Purpose                         |
| ---------------- | ------------------------------- |
| MPU6050 / BNO055 | Orientation and motion tracking |

### Future Sensors

| Sensor            | Purpose                      |
| ----------------- | ---------------------------- |
| Ultrasonic Sensor | Obstacle detection           |
| ToF Sensor        | Precise distance measurement |
| Camera Module     | Vision-based navigation      |

---

## 3. Motion System

The motion subsystem generates movement and balancing forces.

### Components

| Component      | Purpose                     |
| -------------- | --------------------------- |
| BLDC Motors    | Ball movement and balancing |
| Motor Driver   | Motor power control         |
| Encoder System | Position feedback           |

### Functions

* Self-balancing
* Direction control
* Speed control
* Stability correction

---

## 4. Power System

The power subsystem provides regulated energy to all components.

### Components

| Component                       | Purpose                   |
| ------------------------------- | ------------------------- |
| Li-Ion Battery Pack             | Main power source         |
| Battery Management System (BMS) | Protection and monitoring |
| Voltage Regulators              | Stable voltage output     |

### Safety Features

* Over-current protection
* Over-voltage protection
* Battery monitoring
* Emergency shutdown support

---

## 5. Communication System

The communication layer enables wireless interaction with external devices.

### Interfaces

| Interface   | Purpose                      |
| ----------- | ---------------------------- |
| Wi-Fi       | Telemetry and remote control |
| Bluetooth   | Local configuration          |
| OTA Updates | Firmware upgrades            |

---

# Data Flow

```text
IMU Sensors
      │
      ▼
    ESP32
      │
      ▼
 Balance Controller
      │
      ▼
 Motor Drivers
      │
      ▼
 BLDC Motors
      │
      ▼
 Ball Movement
```

---

# Future Hardware Expansion

The architecture is intentionally modular to support future upgrades:

* Advanced IMU sensors
* Computer vision modules
* Autonomous navigation sensors
* AI co-processors
* Multi-battery configurations
* High-performance motor systems

---

# Design Goals

The hardware platform is designed to achieve:

* Stable self-balancing
* Low-latency control
* Modular expansion
* Energy efficiency
* Open-source accessibility
* Cost-effective manufacturing

---

# Revision Status

Version: Draft v1.0

Status: Under Development

Last Updated: June 2026
