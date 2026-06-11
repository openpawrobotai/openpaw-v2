# Sensor Fusion Notes

## Purpose

Combine accelerometer and gyroscope data to obtain stable orientation estimates.

## Methods

### Complementary Filter

Advantages:

- Simple
- Lightweight
- Ideal for ESP32

### Kalman Filter

Advantages:

- Higher accuracy

Disadvantages:

- More computation

## Recommendation

Start with:

- Complementary Filter

Upgrade later:

- Kalman Filter
