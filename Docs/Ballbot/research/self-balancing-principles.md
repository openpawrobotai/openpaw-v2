# Self-Balancing Principles

## Objective

The BallBot must maintain stability while balancing on a single spherical wheel.

## Core Concepts

### Inverted Pendulum

The robot behaves similarly to an inverted pendulum.

The controller continuously measures tilt angle and moves the ball underneath the center of mass to prevent falling.

### Feedback Control

A feedback loop continuously performs:

1. Read IMU data
2. Calculate tilt angle
3. Compute correction
4. Drive motors
5. Repeat

## Control Methods

### PID Control

Most common approach.

Components:

- P = Proportional
- I = Integral
- D = Derivative

Advantages:

- Simple
- Reliable
- Easy to tune

### State Space Control

Advanced control method used in research-grade BallBots.

Advantages:

- Better stability
- Handles multiple axes simultaneously

## Future Work

- PID implementation
- Kalman filtering
- State-space control evaluation
