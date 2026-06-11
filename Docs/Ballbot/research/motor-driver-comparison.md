# Motor Driver Comparison

## Requirements

- Precise speed control
- Fast response
- ESP32 compatibility

## Candidate Drivers

### BTS7960

Pros:

- High current support
- Inexpensive

Cons:

- Large size

### VESC

Pros:

- Excellent BLDC support
- Professional-grade

Cons:

- Expensive

### SimpleFOC Shield

Pros:

- Designed for balancing robots
- FOC support

Cons:

- Additional complexity

## Recommendation

Initial prototype:

- BTS7960 (DC motors)

Future versions:

- VESC + BLDC motors
