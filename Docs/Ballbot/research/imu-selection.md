# IMU Selection Research

## Purpose

The IMU provides orientation and acceleration data required for balancing.

## Candidate Sensors

### MPU6050

Pros:

- Low cost
- Widely supported
- Easy ESP32 integration

Cons:

- Higher drift
- Lower accuracy

### BNO055

Pros:

- Built-in sensor fusion
- Better orientation tracking

Cons:

- More expensive

### ICM20948

Pros:

- High accuracy
- Modern sensor

Cons:

- More complex software

## Recommended Initial Sensor

MPU6050

Reason:

Fastest path to prototype development.
