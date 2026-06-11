# Localization Options

## Objective

Determine robot position indoors.

## Option 1: LiDAR

Pros:

- Accurate mapping
- Industry standard

Cons:

- Expensive
- Increased hardware cost

## Option 2: Visual Odometry

Pros:

- Uses camera

Cons:

- Computationally expensive
- Difficult on ESP32

## Option 3: Marker-Based Localization (Auki)

Pros:

- Easy deployment
- Smartphone-assisted
- Low onboard computation

Cons:

- Requires markers

## Current Direction

Marker-based localization using Auki SDK.

Potential workflow:

1. User places markers
2. Phone scans markers
3. Position is calculated
4. Coordinates sent to robot
5. Robot navigates using received location data
